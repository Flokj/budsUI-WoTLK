local K, C, L, _ = select(2, ...):unpack()

local function Init()
if C.Automation.Resurrection ~= true then return end

local tostring = tostring
local CreateFrame = CreateFrame
local GetZoneText = GetZoneText
local IsInInstance = IsInInstance
local UnitIsDead = UnitIsDead
local StaticPopup_Visible = StaticPopup_Visible
local StaticPopupDialogs = StaticPopupDialogs
local HasSoulstone = HasSoulstone
local IsShiftKeyDown = IsShiftKeyDown

-- Auto-release in BG / Wintergrasp (from FrostAtomUI Popups.lua): accept the DEATH
-- dialog when in a pvp instance, popup visible, no soulstone, no Shift; Wintergrasp kept from KkthnxUI.
local WINTERGRASP
WINTERGRASP = L_ZONE_WINTERGRASP

local function shouldRelease()
	local _, instanceType = IsInInstance()
	local inBattleground = instanceType == "pvp"
	local inWintergrasp = tostring(GetZoneText()) == WINTERGRASP
	if not (inBattleground or inWintergrasp) then
		return false
	end
	if not UnitIsDead("player") or not StaticPopup_Visible("DEATH") then
		return false
	end
	if (HasSoulstone and HasSoulstone()) or IsShiftKeyDown() then
		return false
	end
	return true
end

local function tryRelease()
	if shouldRelease() then
		StaticPopupDialogs.DEATH.OnAccept()
	end
end

-- Fire when Blizzard shows the death popup (most reliable trigger).
hooksecurefunc("StaticPopup_Show", function(which)
	if which == "DEATH" then
		tryRelease()
	end
end)

-- Fallback trigger for the case the popup is already up when PLAYER_DEAD fires.
local autoreleasepvp = CreateFrame("frame")
autoreleasepvp:RegisterEvent("PLAYER_DEAD")
autoreleasepvp:SetScript("OnEvent", tryRelease)
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN")
	Init()
end)
