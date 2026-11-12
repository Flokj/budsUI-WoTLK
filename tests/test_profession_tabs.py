"""Profession sidebar next to the tradeskill / craft windows switches professions."""
from pathlib import Path
from typing import Any
import unittest

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]

SPELLS = {
    2259: "Alchemy",
    2018: "Blacksmithing",
    7411: "Enchanting",
    4036: "Engineering",
    45357: "Inscription",
    25229: "Jewelcrafting",
    2108: "Leatherworking",
    3908: "Tailoring",
    2550: "Cooking",
    3273: "First Aid",
    2575: "Mining",
    2656: "Smelting",
    53428: "Runeforging",
}

PRELUDE = """
C.Blizzard = { ProfessionTabs = true }
C.Media.Border_Color = { 0.5, 0.5, 0.5, 1 }
BOOKTYPE_SPELL = 'spell'
getmetatable(UIParent).__index.CreateBackdrop = function(self)
    self.backdrop = CreateFrame('Frame', nil, self)
end

Test.spellNames = { 'Alchemy', 'Enchanting', 'Cooking', 'Mining', 'Herbalism' }
GetSpellName = function(index, book)
    return Test.spellNames[index], Test.spellNames[index] and '1'
end

Test.spellInfo = {}
for id, name in pairs(%(spells)s) do
    Test.spellInfo[id] = { name, '', 'Interface\\\\Icons\\\\' .. name }
end
GetSpellInfo = function(id)
    local info = Test.spellInfo[id]
    if info then return info[1], info[2], info[3] end
end

CastSpellByName = function(name) Test.cast = name end
GetTradeSkillLine = function() return Test.line end
IsTradeSkillLinked = function() return Test.linked == true end
InCombatLockdown = function() return Test.combat == true end
UIErrorsFrame = { AddMessage = function(_, text) Test.error = text end }

TradeSkillFrame = CreateFrame('Frame', 'TradeSkillFrame', UIParent)

-- Screen geometry for the right/left sidebar decision (right side at defaults).
Test.screenWidth, Test.hostRight = 1024, 500
UIParent.GetWidth = function(self) return Test.screenWidth end
TradeSkillFrame.GetRight = function(self) return Test.hostRight end
""" % {
    "spells": "{" + ",".join("[%d] = '%s'" % (i, n) for i, n in SPELLS.items()) + "}"
}


class ProfessionTabsRuntime:
    def __init__(self):
        self.lua: Any = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute((ROOT / "tests/wow_stub.lua").read_text(encoding="utf-8-sig"))
        self.load("budsUI/Locales/enUS.lua")
        self.lua.execute(PRELUDE)
        self.load("budsUI/Modules/Blizzard/ProfessionTabs.lua")
        self.lua.execute("Fire('ADDON_LOADED', 'Blizzard_TradeSkillUI')")

    def load(self, path):
        code = (ROOT / path).read_text(encoding="utf-8-sig")
        self.lua.execute(code, "budsUI-0.7.1", self.lua.globals().Engine)

    def scalar(self, code):
        return self.lua.execute(code)


