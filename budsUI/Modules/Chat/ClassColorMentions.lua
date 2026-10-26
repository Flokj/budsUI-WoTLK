local K, C, L, _ = select(2, ...):unpack()
if C.Chat.Enable ~= true then return end

-- Class color mentions (ported from ElvUI): player names in chat messages
-- and chat bubbles get colored by their class.

local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local format, gmatch, gsub = string.format, string.gmatch, string.gsub
local strlower = string.lower
local pairs, next = pairs, next
local pcall = pcall

local CUSTOM_CLASS_COLORS = CUSTOM_CLASS_COLORS
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

-- name (lowered) -> english class token
local ClassNames = {}

-- Resolve a name's class by its GUID, cache name->class (mirrors ElvUI).
local GuidCache = {}
local function GetPlayerInfo(guid)
	local data = GuidCache[guid]
	if not data then
		local ok, _, englishClass, _, _, _, name, realm = pcall(GetPlayerInfoByGUID, guid)
		if not (ok and englishClass) then return end
		if realm == "" then realm = nil end
		data = { englishClass = englishClass, name = name, realm = realm }
		if name and name ~= "" then
			ClassNames[strlower(name)] = englishClass
		end
		if name and realm then
			ClassNames[strlower(name .. "-" .. realm)] = englishClass
		end
		GuidCache[guid] = data
	end
	return data
end

local function EscapeString(s)
	return (gsub(s, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
end

-- ElvUI's class color section of CheckKeyword: protect links, then wrap
-- any word matching a known player name in its class color.
local protectLinks = {}
local function CheckKeyword(message)
	for hyperLink in gmatch(message, "|c%x-|H.-|h.-|h|r") do
		protectLinks[hyperLink] = gsub(hyperLink, "%s", "|s")
	end
	for hyperLink, tempLink in pairs(protectLinks) do
		message = gsub(message, EscapeString(hyperLink), tempLink)
	end

	local rebuiltString
	local isFirstWord = true
	for word in gmatch(message, "%s-%S+%s*") do
		if not next(protectLinks) or not protectLinks[gsub(gsub(word, "%s", ""), "|s", " ")] then
			local tempWord = gsub(word, "^[%s%p]-([^%s%p]+)([%-]?[^%s%p]-)[%s%p]*$", "%1%2")
			local classMatch = ClassNames[strlower(tempWord)]
			if classMatch then
				local colorTable = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[classMatch]) or RAID_CLASS_COLORS[classMatch]
				if colorTable then
					word = gsub(word, gsub(tempWord, "%-", "%%-"), format("|cff%.2x%.2x%.2x%s|r", colorTable.r * 255, colorTable.g * 255, colorTable.b * 255, tempWord))
				end
			end
		end
		if isFirstWord then
			rebuiltString = word
			isFirstWord = false
		else
			rebuiltString = rebuiltString .. word
		end
	end

	for hyperLink, tempLink in pairs(protectLinks) do
		rebuiltString = gsub(rebuiltString, EscapeString(tempLink), function() return hyperLink end)
		protectLinks[hyperLink] = nil
	end

	return rebuiltString
end

local CHAT_EVENTS = {
	"CHAT_MSG_CHANNEL",
	"CHAT_MSG_GUILD",
	"CHAT_MSG_OFFICER",
	"CHAT_MSG_PARTY",
	"CHAT_MSG_PARTY_LEADER",
	"CHAT_MSG_RAID",
	"CHAT_MSG_RAID_LEADER",
	"CHAT_MSG_SAY",
	"CHAT_MSG_WHISPER",
	"CHAT_MSG_WHISPER_INFORM",
	"CHAT_MSG_YELL",
}

-- ElvUI runs CheckKeyword through its message pipeline; budsUI has no such
-- pipeline, so a plain 3.3.5 chat filter is the equivalent hook. arg12 of
-- the event (sender GUID) sits at select(10, ...) after (self, event,
-- message=arg1, author=arg2).
local function ChatMentionFilter(self, event, message, author, ...)
	GetPlayerInfo(select(10, ...))
	if C.Chat.ClassColorMentions ~= true then return end
	local newMessage = CheckKeyword(message)
	if newMessage ~= message then
		return false, newMessage, author, ...
	end
end

for _, event in ipairs(CHAT_EVENTS) do
	ChatFrame_AddMessageEventFilter(event, ChatMentionFilter)
end

-- Same recolor inside chat bubbles (budsUI bubble engine).
local BubbleLayer = K.BubbleLayer
if BubbleLayer and BubbleLayer.Register then
	BubbleLayer.Register({
		shown = function(bubble, info)
			if C.Chat.ClassColorMentionsSpeech ~= true then return end
			local text = info and info.text
			if not text then return end
			local drawn = text:GetText()
			if not drawn or drawn == "" then return end
			local recolored = CheckKeyword(drawn)
			if recolored ~= drawn then
				text:SetText(recolored)
			end
		end,
	})
end
