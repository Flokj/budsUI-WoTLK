"""Stance bar holder/mover must resize to the class's actual form count."""
from pathlib import Path
from typing import Any
import unittest

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]

PRELUDE_TEMPLATE = """
C.ActionBar = { Enable = true, StanceBarHide = false, StanceBarHorizontal = %(horizontal)s,
	ButtonSize = 30, ButtonSpace = 4 }
K.Class = "DRUID"

Test.holder = CreateFrame("Frame", "ShiftHolder", UIParent)
for i = 1, 10 do
	local button = CreateFrame("Button", "ShapeshiftButton" .. i, UIParent)
	button:SetID(i)
end

NUM_SHAPESHIFT_SLOTS = 10
GetNumShapeshiftForms = function() return Test.numForms or 6 end
GetShapeshiftFormInfo = function(i)
	if i <= (Test.numForms or 6) then return "some-icon", "Form " .. i, false, true end
end
GetShapeshiftFormCooldown = function() return 0, 0, 0 end
RegisterStateDriver = function() end
hooksecurefunc = function(name, fn)
	Test.hooks = Test.hooks or {}
	Test.hooks[name] = fn
end
InCombatLockdown = function() return Test.inCombat == true end
K.StyleShift = function() end
K.ShiftBarUpdate = function() Test.shiftUpdates = (Test.shiftUpdates or 0) + 1 end
"""


class ShapeshiftBarRuntime:
    def __init__(self, horizontal=True):
        self.lua: Any = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute((ROOT / "tests/wow_stub.lua").read_text(encoding="utf-8-sig"))
        self.lua.execute(
            PRELUDE_TEMPLATE % {"horizontal": "true" if horizontal else "false"})
        self.load("budsUI/Modules/ActionBars/ShapeshiftBar.lua")
        self.lua.execute("Fire('PLAYER_LOGIN')")
        self.lua.execute("Fire('PLAYER_ENTERING_WORLD')")

    def load(self, path):
        code = (ROOT / path).read_text(encoding="utf-8-sig")
        self.lua.execute(code, "budsUI-0.7.1", self.lua.globals().Engine)

    def scalar(self, code):
        return self.lua.execute(code)


class ShapeshiftBarTests(unittest.TestCase):
    def test_horizontal_holder_resizes_to_druid_six_forms(self):
        # 6 forms x 30px + 5 gaps x 4px, not the old hardcoded 3-button size
        rt = ShapeshiftBarRuntime(horizontal=True)
        self.assertEqual(rt.scalar("return Test.holder:GetWidth()"), 200)
        self.assertEqual(rt.scalar("return Test.holder:GetHeight()"), 30)
        self.assertTrue(rt.scalar("return _G['ShapeshiftButton6']:IsShown()"))
        self.assertFalse(rt.scalar("return _G['ShapeshiftButton7']:IsShown()"))

    def test_vertical_holder_resizes_to_druid_six_forms(self):
        rt = ShapeshiftBarRuntime(horizontal=False)
        self.assertEqual(rt.scalar("return Test.holder:GetWidth()"), 30)
        self.assertEqual(rt.scalar("return Test.holder:GetHeight()"), 200)

    def test_deathknight_three_forms_shrink_the_holder(self):
        rt = ShapeshiftBarRuntime(horizontal=True)
        rt.lua.execute("Test.numForms = 3; Fire('UPDATE_SHAPESHIFT_FORMS')")
        self.assertEqual(rt.scalar("return Test.holder:GetWidth()"), 98)
        self.assertEqual(rt.scalar("return Test.holder:GetHeight()"), 30)

    def test_mover_resizes_with_the_holder(self):
        rt = ShapeshiftBarRuntime(horizontal=True)
        rt.lua.execute("""
            Test.mover = CreateFrame("Frame")
            Test.holder.budsUI_Mover = Test.mover
            K.UpdateMoverSize()
        """)
        self.assertEqual(rt.scalar("return Test.mover:GetWidth()"), 200)
        self.assertEqual(rt.scalar("return Test.mover:GetHeight()"), 30)

    def test_form_count_caps_at_the_slot_max(self):
        rt = ShapeshiftBarRuntime(horizontal=True)
        rt.lua.execute("Test.numForms = 50; Fire('UPDATE_SHAPESHIFT_FORMS')")
        self.assertEqual(rt.scalar("return Test.holder:GetWidth()"), 336)

    def test_combat_lockdown_defers_form_updates(self):
        rt = ShapeshiftBarRuntime(horizontal=True)
        # Talent switch mid-combat must not touch the panel or buttons
        rt.lua.execute(
            "Test.inCombat = true; Test.numForms = 4; Fire('UPDATE_SHAPESHIFT_FORMS')")
        self.assertEqual(rt.scalar("return Test.holder:GetWidth()"), 200)
        self.assertFalse(rt.scalar("return _G['ShapeshiftButton7']:IsShown()"))
        self.assertTrue(
            rt.scalar("return _G['UIShapeShift']:IsEventRegistered('PLAYER_REGEN_ENABLED')"))
        self.assertTrue(rt.scalar("return _G['ShapeshiftButton4']:IsShown()"))
        # Leaving combat flushes the pending update
        rt.lua.execute("Test.inCombat = nil; Fire('PLAYER_REGEN_ENABLED')")
        self.assertEqual(rt.scalar("return Test.holder:GetWidth()"), 132)
        self.assertTrue(rt.scalar("return _G['ShapeshiftButton4']:IsShown()"))
        self.assertFalse(rt.scalar("return _G['ShapeshiftButton7']:IsShown()"))


if __name__ == "__main__":
    unittest.main()
