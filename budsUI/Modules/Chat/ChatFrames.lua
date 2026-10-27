local K, C, L, _ = select(2, ...):unpack()
if C.Chat.Enable ~= true then return end

local _G = _G
local gsub = string.gsub
local upper = string.upper
local type = type
local format = string.format
local select = select
local print = print
local find = string.find
local len = string.len
local sub = string.sub
local GetID, GetName = GetID, GetName
local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc
local InCombatLockdown = InCombatLockdown
local dateFunc = BetterDate or date
local origs = {}

-- Chat timestamp formats, same options as KkthnxUI (1 = disabled, picked in /buds -> Chat)
local timestampFormats = {
	[2] = "[%I:%M %p] ",
	[3] = "[%I:%M:%S %p] ",
	[4] = "[%H:%M] ",
	[5] = "[%H:%M:%S] ",
}
local GREY_TIMESTAMP = "|CFFC0C0C0"

local strings = {
	BATTLEGROUND = L_CHAT_BATTLEGROUND,
	GUILD = L_CHAT_GUILD,
	PARTY = L_CHAT_PARTY,
	RAID = L_CHAT_RAID,
	OFFICER = L_CHAT_OFFICER,
	BATTLEGROUND_LEADER = L_CHAT_BATTLEGROUND_LEADER,
	PARTY_LEADER = L_CHAT_PARTY_LEADER,
	RAID_LEADER = L_CHAT_RAID_LEADER,
}

local function ShortChannel(channel)
	return format("|Hchannel:%s|h[%s]|h", channel, strings[channel:upper()] or channel:gsub("channel:", ""))
end

local function AddMessage(frame, str, ...)
	if type(str) ~= "string" then
		local orig = origs[frame]
		if orig then
			return orig(frame, str, ...)
		end
		return
	end
	str = str:gsub("|Hchannel:(.-)|h%[(.-)%]|h", ShortChannel)
	str = str:gsub("CHANNEL:", "")
	str = str:gsub("^(.-|h) "..L_CHAT_WHISPERS, "%1")
	str = str:gsub("^(.-|h) "..L_CHAT_SAYS, "%1")
	str = str:gsub("^(.-|h) "..L_CHAT_YELLS, "%1")
	str = str:gsub("<"..AFK..">", "[|cffFF0000"..L_CHAT_AFK.."|r] ")
	str = str:gsub("<"..DND..">", "[|cffE7E716"..L_CHAT_DND.."|r] ")
	str = str:gsub("%[BN_CONVERSATION:", "%[1".."")
	str = str:gsub("^%["..RAID_WARNING.."%]", "["..L_CHAT_RAID_WARNING.."]")
	-- Chat timestamps, same formats as KkthnxUI (1 = disabled, picked in /buds -> Chat)
	-- Skip blank lines (e.g. bursts of empty service messages on spec swap):
	-- they were invisible before, stamping them would spam visible timestamps.
	local visible = str:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", "")
	local fmt = C.Chat.TimestampFormat
	if fmt and fmt > 1 and timestampFormats[fmt] and not visible:match("^%s*$") then
		-- Strip Blizzard's own timestamp to avoid doubles (Interface -> Display -> Timestamps)
		local ok, showTS = pcall(GetCVar, "showTimestamps")
		if ok and showTS and showTS ~= "none" then
			local okDate, blizzTS = pcall(dateFunc, showTS)
			if okDate and blizzTS and len(blizzTS) > 0 then
				local escaped = blizzTS:gsub("([%%%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
				str = str:gsub("^" .. escaped, "")
			end
		end
		local okDate, stamp = pcall(dateFunc, GREY_TIMESTAMP .. timestampFormats[fmt] .. "|r")
		if okDate and stamp then
			str = stamp .. str
		end
	end
	local orig = origs[frame]
	if orig then
		return orig(frame, str, ...)
	end
end

ChatFrameMenuButton:Kill()

local function SkinFriendsButton()
	local button = FriendsMicroButton
	if not button then return end

	button:GetNormalTexture():SetTexture(nil)
	button:GetPushedTexture():SetTexture(nil)
	button:GetHighlightTexture():SetTexture(nil)
	button:SetSize(16, 16)

	if not button.glyph then
		button.glyph = K.CreateGlyph(button, "user-group", 11, "ARTWORK", "OUTLINE")
		button.glyph:SetPoint("CENTER")
	end

	local function setHover(hovered)
		local color = hovered and { 1, 0.82, 0 } or { 0.75, 0.75, 0.75 }
		button.glyph:SetTextColor(color[1], color[2], color[3])
		button:SetAlpha(hovered and 1 or 0.35)
	end

	button:HookScript("OnEnter", function() setHover(true) end)
	button:HookScript("OnLeave", function() setHover(false) end)
	button:HookScript("OnMouseDown", function() button.glyph:SetPoint("CENTER", 1, -1) end)
	button:HookScript("OnMouseUp", function() button.glyph:SetPoint("CENTER", 0, 0) end)

	setHover(false)

	if FriendsMicroButtonCount then
		FriendsMicroButtonCount:Hide()
		FriendsMicroButtonCount.Show = K.Noop
	end
end

local function AttachFriendsButton()
	local button = FriendsMicroButton
	if not button then return end
	if C.Chat.SocialButton == false then
		button:Hide()
		return
	end
	local chatFrame = (GENERAL_CHAT_DOCK and FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK)) or ChatFrame1
	button:SetParent(chatFrame)
	button:ClearAllPoints()
	button:SetPoint("TOPLEFT", chatFrame, "TOPLEFT", 0, 2)
	button:SetFrameLevel(chatFrame:GetFrameLevel() + 5)
	button:Show()
