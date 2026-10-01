local K, C, L, _ = select(2, ...):unpack()
if C.Chat.Enable ~= true then return end

local lower = string.lower
local match = string.match
local pairs = pairs
local IsResting = IsResting
local UnitIsInMyGuild = UnitIsInMyGuild

-- Systems spam filter
if C.Chat.Filter == true then
	ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_SAY", function() if IsResting() then return true end end)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_YELL", function() if IsResting() then return true end end)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_JOIN", function() return true end)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_LEAVE", function() return true end)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", function() return true end)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_AFK", function() return true end)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_DND", function() return true end)
	DUEL_WINNER_KNOCKOUT = ""
	DUEL_WINNER_RETREAT = ""
	DRUNK_MESSAGE_ITEM_OTHER1 = ""
	DRUNK_MESSAGE_ITEM_OTHER2 = ""
	DRUNK_MESSAGE_ITEM_OTHER3 = ""
	DRUNK_MESSAGE_ITEM_OTHER4 = ""
	DRUNK_MESSAGE_OTHER1 = ""
	DRUNK_MESSAGE_OTHER2 = ""
	DRUNK_MESSAGE_OTHER3 = ""
	DRUNK_MESSAGE_OTHER4 = ""
	DRUNK_MESSAGE_ITEM_SELF1 = ""
	DRUNK_MESSAGE_ITEM_SELF2 = ""
	DRUNK_MESSAGE_ITEM_SELF3 = ""
	DRUNK_MESSAGE_ITEM_SELF4 = ""
	DRUNK_MESSAGE_SELF1 = ""
	DRUNK_MESSAGE_SELF2 = ""
	DRUNK_MESSAGE_SELF3 = ""
	DRUNK_MESSAGE_SELF4 = ""
	ERR_PET_LEARN_ABILITY_S = ""
	ERR_PET_LEARN_SPELL_S = ""
	ERR_PET_SPELL_UNLEARNED_S = ""
	ERR_LEARN_ABILITY_S = ""
	ERR_LEARN_SPELL_S = ""
	ERR_LEARN_PASSIVE_S = ""
	ERR_SPELL_UNLEARNED_S = ""
	ERR_CHAT_THROTTLED = ""
end

-- Players spam filter(by Evl, Elv22 and Affli)
-- The ellipsis (which is what ... is called) only allows you to accept an undefined number of extra arguments
-- So local function blahblah(self, event, text, sender) is the same as local function blahblah(self, event, text, sender, ...)
-- If you pass on the arguments in that function, you need to pass the ... along, or it might break the functionality
if C.Chat.Spam == true then
	-- Repeat spam filter
	-- T19: Module-local state replaces frame pollution (Blizzard frames should not be mutated)
	-- T20: Removed dead `lastMessage` variable (was set but never read independently)
	local repeatState = {}
	local function repeatMessageFilter(self, event, text, sender)
		if sender == K.Name or UnitIsInMyGuild(sender) then return end
		local state = repeatState[self]
		if not state or state.count > 100 then
			state = {count = 0, messages = {}}
			repeatState[self] = state
		end
		if state.messages[sender] == text then
			return true
		end
		state.messages[sender] = text
		state.count = state.count + 1
	end

	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", repeatMessageFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", repeatMessageFilter)

	-- Gold/portals spam filter
	local SpamList = K.ChatSpamList
	local function tradeFilter(self, event, text, sender)
		if sender == K.Name or UnitIsInMyGuild(sender) then return end
		for _, value in pairs(SpamList) do
			if text:lower():match(value) then
				return true
			end
		end
	end

	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", tradeFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", tradeFilter)
end

