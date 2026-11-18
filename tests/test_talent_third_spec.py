"""Third talent set (WoWCircle): state machine that tracks which build is
mounted in group 2 and drives the .spec toggle button."""
from pathlib import Path
from typing import Any
import unittest

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]

# Two candidate builds for group 2: set 2 (default) and the realm's third set.
# Ranks per talent, tab per column: build 2 signature "530-001", build 3 "005-330".
PRELUDE = r"""
C.Blizzard = { TalentFrame = true }
C.Media.Border_Color = { 0.5, 0.5, 0.5, 1 }

Test.builds = {
    [2] = { [1] = { 5, 3, 0 }, [2] = { 0, 0, 1 } },
    [3] = { [1] = { 0, 0, 5 }, [2] = { 3, 3, 0 } },
}
Test.mounted = 2
Test.numGroups = 2
Test.activeGroup = 2
Test.sent = {}
Test.combat = false

GetNumTalentGroups = function(_, pet) return pet and 0 or Test.numGroups end
GetActiveTalentGroup = function() return Test.activeGroup end
GetNumTalentTabs = function() return 2 end
GetNumTalents = function() return 3 end
GetTalentInfo = function(tab, index, inspect, pet, group)
    if group ~= 2 then return nil end
    local build = Test.builds[Test.mounted]
    return 't' .. tab .. '-' .. index, 'icon' .. index, 1, index, build[tab][index]
end

-- Server side of ".spec N": mounts build N into group 2 and fires the event.
Test.Install = function(n)
    Test.mounted = n
    Fire('PLAYER_TALENT_UPDATE')
end

UnitName = function() return 'Player' end
SendChatMessage = function(...) Test.sent[#Test.sent + 1] = { ... } end
PlaySound = function() end
InCombatLockdown = function() return Test.combat == true end
UIErrorsFrame = { AddMessage = function(_, text, r, g, b) Test.lastError = { text, r, g, b } end }
UpdateMicroButtons = function() end
hooksecurefunc = function() end
TalentMicroButton = CreateFrame('Button', 'TalentMicroButton', UIParent)
StaticPopupDialogs.CONFIRM_TALENT_WIPE = {}
"""


class TalentThirdRuntime:
    def __init__(self):
        self.lua: Any = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute((ROOT / "tests/wow_stub.lua").read_text(encoding="utf-8-sig"))
        self.lua.execute(PRELUDE)
        self.load("budsUI/Modules/Blizzard/ThirdSpec.lua")
        self.load("budsUI/Modules/Blizzard/TalentFrame.lua")

    def load(self, path):
        code = (ROOT / path).read_text(encoding="utf-8-sig")
        self.lua.execute(code, "budsUI-0.7.1", self.lua.globals().Engine)

    def scalar(self, code):
        return self.lua.execute(code)

    def loaded(self):
        return self.scalar("return Test.BudsThird.Store().loaded")

    def sig2(self):
        return self.scalar("return Test.BudsThird.Store().sig[2]")

    def sig3(self):
        return self.scalar("return Test.BudsThird.Store().sig[3]")

    def pending(self):
        return self.scalar("return Test.BudsThird.Pending()")

    def sent(self, index=1, field=1):
        return self.scalar("return Test.sent[%d][%d]" % (index, field))


