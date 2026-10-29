"""Optional in-game profiler tests; real Lua code and controlled client counters."""
from pathlib import Path
from typing import Any
import unittest

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
PROBE = ROOT / "budsUI_Perf/Performance.lua"


class ProbeRuntime:
    def __init__(self, profiling="1"):
        self.lua: Any = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute((ROOT / "tests/wow_stub.lua").read_text(encoding="utf-8-sig"))
        self.lua.execute("""
            Test.cvars = { scriptProfile = '1' }
            Test.cpu, Test.calls, Test.addonCPU = {}, {}, { budsUI = 100 }
            Test.combat, Test.reloads, Test.resets = false, 0, 0
            GetCVar = function(key) return Test.cvars[key] end
            SetCVar = function(key, value) Test.cvars[key] = tostring(value) end
            InCombatLockdown = function() return Test.combat end
            ReloadUI = function() Test.reloads = Test.reloads + 1 end
            ResetCPUUsage = function() Test.resets = Test.resets + 1 end
            GetNumAddOns = function() return 1 end
            GetAddOnInfo = function() return 'budsUI', 'budsUI' end
            IsAddOnLoaded = function(name) return name == 'budsUI' end
            UpdateAddOnCPUUsage = function() end
            GetAddOnCPUUsage = function(name) return Test.addonCPU[name] or 0 end
            GetFramerate = function() return 60 end
            GetBuildInfo = function() return '3.3.5', '12340' end
            GetFunctionCPUUsage = function(func, inclusive)
                assert(inclusive == true, 'Script samples must include their callees')
                return Test.cpu[func] or 0, Test.calls[func] or 0
            end
            EnumerateFrames = function(previous)
                if not previous then return Test.frames[1] end
                for i = 1, #Test.frames do
                    if Test.frames[i] == previous then return Test.frames[i + 1] end
                end
            end
            local Frame = getmetatable(UIParent).__index
            function Frame:IsVisible() return self.shown end
            function Frame:UnregisterAllEvents() self.events = {} end
            function Frame:SetMinMaxValues() end
            function Frame:SetVerticalScroll(value) self.scroll = value end
            function Frame:SetScrollChild(child) self.scrollChild = child end
            function Frame:GetStringHeight() return 12 end
            function Frame:SetEnabled(value) self.enabled = value end
            Test.work = function() end
            Test.cpu[Test.work], Test.calls[Test.work] = 50, 10
            Target = CreateFrame('Frame', 'TestTarget', UIParent)
            Target.unit = 'target'
            Target:RegisterEvent('UNIT_AURA')
            Target:SetScript('OnEvent', Test.work)
            Twin = CreateFrame('Frame', 'TestTargetTwin', UIParent)
            Twin:SetScript('OnEvent', Test.work)
            function Tick(elapsed)
                Test.now = Test.now + elapsed
                local count = #Test.frames
                for i = 1, count do
                    local frame = Test.frames[i]
                    local update = frame:GetScript('OnUpdate')
                    if update and frame:IsVisible() then update(frame, elapsed) end
                end
            end
        """)
        self.lua.globals().Test.cvars.scriptProfile = profiling
        self.lua.execute(PROBE.read_text(encoding="utf-8-sig"), "budsUI_Perf", self.lua.table())

    def command(self, value):
        self.lua.globals().SlashCmdList.BUDSUIPERF(value)

    def tick(self, elapsed):
        self.lua.globals().Tick(elapsed)

    def subscriptions(self):
        return [f for f in self.lua.globals().Test.frames.values()
                if f.events["COMBAT_LOG_EVENT_UNFILTERED"] or f.events["UNIT_AURA"]
                and f != self.lua.globals().Target]


class PerformanceProbeTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue(PROBE.is_file(), "Create the optional profiler before running it")

    def test_scan_skips_scripts_unsupported_by_frame_type(self):
        rt = ProbeRuntime()
        rt.lua.execute("""
            local Frame = getmetatable(UIParent).__index
            local getScript = Frame.GetScript
            function Frame:HasScript(script)
                return script ~= 'OnValueChanged' or self.kind == 'Slider'
            end
            function Frame:GetScript(script)
                assert(self:HasScript(script), 'Unsupported frame script: ' .. script)
                return getScript(self, script)
            end
        """)
        rt.command("start")
        rt.tick(0.1)
        rt.command("stop")
        self.assertIsNotNone(rt.lua.globals().budsUI_PerfDB.report)

    def test_idle_probe_has_no_combat_listener_or_ticker(self):
        rt = ProbeRuntime()
        probe = rt.lua.globals().budsUIPerfDriver
        self.assertFalse(probe.IsEventRegistered(probe, "COMBAT_LOG_EVENT_UNFILTERED"))
        self.assertFalse(probe.IsEventRegistered(probe, "UNIT_AURA"))
        self.assertIsNone(probe.GetScript(probe, "OnUpdate"))
        self.assertIsNone(rt.lua.globals().budsUIPerfWindow)

    def test_disabled_native_profiling_refuses_to_start(self):
        rt = ProbeRuntime("0")
        rt.command("start")
        probe = rt.lua.globals().budsUIPerfDriver
        self.assertFalse(probe.IsEventRegistered(probe, "COMBAT_LOG_EVENT_UNFILTERED"))
        self.assertIsNone(probe.GetScript(probe, "OnUpdate"))
        self.assertIsNone(rt.lua.globals().budsUI_PerfDB.report)

    def test_native_samples_use_deltas_and_deduplicate_shared_script(self):
        rt = ProbeRuntime()
        rt.command("start")
        g = rt.lua.globals()
        g.Test.cpu[g.Test.work], g.Test.calls[g.Test.work] = 80, 30
        g.Test.addonCPU.budsUI = 140
        rt.tick(1.0)
        rt.command("stop")
        db = g.budsUI_PerfDB
        self.assertAlmostEqual(db.elapsed, 1.0)
        self.assertEqual(db.addons[1].ms, 40)
        matched = [row for row in db.scripts.values() if "TestTarget" in row.label]
        self.assertEqual(len(matched), 1, "One shared script is one CPU sample, not one per frame")
        self.assertEqual(matched[0].ms, 30)
        self.assertEqual(matched[0].calls, 20)
        self.assertEqual(g.Test.resets, 0, "Do not reset other addons' profiler counters")

    def test_frame_gaps_and_event_counts_are_recorded_without_chat_spam(self):
        rt = ProbeRuntime()
        rt.command("start")
        g = rt.lua.globals()
        messages = len(g.Test.messages)
        g.Fire("COMBAT_LOG_EVENT_UNFILTERED", 100, "SPELL_PERIODIC_DAMAGE")
        g.Fire("COMBAT_LOG_EVENT_UNFILTERED", 100, "SPELL_PERIODIC_DAMAGE")
        g.Fire("UNIT_AURA", "raid1")
        rt.tick(0.02)
        rt.tick(0.08)
        rt.tick(0.12)
        rt.tick(0.80)
        self.assertEqual(len(g.Test.messages), messages, "Combat sampling must stay quiet")
        rt.command("stop")
        db = g.budsUI_PerfDB
        self.assertEqual(db.cleu, 2)
        self.assertEqual(db.aura, 1)
        self.assertEqual(db.frames, 4)
        self.assertEqual(db.over50, 3)
        self.assertEqual(db.over100, 2)
        self.assertAlmostEqual(db.maxMs, 800)
        self.assertEqual(len(db.windows), 1)
        self.assertIn("UNIT_AURA", db.report)
        self.assertIn("not additive", db.report)

    def test_stop_removes_runtime_work_and_later_events_do_not_change_report(self):
        rt = ProbeRuntime()
        rt.command("start")
        rt.tick(0.1)
        rt.command("stop")
        g = rt.lua.globals()
        saved = g.budsUI_PerfDB.report
        probe = g.budsUIPerfDriver
        self.assertFalse(probe.IsEventRegistered(probe, "COMBAT_LOG_EVENT_UNFILTERED"))
        self.assertFalse(probe.IsEventRegistered(probe, "UNIT_AURA"))
        self.assertIsNone(probe.GetScript(probe, "OnUpdate"))
        g.Fire("UNIT_AURA", "target")
        rt.tick(1.0)
        self.assertEqual(g.budsUI_PerfDB.report, saved)

    def test_enable_and_off_restore_original_profile_cvar(self):
        rt = ProbeRuntime("0")
        rt.command("enable")
        g = rt.lua.globals()
        self.assertEqual(g.Test.cvars.scriptProfile, "1")
        self.assertEqual(g.Test.reloads, 1)
        self.assertEqual(g.budsUI_PerfDB.previousProfile, "0")
        rt.command("off")
        self.assertEqual(g.Test.cvars.scriptProfile, "0")
        self.assertEqual(g.Test.reloads, 2)

    def test_start_and_enable_are_refused_in_combat(self):
        rt = ProbeRuntime()
        rt.lua.globals().Test.combat = True
        rt.command("start")
        rt.command("enable")
        probe = rt.lua.globals().budsUIPerfDriver
        self.assertIsNone(probe.GetScript(probe, "OnUpdate"))
        self.assertEqual(rt.lua.globals().Test.reloads, 0)

    def test_long_capture_keeps_bounded_windows_and_stops_automatically(self):
        rt = ProbeRuntime()
        rt.command("start")
        rt.tick(121.0)
        g = rt.lua.globals()
        probe = g.budsUIPerfDriver
        self.assertIsNone(probe.GetScript(probe, "OnUpdate"))
        self.assertLessEqual(len(g.budsUI_PerfDB.windows), 120)
        self.assertIsNotNone(g.budsUI_PerfDB.report)
        self.assertIsNone(g.budsUIPerfWindow, "Automatic stop must not open a window in combat")


if __name__ == "__main__":
    unittest.main()
