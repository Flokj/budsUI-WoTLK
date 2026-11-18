"""Unit-frame toggles must survive the client's SavedVariables load order."""
from pathlib import Path
from typing import Any
import unittest

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]

CLIENT = """
Test.loggedIn = false
budsUIData = nil
function UnitClass() return 'Mage', 'MAGE' end
function GetAddOnMetadata() end
function GetNumRaidMembers() return 0 end
function RegisterStateDriver(frame, state, condition)
    assert(not InCombatLockdown(), 'cannot register a state driver in combat')
    frame:SetAttribute('state-' .. state, condition)
end
local Frame = getmetatable(UIParent).__index
function Frame:SetAttribute(key, value)
    self.attributes = self.attributes or {}
    self.attributes[key] = value
end
function Frame:GetAttribute(key) return self.attributes and self.attributes[key] end
function Frame:SetShadowColor(...) self.shadowColor = { ... } end
function Frame:SetShadowOffset(...) self.shadowOffset = { ... } end
"""


def load(lua, directory, files, namespace):
    for name in files:
        path = ROOT / directory / name
        lua.execute(path.read_text(encoding="utf-8-sig"), directory, namespace)


def boot(saved=None, *, combat=False) -> Any:
    lua: Any = LuaRuntime(unpack_returned_tuples=True)
    load(lua, "tests", ("wow_stub.lua", "config_stub.lua"), None)
    lua.execute(CLIENT)
    lua.globals().Test.combat = combat
    engine = lua.globals().Engine
    load(lua, "budsUI", ("Config/Settings.lua", "Modules/Profiles/Serialize.lua",
                         "Modules/Profiles/Migrations.lua", "Modules/Profiles/Core.lua",
                         "Modules/Profiles/Options.lua", "Libs/oUF/init.lua", "Libs/oUF/private.lua",
                         "Libs/oUF/ouf.lua", "Libs/oUF/blizzard.lua",
                         "Modules/UnitFrames/Compat.lua", "Modules/UnitFrames/Core.lua",
                         "Modules/UnitFrames/Units/Group.lua"), engine)
    # Only the secure group headers are exercised; the client creates their children.
    lua.execute("Engine.UnitFrames.UnitDefs = {}; C.Unitframe.Boss.Enable = false")
    load(lua, "budsUI", ("Modules/UnitFrames/Init.lua",), engine)
    if saved is not None:
        lua.globals().budsUIData = lua.eval("K.Deserialize")(saved)
    lua.execute("Fire('ADDON_LOADED', 'budsUI'); Test.loggedIn = true; Fire('PLAYER_LOGIN')")
    return lua


def toggle_group_frames(lua, group):
    load(lua, "budsUI_Config", ("Locales/enUS.lua", "Controls.lua", "Pages/Unitframe.lua", "Core.lua"),
         lua.globals().configNS)
    lua.execute("""
        local group = ...
        configNS.pages[1].activeTabKey = 'Group'
        configNS.Toggle('Unitframe')
        for _, widget in ipairs(Test.frames) do
            local parent = widget:GetParent()
            local entry = parent and parent.entry
            if widget.kind == 'CheckButton' and entry and entry.group == 'Unitframe'
                    and entry.option == group and entry.key == 'Enable' then
                widget:SetChecked(not widget:GetChecked())
                widget:Click()
                return
            end
        end
        error('Missing Enable checkbox for ' .. group)
    """, group)


class UnitFrameConfigTests(unittest.TestCase):
    def test_enabled_group_frames_spawn_after_ui_reload(self):
        for group, other in (("Party", "Raid"), ("Raid", "Party")):
            with self.subTest(group=group):
                lua = boot()
                self.assertIsNone(lua.globals()["budsUI_" + group])
                toggle_group_frames(lua, group)
                saved = lua.eval("K.Serialize(budsUIData)")

                reloaded = boot(saved).globals()
                self.assertIs(reloaded.C.Unitframe[group].Enable, True)
                self.assertIsNotNone(reloaded["budsUI_" + group])
                self.assertIsNone(reloaded["budsUI_" + other])

    def test_login_in_combat_defers_group_frames_until_combat_ends(self):
        lua = boot()
        toggle_group_frames(lua, "Party")
        reloaded = boot(lua.eval("K.Serialize(budsUIData)"), combat=True)
        self.assertIsNone(reloaded.globals().budsUI_Party)
        reloaded.execute("Test.combat = false; Fire('PLAYER_REGEN_ENABLED'); Fire('PLAYER_REGEN_ENABLED')")
        self.assertIsNotNone(reloaded.globals().budsUI_Party)
        self.assertEqual(reloaded.eval("#Engine.oUF.headers"), 1)

    def test_group_toggle_offers_reload(self):
        for group in ("Party", "Raid"):
            with self.subTest(group=group):
                lua = boot()
                toggle_group_frames(lua, group)
                reload_button = lua.globals().budsUIConfigFrame.reloadButton
                self.assertTrue(reload_button.IsShown(reload_button))
                reload_button.Click(reload_button)
                self.assertEqual(lua.globals().Test.reloads, 1)


if __name__ == "__main__":
    unittest.main()
