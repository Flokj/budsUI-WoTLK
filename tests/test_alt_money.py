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

    def test_entries_put_current_realm_first_then_gold_desc(self):
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

    def test_tooltip_groups_by_realm_with_subtotals(self):
        rt = AltMoneyRuntime()
        rt.lua.execute(
            """
            budsUIData.CharacterMoney.Realm.Alt = { copper = 99999999, class = 'WARRIOR' }
            budsUIData.CharacterMoney.Other = {}
            budsUIData.CharacterMoney.Other.Twink = { copper = 5000, class = 'MAGE' }
            K.ShowAltMoneyTooltip(Stuffing.frame.gold)
            Test.header = GameTooltip.lines[1][1]
            Test.current = GameTooltip.lines[2][1]
            Test.currentMoney = GameTooltip.lines[2][2]
            Test.altLabel = GameTooltip.lines[3][1]
            Test.altColorR = GameTooltip.lines[3][3]
            Test.spacingBeforeTotal = GameTooltip.lines[4][1]
            Test.realmTotalLabel = GameTooltip.lines[5][1]
            Test.realmTotalMoney = GameTooltip.lines[5][2]
            Test.spacingAfterTotal = GameTooltip.lines[6][1]
            Test.otherLabel = GameTooltip.lines[7][1]
            Test.spacingBeforeOtherTotal = GameTooltip.lines[8][1]
            Test.otherTotalLabel = GameTooltip.lines[9][1]
            Test.otherTotalMoney = GameTooltip.lines[9][2]
            Test.hint = GameTooltip.lines[11][1]
            """
        )
        g = rt.lua.globals()
        self.assertEqual(g.Test.header, "Character gold")
        # Current character is listed like everyone else (mists style, no label).
        self.assertEqual(g.Test.current, "Player")
        # mists-style money: plain numbers, colored g/s/c letters, separators.
        self.assertEqual(g.Test.currentMoney,
                         "123|cffffd700g|r 45|cffc7c7cfs|r 67|cffeda55fc|r")
        self.assertEqual(g.Test.altLabel, "Alt")
        self.assertAlmostEqual(g.Test.altColorR, 0.78, places=3)
        # The subtotal gets a blank line on both sides so it stands out.
        self.assertEqual(g.Test.spacingBeforeTotal, " ")
        self.assertEqual(g.Test.spacingAfterTotal, " ")
        # First realm subtotal: 1234567 + 99999999 copper -> 10123g 45s 66c
        self.assertEqual(g.Test.realmTotalLabel, "Total")
        self.assertEqual(g.Test.realmTotalMoney,
                         "10,123|cffffd700g|r 45|cffc7c7cfs|r 66|cffeda55fc|r")
        # Second realm block with its own subtotal.
        self.assertEqual(g.Test.otherLabel, "Twink - Other")
        self.assertEqual(g.Test.spacingBeforeOtherTotal, " ")
        self.assertEqual(g.Test.otherTotalLabel, "Total")
        self.assertEqual(g.Test.otherTotalMoney,
                         "50|cffc7c7cfs|r 00|cffeda55fc|r")
        self.assertEqual(g.Test.hint, "Ctrl+Right-click: clear the list")

    def test_realm_names_are_shortened_to_their_tail(self):
        rt = AltMoneyRuntime()
        rt.lua.execute("K.Realm = 'WoW Circle 3.3.5a x1'")
        self.assertEqual(
            rt.scalar("return K.ShortAltRealm('WoW Circle 3.3.5a x100')"), "x100")
        self.assertEqual(
            rt.scalar("return K.ShortAltRealm('WoW Circle 3.3.5a Fun')"), "Fun")
        # A shared word boundary keeps the whole "x1 [FIN]" tail visible.
        self.assertEqual(
            rt.scalar("return K.ShortAltRealm('x1 [FIN]')"), "x1 [FIN]")
        self.assertIsNone(rt.scalar("return K.ShortAltRealm('WoW Circle 3.3.5a x1')"))

    def test_money_text_matches_the_mists_format(self):
        rt = AltMoneyRuntime()
        rt.lua.execute(
            """
            budsUIData.CharacterMoney.Realm.Alt = { copper = 12345678901, class = 'WARRIOR' }
            K.ShowAltMoneyTooltip(Stuffing.frame.gold)
            Test.value = GameTooltip.lines[3][2]
            """
        )
        # 1234567g 89s 01c with thousands separators and a padded copper.
        self.assertEqual(rt.scalar("return Test.value"),
                         "1,234,567|cffffd700g|r 89|cffc7c7cfs|r 01|cffeda55fc|r")

    def test_ctrl_right_click_asks_before_clearing_everyone(self):
        rt = AltMoneyRuntime()
        rt.lua.execute(
            """
            budsUIData.CharacterMoney.Realm.Alt = { copper = 99999999, class = 'WARRIOR' }
            budsUIData.CharacterMoney.Other = {}
            budsUIData.CharacterMoney.Other.Twink = { copper = 5000, class = 'MAGE' }
            Test.hover = _G['budsUIAltMoneyHover']
            Test.ctrl = true
            Test.hover.scripts.OnMouseDown(Test.hover, 'RightButton')
            Test.dialog = Test.lastPopupKey
            StaticPopupDialogs[Test.dialog].OnAccept()
            """
        )
        self.assertEqual(rt.scalar("return Test.dialog"), "BUDSUI_RESET_ALTMONEY")
        # Only the current character survives the reset.
        self.assertEqual(
            rt.scalar(
                """
                local n = 0
                for r, c in pairs(budsUIData.CharacterMoney or {}) do
                    for k in pairs(c) do n = n + 1 end
                end
                return n
                """
            ),
            1)
        self.assertEqual(
            rt.scalar("return budsUIData.CharacterMoney.Realm.Player.copper"), 1234567)

    def test_plain_right_click_does_not_clear(self):
        rt = AltMoneyRuntime()
        rt.lua.execute(
            """
            budsUIData.CharacterMoney.Realm.Alt = { copper = 99999999, class = 'WARRIOR' }
            Test.hover = _G['budsUIAltMoneyHover']
            Test.hover.scripts.OnMouseDown(Test.hover, 'RightButton')
            """
        )
        self.assertIsNone(rt.scalar("return Test.lastPopupKey"))

    def test_left_click_does_not_clear(self):
        rt = AltMoneyRuntime()
        rt.lua.execute(
            """
            budsUIData.CharacterMoney.Realm.Alt = { copper = 99999999, class = 'WARRIOR' }
            Test.hover = _G['budsUIAltMoneyHover']
            Test.hover.scripts.OnMouseDown(Test.hover, 'LeftButton')
            """
        )
        self.assertIsNone(rt.scalar("return Test.lastPopupKey"))

    def test_single_character_shows_a_hint_instead_of_subtotals(self):
        rt = AltMoneyRuntime()
        hint = rt.scalar(
            """
            K.ShowAltMoneyTooltip(Stuffing.frame.gold)
            return GameTooltip.lines[2][1]
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
        self.assertEqual(rt.scalar("return GameTooltip.lines[6][1]"), "Twink - Other")


if __name__ == "__main__":
    unittest.main()