end

if C.Chat.SocialButton ~= false then
	SkinFriendsButton()
	AttachFriendsButton()
	hooksecurefunc("FCFDock_SelectWindow", AttachFriendsButton)
else
	FriendsMicroButton:Kill()
end

local editBoxes = {}
local function PlaceEditBox(editbox)
	local chat = ChatFrame1
	editbox:ClearAllPoints()
	if C.Chat.EditBoxPosition == "below" then
		editbox:SetPoint("TOPLEFT", chat, "BOTTOMLEFT", -4, -4)
		editbox:SetPoint("TOPRIGHT", chat, "BOTTOMRIGHT", 4, -4)
	else
		editbox:SetPoint("BOTTOMLEFT", chat, "TOPLEFT", -4, 23)
		editbox:SetPoint("BOTTOMRIGHT", chat, "TOPRIGHT", 4, 23)
	end
end

local function UpdateEditBoxBorder(editbox)
	if not editbox then return end
	local backdrop = editbox.backdrop
	if not backdrop then return end

	local chatType = editbox:GetAttribute("chatType")
	if not chatType then
		backdrop:SetBackdropBorderColor(unpack(C.Media.Border_Color))
		return
	end

	if chatType == "CHANNEL" then
		local channel = editbox:GetAttribute("channelTarget")
		local info = channel and channel ~= 0 and ChatTypeInfo[chatType .. channel]
		if not info then
			local id = GetChannelName(channel)
			info = id and id ~= 0 and ChatTypeInfo[chatType .. id]
		end
		if info then
			backdrop:SetBackdropBorderColor(info.r, info.g, info.b)
		else
			backdrop:SetBackdropBorderColor(unpack(C.Media.Border_Color))
		end
	else
		local info = ChatTypeInfo[chatType]
		if info then
			backdrop:SetBackdropBorderColor(info.r, info.g, info.b)
		else
			backdrop:SetBackdropBorderColor(unpack(C.Media.Border_Color))
		end
	end
end

hooksecurefunc("ChatEdit_UpdateHeader", UpdateEditBoxBorder)

