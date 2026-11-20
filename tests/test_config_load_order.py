"""GUI toggles for default-off features (SplitBars, ThreatMeter) must survive the
3.3.5 SavedVariables load order: profile values land in C only at ADDON_LOADED,
so file-scope gates would always see the Settings.lua default."""
from pathlib import Path
from typing import Any
import unittest

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]

PRELUDE = """
Test.combat = false
Test.loggedIn = false
CUSTOM_CLASS_COLORS = { MAGE = { r = 0.2, g = 0.4, b = 0.8 } }
RAID_CLASS_COLORS = CUSTOM_CLASS_COLORS
UnitDetailedThreatSituation = function() return 0, 0, 100 end
UnitIsVisible = function() return true end
UnitIsDead = function() return false end
UnitIsPlayer = function() return false end
UnitCanAttack = function() return true end
UnitName = function() return "Mob" end
GetNumRaidMembers = function() return 0 end
GetNumPartyMembers = function() return 0 end
K.CreateBorder = function() end
UnitClass = function() return "Mage", "MAGE" end
RegisterStateDriver = function() end

-- Core/API.lua installs Frame:CreatePanel; emulate it here.
local FrameMT = getmetatable(UIParent).__index
function FrameMT:CreatePanel(_, w, h, ...)
    if w and h then self:SetSize(w, h) end
    if select("#", ...) >= 3 then self:SetPoint(...) end
end
PetActionBarFrame = CreateFrame("Frame", "PetActionBarFrame", UIParent)
PetHolder = nil
MultiBarBottomRight = CreateFrame("Frame", "MultiBarBottomRight", UIParent)
for i = 1, 12 do
    _G["MultiBarBottomRightButton" .. i] = CreateFrame("Button", "MultiBarBottomRightButton" .. i, MultiBarBottomRight)
end
Bar1Holder = CreateFrame("Frame", "Bar1Holder", UIParent)
"""


def load(lua, directory, files, namespace):
    for name in files:
        path = ROOT / directory / name
        lua.execute(path.read_text(encoding="utf-8-sig"), directory, namespace)


def boot(threat_enable=False, split_bars=False) -> Any:
    lua: Any = LuaRuntime(unpack_returned_tuples=True)
    load(lua, "tests", ("wow_stub.lua", "config_stub.lua"), None)
    lua.execute(PRELUDE)
    engine = lua.globals().Engine
    # File-load phase: in 3.3.5 SavedVariables are assigned only after the
    # addon's files ran, so budsUIData is nil here and the merge is a no-op.
    lua.execute("budsUIData = nil")
    load(lua, "budsUI",
         ("Config/Settings.lua", "Config/Positions.lua", "Modules/Profiles/Core.lua"), engine)
    load(lua, "budsUI",
         ("Core/Panels.lua", "Modules/ActionBars/Bar5.lua", "Modules/Misc/ThreatMeter.lua"), engine)
    # Client phase: SavedVariables assigned, then events fire in order.
    lua.execute(
        "budsUIData = { ActiveProfiles = { ['Realm-Player'] = 'Default' }, "
        "Profiles = { Default = { ThreatMeter = { Enable = %s }, "
        "ActionBar = { SplitBars = %s } } } }"
        % ("true" if threat_enable else "false", "true" if split_bars else "false"))
    lua.execute("Test.loggedIn = true; Fire('ADDON_LOADED', 'budsUI')")
    lua.execute("Fire('PLAYER_LOGIN')")
    return lua


PRELUDE_EXTRA = """
-- Battery-boot stubs: flattened globals + module init deps.
hooksecurefunc = function() end
MAX_PLAYER_LEVEL = 80
K.Level = 80
K.NoScaleMult = 1
K.CheckChat = function() return "PARTY" end
LoggingCombat = function() return false end
DurabilityFrame = CreateFrame("Frame", "DurabilityFrame", UIParent)
ItemRefShoppingTooltip1 = CreateFrame("GameTooltip", "ItemRefShoppingTooltip1", UIParent)
ItemRefShoppingTooltip2 = CreateFrame("GameTooltip", "ItemRefShoppingTooltip2", UIParent)
ShoppingTooltip1 = CreateFrame("GameTooltip", "ShoppingTooltip1", UIParent)
ShoppingTooltip2 = CreateFrame("GameTooltip", "ShoppingTooltip2", UIParent)
"""

LOAD_ORDER = ("Config/Settings.lua", "Config/Positions.lua", "Modules/Profiles/Core.lua",
              "Config/Filters/Announcements.lua",
              "Modules/Announcements/Interrupt.lua",
              "Modules/Automation/LoggingCombat.lua",
              "Modules/Misc/PulseCD.lua",
              "Modules/Loot/AutoGreed.lua",
              "Modules/Tooltip/SpellID.lua")


