"""ClassColorMentions must also color player names inside loot lines."""
from pathlib import Path
from typing import Any
import unittest

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


class MentionsRuntime:
    def __init__(self):
        self.lua: Any = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute((ROOT / "tests/wow_stub.lua").read_text(encoding="utf-8-sig"))
        # The stub ships an empty Chat table; the module gate needs its flag.
        self.lua.globals().C.Chat.ClassColorMentions = True
        self.load("budsUI/Locales/enUS.lua")
        ru = ROOT / "budsUI/Locales/ruRU.lua"
        if ru.exists():
            self.load("budsUI/Locales/ruRU.lua")
        self.lua.execute(
            """
            hooksecurefunc = function(name, hook)
                local orig = _G[name]
                _G[name] = function(...) local r = orig(...) hook(...); return r end
            end
            GetPlayerInfoByGUID = function(guid)
                if guid == '0x0000000000000009' then
                    return 'Воин', 'WARRIOR', 'Орк', 'ORC', 3, 'Thrall', ''
                end
                if guid == Test.playerGUID then
                    return 'Маг', 'MAGE', 'Человек', 'HUMAN', 0, 'Player', ''
                end
            end
            UnitGUID = function(unit) return unit == 'player' and Test.playerGUID end
            GetNumRaidMembers = function() return 0 end
            GetNumPartyMembers = function() return 0 end
            RAID_CLASS_COLORS = { WARRIOR = { r = 0.78, g = 0.61, b = 0.43 } }
            """
        )
        self.load("budsUI/Modules/Chat/ClassColorMentions.lua")
        # Prime the cache exactly like a real session: any GUID lookup fills ClassNames.
        self.lua.execute("GetPlayerInfoByGUID('0x0000000000000009')")

    def load(self, path):
        code = (ROOT / path).read_text(encoding="utf-8-sig")
        self.lua.execute(code, "budsUI-0.7.1", self.lua.globals().Engine)

    def run_filters(self, event, message):
        lua = self.lua
        lua.globals().Test.filterInput = message
        out = lua.execute(f"""
            local f = Test.chatFilters and Test.chatFilters['{event}']
            if not f then return nil end
            local msg = Test.filterInput
            for i = 1, #f do
                local hide, newMsg = f[i](ChatFrame1, '{event}', msg, 'SomeAuthor')
                if hide then return 'HIDDEN' end
                if newMsg then msg = newMsg end
            end
            return msg
        """)
        return out


class LootClassColorTests(unittest.TestCase):
    def test_loot_event_has_a_filter_registered(self):
        rt = MentionsRuntime()
        self.assertIsNotNone(rt.lua.globals().Test.chatFilters.CHAT_MSG_LOOT)

    def test_player_name_in_loot_line_gets_class_color(self):
        rt = MentionsRuntime()
        result = rt.run_filters(
            "CHAT_MSG_LOOT",
            "Thrall received loot: |cff10ff00|Hitem:45000|h[Emerald Stormshard]|h|r",
        )
        self.assertNotEqual(result, "HIDDEN")
        # WARRIOR class color wraps the name; item link stays intact.
        self.assertRegex(str(result), r"\|cff[0-9a-f]{6}Thrall\|r")

    def test_item_hyperlink_is_not_recolored(self):
        rt = MentionsRuntime()
        link = "|cff10ff00|Hitem:45000|h[Emerald Stormshard]|h|r"
        result = rt.run_filters("CHAT_MSG_LOOT", f"You receive loot: {link}")
        self.assertIn(link, result)

    def test_money_event_also_colored(self):
        rt = MentionsRuntime()
        result = rt.run_filters("CHAT_MSG_MONEY", "Thrall receives loot: 12 Gold, 40 Silver")
        self.assertRegex(str(result), r"\|cff[0-9a-f]{6}Thrall\|r")

    def test_unknown_names_stay_untouched(self):
        rt = MentionsRuntime()
        result = rt.run_filters("CHAT_MSG_LOOT", "Nobody Here receives loot: a rock")
        self.assertNotIn("|cff", str(result))


if __name__ == "__main__":
    unittest.main()
