local K, C, L = select(2, ...):unpack()
if C.Announcements.SaySapped ~= true then return end

-- Cache Sap spell name for robust catching of all ranks/custom variations
local sapSpellName = K.GetSpellInfo(6770)

local SaySapped = CreateFrame("Frame")
local playerGUID = UnitGUID("player")

SaySapped:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
SaySapped:SetScript("OnEvent", function(self, event, ...)
	local _, subEvent, _, sourceName, _, destGUID, destName, destFlags, spellID, spellName = ...

	-- Short-circuit evaluation: Check target identity and event type first
	if (destGUID == playerGUID) and (subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REFRESH") then
		-- Check both common IDs and the localized name to catch custom Ascension modifications
		if spellID == 51724 or spellID == 11297 or spellID == 2070 or spellID == 6770 or (spellName and spellName == sapSpellName) then
			SendChatMessage(L_ANNOUNCE_SAPPED or "Sapped", "SAY")
			K.Print((L_ANNOUNCE_SAPPED_BY or "Sapped by: ")..(sourceName or "(unknown)"))
		end
	end
end)