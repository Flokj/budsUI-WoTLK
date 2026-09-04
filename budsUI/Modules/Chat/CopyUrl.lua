local K, C, L, _ = select(2, ...):unpack()

local pairs = pairs
local match = string.match
local gsub = string.gsub
local sub = string.sub

-- Copy url from chat(module from Gibberish by p3lim)
local patterns = {
	"(%d+%.%d+%.%d+%.%d+:?%d*)",
	"(http://%S+)",
	"(https://%S+)",
	"(www%.%S+)"
}

for _, event in pairs({
	"CHAT_MSG_BATTLEGROUND",
	"CHAT_MSG_BATTLEGROUND_LEADER",
	"CHAT_MSG_BN_WHISPER",
	"CHAT_MSG_CHANNEL",
	"CHAT_MSG_GUILD",
	"CHAT_MSG_OFFICER",
	"CHAT_MSG_PARTY",
	"CHAT_MSG_PARTY_LEADER",
	"CHAT_MSG_RAID",
	"CHAT_MSG_RAID_LEADER",
	"CHAT_MSG_RAID_WARNING",
	"CHAT_MSG_SAY",
	"CHAT_MSG_WHISPER",
	"CHAT_MSG_YELL"
}) do
	ChatFrame_AddMessageEventFilter(event, function(self, event, str, ...)
		for _, pattern in pairs(patterns) do
			-- T17: Renamed `match` -> `count` to avoid shadowing the outer string.match upvalue
			local result, count = gsub(str, pattern, "|cff00FF00|Hurl:%1|h[%1]|h|r")
			if count > 0 then
				return false, result, ...
			end
		end
	end)
end

-- T18: Defensive wrapper preserving prior addon overrides (avoids raw method clobber)
-- Intentional: intercepts `url:` hyperlinks to insert them into the chat edit box.
local origSetHyperlink = _G.ItemRefTooltip.SetHyperlink
function _G.ItemRefTooltip:SetHyperlink(link, ...)
	if link and (strsub(link, 1, 3) == "url") then
		local editbox = ChatEdit_ChooseBoxForSend()
		ChatEdit_ActivateChat(editbox)
		editbox:Insert(sub(link, 5))
		editbox:HighlightText()
		return
	end
	return origSetHyperlink(self, link, ...)
end