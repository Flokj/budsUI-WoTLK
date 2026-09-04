local K, C, L, _ = select(2, ...):unpack()
if C.Announcements.Interrupt ~= true then return end

local format = string.format
local CreateFrame = CreateFrame
local SendChatMessage = SendChatMessage
local GetSpellInfo = GetSpellInfo

-- WoW 3.3.5: GetSpellLink doesn't exist, create spell link manually
local function GetSpellLink(spellID)
	local name = GetSpellInfo(spellID)
	if name then
		return "|cff71d5ff|Hspell:"..spellID.."|h["..name.."]|h|r"
	end
	return nil
end

-- Announce your interrupts
local frame = CreateFrame("Frame")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:SetScript("OnEvent", function(self, _, ...)
	local _, event, sourceGUID, _, _, _, destName, _, _, _, _, spellID = ...
	if not (event == "SPELL_INTERRUPT" and sourceGUID == UnitGUID("player")) then return end

	local spellLink = GetSpellLink(spellID)
	if spellLink then
		SendChatMessage(L_ANNOUNCE_INTERRUPTED.." "..destName..": "..spellLink, K.CheckChat())
	end
end)