local K, C, L, _ = select(2, ...):unpack()
if C.Announcements.Spells ~= true then return end

local format = string.format
local gsub = string.gsub
local pairs = pairs
local CreateFrame = CreateFrame
local GetInstanceInfo = GetInstanceInfo
local GetSpellInfo = GetSpellInfo
local SendChatMessage = SendChatMessage
local playerGUID = UnitGUID("player")

-- WoW 3.3.5: GetSpellLink doesn't exist, create spell link manually
local function GetSpellLink(spellID)
	local name = GetSpellInfo(spellID)
	if name then
		return "|cff71d5ff|Hspell:"..spellID.."|h["..name.."]|h|r"
	end
	return nil
end

-- Announce some spells
local frame = CreateFrame("Frame")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:SetScript("OnEvent", function(self, _, ...)
	local _, event, sourceGUID, sourceName, _, _, destName, _, spellID = ...
	local spells = K.AnnounceSpells
	
	local inInstance, instanceType = GetInstanceInfo()
	if not (inInstance and (instanceType == "raid" or instanceType == "party")) then return end

	if event ~= "SPELL_CAST_SUCCESS" then return end
	
	-- Note: sourceGUID == playerGUID is sufficient to check if we cast it, no need to match K.Name.
	if C.Announcements.SpellsFromAll == true and not (sourceGUID == playerGUID) then
		if not sourceName then return end

		for i, spell in ipairs(spells) do
			if spellID == spell then
				if sourceName then sourceName = sourceName:gsub("%-[^|]+", "") end
				if destName then destName = destName:gsub("%-[^|]+", "") end
				
				local spellLink = GetSpellLink(spellID)
				if spellLink then
					if destName == nil then
						SendChatMessage(format(L_ANNOUNCE_FP_USE, sourceName, spellLink), K.CheckChat())
					else
						SendChatMessage(format(L_ANNOUNCE_FP_USE, sourceName, spellLink.." -> "..destName), K.CheckChat())
					end
				end
			end
		end
	else
		if not (sourceGUID == playerGUID) then return end
		if sourceName then sourceName = sourceName:gsub("%-[^|]+", "") end

		for i, spell in ipairs(spells) do
			if spellID == spell then
				if destName then destName = destName:gsub("%-[^|]+", "") end
				local spellLink = GetSpellLink(spellID)
				if spellLink then
					if destName == nil then
						SendChatMessage(format(L_ANNOUNCE_FP_USE, sourceName, spellLink), K.CheckChat())
					else
						SendChatMessage(spellLink.." -> "..destName, K.CheckChat())
					end
				end
			end
		end
	end
end)