-- ═══════════════════════════════════════════════════════════════
--  Battleground / arena announcements filter (ported from FrostAtomUI)
--  Kills CAMPAIGN-spam ([BG Queue Announcer] / server adverts),
--  arena-result spam, and battleground player join/leave
--  notifications while inside a BG.
-- ═══════════════════════════════════════════════════════════════
if C.Chat.Filter == true then
	local IsInInstance = IsInInstance
	local GetTime = GetTime
	local find, match, gsub, sub = string.find, string.match, string.gsub, string.sub

	-- Server/spam advertise lines (also covers the BG Queue Announcer)
	local SYSTEM_SPAM = {
		"^|cffff0000%[BG Queue Announcer%]:|r",
		"wowcircle%.net",
		"control panel at our website",
		"Speeding up the battle start",
		"/join english",
	}

	local function formatToPattern(text)
		return "^" .. gsub(gsub(text, "[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0"), "%%%%[sd]", "(.-)") .. "$"
	end
	local function withOptionalPeriod(pattern)
		return sub(pattern, 1, -2) .. "%.?$"
	end

	local BG_JOINED = {
		withOptionalPeriod(formatToPattern(ERR_BG_PLAYER_JOINED_SS)),
		withOptionalPeriod(formatToPattern((gsub(ERR_BG_PLAYER_JOINED_SS, "|H.-|h.-|h", "%%s", 1)))),
		formatToPattern(ERR_RAID_MEMBER_ADDED_S),
	}
	local BG_LEFT = {
		withOptionalPeriod(formatToPattern(ERR_BG_PLAYER_LEFT_S)),
		formatToPattern(ERR_RAID_MEMBER_REMOVED_S),
	}

	local function appendFormatPatterns(patterns, ...)
		for i = 1, select("#", ...) do
			patterns[#patterns + 1] = formatToPattern((select(i, ...)))
		end
		return patterns
	end

	local ARENA_SPAM = appendFormatPatterns(
		{
			BG_JOINED[1],
			BG_JOINED[2],
			"^One minute until the Arena battle begins!$",
			"^Thirty seconds until the Arena battle begins!$",
			"^Fifteen seconds until the Arena battle begins!$",
			"^The Arena battle has begun!$",
			"^Speeding up the battle start! Players ready: %d+%.$",
			"^You are in Spectator Mode%. ",
			"^The %a+ Team wins!$",
		},
		ERR_SET_LOOT_FREEFORALL,
		ERR_SET_LOOT_GROUP,
		ERR_SET_LOOT_MASTER,
		ERR_SET_LOOT_ROUNDROBIN,
		ERR_SET_LOOT_THRESHOLD_S,
		ERR_RAID_YOU_JOINED,
		ERR_RAID_YOU_LEFT,
		ERR_RAID_MEMBER_ADDED_S,
		ERR_RAID_MEMBER_REMOVED_S,
		ERR_BG_PLAYER_LEFT_S,
		ERR_PLAYER_DIED_S,
		ERR_LEFT_GROUP_S,
		ERR_NEW_LEADER_YOU,
		ERR_NEW_LEADER_S
	)

	local wasInArena, arenaLeftAt = false, 0
	local inBattleground = false
	local ARENA_SPAM_AFTER_LEAVE = 10

	local function matchesAny(message, patterns)
		for i = 1, #patterns do
			if find(message, patterns[i]) then
				return true
			end
		end
		return false
	end

	local function isServerSpam(message)
		return matchesAny(message, SYSTEM_SPAM)
	end

	local function isBattlegroundJoinLeave(message)
		if not inBattleground then
			return false
		end
		return matchesAny(message, BG_JOINED) or matchesAny(message, BG_LEFT)
	end

	local function isArenaSpam(message)
		if not wasInArena and GetTime() - arenaLeftAt > ARENA_SPAM_AFTER_LEAVE then
			return false
		end
		return matchesAny(message, ARENA_SPAM)
	end

	local function filterSystem(self, event, message)
		if isServerSpam(message) or isArenaSpam(message) or isBattlegroundJoinLeave(message) then
			return true
		end
	end

	local function filterBgSystem(self, event, message)
		return isArenaSpam(message)
	end

	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", filterSystem)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BG_SYSTEM_NEUTRAL", filterBgSystem)

	-- Track which instance we're in so the filters only fire when relevant.
	local bgStateFrame = CreateFrame("Frame")
	bgStateFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	bgStateFrame:SetScript("OnEvent", function()
		local _, instanceType = IsInInstance()
		local inArena = instanceType == "arena"
		if wasInArena and not inArena then
			arenaLeftAt = GetTime()
		end
		wasInArena = inArena
		inBattleground = instanceType == "pvp"
	end)
end