"""budsUI_Config ships as a load-on-demand addon pulled in by the main addon."""
from pathlib import Path
from typing import Any
import re
import unittest

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]

PRELUDE = """
Test.locale = 'enUS'
RAID_CLASS_COLORS = { MAGE = { r = 0.2, g = 0.4, b = 0.8 } }
GetCVar = function() return '1920x1080' end
UnitName = function() return 'Player' end
UnitClass = function() return 'Mage', 'MAGE' end
UnitRace = function() return 'Human', 'Human' end
UnitLevel = function() return 80 end
GetRealmName = function() return 'Realm' end
GetBuildInfo = function() return '3.3.5', '12340', '2020-01-01', 30300 end
ReloadUI = function() Test.reloaded = true end
IsLoggedIn = function() return true end

Test.addons = { 'budsUI', 'budsUI_Config' }
Test.loadedAddons = {}
Test.loadRequests = {}
IsAddOnLoaded = function(name)
    if type(name) == 'number' then name = Test.addons[name] end
    return Test.loadedAddons[name] == true
end
GetNumAddOns = function() return #Test.addons end
GetAddOnInfo = function(index)
    local name = Test.addons[index]
    if not name then return nil end
    return name, name, '', true, true, false
end
LoadAddOn = function(index)
    local name = type(index) == 'number' and Test.addons[index] or index
    Test.loadRequests[#Test.loadRequests + 1] = name
    if Test.loadFails or not name then return false, 'MISSING' end
    Test.loadedAddons[name] = true
    return true, nil
end
StaticPopup_Show = function(key) Test.popup = key end
"""


def toc_metadata(path):
    data = {}
    for line in path.read_text(encoding="utf-8-sig").splitlines():
        match = re.match(r"##\s*([^:]+):\s*(.*)", line)
        if match:
            data[match.group(1).strip()] = match.group(2).strip()
    return data


class ConfigLoadOnDemandTests(unittest.TestCase):
    def test_config_toc_is_load_on_demand_and_depends_on_budsui(self):
        toc = toc_metadata(ROOT / "budsUI_Config/budsUI_Config.toc")
        self.assertEqual(toc.get("LoadOnDemand"), "1")
        self.assertEqual(toc.get("Dependencies"), "budsUI")

    def test_config_toc_does_not_declare_saved_variables_itself(self):
        # budsUIData/SavedOptions belong to the main addon; the on-demand addon
        # loads after it and must not claim ownership of the same files.
        toc = toc_metadata(ROOT / "budsUI_Config/budsUI_Config.toc")
        self.assertNotIn("SavedVariables", toc)

    def test_main_addon_loads_the_config_addon(self):
        lua: Any = LuaRuntime(unpack_returned_tuples=True)
        lua.execute((ROOT / "tests/wow_stub.lua").read_text(encoding="utf-8-sig"))
        lua.execute(PRELUDE)
        lua.execute((ROOT / "budsUI/Core/Init.lua").read_text(encoding="utf-8-sig"),
                    "budsUI", lua.globals().Engine)
        lua.execute("Fire('ADDON_LOADED', 'budsUI')")
        self.assertEqual(lua.globals().Test.loadRequests[1], "budsUI_Config")
        self.assertTrue(lua.globals().Test.loadedAddons["budsUI_Config"])

    def test_login_in_combat_retries_on_regen(self):
        lua: Any = LuaRuntime(unpack_returned_tuples=True)
        lua.execute((ROOT / "tests/wow_stub.lua").read_text(encoding="utf-8-sig"))
        lua.execute(PRELUDE)
        lua.execute((ROOT / "budsUI/Core/Init.lua").read_text(encoding="utf-8-sig"),
                    "budsUI", lua.globals().Engine)
        lua.execute("""
            Test.loadFails = true
            Fire('ADDON_LOADED', 'budsUI')
            Fire('PLAYER_ENTERING_WORLD')
            Test.loadFails = nil
            Fire('PLAYER_REGEN_ENABLED')
        """)
        self.assertTrue(lua.globals().Test.loadedAddons["budsUI_Config"])

    def test_missing_config_folder_warns_once(self):
        lua: Any = LuaRuntime(unpack_returned_tuples=True)
        lua.execute((ROOT / "tests/wow_stub.lua").read_text(encoding="utf-8-sig"))
        lua.execute(PRELUDE)
        lua.execute((ROOT / "budsUI/Core/Init.lua").read_text(encoding="utf-8-sig"),
                    "budsUI", lua.globals().Engine)
        lua.execute("""
            Test.loadFails = true
            Test.addons = { 'budsUI' }
            Fire('ADDON_LOADED', 'budsUI')
        """)
        self.assertEqual(lua.globals().Test.popup, "BUDSUI_MISSING_CONFIG")

    def test_slash_command_still_exists_before_the_config_loads(self):
        lua: Any = LuaRuntime(unpack_returned_tuples=True)
        lua.execute((ROOT / "tests/wow_stub.lua").read_text(encoding="utf-8-sig"))
        lua.execute(PRELUDE)
        lua.execute((ROOT / "budsUI/Core/Commands.lua").read_text(encoding="utf-8-sig"),
                    "budsUI", lua.globals().Engine)
        lua.execute("SlashCmdList.BUDSUICONFIG()")
        self.assertEqual(lua.globals().Test.loadRequests[1], "budsUI_Config")


if __name__ == "__main__":
    unittest.main()