class TalentThirdSpecTests(unittest.TestCase):
    def test_first_sight_assumes_the_second_set(self):
        rt = TalentThirdRuntime()
        rt.lua.execute("Fire('PLAYER_TALENT_UPDATE')")
        self.assertEqual(rt.loaded(), 2)
        self.assertEqual(rt.sig2(), "530-001")

    def test_signatures_distinguish_the_two_builds(self):
        rt = TalentThirdRuntime()
        self.assertEqual(rt.scalar("return Test.BudsThird.Sig(2)"), "530-001")
        rt.lua.execute("Test.mounted = 3")
        self.assertEqual(rt.scalar("return Test.BudsThird.Sig(2)"), "005-330")

    def test_click_whispers_the_third_set_and_learns_it(self):
        rt = TalentThirdRuntime()
        rt.lua.execute("Test.BudsThird.Click()")
        self.assertEqual(rt.sent(1, 1), ".spec 3")
        self.assertEqual(rt.sent(1, 2), "WHISPER")
        self.assertEqual(rt.sent(1, 4), "Player")
        rt.lua.execute("Test.Install(3)")
        self.assertEqual(rt.loaded(), 3)
        self.assertEqual(rt.sig3(), "005-330")

    def test_click_toggles_back_to_the_second_set(self):
        rt = TalentThirdRuntime()
        rt.lua.execute("Test.BudsThird.Click(); Test.Install(3)")
        rt.lua.execute("Test.BudsThird.Click()")
        self.assertEqual(rt.sent(2, 1), ".spec 2")
        rt.lua.execute("Test.Install(2)")
        self.assertEqual(rt.loaded(), 2)

    def test_click_from_primary_reloads_the_third_set(self):
        # The third set is mounted but the player is playing the PRIMARY spec:
        # the button must load the third set (glow is off), NOT jump to second.
        rt = TalentThirdRuntime()
        rt.lua.execute("Test.BudsThird.Click(); Test.Install(3)")
        rt.lua.execute("Test.activeGroup = 1")
        rt.lua.execute("Test.BudsThird.Click()")
        self.assertEqual(rt.sent(2, 1), ".spec 3")
        rt.lua.execute("Test.Install(3)")
        self.assertEqual(rt.loaded(), 3)

    def test_out_of_band_swap_is_recognized_once_both_builds_known(self):
        rt = TalentThirdRuntime()
        rt.lua.execute("Test.BudsThird.Click(); Test.Install(3)")
        rt.lua.execute("Test.BudsThird.Click(); Test.Install(2)")
        # Another addon (or a relog) mounts the third set behind our back.
        rt.lua.execute("Test.mounted = 3; Fire('PLAYER_TALENT_UPDATE')")
        self.assertEqual(rt.loaded(), 3)
        rt.lua.execute("Test.mounted = 2; Fire('PLAYER_TALENT_UPDATE')")
        self.assertEqual(rt.loaded(), 2)

    def test_combat_blocks_the_toggle(self):
        rt = TalentThirdRuntime()
        rt.lua.execute("Test.combat = true; Test.BudsThird.Click()")
        # No command is sent and the player is told; the machine only seeds its
        # default state (second set) and refuses the toggle.
        self.assertEqual(rt.scalar("return #Test.sent"), 0)
        self.assertEqual(rt.scalar("return Test.lastError[1]"), "Not available in combat")
        self.assertEqual(rt.loaded(), 2)

    def test_double_click_sends_one_command(self):
        rt = TalentThirdRuntime()
        rt.lua.execute("Test.BudsThird.Click(); Test.BudsThird.Click()")
        self.assertEqual(rt.scalar("return #Test.sent"), 1)

    def test_watchdog_times_out_then_late_load_is_recognized(self):
        rt = TalentThirdRuntime()
        # The watchdog unlocks a failed request after WAIT_SECONDS (3): at
        # exactly 3s it holds, just past 3s it drops into the late window.
        rt.lua.execute("Test.BudsThird.Click()")
        rt.lua.execute("Test.now = 103")
        rt.lua.execute("local c = Test.BudsThird.Clock; c.scripts.OnUpdate(c); return nil")
        self.assertTrue(rt.pending())
        rt.lua.execute("Test.now = 104")
        rt.lua.execute("local c = Test.BudsThird.Clock; c.scripts.OnUpdate(c); return nil")
        self.assertFalse(rt.pending())
        self.assertEqual(rt.loaded(), 2)
        # The swap completes inside the late window and is still recognized.
        rt.lua.execute("Test.now = 120; Test.mounted = 3; Fire('PLAYER_TALENT_UPDATE')")
        self.assertEqual(rt.loaded(), 3)

    def test_leaving_world_drops_pending(self):
        rt = TalentThirdRuntime()
        rt.lua.execute("Test.BudsThird.Click()")
        self.assertTrue(rt.pending())
        rt.lua.execute("Fire('PLAYER_LEAVING_WORLD')")
        self.assertFalse(rt.pending())

    def test_legacy_intent_store_migrates_to_loaded(self):
        rt = TalentThirdRuntime()
        # Pre-machine store: only the old "onThird" intent existed.
        rt.lua.execute("""
            budsUIData.CharacterData = { ['Realm-Player'] = { ThirdSpec = { onThird = true } } }
            Test.mounted = 3
            Fire('PLAYER_TALENT_UPDATE')
        """)
        self.assertEqual(rt.loaded(), 3)
        self.assertEqual(rt.sig3(), "005-330")

    def test_unknown_change_updates_the_current_signature(self):
        rt = TalentThirdRuntime()
        rt.lua.execute("Fire('PLAYER_TALENT_UPDATE')")
        self.assertEqual(rt.sig2(), "530-001")
        # A manual respec edits the mounted build in place, so it is not a swap.
        rt.lua.execute("Test.builds[2][1][2] = 5; Fire('PLAYER_TALENT_UPDATE')")
        self.assertEqual(rt.sig2(), "550-001")
        self.assertEqual(rt.loaded(), 2)


if __name__ == "__main__":
    unittest.main()
