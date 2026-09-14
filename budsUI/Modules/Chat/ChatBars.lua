local K, C, L, _ = select(2, ...):unpack()
if C.Chat.Enable ~= true then return end

local _G = _G
local CreateFrame = CreateFrame
local tinsert = tinsert

-- Vertical channel bar to the right of the chat: a column of small
-- colored squares (KkthnxUI style), one per channel, tooltip on hover.

local BUTTON_SIZE = 16
local GAP = 8

local function GetChatFrame()
	return SELECTED_DOCK_FRAME or DEFAULT_CHAT_FRAME or _G.ChatFrame1
end

local function IsGuildOfficer()
	return CanEditOfficerNote() or CanViewOfficerNote() or IsGuildLeader()
end

local function WhisperTargetOrOpen(chatFrame)
	if UnitExists("target") and UnitName("target") and UnitIsPlayer("target") then
		local name = UnitName("target")
		if name then
			ChatFrame_OpenChat("/w " .. name .. " ", chatFrame)
			return
		end
	end
	ChatFrame_OpenChat("/w ", chatFrame)
end

local function BuildButtons()
	local chatFrame = GetChatFrame()
	return {
		-- {r, g, b, tooltip title, tooltip hint, onClick}
		{1, 1, 1, SAY .. "/" .. YELL, "Left: Say | Right: Yell", function(_, btn)
			if btn == "RightButton" then
				ChatFrame_OpenChat("/y ", chatFrame)
			else
				ChatFrame_OpenChat("/s ", chatFrame)
			end
		end},
		{1, 0.5, 1, WHISPER, "Left: Whisper target | Right: Reply", function(_, btn)
			if btn == "RightButton" then
				ChatFrame_ReplyTell(chatFrame)
				local editBox = chatFrame.editBox or _G[chatFrame:GetName() .. "EditBox"]
				if editBox and (not editBox:IsVisible() or editBox:GetAttribute("chatType") ~= "WHISPER") then
					ChatFrame_OpenChat("/w ", chatFrame)
				end
			else
				WhisperTargetOrOpen(chatFrame)
			end
		end},
		{0.65, 0.65, 1, PARTY, "Open Party chat", function()
			ChatFrame_OpenChat("/p ", chatFrame)
		end},
		{1, 0.5, 0, (BATTLEGROUND or "BG") .. "/" .. RAID, "In BG: BG chat | Else: Raid chat", function()
			if UnitInBattleground("player") then
				ChatFrame_OpenChat("/bg ", chatFrame)
			else
				ChatFrame_OpenChat("/raid ", chatFrame)
			end
		end},
		{0.25, 1, 0.25, GUILD .. "/" .. OFFICER, "Left: Guild | Right: Officer", function(_, btn)
			if btn == "RightButton" and IsGuildOfficer() then
				ChatFrame_OpenChat("/o ", chatFrame)
			else
				ChatFrame_OpenChat("/g ", chatFrame)
			end
		end},
		{1, 0.75, 0.75, EMOTE or "Emote", "Open Emote chat", function()
			ChatFrame_OpenChat("/e ", chatFrame)
		end},
		{0.8, 1, 0.6, LOOT_ROLL or "Roll", "Click: /roll 1-100", nil, "/roll"},
		{1, 1, 0, BINDING_NAME_TOGGLECOMBATLOG or "Combat Log", "Click: toggle /combatlog", nil, "/combatlog"},
	}
end

local function CreateChatbar()
	local anchor = _G.ChatFrame1
	if not anchor then return end

	local bar = CreateFrame("Frame", "KkthnxUI_ChatBar", UIParent)
	-- Same position as before: vertical column to the right of the chat.
	bar:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 10, -2)

	local prev
	local buttonInfo = BuildButtons()
	for _, data in ipairs(buttonInfo) do
		local r, g, b, title, hint, onClick, macro = data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8]

		local bu = CreateFrame("Button", nil, bar, "SecureActionButtonTemplate")
		bu:SetWidth(BUTTON_SIZE)
		bu:SetHeight(BUTTON_SIZE)
		bu:RegisterForClicks("AnyUp")
		bu:SetHitRectInsets(0, 0, -GAP, -GAP)

		bu:SetBackdrop({
			bgFile = C.Media.Blank,
			edgeFile = C.Media.Blank,
			edgeSize = 1,
		})
		bu:SetBackdropColor(r, g, b, 0.9)
		bu:SetBackdropBorderColor(0, 0, 0, 1)

		if bu.CreateBorder then bu:CreateBorder() end
		if bu.StyleButton then bu:StyleButton() end

		if prev then
			bu:SetPoint("TOP", prev, "BOTTOM", 0, -GAP)
		else
			bu:SetPoint("TOP", bar, "TOP", 0, 0)
		end
		prev = bu

		-- NOTE: never touch OnClick on macro buttons -- SetScript would replace
		-- the SecureActionButtonTemplate's own click handler and the macro
		-- would stop firing.
		if macro then
			-- Macro buttons (Roll, CombatLog): executed by the secure template,
			-- works in combat, exactly like the old implementation.
			bu:SetAttribute("type", "macro")
			bu:SetAttribute("macrotext", macro)
		elseif onClick then
			bu:SetScript("OnClick", onClick)
		end
		bu:SetScript("OnEnter", function(self)
			self:SetBackdropColor(r, g, b, 1)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText(title)
			if hint then GameTooltip:AddLine(hint, 1, 1, 1) end
			GameTooltip:Show()
		end)
		bu:SetScript("OnLeave", function(self)
			self:SetBackdropColor(r, g, b, 0.9)
			GameTooltip:Hide()
		end)
	end

	local count = #buttonInfo
	bar:SetWidth(BUTTON_SIZE)
	bar:SetHeight(count * BUTTON_SIZE + (count - 1) * GAP)

	if K.MoverFrames then
		tinsert(K.MoverFrames, bar)
	end
	if K.RegisterMoverFrame then
		pcall(K.RegisterMoverFrame, bar)
	end

	return bar
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	CreateChatbar()
end)
