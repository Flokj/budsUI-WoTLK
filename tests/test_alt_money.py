"""Hovering the bags money lists the gold of every recorded character."""
from pathlib import Path
from typing import Any
import unittest

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


class AltMoneyRuntime:
    def __init__(self):
        self.lua: Any = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute((ROOT / "tests/wow_stub.lua").read_text(encoding="utf-8-sig"))
        self.load("budsUI/Locales/enUS.lua")
        self.lua.execute(
            """
            C.Bag = { AltMoney = true }
            Test.money = 1234567
            GetMoney = function() return Test.money end
            RAID_CLASS_COLORS = {
                MAGE = { r = 0.25, g = 0.78, b = 0.92 },
                WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
            }
            Stuffing = { frame = CreateFrame('Frame', 'StuffingFrameBags', UIParent) }
            Stuffing.frame.gold = Stuffing.frame:CreateFontString(nil, 'ARTWORK')
            Stuffing.frame.gold:SetText('123g')
            """
        )
        self.load("budsUI/Modules/Misc/AltMoney.lua")
        self.lua.execute("Fire('PLAYER_ENTERING_WORLD')")

    def load(self, path):
        code = (ROOT / path).read_text(encoding="utf-8-sig")
        self.lua.execute(code, "budsUI-0.7.1", self.lua.globals().Engine)

    def scalar(self, code):
        return self.lua.execute(code)


class AltMoneyTests(unittest.TestCase):
    def test_current_character_is_recorded_on_login(self):
        rt = AltMoneyRuntime()
        self.assertEqual(
            rt.scalar("return budsUIData.CharacterMoney.Realm.Player.copper"), 1234567)
        self.assertEqual(
            rt.scalar("return budsUIData.CharacterMoney.Realm.Player['class']"), "MAGE")

    def test_entries_put_current_character_first_then_gold_desc(self):
        rt = AltMoneyRuntime()
        rt.lua.execute(
            """
            budsUIData.CharacterMoney.Realm.Alt = { copper = 99999999, class = 'WARRIOR' }
            budsUIData.CharacterMoney.Other = {}
            budsUIData.CharacterMoney.Other.Twink = { copper = 5000, class = 'MAGE' }
            """
        )
        order = rt.scalar(
            """
            local names = {}
            for _, entry in ipairs(K.GetAltMoneyEntries()) do
                names[#names + 1] = entry.name .. (entry.current and '*' or '')
            end
            return table.concat(names, ',')
            """
        )
        self.assertEqual(order, "Player*,Alt,Twink")

    def test_tooltip_lists_characters_with_class_colors_and_total(self):
        rt = AltMoneyRuntime()
        rt.lua.execute(
            """
            budsUIData.CharacterMoney.Realm.Alt = { copper = 99999999, class = 'WARRIOR' }
            K.ShowAltMoneyTooltip(Stuffing.frame.gold)
            Test.header = GameTooltip.lines[1][1]
            Test.first = GameTooltip.lines[2][1]
            Test.currentMoney = GameTooltip.lines[2][2]
            Test.altLabel = GameTooltip.lines[3][1]
            Test.altColorR = GameTooltip.lines[3][3]
            Test.totalLabel = GameTooltip.lines[5][1]
            Test.totalMoney = GameTooltip.lines[5][2]
            """
        )
        g = rt.lua.globals()
        self.assertEqual(g.Test.header, "Character gold")
        self.assertIn("Player", g.Test.first)
        self.assertIn("(current)", g.Test.first)
        self.assertEqual(g.Test.altLabel, "Alt")
        self.assertAlmostEqual(g.Test.altColorR, 0.78, places=3)
        self.assertEqual(g.Test.totalLabel, "Total")
        # 1234567 copper -> 123g 45s 67c
        self.assertEqual(g.Test.currentMoney,
                         "|cffffd700123g|r |cffc7c7cf45s|r |cffeda55f67c|r")
        # 1234567 + 99999999 copper -> 10123g 45s 66c
        self.assertEqual(g.Test.totalMoney,
                         "|cffffd70010123g|r |cffc7c7cf45s|r |cffeda55f66c|r")

    def test_single_character_shows_a_hint_instead_of_a_total(self):
        rt = AltMoneyRuntime()
        hint = rt.scalar(
            """
            K.ShowAltMoneyTooltip(Stuffing.frame.gold)
            return GameTooltip.lines[3][1]
            """
        )
        self.assertEqual(hint, "No other characters recorded yet")

    def test_money_change_updates_the_stored_amount(self):
        rt = AltMoneyRuntime()
        rt.lua.execute("Test.money = 2000000; Fire('PLAYER_MONEY')")
        self.assertEqual(
            rt.scalar("return budsUIData.CharacterMoney.Realm.Player.copper"), 2000000)

    def test_zero_before_the_purse_arrives_does_not_wipe_a_known_amount(self):
        # 3.3.5 cores can report 0 at PEW/logout before the server sends the purse;
        # the recorded amount must survive that.
        rt = AltMoneyRuntime()
        rt.lua.execute("Test.money = 0; Fire('PLAYER_LOGOUT')")
        self.assertEqual(
            rt.scalar("return budsUIData.CharacterMoney.Realm.Player.copper"), 1234567)

    def test_player_money_zero_records_an_actually_empty_purse(self):
        rt = AltMoneyRuntime()
        rt.lua.execute("Test.money = 0; Fire('PLAYER_MONEY')")
        self.assertEqual(
            rt.scalar("return budsUIData.CharacterMoney.Realm.Player.copper"), 0)

    def test_bags_gold_hover_shows_and_hides_the_tooltip(self):
        rt = AltMoneyRuntime()
        rt.lua.execute(
            """
            Test.hover = _G['budsUIAltMoneyHover']
            Test.hover.scripts.OnEnter(Test.hover)
            """
        )
        self.assertTrue(rt.scalar("return GameTooltip.owner[1] == Test.hover"))
        self.assertEqual(rt.scalar("return GameTooltip.lines[1][1]"), "Character gold")
        rt.lua.execute("Test.hover.scripts.OnLeave(Test.hover)")
        self.assertFalse(rt.scalar("return GameTooltip:IsShown()"))

    def test_toggle_off_suppresses_the_tooltip(self):
        rt = AltMoneyRuntime()
        rt.lua.execute(
            """
            GameTooltip.owner = nil
            C.Bag.AltMoney = false
            Test.hover = _G['budsUIAltMoneyHover']
            Test.hover.scripts.OnEnter(Test.hover)
            """
        )
        self.assertFalse(rt.scalar("return GameTooltip.owner ~= nil"))

    def test_different_realm_appends_the_realm_name(self):
        rt = AltMoneyRuntime()
        rt.lua.execute(
            """
            budsUIData.CharacterMoney.Other = {}
            budsUIData.CharacterMoney.Other.Twink = { copper = 5000, class = 'MAGE' }
            K.ShowAltMoneyTooltip(Stuffing.frame.gold)
            """
        )
        self.assertEqual(rt.scalar("return GameTooltip.lines[3][1]"), "Twink - Other")


if __name__ == "__main__":
    unittest.main()
