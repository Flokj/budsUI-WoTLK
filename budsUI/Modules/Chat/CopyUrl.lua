local K, C, L, _ = select(2, ...):unpack()
if C.Chat.Enable ~= true then return end

local _G = _G
local format = string.format
local gsub = string.gsub
local find = string.find
local sub = string.sub
local lower = string.lower
local tconcat = table.concat
local pairs = pairs
local wipe = wipe
local StaticPopup_Show = StaticPopup_Show
local StaticPopupDialogs = StaticPopupDialogs

local URL_LINK = "|cff3399ff|Hurl:%s|h[%s]|h|r"
-- Leading frontier is %f[%w], not %f[%S]: Lua's %f treats the byte before
-- position 1 as \0, which counts as non-space, so %f[%S] never fires at the
-- start of a message and links pasted as the whole message stayed plain text.
-- %w excludes \0 and still blocks matches glued inside a word.
local URL_PATTERNS = {
	"%f[%w](%a[%w+.%-]+://%S+)",
	"%f[%w](www%.[%w_%%%-]+%.%S+)",
	"%f[%w](%d+%.%d+%.%d+%.%d+:?%d*/?%S*)",
	"%f[%w]([%w_%.%%%-]+%.(%a%a+)[:/]%S+)",
	"%f[%w]([%w_%.%%%-]+%.(%a%a+))%f[%s%p%z]",
}

local URL_TLDS = {}
for tld in ("com net org ru su ua by kz eu de fr uk io gg tv me co info biz dev app xyz pro club online site live"):gmatch("%S+") do
	URL_TLDS[tld] = true
end

local linkedAny = false

local function linkUrl(url, tld)
	if tld and not URL_TLDS[lower(tld)] then
		return
	end
	linkedAny = true
	return format(URL_LINK, url, url)
end

local urlParts = {}

local function linkUrls(text)
	if not text or not find(text, ".", 1, true) then
		return text
	end

	for i = 1, #URL_PATTERNS do
		if not find(text, "|H", 1, true) then
			linkedAny = false
			local linked = gsub(text, URL_PATTERNS[i], linkUrl)
			if linkedAny then
				text = linked
			end
		else
			wipe(urlParts)
			local position = 1
			local changed = false
			while true do
				local linkStart, linkEnd = find(text, "|H.-|h.-|h", position)
				if not linkStart then
					break
				end
				local segment = sub(text, position, linkStart - 1)
				if find(segment, ".", 1, true) then
					linkedAny = false
					local linkedSegment = gsub(segment, URL_PATTERNS[i], linkUrl)
					if linkedAny then
						segment = linkedSegment
						changed = true
					end
				end
				urlParts[#urlParts + 1] = segment
				urlParts[#urlParts + 1] = sub(text, linkStart, linkEnd)
				position = linkEnd + 1
			end
			local tail = sub(text, position)
			if find(tail, ".", 1, true) then
				linkedAny = false
				local linkedTail = gsub(tail, URL_PATTERNS[i], linkUrl)
				if linkedAny then
					tail = linkedTail
					changed = true
				end
			end
			urlParts[#urlParts + 1] = tail
			if changed then
				text = tconcat(urlParts)
			end
		end
	end
	return text
end

local currentUrl = ""

local function focusEditBoxText(popup, url)
	local editBox = _G[popup:GetName() .. "EditBox"]
	if editBox then
		editBox:SetMaxLetters(1024)
		editBox:SetText(url or "")
		editBox:SetFocus()
		editBox:HighlightText()
	end
end

StaticPopupDialogs["BUDSUI_COPY_URL"] = {
	text = L_POPUP_COPY_URL or "Ctrl+C to copy",
	button1 = CLOSE or "Close",
	hasEditBox = true,
	editBoxWidth = 350,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
	OnShow = function(self)
		focusEditBoxText(self, currentUrl)
	end,
	EditBoxOnEnterPressed = function(self)
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
}

local function showCopyPopup(url)
	currentUrl = url or ""
	local popup = StaticPopup_Show("BUDSUI_COPY_URL")
	if popup then
		popup.url = currentUrl
		focusEditBoxText(popup, currentUrl)
	end
end

local CHAT_EVENTS = {
	"CHAT_MSG_BATTLEGROUND",
	"CHAT_MSG_BATTLEGROUND_LEADER",
	"CHAT_MSG_BN_CONVERSATION",
	"CHAT_MSG_BN_WHISPER",
	"CHAT_MSG_BN_WHISPER_INFORM",
	"CHAT_MSG_CHANNEL",
	"CHAT_MSG_EMOTE",
	"CHAT_MSG_GUILD",
	"CHAT_MSG_OFFICER",
	"CHAT_MSG_PARTY",
	"CHAT_MSG_PARTY_LEADER",
	"CHAT_MSG_RAID",
	"CHAT_MSG_RAID_LEADER",
	"CHAT_MSG_RAID_WARNING",
	"CHAT_MSG_SAY",
	"CHAT_MSG_TEXT_EMOTE",
	"CHAT_MSG_WHISPER",
	"CHAT_MSG_WHISPER_INFORM",
	"CHAT_MSG_YELL",
}

for _, event in pairs(CHAT_EVENTS) do
	ChatFrame_AddMessageEventFilter(event, function(self, event, str, ...)
		local result = linkUrls(str)
		if result ~= str then
			return false, result, ...
		end
	end)
end

local origSetItemRef = SetItemRef
function SetItemRef(link, text, button, chatFrame)
	if link and sub(link, 1, 4) == "url:" then
		showCopyPopup(sub(link, 5))
		return
	end
	return origSetItemRef(link, text, button, chatFrame)
end

local origSetHyperlink = _G.ItemRefTooltip.SetHyperlink
function _G.ItemRefTooltip:SetHyperlink(link, ...)
	if link and sub(link, 1, 4) == "url:" then
		showCopyPopup(sub(link, 5))
		return
	end
	return origSetHyperlink(self, link, ...)
end