def load_battery(enabled) -> Any:
    """Boot the transformed module battery with the given profile toggles on."""
    lua: Any = LuaRuntime(unpack_returned_tuples=True)
    load(lua, "tests", ("wow_stub.lua", "config_stub.lua"), None)
    lua.execute(PRELUDE + PRELUDE_EXTRA)
    engine = lua.globals().Engine
    lua.execute("budsUIData = nil")
    load(lua, "budsUI", LOAD_ORDER, engine)
    profile = []
    for path in ("Announcements.Interrupt", "Automation.LoggingCombat",
                 "PulseCD.Enable", "Loot.AutoGreed", "Tooltip.SpellID"):
        group, key = path.split(".")
        profile.append("%s = { %s = %s }" % (group, key, "true" if enabled.get(path) else "false"))
    lua.execute(
        "budsUIData = { ActiveProfiles = { ['Realm-Player'] = 'Default' }, "
        "Profiles = { Default = { %s } } }" % ", ".join(profile))
    lua.execute("Test.loggedIn = true; Fire('ADDON_LOADED', 'budsUI')")
    lua.execute("Fire('PLAYER_LOGIN')")
    return lua


def registered_event(lua, event):
    return lua.eval(
        "(function()\n"
        "    local found = 0\n"
        "    for _, f in ipairs(Test.frames) do\n"
        "        if f.events and f.events[%s] then found = found + 1 end\n"
        "    end\n"
        "    return found\n"
        "end)()\n" % ("'" + event + "'"))


class ConfigLoadOrderTests(unittest.TestCase):
    def test_threat_meter_initializes_when_profile_enables_it(self):
        # Bug: file-scope gate saw the Settings.lua default (false) and returned,
        # so the PLAYER_LOGIN loader was never registered even after the profile
        # merge set C.ThreatMeter.Enable = true.
        lua = boot(threat_enable=True)
        self.assertIsNotNone(lua.globals().budsUIThreatMeter)

    def test_threat_meter_stays_off_at_default(self):
        lua = boot(threat_enable=False)
        self.assertIsNone(lua.globals().budsUIThreatMeter)

    def test_split_bars_layout_applies_from_profile_after_reload(self):
        lua = boot(split_bars=True)
        g = lua.globals()
        self.assertTrue(g.SplitBarLeft.IsShown(g.SplitBarLeft))
        self.assertTrue(g.SplitBarRight.IsShown(g.SplitBarRight))
        # Two rows of buttons instead of three: (34*2 + 3) == 71.
        self.assertEqual(g.ActionBarAnchor.GetHeight(g.ActionBarAnchor), 71)
        self.assertEqual(g.Bar5Holder.allPoints.name, "SplitBarLeft")
        # Button 1 anchors to the left split block.
        self.assertEqual(g.MultiBarBottomRightButton1.points[1][2].name, "SplitBarLeft")
        self.assertEqual(g.MultiBarBottomRightButton1.points[1][3], "TOPLEFT")

    def test_default_layout_unaffected_when_split_off(self):
        lua = boot(split_bars=False)
        g = lua.globals()
        self.assertFalse(g.SplitBarLeft.IsShown(g.SplitBarLeft))
        self.assertFalse(g.SplitBarRight.IsShown(g.SplitBarRight))
        self.assertEqual(g.ActionBarAnchor.GetHeight(g.ActionBarAnchor), 108)
        self.assertEqual(g.Bar5Holder.allPoints.name, "ActionBarAnchor")

    def test_class_battery_initializes_when_profile_enables(self):
        lua = load_battery({
            "Announcements.Interrupt": True, "Automation.LoggingCombat": True,
            "PulseCD.Enable": True, "Loot.AutoGreed": True, "Tooltip.SpellID": True,
        })
        g = lua.globals()
        # Announcement module armed its CLEU listener.
        self.assertGreater(registered_event(lua, "COMBAT_LOG_EVENT_UNFILTERED"), 0)
        # Combat-log auto-logger armed its PEW listener.
        self.assertGreater(registered_event(lua, "PLAYER_ENTERING_WORLD"), 0)
        # PulseCD frame (named, created at login when enabled).
        self.assertIsNotNone(g.PulseCDFrame)
        # Auto-greed armed its loot-roll listener.
        self.assertGreater(registered_event(lua, "START_LOOT_ROLL"), 0)
        # Spell-ID tooltip hook installed.
        self.assertIsNotNone(g.GameTooltip.scripts.OnTooltipSetSpell)

    def test_class_battery_stays_off_at_defaults(self):
        lua = load_battery({})
        g = lua.globals()
        self.assertEqual(registered_event(lua, "COMBAT_LOG_EVENT_UNFILTERED"), 0)
        self.assertEqual(registered_event(lua, "PLAYER_ENTERING_WORLD"), 0)
        self.assertIsNone(g.PulseCDFrame)
        self.assertEqual(registered_event(lua, "START_LOOT_ROLL"), 0)
        self.assertIsNone(g.GameTooltip.scripts.OnTooltipSetSpell)


if __name__ == "__main__":
    unittest.main()
