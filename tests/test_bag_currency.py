"""Pinned currencies get a strip inside the Stuffing bags window."""
from pathlib import Path
from typing import Any
import unittest

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]

PRELUDE = """
C.Bag = { Currency = true }
C.Media.Border_Color = { 0.5, 0.5, 0.5, 1 }
K.ShortValue = function(value)
    if value >= 1e3 then return ('%.1fk'):format(value / 1e3) end
    return tostring(value)
end
getmetatable(UIParent).__index.CreateBackdrop = function(self)
    self.backdrop = CreateFrame('Frame', nil, self)
end

GetBackpackCurrencyInfo = function(index)
    local token = Test.tokens[index]
    if token then return token.name, token.count, token.type, token.icon, token.itemID end
end
UnitFactionGroup = function() return 'Alliance' end
LoadAddOn = function(name) Test.loadedAddon = name end
ToggleCharacter = function(frame) Test.opened = frame end
InCombatLockdown = function() return false end

Test.tokens = {
    { name = 'Emblem of Triumph', count = 1200, type = 0,
      icon = 'Interface\\\\Icons\\\\inv_misc_runedorb', itemID = 47241 },
    { name = 'Arena Points', count = 900, type = 1, icon = 'Interface\\\\Icons\\\\arena' },
    { name = 'Honor Points', count = 15000, type = 2, icon = 'Interface\\\\Icons\\\\honor' },
}

Stuffing = { frame = CreateFrame('Frame', 'StuffingFrameBags', UIParent) }
Stuffing.frame:SetHeight(100)
Stuffing.Layout = function(self) self.frame:SetHeight(100) end
"""


class BagCurrencyRuntime:
    def __init__(self):
        self.lua: Any = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute((ROOT / "tests/wow_stub.lua").read_text(encoding="utf-8-sig"))
        self.load("budsUI/Locales/enUS.lua")
        self.lua.execute(PRELUDE)
        self.load("budsUI/Modules/Blizzard/BagCurrency.lua")
        self.lua.execute("Fire('PLAYER_ENTERING_WORLD')")

    def load(self, path):
        code = (ROOT / path).read_text(encoding="utf-8-sig")
        self.lua.execute(code, "budsUI-0.7.1", self.lua.globals().Engine)

    def scalar(self, code):
        return self.lua.execute(code)


class BagCurrencyTests(unittest.TestCase):
    def test_strip_lists_pinned_tokens(self):
        rt = BagCurrencyRuntime()
        self.assertTrue(rt.scalar("return _G['budsUIBagCurrencyBar']:IsShown()"))
        self.assertEqual(rt.scalar("return _G['budsUIBagCurrencyToken1'].count:GetText()"), "1.2k")
        self.assertTrue(rt.scalar("return _G['budsUIBagCurrencyToken1']:IsShown()"))
        self.assertTrue(rt.scalar("return _G['budsUIBagCurrencyToken2']:IsShown()"))
        self.assertTrue(rt.scalar("return _G['budsUIBagCurrencyToken3']:IsShown()"))
        self.assertFalse(rt.scalar("return _G['budsUIBagCurrencyToken4'] ~= nil"))

    def test_arena_points_use_the_vanilla_icon(self):
        rt = BagCurrencyRuntime()
        self.assertEqual(
            rt.scalar("return _G['budsUIBagCurrencyToken2'].icon:GetTexture()"),
            "Interface\\PVPFrame\\PVP-ArenaPoints-Icon")
        self.assertTrue(rt.scalar(
            "local t = _G['budsUIBagCurrencyToken2'].icon.texCoord return t[1] == 0 and t[2] == 1"))

    def test_honor_points_crop_the_pvp_sheet(self):
        # UI-PVP-Alliance is a sheet: a square texcoord shows a broken fragment.
        rt = BagCurrencyRuntime()
        self.assertEqual(
            rt.scalar("return _G['budsUIBagCurrencyToken3'].icon:GetTexture()"),
            "Interface\\TargetingFrame\\UI-PVP-Alliance")
        self.assertTrue(rt.scalar("""
            local t = _G['budsUIBagCurrencyToken3'].icon.texCoord
            return t[1] == 0.03125 and t[2] == 0.59375 and t[3] == 0.03125 and t[4] == 0.59375
        """))

    def test_item_tokens_keep_the_inset_icon_crop(self):
        rt = BagCurrencyRuntime()
        self.assertTrue(rt.scalar("""
            local t = _G['budsUIBagCurrencyToken1'].icon.texCoord
            return t[1] == 0.07 and t[2] == 0.93
        """))

    def test_click_opens_the_currency_tab(self):
        rt = BagCurrencyRuntime()
        rt.lua.execute("Test.button = _G['budsUIBagCurrencyToken1']; Test.button.scripts.OnClick(Test.button)")
        self.assertEqual(rt.scalar("return Test.opened"), "TokenFrame")
        self.assertEqual(rt.scalar("return Test.loadedAddon"), "Blizzard_TokenUI")

    def test_unpinning_hides_the_strip_and_its_band(self):
        rt = BagCurrencyRuntime()
        # Band is reserved while tokens are pinned: 16px row + 8px padding.
        rt.lua.execute("Stuffing:Layout(false)")
        self.assertEqual(rt.scalar("return Stuffing.frame:GetHeight()"), 124)
        rt.lua.execute("""
            Test.tokens = {}
            K.RefreshBagCurrency()
        """)
        self.assertFalse(rt.scalar("return _G['budsUIBagCurrencyBar']:IsShown()"))
        rt.lua.execute("Stuffing:Layout(false)")
        self.assertEqual(rt.scalar("return Stuffing.frame:GetHeight()"), 100)

    def test_narrow_bag_wraps_tokens_into_a_second_row(self):
        rt = BagCurrencyRuntime()
        rt.lua.execute("""
            local bar = _G['budsUIBagCurrencyBar']
            bar:SetWidth(40)
            K.RefreshBagCurrency()
        """)
        self.assertEqual(rt.scalar("return _G['budsUIBagCurrencyBar'].rows"), 3)
        rt.lua.execute("Stuffing:Layout(false)")
        self.assertEqual(rt.scalar("return Stuffing.frame:GetHeight()"), 156)

    def test_disabled_option_hides_everything(self):
        rt = BagCurrencyRuntime()
        rt.lua.execute("C.Bag.Currency = false; K.RefreshBagCurrency()")
        self.assertFalse(rt.scalar("return _G['budsUIBagCurrencyBar']:IsShown()"))
        self.assertFalse(rt.scalar("return _G['budsUIBagCurrencyToken1']:IsShown()"))

    def test_layout_wrapper_survives_repeated_calls(self):
        rt = BagCurrencyRuntime()
        rt.lua.execute("Stuffing:Layout(false); Stuffing:Layout(false)")
        self.assertEqual(rt.scalar("return Stuffing.frame:GetHeight()"), 124)


if __name__ == "__main__":
    unittest.main()
