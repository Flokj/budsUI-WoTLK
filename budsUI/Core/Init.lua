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

-- budsUI_Config ships as a LoadOnDemand addon (see its .toc) so it does not
-- appear as a second addon in the list; the main addon loads it here.
local CONFIG_ADDON = "budsUI_Config"

local function ShowMissingConfigPopup()
	StaticPopupDialogs["BUDSUI_MISSING_CONFIG"] = {
		text = "|cffff0000WARNING:|r budsUI could not load its settings module (" .. CONFIG_ADDON .. ").\n\nMake sure the budsUI_Config folder sits next to the budsUI folder in Interface/AddOns, that the module is enabled in the addon list, and that \"Load out of date AddOns\" is checked at the character screen.",
		button1 = OKAY,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = false,
		preferredIndex = 3,
	}
	StaticPopup_Show("BUDSUI_MISSING_CONFIG")
end

-- 3.3.5 GetAddOnInfo() is index based, so resolve the index once by name.
local function ConfigAddonIndex()
	for i = 1, GetNumAddOns() do
		if GetAddOnInfo(i) == CONFIG_ADDON then
			return i
		end
	end
end

local configWarned = false
local function WarnOnce()
	if configWarned then return end
	configWarned = true
	ShowMissingConfigPopup()
end

local function LoadConfigAddon()
	if IsAddOnLoaded(CONFIG_ADDON) then return true end
	local index = ConfigAddonIndex()
	if not index then
		-- The folder is missing: no retry will ever succeed.
		WarnOnce()
		return false
	end
	local loaded = LoadAddOn(index)
	if not loaded then
		local _, _, _, enabled = GetAddOnInfo(index)
		if enabled == false then
			WarnOnce()
		end
	end
	return loaded and true or false
end

local configLoader = CreateFrame("Frame")
configLoader:RegisterEvent("ADDON_LOADED")
configLoader:RegisterEvent("PLAYER_ENTERING_WORLD")
configLoader:RegisterEvent("PLAYER_REGEN_ENABLED")
configLoader:SetScript("OnEvent", function(self, event, addon)
	if event == "ADDON_LOADED" then
		if addon ~= AddOn then return end
		-- The config is loaded on demand by the client, so pull it in ourselves.
		LoadConfigAddon()
		self:UnregisterEvent("ADDON_LOADED")
		return
	end

	if not IsAddOnLoaded(CONFIG_ADDON) then
		-- Login in combat on some 3.3.5 cores blocks LoadAddOn; retry once we can.
		LoadConfigAddon()
	end

	if event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")

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
	end

	if IsAddOnLoaded(CONFIG_ADDON) then
		self:UnregisterAllEvents()
	end
end)

_G.SLASH_RELOADUI1 = "/rl"
_G.SLASH_RELOADUI2 = "/reload"
_G.SLASH_RELOADUI3 = "/reloadui"
_G.SLASH_RELOADUI4 = "//"
_G.SLASH_RELOADUI5 = "/."
_G.SLASH_RELOADUI6 = "/кд"
_G.SlashCmdList.RELOADUI = ReloadUI

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