class ProfessionTabsTests(unittest.TestCase):
    def test_only_known_crafting_professions_get_tabs(self):
        rt = ProfessionTabsRuntime()
        self.assertEqual(rt.scalar("return _G['budsUIProfessionTab1'].profName"), "Alchemy")
        self.assertEqual(rt.scalar("return _G['budsUIProfessionTab2'].profName"), "Enchanting")
        self.assertEqual(rt.scalar("return _G['budsUIProfessionTab3'].profName"), "Cooking")
        self.assertEqual(rt.scalar("return _G['budsUIProfessionTab4'].profName"), "Mining")
        # Herbalism has no window and Blacksmithing is not in the spellbook.
        self.assertFalse(rt.scalar("return _G['budsUIProfessionTab5'] ~= nil"))
        self.assertEqual(rt.scalar("return _G['budsUIProfessionTab4'].castName"), "Smelting")

    def test_tabs_live_in_the_sidebar_strip(self):
        rt = ProfessionTabsRuntime()
        self.assertTrue(rt.scalar(
            "return _G['budsUIProfessionTab1']:GetParent() == _G['budsUIProfessionTabs']"))

    def test_strip_shows_next_to_the_tradeskill_window(self):
        rt = ProfessionTabsRuntime()
        rt.lua.execute("TradeSkillFrame:Hide(); TradeSkillFrame:Show()")
        self.assertTrue(rt.scalar("return _G['budsUIProfessionTabs']:IsShown()"))
        # Sidebar sits on the RIGHT side of the window: strip TOPLEFT -> host TOPRIGHT.
        self.assertEqual(rt.scalar("return _G['budsUIProfessionTabs'].points[1][1]"), "TOPLEFT")
        self.assertTrue(rt.scalar(
            "return _G['budsUIProfessionTabs'].points[1][2] == TradeSkillFrame"))
        self.assertEqual(rt.scalar("return _G['budsUIProfessionTabs'].points[1][3]"), "TOPRIGHT")
        rt.lua.execute("TradeSkillFrame:Hide()")
        self.assertFalse(rt.scalar("return _G['budsUIProfessionTabs']:IsShown()"))

    def test_enchanting_window_uses_craftframe_as_its_host(self):
        rt = ProfessionTabsRuntime()
        rt.lua.execute("""
            CraftFrame = CreateFrame('Frame', 'CraftFrame', UIParent)
            CraftFrame:Hide()
            Fire('ADDON_LOADED', 'Blizzard_CraftUI')
            CraftFrame:Show()
            Test.line = nil
            Fire('TRADE_SKILL_UPDATE')
        """)
        self.assertTrue(rt.scalar("return _G['budsUIProfessionTabs']:IsShown()"))
        # Enchanting is the current profession while CraftFrame is the open window.
        self.assertEqual(rt.scalar("return _G['budsUIProfessionTab2'].backdrop.borderColor[1]"), 1)

    def test_click_casts_the_profession_spell(self):
        rt = ProfessionTabsRuntime()
        rt.lua.execute("TradeSkillFrame:Hide(); TradeSkillFrame:Show()")
        rt.lua.execute("Test.tab = _G['budsUIProfessionTab3']; Test.tab.scripts.OnClick(Test.tab)")
        self.assertEqual(rt.scalar("return Test.cast"), "Cooking")

    def test_click_on_current_profession_does_nothing(self):
        rt = ProfessionTabsRuntime()
        rt.lua.execute("""
            TradeSkillFrame:Hide(); TradeSkillFrame:Show()
            Test.line = 'Alchemy'
            Test.tab = _G['budsUIProfessionTab1']
            Test.tab.scripts.OnClick(Test.tab)
        """)
        self.assertIsNone(rt.scalar("return Test.cast"))

    def test_current_profession_is_marked(self):
        rt = ProfessionTabsRuntime()
        rt.lua.execute("TradeSkillFrame:Hide(); TradeSkillFrame:Show(); Test.line = 'Cooking'")
        rt.lua.execute("Fire('TRADE_SKILL_UPDATE')")
        self.assertEqual(rt.scalar("return _G['budsUIProfessionTab3'].backdrop.borderColor[1]"), 1)
        self.assertEqual(rt.scalar("return _G['budsUIProfessionTab1'].backdrop.borderColor[1]"), 0.5)

    def test_linked_tradeskill_counts_as_not_current(self):
        rt = ProfessionTabsRuntime()
        rt.lua.execute("""
            TradeSkillFrame:Hide(); TradeSkillFrame:Show()
            Test.line = 'Alchemy'
            Test.linked = true
            Test.tab = _G['budsUIProfessionTab1']
            Test.tab.scripts.OnClick(Test.tab)
        """)
        self.assertEqual(rt.scalar("return Test.cast"), "Alchemy")

    def test_combat_blocks_the_switch(self):
        rt = ProfessionTabsRuntime()
        rt.lua.execute("""
            TradeSkillFrame:Hide(); TradeSkillFrame:Show()
            Test.combat = true
            Test.tab = _G['budsUIProfessionTab1']
            Test.tab.scripts.OnClick(Test.tab)
        """)
        self.assertIsNone(rt.scalar("return Test.cast"))
        self.assertEqual(rt.scalar("return Test.error"), "Not available in combat")

    def test_option_off_hides_the_sidebar(self):
        rt = ProfessionTabsRuntime()
        rt.lua.execute("""
            TradeSkillFrame:Hide(); TradeSkillFrame:Show()
            C.Blizzard.ProfessionTabs = false
            K.ApplyProfessionTabs()
        """)
        self.assertFalse(rt.scalar("return _G['budsUIProfessionTabs']:IsShown()"))

    def test_runeforging_is_available_for_death_knights(self):
        rt = ProfessionTabsRuntime()
        rt.lua.execute("""
            Test.spellNames = { 'Runeforging', 'Alchemy' }
            Fire('SPELLS_CHANGED')
            TradeSkillFrame:Hide(); TradeSkillFrame:Show()
        """)
        self.assertEqual(rt.scalar("return _G['budsUIProfessionTab1'].profName"), "Alchemy")
        self.assertEqual(rt.scalar("return _G['budsUIProfessionTab2'].profName"), "Runeforging")
        rt.lua.execute("Test.tab = _G['budsUIProfessionTab2']; Test.tab.scripts.OnClick(Test.tab)")
        self.assertEqual(rt.scalar("return Test.cast"), "Runeforging")

    def test_runeforge_window_marks_runeforging_current(self):
        rt = ProfessionTabsRuntime()
        rt.lua.execute("""
            Test.spellNames = { 'Runeforging', 'Alchemy' }
            Fire('SPELLS_CHANGED')
            RuneforgeFrame = CreateFrame('Frame', 'RuneforgeFrame', UIParent)
            RuneforgeFrame:Hide()
            Fire('ADDON_LOADED', 'Blizzard_RuneforgeUI')
            TradeSkillFrame:Hide(); TradeSkillFrame:Show()
            RuneforgeFrame:Show()
        """)
        self.assertEqual(rt.scalar("return _G['budsUIProfessionTab2'].backdrop.borderColor[1]"), 1)
        self.assertEqual(rt.scalar("return _G['budsUIProfessionTab1'].backdrop.borderColor[1]"), 0.5)

    def test_rebuild_hides_tabs_of_unlearned_professions(self):
        rt = ProfessionTabsRuntime()
        rt.lua.execute("""
            Test.spellNames = { 'Alchemy' }
            Fire('SPELLS_CHANGED')
        """)
        self.assertTrue(rt.scalar("return _G['budsUIProfessionTab1']:IsShown()"))
        self.assertFalse(rt.scalar("return _G['budsUIProfessionTab2']:IsShown()"))

    def test_single_profession_hides_the_sidebar(self):
        rt = ProfessionTabsRuntime()
        rt.lua.execute("""
            Test.spellNames = { 'Alchemy' }
            Fire('SPELLS_CHANGED')
            TradeSkillFrame:Hide(); TradeSkillFrame:Show()
        """)
        self.assertFalse(rt.scalar("return _G['budsUIProfessionTabs']:IsShown()"))

    def test_tabs_carry_the_spellbook_tab_sheet(self):
        # The stock SpellBookSkillLineTabTemplate art: 64x64 behind the 32x32
        # button, offset up and to the right so it pokes past the window edge.
        rt = ProfessionTabsRuntime()
        tab = "_G['budsUIProfessionTab1']"
        self.assertEqual(
            rt.scalar("return %s.sheet.texture:GetTexture()" % tab),
            "Interface\\SpellBook\\SpellBook-SkillLineTab")
        self.assertEqual(rt.scalar("return %s.sheet:GetWidth()" % tab), 64)
        self.assertEqual(rt.scalar("return %s.sheet:GetHeight()" % tab), 64)
        self.assertEqual(rt.scalar("return %s.sheet.points[1][1]" % tab), "TOPLEFT")
        self.assertEqual(rt.scalar("return %s.sheet.points[1][4]" % tab), -3)
        self.assertEqual(rt.scalar("return %s.sheet.points[1][5]" % tab), 11)
        # The sheet has to live under the backdrop border, not above it.
        self.assertTrue(rt.scalar(
            "return %s.sheet:GetFrameLevel() < %s:GetFrameLevel()" % (tab, tab)))

    def test_sheet_flips_when_the_sidebar_moves_to_the_left(self):
        rt = ProfessionTabsRuntime()
        rt.lua.execute("Test.hostRight = 1010; TradeSkillFrame:Hide(); TradeSkillFrame:Show()")
        self.assertEqual(rt.scalar("return _G['budsUIProfessionTabs'].points[1][1]"), "TOPRIGHT")
        self.assertEqual(rt.scalar("return _G['budsUIProfessionTab1'].sheet.points[1][1]"), "TOPRIGHT")
        self.assertEqual(rt.scalar("return _G['budsUIProfessionTab1'].sheet.points[1][4]"), 3)
        self.assertEqual(rt.scalar("return _G['budsUIProfessionTab1'].sheet.points[1][5]"), 11)

    def test_current_tab_gets_the_checked_glow(self):
        rt = ProfessionTabsRuntime()
        rt.lua.execute("TradeSkillFrame:Hide(); TradeSkillFrame:Show(); Test.line = 'Cooking'")
        rt.lua.execute("Fire('TRADE_SKILL_UPDATE')")
        self.assertTrue(rt.scalar("return _G['budsUIProfessionTab3'].checked:IsShown()"))
        self.assertFalse(rt.scalar("return _G['budsUIProfessionTab1'].checked:IsShown()"))
        self.assertEqual(
            rt.scalar("return _G['budsUIProfessionTab3'].checked:GetTexture()"),
            "Interface\\Buttons\\CheckButtonHilight")

    def test_hover_highlight_uses_the_spellbook_glow(self):
        rt = ProfessionTabsRuntime()
        self.assertEqual(
            rt.scalar("return _G['budsUIProfessionTab1']:GetHighlightTexture():GetTexture()"),
            "Interface\\Buttons\\ButtonHilight-Square")


if __name__ == "__main__":
    unittest.main()
