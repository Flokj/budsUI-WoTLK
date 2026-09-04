local K, C, L, _ = select(2, ...):unpack()
if C.Chat.Enable ~= true then return end

local function CreateChatbar()

	local chatFrame = SELECTED_DOCK_FRAME or DEFAULT_CHAT_FRAME
	local width, height, padding, buttonList = 15, 15, 8, {}

	local Chatbar = CreateFrame("Frame", "KkthnxUI_ChatBar", UIParent)
	Chatbar:SetPoint("TOPLEFT", ChatFrame1, "TOPRIGHT", 10, -2)

	local function IsGuildOfficer()
		return CanEditOfficerNote() or CanViewOfficerNote() or IsGuildLeader()
	end

	local function AddButton(r, g, b, text, func)
		local bu = CreateFrame("Button", nil, Chatbar, "SecureActionButtonTemplate")
		bu:SetWidth(width)
		bu:SetHeight(height)

		local texture = (C and C.Media and C.Media.Blank) or "Interface\\Buttons\\WHITE8x8"
		bu:SetBackdrop({
			bgFile = texture,
			edgeFile = texture,
			edgeSize = 1,
		})
		bu:SetBackdropColor(r, g, b, 0.9)
		bu:SetBackdropBorderColor(0, 0, 0, 1)

		if bu.CreateBorder then bu:CreateBorder() end
		if bu.StyleButton then bu:StyleButton() end

		bu:SetHitRectInsets(0, 0, -8, -8)
		bu:RegisterForClicks("AnyUp")

		if text then
			bu:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_TOP")
				GameTooltip:SetText(text)
				GameTooltip:Show()
			end)
			bu:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
		end
		if func then bu:SetScript("OnClick", func) end

		tinsert(buttonList, bu)
		return bu
	end

	local buttonInfo = {
		{1, 1, 1, SAY.."/"..YELL, function(_, btn)
			if btn == "RightButton" then
				ChatFrame_OpenChat("/y ", chatFrame)
			else
				ChatFrame_OpenChat("/s ", chatFrame)
			end
		end},
		{1, .5, 1, WHISPER, function(_, btn)
			if btn == "RightButton" then
				ChatFrame_ReplyTell(chatFrame)
				local editBox = chatFrame.editBox or _G[chatFrame:GetName().."EditBox"]
				if editBox and (not editBox:IsVisible() or editBox:GetAttribute("chatType") ~= "WHISPER") then
					ChatFrame_OpenChat("/w ", chatFrame)
				end
			else
				if UnitExists("target") and UnitName("target") and UnitIsPlayer("target") and GetDefaultLanguage("player") == GetGetDefaultLanguage("target") then
					local name = UnitName("target")
					ChatFrame_OpenChat("/w "..name.." ", chatFrame)
				else
					ChatFrame_OpenChat("/w ", chatFrame)
				end
			end
		end},
		{.65, .65, 1, PARTY, function() ChatFrame_OpenChat("/p ", chatFrame) end},
		{1, .5, 0, (BATTLEGROUND or "BG").."/"..RAID, function()
			if UnitInBattleground("player") then
				ChatFrame_OpenChat("/bg ", chatFrame)
			else
				ChatFrame_OpenChat("/raid ", chatFrame)
			end
		end},
		{.25, 1, .25, GUILD.."/"..OFFICER, function(_, btn)
			if btn == "RightButton" and IsGuildOfficer() then
				ChatFrame_OpenChat("/o ", chatFrame)
			else
				ChatFrame_OpenChat("/g ", chatFrame)
			end
		end},
	}

	for _, info in pairs(buttonInfo) do AddButton(unpack(info)) end

	-- ROLL
	local roll = AddButton(.8, 1, .6, LOOT_ROLL or "Roll")
	roll:SetAttribute("type", "macro")
	roll:SetAttribute("macrotext", "/roll")
	roll:RegisterForClicks("AnyUp")

	-- COMBATLOG
	local combat = AddButton(1, 1, 0, BINDING_NAME_TOGGLECOMBATLOG or "Combat Log")
	combat:SetAttribute("type", "macro")
	combat:SetAttribute("macrotext", "/combatlog")
	combat:RegisterForClicks("AnyUp")

	-- RELOAD
	-- local reload = AddButton(1, .3, .1, "RELOAD")
	-- reload:SetAttribute("type", "macro")
	-- reload:SetAttribute("macrotext", "/reload")

	for i = 1, #buttonList do
		if i == 1 then
			buttonList[i]:SetPoint("TOP")
		else
			buttonList[i]:SetPoint("TOP", buttonList[i-1], "BOTTOM", 0, -padding)
		end
	end

	local totalHeight = (#buttonList * height) + ((#buttonList - 1) * padding)
	Chatbar:SetWidth(width)
	Chatbar:SetHeight(totalHeight)

	if K.MoverFrames then
		tinsert(K.MoverFrames, Chatbar)
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	CreateChatbar()
end)