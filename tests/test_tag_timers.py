"""oUF tag-event regression tests in real Lua 5.1; only client APIs are stubbed."""
from pathlib import Path
from typing import Any
import unittest

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


class TagRuntime:
    def __init__(self):
        self.lua: Any = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute((ROOT / "tests/wow_stub.lua").read_text(encoding="utf-8-sig"))
        self.lua.execute("""
            format, floor, max = string.format, math.floor, math.max
            local Frame = getmetatable(UIParent).__index
            function Frame:IsVisible()
                return self.shown and (not self.parent or self.parent:IsVisible())
            end
            UnitExists = function(unit) return unit ~= nil end
            UnitIsVisible = UnitExists
            Test.unitHealth = { target = 100, raid1 = 900 }
            Test.unitNames = { target = 'Enemy', raid1 = 'Ally' }
            UnitHealth = function(unit) return Test.unitHealth[unit] or 1 end
            UnitName = function(unit) return Test.unitNames[unit] or unit end
            Engine.oUF = { Private = {
                unitExists = UnitExists,
                validateEvent = function() return true end,
            } }
            function Engine.oUF:RegisterMetaFunction(name, method)
                Frame[name] = method
            end
            function Tick(elapsed)
                Test.now = Test.now + elapsed
                local count = #Test.frames
                for i = 1, count do
                    local frame = Test.frames[i]
                    local callback = frame:GetScript('OnUpdate')
                    if callback and frame:IsVisible() then callback(frame, elapsed) end
                end
            end
        """)
        self.lua.execute((ROOT / "budsUI/Libs/oUF/elements/tags.lua").read_text(encoding="utf-8-sig"),
                         "budsUI", self.lua.globals().Engine)
        self.lua.execute("""
            Target = CreateFrame('Frame', 'TestTarget', UIParent)
            Target.unit, Target.colors, Target.__elements = 'target', {}, {}
            HealthText = Target:CreateFontString()
            NameText = Target:CreateFontString()
            Target:Tag(HealthText, '[curhp]')
            Target:Tag(NameText, '[name]')
            Target:UpdateTags()
        """)

    def fire(self, event, unit):
        self.lua.globals().Fire(event, unit)

    def tick(self, elapsed):
        self.lua.globals().Tick(elapsed)

    def count_frames(self):
        return self.lua.eval("#Test.frames")

    def text(self, name):
        frame = self.lua.globals()[name]
        return frame.GetText(frame)


class TagTimerTests(unittest.TestCase):
    def test_completed_update_cycles_reuse_one_waiter_frame(self):
        # A fresh client frame per completed batch cannot be garbage-collected in WoW.
        rt = TagRuntime()
        rt.fire("UNIT_HEALTH", "target")
        rt.tick(0.11)
        warmed_count = rt.count_frames()
        for value in range(101, 201):
            rt.lua.globals().Test.unitHealth.target = value
            rt.fire("UNIT_HEALTH", "target")
            rt.tick(0.11)
        self.assertEqual(rt.text("HealthText"), "200")
        self.assertEqual(rt.count_frames(), warmed_count,
                         "Finished tag batches must reuse the existing timer, not create 100 more frames")

    def test_foreign_unit_events_do_not_postpone_pending_text(self):
        rt = TagRuntime()
        rt.lua.globals().Test.unitHealth.target = 456
        rt.fire("UNIT_HEALTH", "target")
        rt.tick(0.06)
        rt.fire("UNIT_HEALTH", "raid1")
        rt.tick(0.05)
        self.assertEqual(rt.text("HealthText"), "456",
                         "A raid member's event must not reset the target's pending timer")

    def test_continuous_matching_events_do_not_starve_text_updates(self):
        rt = TagRuntime()
        rt.lua.globals().Test.unitHealth.target = 123
        rt.fire("UNIT_HEALTH", "target")
        rt.tick(0.06)
        rt.lua.globals().Test.unitHealth.target = 456
        rt.fire("UNIT_HEALTH", "target")
        rt.tick(0.05)
        self.assertEqual(rt.text("HealthText"), "456",
                         "Batch from the first event and render the newest value on schedule")

    def test_foreign_event_does_not_queue_unrelated_target_tag(self):
        rt = TagRuntime()
        rt.lua.globals().Test.unitHealth.target = 456
        rt.lua.globals().Test.unitNames.target = "Changed without target event"
        rt.fire("UNIT_HEALTH", "target")
        rt.fire("UNIT_NAME_UPDATE", "raid1")
        rt.tick(0.11)
        self.assertEqual(rt.text("HealthText"), "456")
        self.assertEqual(rt.text("NameText"), "Enemy",
                         "Unit validation must happen before adding an event to the tag batch")

    def test_matching_events_in_one_batch_update_both_tags(self):
        rt = TagRuntime()
        rt.lua.globals().Test.unitHealth.target = 456
        rt.lua.globals().Test.unitNames.target = "New enemy"
        rt.fire("UNIT_HEALTH", "target")
        rt.fire("UNIT_NAME_UPDATE", "target")
        rt.tick(0.11)
        self.assertEqual(rt.text("HealthText"), "456")
        self.assertEqual(rt.text("NameText"), "New enemy")

    def test_unmatched_units_create_no_waiter(self):
        rt = TagRuntime()
        before = rt.count_frames()
        for _ in range(50):
            rt.fire("UNIT_HEALTH", "raid1")
            rt.tick(0.11)
        self.assertEqual(rt.count_frames(), before)
        self.assertEqual(rt.text("HealthText"), "100")

    def test_reused_waiter_respects_updated_interval(self):
        rt = TagRuntime()
        rt.fire("UNIT_HEALTH", "target")
        rt.tick(0.11)
        before = rt.count_frames()
        tags = rt.lua.globals().Engine.oUF.Tags
        tags.SetEventUpdateTimer(tags, 0.2)
        rt.lua.globals().Test.unitHealth.target = 456
        rt.fire("UNIT_HEALTH", "target")
        rt.tick(0.11)
        self.assertEqual(rt.text("HealthText"), "100")
        rt.tick(0.10)
        self.assertEqual(rt.text("HealthText"), "456")
        self.assertEqual(rt.count_frames(), before)


if __name__ == "__main__":
    unittest.main()