-- Set chat style
local function SetChatStyle(frame)
	local frame = frame
	local id = frame:GetID()
	local framename = frame:GetName()
	local tab = _G[framename.."Tab"]
	local editbox = _G[framename.."EditBox"]

	frame:SetFrameLevel(4)

	frame:SetClampRectInsets(0, 0, 0, 0)
	frame:SetClampedToScreen(false)
	if C.Chat.Fading == false then
		frame:SetFading(false)
	else
		frame:SetFading(true)
		frame:SetTimeVisible(C.Chat.FadeTime)
	end

	if not frame.backdrop then
		if frame.CreateBackdrop then
			frame:CreateBackdrop()
			if frame.backdrop then
				frame.backdrop:ClearAllPoints()
				frame.backdrop:SetPoint("TOPLEFT", frame, "TOPLEFT", -4, 4)
				frame.backdrop:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 4, -4)
			end
		else
			local backdrop = CreateFrame("Frame", nil, frame)
			backdrop:SetBackdrop(K.Backdrop)
			backdrop:SetBackdropColor(unpack(C.Media.Backdrop_Color))
			backdrop:SetBackdropBorderColor(unpack(C.Media.Border_Color))
			backdrop:ClearAllPoints()
			backdrop:SetPoint("TOPLEFT", frame, "TOPLEFT", -4, 4)
			backdrop:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 4, -4)
			backdrop:SetFrameLevel(frame:GetFrameLevel() > 0 and frame:GetFrameLevel() - 1 or 0)
			frame.backdrop = backdrop
		end
	end

	-- Move the chat edit box
	PlaceEditBox(editbox)
	editBoxes[#editBoxes + 1] = editbox

	-- Hide textures if enabled in config
	if C.Chat.HideTextures == true then
		for i = 1, #CHAT_FRAME_TEXTURES do
			_G[framename..CHAT_FRAME_TEXTURES[i]]:SetTexture(nil)
		end
	end

	-- Removes Default ChatFrame Tabs texture
	_G[format("ChatFrame%sTabLeft", id)]:Kill()
	_G[format("ChatFrame%sTabMiddle", id)]:Kill()
	_G[format("ChatFrame%sTabRight", id)]:Kill()

	_G[format("ChatFrame%sTabSelectedLeft", id)]:Kill()
	_G[format("ChatFrame%sTabSelectedMiddle", id)]:Kill()
	_G[format("ChatFrame%sTabSelectedRight", id)]:Kill()

	_G[format("ChatFrame%sTabHighlightLeft", id)]:Kill()
	_G[format("ChatFrame%sTabHighlightMiddle", id)]:Kill()
	_G[format("ChatFrame%sTabHighlightRight", id)]:Kill()

	_G[format("ChatFrame%sButtonFrameUpButton", id)]:Kill()
	_G[format("ChatFrame%sButtonFrameDownButton", id)]:Kill()
	_G[format("ChatFrame%sButtonFrameBottomButton", id)]:Kill()
	_G[format("ChatFrame%sButtonFrameMinimizeButton", id)]:Kill()
	_G[format("ChatFrame%sButtonFrame", id)]:Kill()

	_G[format("ChatFrame%sEditBoxFocusLeft", id)]:Kill()
	_G[format("ChatFrame%sEditBoxFocusMid", id)]:Kill()
	_G[format("ChatFrame%sEditBoxFocusRight", id)]:Kill()

	_G[format("ChatFrame%sTabGlow", id)]:Kill()

	for _, region in ipairs({editbox:GetRegions()}) do
		if region:GetObjectType() == "Texture" then
			region:Kill()
		end
	end

	if tab.conversationIcon then tab.conversationIcon:Kill() end

	editbox:SetAltArrowKeyMode(false)
	editbox:Hide()

	editbox:HookScript("OnEditFocusGained", function(self)
		self:Show()
		UpdateEditBoxBorder(self)
	end)
	editbox:HookScript("OnEditFocusLost", function(self)
		self:Hide()
		if self.backdrop then
			self.backdrop:SetBackdropBorderColor(unpack(C.Media.Border_Color))
		end
	end)

	local function OnTextChanged(self)
		local text = self:GetText()

		local MIN_REPEAT_CHARACTERS = 5
		if len(text) > MIN_REPEAT_CHARACTERS then
			local repeatChar = true
			for i = 1, MIN_REPEAT_CHARACTERS do
				if sub(text, -i, -i) ~= sub(text, -i-1, -i-1) then
					repeatChar = false
					break
				end
			end
			if repeatChar then
				self:SetText("")
				return
			end
		end

		local new, found = gsub(text, "|Kf(%S+)|k(%S+)%s(%S+)|k", "%2 %3")
		if found > 0 then
			new = new:gsub("|", "")
			self:SetText(new)
		end
	end
	editbox:HookScript("OnTextChanged", OnTextChanged)

	tab:HookScript("OnClick", function() editbox:Hide() end)

	if not editbox.backdrop then
		local backdrop = CreateFrame("Frame", nil, editbox)
		backdrop:SetBackdrop(K.Backdrop)
		backdrop:SetBackdropColor(unpack(C.Media.Backdrop_Color))
		backdrop:SetBackdropBorderColor(unpack(C.Media.Border_Color))
		backdrop:ClearAllPoints()
		backdrop:SetPoint("TOPLEFT", editbox, "TOPLEFT", 7, -3)
		backdrop:SetPoint("BOTTOMRIGHT", editbox, "BOTTOMRIGHT", -7, 2)
		backdrop:SetFrameLevel(editbox:GetFrameLevel() > 0 and editbox:GetFrameLevel() - 1 or 0)
		editbox.backdrop = backdrop
	end

	if frame ~= _G["ChatFrame2"] then
		origs[frame] = frame.AddMessage
		frame.AddMessage = AddMessage
	else
		CombatLogQuickButtonFrame_Custom:StripTextures()
		CombatLogQuickButtonFrame_Custom:CreateBackdrop()
		CombatLogQuickButtonFrame_Custom.backdrop:SetPoint("TOPLEFT", -2, -2)
		CombatLogQuickButtonFrame_Custom.backdrop:SetPoint("BOTTOMRIGHT", 2, -2)
		CombatLogQuickButtonFrame_CustomAdditionalFilterButton:SetSize(26, 28)
		CombatLogQuickButtonFrame_CustomAdditionalFilterButton:SetPoint("TOPRIGHT", CombatLogQuickButtonFrame_Custom, "TOPRIGHT", 4, -1)
		CombatLogQuickButtonFrame_CustomProgressBar:ClearAllPoints()
		CombatLogQuickButtonFrame_CustomProgressBar:SetPoint("TOPLEFT", CombatLogQuickButtonFrame_Custom.backdrop, 4, -4)
		CombatLogQuickButtonFrame_CustomProgressBar:SetPoint("BOTTOMRIGHT", CombatLogQuickButtonFrame_Custom.backdrop, -4, 4)
		CombatLogQuickButtonFrame_CustomProgressBar:SetStatusBarTexture(C.Media.Texture)
		CombatLogQuickButtonFrameButton1:SetPoint("BOTTOM", 0, 0)
	end

	frame.skinned = true
end

-- Setup chatframes 1 to 10 on login
local function SetupChat(self)
	for i = 1, NUM_CHAT_WINDOWS do
		local frame = _G[format("ChatFrame%s", i)]
		SetChatStyle(frame)
	end

	local var = C.Chat.Sticky == true and 1 or 0
	ChatTypeInfo.SAY.sticky = var
	ChatTypeInfo.PARTY.sticky = var
	ChatTypeInfo.PARTY_LEADER.sticky = var
	ChatTypeInfo.GUILD.sticky = var
	ChatTypeInfo.OFFICER.sticky = var
	ChatTypeInfo.RAID.sticky = var
	ChatTypeInfo.RAID_WARNING.sticky = var
	ChatTypeInfo.WHISPER.sticky = var
	ChatTypeInfo.BN_WHISPER.sticky = var
	ChatTypeInfo.CHANNEL.sticky = var
	ChatTypeInfo.BATTLEGROUND.sticky = var
end

local function SetupChatPosAndFont(self)
	if C.Chat.Width and C.Chat.Height then
		ChatFrame1:SetSize(C.Chat.Width, C.Chat.Height)
	end
	
	for i = 1, NUM_CHAT_WINDOWS do
		local chat = _G[format("ChatFrame%s", i)]
		local id = chat:GetID()
		local _, fontSize = FCF_GetChatWindowInfo(id)

		-- No FCF_SetChatWindowFontSize here: it is a secure chat-dock API,
		-- and calling it from addon context at login taints ChatFrame1 / the
		-- dock for the whole session (FrostAtomUI never calls it at init).
		-- The SetFont below styles the same frames via the frame API only.

		if C.Chat.Outline == true then
			chat:SetFont(C.Media.Font, fontSize, C.Media.Font_Style)
			chat:SetShadowColor(0/255, 0/255, 0/255, 0.2)
		else
			chat:SetFont(C.Media.Font, fontSize)
			chat:SetShadowColor(0/255, 0/255, 0/255, 1)
			chat:SetShadowOffset((K.Mult or 1), -(K.Mult or 1))
		end

		if i == 2 then
			if C.Chat.CombatLog ~= true then
				if chat.isDocked or chat:IsShown() then
					FCF_Close(chat)
				end
			end
		end
	end

	BNToastFrame:HookScript("OnShow", function(self)
		self:ClearAllPoints()
		self:SetPoint(unpack(C.Position.BnetPopup))
	end)
end

local UIChat = CreateFrame("Frame")
UIChat:RegisterEvent("ADDON_LOADED")
UIChat:RegisterEvent("PLAYER_ENTERING_WORLD")
UIChat:SetScript("OnEvent", function(self, event, addon)
	if event == "ADDON_LOADED" then
		if addon == "Blizzard_CombatLog" then
			self:UnregisterEvent("ADDON_LOADED")
			if InCombatLockdown() then
				-- ChatFrame styling calls secure dock/frame APIs (SetSize,
				-- FCF_SetChatWindowFontSize, FCF_DockFrame); running them during
				-- combat lockdown taints the chat dock, so every in-combat
				-- FCFDock_UpdateTabs -> ChatFrame1:Show() gets blocked.
				self.__pendingStyle = true
				self:RegisterEvent("PLAYER_REGEN_ENABLED")
			else
				SetupChat(self)
			end
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		if InCombatLockdown() then
			self.__pendingFonts = true
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
		else
			SetupChatPosAndFont(self)
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		if self.__pendingStyle then
			self.__pendingStyle = nil
			SetupChat(self)
		end
		if self.__pendingFonts then
			self.__pendingFonts = nil
			SetupChatPosAndFont(self)
		end
		if not self.__pendingStyle and not self.__pendingFonts then
			self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		end
	end
end)

local function SetupTempChat()
	local frame = FCF_GetCurrentChatFrame()
	if frame.skinned then return end
	SetChatStyle(frame)
end
hooksecurefunc("FCF_OpenTemporaryWindow", SetupTempChat)

local function RemoveRealmName(self, event, msg, author, ...)
	local realm = gsub(K.Realm, " ", "")
	if msg:find("-" .. realm) then
		return false, gsub(msg, "%-"..realm, ""), author, ...
	end
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", RemoveRealmName)

local function TypoHistory_Posthook_AddMessage(chat, text)
	if strfind(text, HELP_TEXT_SIMPLE) then
		ChatEdit_AddHistory(chat.editBox)
	end
end

for i = 1, NUM_CHAT_WINDOWS do
	if i ~= 2 then
		hooksecurefunc(_G["ChatFrame"..i], "AddMessage", TypoHistory_Posthook_AddMessage)
	end
end

local bigchat = false
SLASH_BIGCHAT1 = "/bigchat"
SlashCmdList.BIGCHAT = function(msg, editbox)
	if bigchat == false then
		ChatFrame1:SetSize(C.Chat.BigWidth, C.Chat.BigHeight)
		bigchat = true
		K.Print(L_CHAT_BIGCHAT_ON)
	else
		ChatFrame1:SetSize(C.Chat.Width, C.Chat.Height)
		bigchat = false
		K.Print(L_CHAT_BIGCHAT_OFF)
	end
end