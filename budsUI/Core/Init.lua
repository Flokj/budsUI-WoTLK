-- Initiation / Engine of budsUI
local AddOn, Engine = ...

Engine[1] = CreateFrame("Frame")
Engine[2] = {}
Engine[3] = {}
Engine[4] = {}

function Engine:unpack()
    return self[1], self[2], self[3], self[4]
end

Engine[1].Directory = AddOn
Engine[1].Noop = function() return end
Engine[1].Unit = UnitGUID("player")
Engine[1].Name = UnitName("player")
Engine[1].Class = select(2, UnitClass("player"))
Engine[1].Race = select(2, UnitRace("player"))
Engine[1].Level = UnitLevel("player")
Engine[1].Client = GetLocale()
Engine[1].Realm = GetRealmName()
local res = GetCVar("gxResolution")
if not res or not string.match(res, "%d+x%d+") then
	res = "1920x1080"
end
Engine[1].Resolution = res
Engine[1].Color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[Engine[1].Class]
Engine[1].Version = "0.7.1"
Engine[1].ScreenHeight = tonumber(string.match(Engine[1].Resolution, "%d+x(%d+)"))
Engine[1].ScreenWidth = tonumber(string.match(Engine[1].Resolution, "(%d+)x+%d"))
Engine[1].VersionNumber = tonumber(Engine[1].Version)
Engine[1].WoWPatch, Engine[1].WoWBuild, Engine[1].WoWPatchReleaseDate, Engine[1].TocVersion = GetBuildInfo()

-- Initialize Global Addon Configuration Settings
if type(SavedOptions) ~= "table" then SavedOptions = {} end

-- Soft-Mandatory config check (Warns user if budsUI_Config is disabled)
local configWarningFrame = CreateFrame("Frame")
configWarningFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
configWarningFrame:SetScript("OnEvent", function(self, event)
	if not IsAddOnLoaded("budsUI_Config") then
		StaticPopupDialogs["BUDSUI_MISSING_CONFIG"] = {
			text = "|cffff0000WARNING:|r You are running budsUI without the budsUI_Config addon enabled. \n\nbudsUI heavily relies on its Config addon to function properly. Please enable it in the character select screen.",
			button1 = OKAY,
			timeout = 0,
			whileDead = 1,
			hideOnEscape = false,
			preferredIndex = 3,
		}
		StaticPopup_Show("BUDSUI_MISSING_CONFIG")
	end
	
	-- We also use this opportunity to warn legacy users about the v0.7.0 reset once per account
	if SavedOptions and not SavedOptions.v070ResetWarned then
		StaticPopupDialogs["BUDSUI_V070_RESET"] = {
			text = "|cff388bdbbudsUI v0.7.0 Update|r\n\nA new profile system has been implemented! Your previous legacy settings have been reset to ensure a clean slate and maximum performance.\n\nPlease take a moment to reconfigure your UI in the options menu.",
			button1 = OKAY,
			timeout = 0,
			whileDead = 1,
			hideOnEscape = false,
			preferredIndex = 3,
		}
		StaticPopup_Show("BUDSUI_V070_RESET")
		SavedOptions.v070ResetWarned = true
	end
	
	self:UnregisterEvent(event)
end)

SLASH_RELOADUI1, SLASH_RELOADUI2 = "/rl", "/reloadui"
SlashCmdList["RELOADUI"] = ReloadUI

budsUI = Engine

--[[
-- ** budsUI Engine Documentation ** --

This should be at the top of every file inside of the budsUI AddOn.
local K, C, L, _ = select(2, ...):unpack()
You can also do local K, C, _ = select(2, ...):unpack()
As well as K, _ = select(2, ...):unpack()
This is going to depend on what you are going to be using in the file.

This is how another addon imports the budsUI engine.
local K, C, L, _ = budsUI:unpack()
You can also do local K, C, _ = budsUI:unpack()
As well as K, _ = select(2, ...):unpack()
This is going to depend on what you are going to be using in the file.

We put an _ for taint prevention.
]]