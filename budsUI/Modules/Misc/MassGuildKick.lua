local K, C, L, _ = select(2, ...):unpack()

local split = string.split
local tonumber = tonumber

StaticPopupDialogs["CLEANGUILD"] = {
	text = L_MISC_GUILD_CLEANUP_PROMPT,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self)
		local msg = self.data
		local minLevel, minDays, minRankIndex = split(",", msg)
		minRankIndex = tonumber(minRankIndex)
		minLevel = tonumber(minLevel)
		minDays = tonumber(minDays)

		if not minRankIndex then minRankIndex = GuildControlGetNumRanks() - 1 end

		local removedCount = 0
		for i = 1, GetNumGuildMembers() do
			local name, _, rankIndex, level, class, _, note, officerNote, connected, _, class = GetGuildRosterInfo(i)
			local minLevelx = minLevel

			if class == "DEATHKNIGHT" then
				minLevelx = minLevelx + 55
			end

			if not connected then
				local years, months, days, hours = GetGuildRosterLastOnline(i)
				if days ~= nil and ((years > 0 or months > 0 or days >= minDays) and rankIndex >= minRankIndex) and note ~= nil and officerNote ~= nil and (level <= minLevelx) then
					GuildUninvite(name)
					removedCount = removedCount + 1
				end
			end
		end

		SendChatMessage("Guild Cleanup Results: Removed " .. removedCount .. " members below rank " .. GuildControlGetRankName(minRankIndex) .. ", that have a minimal level of " .. minLevel .. ", and have not been online for at least: " .. minDays .. " days.", "GUILD")
	end,
	timeout = 0,
	whileDead = 1,
}

SLASH_MASSGUILDKICK1 = "/cleanguild"
SLASH_MASSGUILDKICK2 = "/MassGuildKick"
SlashCmdList["MASSGUILDKICK"] = function(msg)
	local minLevel, minDays, minRankIndex = split(",", msg)
	minLevel = tonumber(minLevel)
	minDays = tonumber(minDays)

	if not minLevel or not minDays then
		K.Print("Usage: /cleanguild <minLevel>, <minDays>, [<minRankIndex>]")
		return
	end

	if minDays > 31 then
		K.Print("Maximum days value must be below 32.")
		return
	end

	local dialog = StaticPopup_Show("CLEANGUILD")
	if dialog then
		dialog.data = msg
	end
end