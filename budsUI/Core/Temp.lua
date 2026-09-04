local K, C, L, _ = select(2, ...):unpack()

-- THIS FILE IS FOR TESTING AND REMINDERS BULLSHIT :D
-- [[ -*- NOTES -*- ]] --

-- [[ -*- COMBAT_LOG_EVENT_UNFILTERED -*- ]] --
-- timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID = ...
-- timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName = select (1, ...)

if C.General.DeveloperMode == true then

	local GetZonePVPInfo = GetZonePVPInfo
	local GetSpellInfo = GetSpellInfo
	local SendChatMessage = SendChatMessage
	local UnitName = UnitName
	local UnitClass = UnitClass

	--if C.Announcements.ArenaDrinking ~= true then return end
	L_MISC_DRINKING = " is drinking."

	-- Cache spell names at load time to avoid per-event GetSpellInfo cost
	local drinkSpellName1 = K.GetSpellInfo(57073)
	local drinkSpellName2 = K.GetSpellInfo(43183)

	-- Announce enemy drinking in arena(by Duffed)
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	frame:SetScript("OnEvent", function(self, event, ...)
		if not (event == "UNIT_SPELLCAST_SUCCEEDED" and GetZonePVPInfo() == "arena") then return end

		local unit, _, _, _, spellID = ...
		local castSpellName = K.GetSpellInfo(spellID)
		if UnitIsEnemy("player", unit) and (castSpellName == drinkSpellName1 or castSpellName == drinkSpellName2) then
			SendChatMessage(UnitClass(unit).." "..UnitName(unit)..L_MISC_DRINKING, K.CheckChat(true))
		end
	end)
end