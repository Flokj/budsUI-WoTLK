local K, C, L, _ = select(2, ...):unpack()
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

-- Auto resurrection in battlegrounds / Wintergrasp.
-- Ported from FrostAtomUI (Modules/Interface/Popups.lua) — release via the
-- actual DEATH dialog Accept (RepopMe), gated on instance type "pvp", the
-- DEATH popup being visible, no soulstone buff and no Shift held (manual
-- override). Wintergrasp is kept from the old KkthnxUI logic since it is an
-- outdoor zone, not a pvp instance.
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