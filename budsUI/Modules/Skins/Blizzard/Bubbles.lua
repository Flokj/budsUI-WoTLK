local K, C, L, _ = select(2, ...):unpack()

if C.Skins.ChatBubble ~= true then return end
if IsAddOnLoaded("BossEncounter2") then return end

local DEBUG = C.General and C.General.DeveloperMode == true
local function dbg(...)
	if DEBUG then
		print("|cffff7d0abudsUI Bubbles:|r", ...)
	end
end

local BubbleLayer = K.BubbleLayer
if not BubbleLayer then
	dbg("K.BubbleLayer missing (load order!), aborting")
	return
end

dbg("consumer enabled (BubbleLayer + WorldChildren architecture)")

local find, gsub, sub, lower, match = string.find, string.gsub, string.sub, string.lower, string.match
local min, max = math.min, math.max

local GetPlayerInfoByGUID = GetPlayerInfoByGUID

local ICON_TAG_LIST = ICON_TAG_LIST
local ICON_LIST = ICON_LIST

local BACKDROP = {
	bgFile = C.Media.Blank,
	edgeFile = C.Media.Blizz,
	edgeSize = 14,
	insets = { left = 2.5, right = 2.5, top = 2.5, bottom = 2.5 }
}
local PADDING = 4
local BORDER_INSET = 2.5
local SENDER_GAP = 2

local function iconTagToTexture(tag)
	local index = ICON_TAG_LIST[lower(sub(tag, 2, -2))]
	return index and ICON_LIST[index] and (ICON_LIST[index] .. "0|t") or tag
end

local byte = string.byte
local GUID_PLAYER_BYTE = 0x04

local function IsPlayerGUID(guid)
	-- Player-type guilds have the type byte (GUID_PLAYER_BYTE = 4) at index 3.
	-- For empty guid ("") byte returns nil → false. This is the FrostAtomUI
	-- PlateLayer.IsPlayerGUID approach: never call GetPlayerInfoByGUID on a guid
	-- that isn't a player (monster bubbles carry guid="", would error).
	return guid ~= nil and byte(guid, 3) == GUID_PLAYER_BYTE
end

local function senderColor(info)
	-- Player-bubble sender name in class color; monsters/NPCs use bubble text color.
	local guid = info.guid
	if guid and IsPlayerGUID(guid) then
		local _, class = GetPlayerInfoByGUID(guid)
		if class then
			local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
			if color then
				return color.r, color.g, color.b
			end
		end
	end
	return info.r, info.g, info.b
end

local function layout(bubble, info)
	local text, sender = bubble.text, bubble.sender
	if not text then
		return
	end
	local r, g, b = info.r, info.g, info.b

	text:SetFont(C.Media.Font, C.General.BubbleFontSize or C.Media.Font_Size, C.Media.Font_Style)
	text:SetTextColor(r, g, b)

	local senderWidth, senderHeight = 0, 0
	if C.Chat.BubbleShowSender and info.sender then
		sender:SetFont(C.Media.Font, C.Media.Font_Size, C.Media.Font_Style)
		sender:SetText(match(info.sender, "^[^%-]+"))
		sender:SetTextColor(senderColor(info))
		sender:Show()
		senderWidth, senderHeight = sender:GetStringWidth(), sender:GetStringHeight() + SENDER_GAP
	else
		sender:Hide()
	end

	text:SetWidth(0)
	text:SetWidth(max(min(text:GetStringWidth(), C.Chat.BubbleMaxWidth or 300), senderWidth))

	local inset = PADDING + BORDER_INSET
	-- 3.3.5: the client sets the bubble's points only once and afterwards moves just the text
	bubble:ClearAllPoints()
	bubble:SetPoint("BOTTOMLEFT", text, -inset, -inset)
	bubble:SetPoint("TOPRIGHT", text, inset, inset + senderHeight)

	local backdropColor = C.Media.Backdrop_Color
	bubble:SetBackdropColor(backdropColor[1], backdropColor[2], backdropColor[3], backdropColor[4])
	if C.Chat.BubbleTypeBorder then
		bubble:SetBackdropBorderColor(r, g, b)
	else
		local borderColor = C.Media.Border_Color
		bubble:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
	end
end

local function onShown(bubble, info)
	if not bubble.sender then
		return
	end
	-- NOTE: sender/guid matching (takePending) already happened in
	-- BubbleLayer.onShow before this fires. Do NOT takePending again here:
	-- the text may already be rewritten below and would no longer match.
	local text = bubble.text
	local message = text:GetText() or ""
	if find(message, "{", 1, true) then
		text:SetText((gsub(message, "%b{}", iconTagToTexture)))
	end
	dbg("onShown:", "sender =", tostring(info.sender), "text =", (text:GetText() or ""):sub(1, 40))
	layout(bubble, info)
end

local function setupBubble(bubble, info)
	local text = info.text
	if not text then
		dbg("setupBubble skipped: no FontString")
		return
	end
	dbg("setupBubble, text =", (text:GetText() or ""):sub(1, 40))
	if info.tail then
		info.tail:SetTexture(nil)
		info.tail:Hide()
	end
	-- 3.3.5: SetBackdrop destroys the client's backdrop regions; info.background and info.edges die
	bubble:SetBackdrop(BACKDROP)

	text:SetShadowColor(0, 0, 0, 1)
	text:SetShadowOffset(1, -1)
	text:SetJustifyH("LEFT")

	local sender = bubble:CreateFontString(nil, "OVERLAY")
	sender:SetPoint("BOTTOMLEFT", text, "TOPLEFT", 0, SENDER_GAP)
	sender:SetJustifyH("LEFT")
	sender:SetWordWrap(false)
	sender:Hide()

	bubble.text = text
	bubble.sender = sender
end

local function relayout()
	local bubbles = BubbleLayer.bubbles
	for i = 1, #bubbles do
		local bubble = bubbles[i]
		local info = BubbleLayer.GetInfo(bubble)
		if bubble.sender and info and info.shown then
			layout(bubble, info)
		end
	end
end

BubbleLayer.Register({ created = setupBubble, shown = onShown })

local configWatch = CreateFrame("Frame")
configWatch:RegisterEvent("CVAR_UPDATE")
configWatch:SetScript("OnEvent", function(_, _, cvar)
	if cvar == "chatBubbles" or cvar == "chatBubblesParty" then
		relayout()
	end
end)
