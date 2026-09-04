local K, C, L, _ = select(2, ...):unpack()

local _G = _G
local format = format
local min, max = math.min, math.max
local match = string.match
local unpack, select = unpack, select
local print = print
local CreateFrame = CreateFrame
local IsAddOnLoaded = IsAddOnLoaded
local SetCVar = SetCVar
local ReloadUI = ReloadUI
local ChatFrame_AddMessageGroup = ChatFrame_AddMessageGroup
local ChatFrame_RemoveAllMessageGroups = ChatFrame_RemoveAllMessageGroups
local ChatFrame_AddChannel = ChatFrame_AddChannel
local ChatFrame_RemoveChannel = ChatFrame_RemoveChannel
local ChangeChatColor = ChangeChatColor
local ToggleChatColorNamesByClassGroup = ToggleChatColorNamesByClassGroup
local FCF_ResetChatWindows = FCF_ResetChatWindows
local FCF_SetLocked = FCF_SetLocked
local FCF_DockFrame, FCF_UnDockFrame = FCF_DockFrame, FCF_UnDockFrame
local FCF_OpenNewWindow = FCF_OpenNewWindow
local FCF_SavePositionAndDimensions = FCF_SavePositionAndDimensions
local FCF_GetChatWindowInfo = FCF_GetChatWindowInfo
local FCF_SetWindowName = FCF_SetWindowName
local FCF_StopDragging = FCF_StopDragging
local FCF_SetChatWindowFontSize = FCF_SetChatWindowFontSize
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS
local LOOT, GENERAL, TRADE = LOOT, GENERAL, TRADE

local Install = CreateFrame("Frame", nil, UIParent)

-- Installation step tracker
local InstallStep = 0

-- Step 1: Interface Settings
local function InstallStep1_Interface()
	K.SafeSetCVar("alwaysShowActionBars", 1)
	K.SafeSetCVar("lockActionBars", 1)
	K.SafeSetCVar("autoDismount", 1)
	K.SafeSetCVar("autoQuestProgress", 1)
	K.SafeSetCVar("autoQuestWatch", 1)
	K.SafeSetCVar("mapQuestDifficulty", 1)
	K.SafeSetCVar("lootUnderMouse", 0)
	K.SafeSetCVar("showLootSpam", 1)
	
	InterfaceOptionsControlsPanelAutoLootKeyDropDown:SetValue("SHIFT")
	InterfaceOptionsControlsPanelAutoLootKeyDropDown:RefreshValue()
	
	InterfaceOptionsCombatPanelSelfCastKeyDropDown:SetValue("ALT")
	InterfaceOptionsCombatPanelSelfCastKeyDropDown:RefreshValue()
end

-- Step 2: Graphics & Camera
local function InstallStep2_Graphics()
	K.SafeSetCVar("cameraDistanceMax", 50)
	K.SafeSetCVar("screenshotQuality", 10)
	K.SafeSetCVar("violenceLevel", 5)
	K.SafeSetCVar("useUiScale", 1)
	
	local screenHeight = K.ScreenHeight or tonumber(match(({GetScreenResolutions()})[GetCurrentResolution()] or "", "%d+x(%d+)"))
	if screenHeight and screenHeight > 0 then
		K.SafeSetCVar("uiScale", max(0.64, min(1.0, 768 / screenHeight)))
	end
end

-- Step 3: Combat & Tooltips
local function InstallStep3_Combat()
	K.SafeSetCVar("buffDurations", 1)
	K.SafeSetCVar("threatWarning", 3)
	K.SafeSetCVar("UberTooltips", 1)
	K.SafeSetCVar("ShowClassColorInNameplate", 1)
	K.SafeSetCVar("ConsolidateBuffs", 0)
end

-- Step 4: Chat Settings
local function InstallStep4_Chat()
	K.SafeSetCVar("chatMouseScroll", 1)
	K.SafeSetCVar("chatStyle", "classic", "chatStyle")
	K.SafeSetCVar("removeChatDelay", 1)
	K.SafeSetCVar("WholeChatWindowClickable", 0)
	K.SafeSetCVar("ConversationMode", "inline")
	K.SafeSetCVar("SpamFilter", 0)
end

-- Step 5: Chat Windows Setup
local function InstallStep5_ChatWindows()
	if C.Chat.Enable ~= true or (select(4, GetAddOnInfo("Prat-3.0")) or select(4, GetAddOnInfo("Chatter"))) then
		return
	end
	
	FCF_ResetChatWindows()
	FCF_SetLocked(ChatFrame1, 1)
	FCF_DockFrame(ChatFrame2)
	FCF_SetLocked(ChatFrame2, 1)
	
	FCF_OpenNewWindow(LOOT)
	FCF_DockFrame(ChatFrame3)
	FCF_SetLocked(ChatFrame3, 1)
	ChatFrame3:Show()
	
	FCF_OpenNewWindow(TRADE)
	FCF_DockFrame(ChatFrame4)
	FCF_SetLocked(ChatFrame4, 1)
	ChatFrame4:Show()
	
	FCF_OpenNewWindow("Group")
	FCF_DockFrame(ChatFrame5)
	FCF_SetLocked(ChatFrame5, 1)
	ChatFrame5:Show()
	
	for i = 1, NUM_CHAT_WINDOWS do
		local frame = _G[format("ChatFrame%s", i)]
		local chatFrameId = frame:GetID()
		
		if i == 1 then
			frame:ClearAllPoints()
			frame:SetPoint(unpack(C.Position.Chat))
		end
		
		FCF_SavePositionAndDimensions(frame)
		FCF_StopDragging(frame)
		FCF_SetChatWindowFontSize(nil, frame, 12)
		
		if i == 1 then
			FCF_SetWindowName(frame, GENERAL)
		elseif i == 2 then
			FCF_SetWindowName(frame, GUILD_EVENT_LOG)
		elseif i == 3 then
			FCF_SetWindowName(frame, LOOT)
		elseif i == 4 then
			FCF_SetWindowName(frame, TRADE)
		elseif i == 5 then
			FCF_SetWindowName(frame, "Group")
		end
	end
	
	-- Setup ChatFrame1 message groups (General chat without group content)
	ChatFrame_RemoveAllMessageGroups(ChatFrame1)
	ChatFrame_AddMessageGroup(ChatFrame1, "SAY")
	ChatFrame_AddMessageGroup(ChatFrame1, "EMOTE")
	ChatFrame_AddMessageGroup(ChatFrame1, "YELL")
	ChatFrame_AddMessageGroup(ChatFrame1, "MONSTER_SAY")
	ChatFrame_AddMessageGroup(ChatFrame1, "MONSTER_EMOTE")
	ChatFrame_AddMessageGroup(ChatFrame1, "MONSTER_YELL")
	ChatFrame_AddMessageGroup(ChatFrame1, "MONSTER_BOSS_EMOTE")
	ChatFrame_AddMessageGroup(ChatFrame1, "SYSTEM")
	ChatFrame_AddMessageGroup(ChatFrame1, "ERRORS")
	ChatFrame_AddMessageGroup(ChatFrame1, "AFK")
	ChatFrame_AddMessageGroup(ChatFrame1, "DND")
	ChatFrame_AddMessageGroup(ChatFrame1, "IGNORED")
	ChatFrame_AddMessageGroup(ChatFrame1, "ACHIEVEMENT")
	ChatFrame_AddMessageGroup(ChatFrame1, "BN_INLINE_TOAST_ALERT")
	
	-- Setup ChatFrame2 for guild
	ChatFrame_RemoveAllMessageGroups(ChatFrame2)
	ChatFrame_AddMessageGroup(ChatFrame2, "GUILD")
	ChatFrame_AddMessageGroup(ChatFrame2, "OFFICER")
	ChatFrame_AddMessageGroup(ChatFrame2, "GUILD_ACHIEVEMENT")
	
	-- Setup ChatFrame3 for loot only
	ChatFrame_RemoveAllMessageGroups(ChatFrame3)
	ChatFrame_AddMessageGroup(ChatFrame3, "COMBAT_FACTION_CHANGE")
	ChatFrame_AddMessageGroup(ChatFrame3, "SKILL")
	ChatFrame_AddMessageGroup(ChatFrame3, "LOOT")
	ChatFrame_AddMessageGroup(ChatFrame3, "MONEY")
	ChatFrame_AddMessageGroup(ChatFrame3, "COMBAT_XP_GAIN")
	ChatFrame_AddMessageGroup(ChatFrame3, "COMBAT_HONOR_GAIN")
	ChatFrame_AddMessageGroup(ChatFrame3, "COMBAT_GUILD_XP_GAIN")
	
	-- Setup ChatFrame4 for trade
	ChatFrame_RemoveAllMessageGroups(ChatFrame4)
	
	-- Setup ChatFrame5 for group communication (whisper, party, raid, bg)
	ChatFrame_RemoveAllMessageGroups(ChatFrame5)
	ChatFrame_AddMessageGroup(ChatFrame5, "WHISPER")
	ChatFrame_AddMessageGroup(ChatFrame5, "BN_WHISPER")
	ChatFrame_AddMessageGroup(ChatFrame5, "BN_CONVERSATION")
	ChatFrame_AddMessageGroup(ChatFrame5, "PARTY")
	ChatFrame_AddMessageGroup(ChatFrame5, "PARTY_LEADER")
	ChatFrame_AddMessageGroup(ChatFrame5, "RAID")
	ChatFrame_AddMessageGroup(ChatFrame5, "RAID_LEADER")
	ChatFrame_AddMessageGroup(ChatFrame5, "RAID_WARNING")
	ChatFrame_AddMessageGroup(ChatFrame5, "BATTLEGROUND")
	ChatFrame_AddMessageGroup(ChatFrame5, "BATTLEGROUND_LEADER")
	ChatFrame_AddMessageGroup(ChatFrame5, "BG_HORDE")
	ChatFrame_AddMessageGroup(ChatFrame5, "BG_ALLIANCE")
	ChatFrame_AddMessageGroup(ChatFrame5, "BG_NEUTRAL")
	
	-- Add channels to correct frames (using channel names)
	ChatFrame_AddChannel(ChatFrame1, GENERAL)
	ChatFrame_RemoveChannel(ChatFrame1, TRADE)
	ChatFrame_AddChannel(ChatFrame4, TRADE)
	
	-- Enable class colors
	local channels = {"SAY", "EMOTE", "YELL", "GUILD", "OFFICER", "GUILD_ACHIEVEMENT", "ACHIEVEMENT", 
		"WHISPER", "PARTY", "PARTY_LEADER", "RAID", "RAID_LEADER", "RAID_WARNING", 
		"BATTLEGROUND", "BATTLEGROUND_LEADER"}
	for _, channel in pairs(channels) do
		ToggleChatColorNamesByClassGroup(true, channel)
	end
	
	for i = 1, 11 do
		ToggleChatColorNamesByClassGroup(true, "CHANNEL"..i)
	end
	
	-- Adjust Chat Colors
	ChangeChatColor("CHANNEL1", 195/255, 230/255, 232/255)
	ChangeChatColor("CHANNEL2", 232/255, 158/255, 121/255)
	ChangeChatColor("CHANNEL3", 232/255, 228/255, 121/255)

	-- Force default chat position upon installation
	ChatFrame1:ClearAllPoints()
	ChatFrame1:SetSize(C.Chat.Width, C.Chat.Height)
	ChatFrame1:SetPoint(C.Position.Chat[1], C.Position.Chat[2], C.Position.Chat[3], C.Position.Chat[4], C.Position.Chat[5])
	FCF_SavePositionAndDimensions(ChatFrame1)
	ChatFrame1:SetUserPlaced(true)
end

-- Step 6: Misc Settings
local function InstallStep6_Misc()
	K.SafeSetCVar("RotateMinimap", 0)
	K.SafeSetCVar("ShowAllSpellRanks", 0)
	K.SafeSetCVar("colorblindMode", 0)
	K.SafeSetCVar("gameTip", 0)
	K.SafeSetCVar("maxfpsbk", 0)
	K.SafeSetCVar("scriptErrors", 0)
	K.SafeSetCVar("showNewbieTips", 0)
	K.SafeSetCVar("showTutorials", 0)
	K.SafeSetCVar("taintLog", 0)
	
	if C.General.DeveloperMode == true then
		K.SafeSetCVar("scriptErrors", 1)
	end
end

-- Step 7: Finalize
local function InstallStep7_Finalize()
	if not budsUIData then budsUIData = {} end
	if type(budsUIData.CharacterData) ~= "table" then budsUIData.CharacterData = {} end
	
	local realmKey = K.Realm .. "-" .. K.Name
	if type(budsUIData.CharacterData[realmKey]) ~= "table" then budsUIData.CharacterData[realmKey] = {} end
	local charSettings = budsUIData.CharacterData[realmKey]
	
	charSettings.Install = true
	charSettings.AutoInvite = false
	charSettings.BarsLocked = false
	charSettings.SplitBars = true
	charSettings.RightBars = C.ActionBar.RightBars
	charSettings.BottomBars = C.ActionBar.BottomBars
	
	local activeProfile = K.GetActiveProfile()
	if activeProfile and budsUIData.Profiles[activeProfile] then
		budsUIData.Profiles[activeProfile] = {}
	end
end



local function DisableUI()
	DisableAddOn("budsUI")
	ReloadUI()
end

-- Multi-Step Install Wizard
local InstallFrame = nil

local function CreateInstallWizard()
	if InstallFrame then return end
	
	InstallFrame = CreateFrame("Frame", "budsUI_InstallWizard", UIParent)
	InstallFrame:SetSize(600, 500)
	InstallFrame:SetPoint("CENTER")
	InstallFrame:SetFrameStrata("DIALOG")
	InstallFrame:SetTemplate("Transparent")
	InstallFrame:CreateBorder()
	InstallFrame:EnableMouse(true)
	InstallFrame:SetMovable(true)
	InstallFrame:RegisterForDrag("LeftButton")
	InstallFrame:SetScript("OnDragStart", InstallFrame.StartMoving)
	InstallFrame:SetScript("OnDragStop", InstallFrame.StopMovingOrSizing)
	
	-- Logo
	local logo = InstallFrame:CreateTexture(nil, "ARTWORK")
	logo:SetSize(400, 100)
	logo:SetPoint("TOP", InstallFrame, "TOP", 0, -15)
	logo:SetTexture([[Interface\AddOns\]] .. K.Directory .. [[\Media\assets\budsui_logo.tga]])
	
	-- Title
	local title = InstallFrame:FontString(nil, C.Media.Font, 18)
	title:SetPoint("TOP", logo, "BOTTOM", 0, -10)
	title:SetText(L_INSTALL_TITLE)
	
	-- Step indicator
	local stepText = InstallFrame:FontString(nil, C.Media.Font, 16)
	stepText:SetPoint("TOP", title, "BOTTOM", 0, -10)
	InstallFrame.stepText = stepText
	
	-- Description text
	local desc = InstallFrame:FontString(nil, C.Media.Font, 14)
	desc:SetPoint("TOP", stepText, "BOTTOM", 0, -20)
	desc:SetWidth(500)
	desc:SetJustifyH("LEFT")
	InstallFrame.desc = desc
	
	-- Progress bar
	local progressBar = CreateFrame("StatusBar", nil, InstallFrame)
	progressBar:SetSize(500, 20)
	progressBar:SetPoint("BOTTOM", InstallFrame, "BOTTOM", 0, 60)
	progressBar:SetStatusBarTexture(C.Media.Texture)
	progressBar:SetStatusBarColor(0.22, 0.55, 0.86)
	progressBar:SetMinMaxValues(0, 7)
	progressBar:SetValue(0)
	progressBar:CreateBorder()
	InstallFrame.progressBar = progressBar
	
	-- Previous button
	local prevBtn = CreateFrame("Button", nil, InstallFrame, "UIPanelButtonTemplate")
	prevBtn:SetSize(120, 30)
	prevBtn:SetPoint("BOTTOMLEFT", InstallFrame, "BOTTOMLEFT", 20, 15)
	prevBtn:SetText(L_INSTALL_BTN_PREV)
	prevBtn:StyleButton()
	InstallFrame.prevBtn = prevBtn
	
	-- Next button
	local nextBtn = CreateFrame("Button", nil, InstallFrame, "UIPanelButtonTemplate")
	nextBtn:SetSize(120, 30)
	nextBtn:SetPoint("BOTTOMRIGHT", InstallFrame, "BOTTOMRIGHT", -20, 15)
	nextBtn:SetText(L_INSTALL_BTN_NEXT)
	nextBtn:StyleButton()
	InstallFrame.nextBtn = nextBtn
	
	-- Skip button
	local skipBtn = CreateFrame("Button", nil, InstallFrame, "UIPanelButtonTemplate")
	skipBtn:SetSize(120, 30)
	skipBtn:SetPoint("BOTTOM", InstallFrame, "BOTTOM", 0, 15)
	skipBtn:SetText(L_INSTALL_BTN_SKIP)
	skipBtn:StyleButton()
	skipBtn:SetScript("OnClick", function()
		if not budsUIData then budsUIData = {} end
		if not budsUIData.CharacterData then budsUIData.CharacterData = {} end
		if not budsUIData.CharacterData[K.Realm.."-"..K.Name] then budsUIData.CharacterData[K.Realm.."-"..K.Name] = {} end
		budsUIData.CharacterData[K.Realm.."-"..K.Name].Install = false
		InstallFrame:Hide()
	end)
	InstallFrame.skipBtn = skipBtn
end

local installSteps = {
	{
		title = L_INSTALL_STEP1_TITLE,
		desc = L_INSTALL_STEP1_DESC,
		func = nil
	},
	{
		title = L_INSTALL_STEP2_TITLE,
		desc = L_INSTALL_STEP2_DESC,
		func = InstallStep1_Interface
	},
	{
		title = L_INSTALL_STEP3_TITLE,
		desc = L_INSTALL_STEP3_DESC,
		func = InstallStep2_Graphics
	},
	{
		title = L_INSTALL_STEP4_TITLE,
		desc = L_INSTALL_STEP4_DESC,
		func = InstallStep3_Combat
	},
	{
		title = L_INSTALL_STEP5_TITLE,
		desc = L_INSTALL_STEP5_DESC,
		func = InstallStep4_Chat
	},
	{
		title = L_INSTALL_STEP6_TITLE,
		desc = L_INSTALL_STEP6_DESC,
		func = InstallStep5_ChatWindows
	},
	{
		title = L_INSTALL_STEP7_TITLE,
		desc = L_INSTALL_STEP7_DESC,
		func = InstallStep6_Misc
	},
	{
		title = L_INSTALL_STEP8_TITLE,
		desc = L_INSTALL_STEP8_DESC,
		func = InstallStep7_Finalize
	}
}

local function UpdateInstallWizard(step)
	if not InstallFrame then return end
	
	local stepData = installSteps[step]
	if not stepData then return end
	
	InstallFrame.stepText:SetText(string.format(L_INSTALL_STEP_TXT, step, #installSteps))
	InstallFrame.desc:SetText(stepData.desc)
	InstallFrame.progressBar:SetValue(step)
	
	-- Update buttons
	if step == 1 then
		InstallFrame.prevBtn:Disable()
		InstallFrame.nextBtn:SetText(L_INSTALL_BTN_NEXT)
		InstallFrame.skipBtn:Show()
	elseif step == #installSteps then
		InstallFrame.prevBtn:Enable()
		InstallFrame.nextBtn:SetText(L_INSTALL_BTN_DONE)
		InstallFrame.skipBtn:Hide()
	else
		InstallFrame.prevBtn:Enable()
		InstallFrame.nextBtn:SetText(L_INSTALL_BTN_NEXT)
		InstallFrame.skipBtn:Show()
	end
end

local function ShowInstallWizard()
	CreateInstallWizard()
	InstallStep = 1
	UpdateInstallWizard(InstallStep)
	InstallFrame:Show()
	
	InstallFrame.prevBtn:SetScript("OnClick", function()
		if InstallStep > 1 then
			InstallStep = InstallStep - 1
			UpdateInstallWizard(InstallStep)
		end
	end)
	
	InstallFrame.nextBtn:SetScript("OnClick", function()
		local stepData = installSteps[InstallStep]
		if stepData.func then
			local ok, err = pcall(stepData.func)
			if not ok then
				print(L_INSTALL_ERROR .. tostring(err))
			end
		end
		
		if InstallStep < #installSteps then
			InstallStep = InstallStep + 1
			UpdateInstallWizard(InstallStep)
		else
			-- Final step - reload UI
			InstallFrame:Hide()
			StaticPopup_Show("RELOAD_UI")
		end
	end)
end

-- Install Popups
StaticPopupDialogs["INSTALL_UI"] = {
	text = L_POPUP_INSTALLUI,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		ShowInstallWizard()
	end,
	OnCancel = function() 
		if not budsUIData.CharacterData[K.Realm.."-"..K.Name] then budsUIData.CharacterData[K.Realm.."-"..K.Name] = {} end
		budsUIData.CharacterData[K.Realm.."-"..K.Name].Install = false 
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = false,
	preferredIndex = 3
}

StaticPopupDialogs["RELOAD_UI"] = {
	text = L_POPUP_RELOADUI,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function() ReloadUI() end,
	OnCancel = function() end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = false,
	preferredIndex = 3
}

StaticPopupDialogs["DISABLE_UI"] = {
	text = L_POPUP_DISABLEUI,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = DisableUI,
	showAlert = true,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = true,
	preferredIndex = 3
}

StaticPopupDialogs["RESET_UI"] = {
	text = L_POPUP_RESETUI,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		ShowInstallWizard()
	end,
	OnCancel = function() 
		if not budsUIData.CharacterData[K.Realm.."-"..K.Name] then budsUIData.CharacterData[K.Realm.."-"..K.Name] = {} end
		budsUIData.CharacterData[K.Realm.."-"..K.Name].Install = true 
	end,
	showAlert = true,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = true,
	preferredIndex = 3
}

StaticPopupDialogs["RESTART_GFX"] = {
	text = L_POPUP_RESTART_GFX,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function() RestartGx() end,
	showAlert = true,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = false,
	preferredIndex = 3
}

SLASH_INSTALLUI1 = "/installui"
SlashCmdList.INSTALLUI = function() StaticPopup_Show("INSTALL_UI") end

SLASH_CONFIGURE1 = "/resetui"
SlashCmdList.CONFIGURE = function() StaticPopup_Show("RESET_UI") end

-- On login function
Install:RegisterEvent("ADDON_LOADED")
Install:SetScript("OnEvent", function(self, event, addon)
	if (addon ~= "budsUI") then
		return
	end

	-- Initialize budsUIData structure if missed
	if type(budsUIData) ~= "table" then budsUIData = {} end
	if type(budsUIData.CharacterData) ~= "table" then budsUIData.CharacterData = {} end
	
	local realmKey = K.Realm .. "-" .. K.Name
	if type(budsUIData.CharacterData[realmKey]) ~= "table" then budsUIData.CharacterData[realmKey] = {} end
	local charSettings = budsUIData.CharacterData[realmKey]
	
	if charSettings.AutoInvite == nil then charSettings.AutoInvite = false end
	if charSettings.BarsLocked == nil then charSettings.BarsLocked = false end
	if charSettings.SplitBars == nil then charSettings.SplitBars = true end
	if charSettings.RightBars == nil then charSettings.RightBars = C.ActionBar.RightBars end
	if charSettings.BottomBars == nil then charSettings.BottomBars = C.ActionBar.BottomBars end

	if K.ScreenWidth < 1200 then
		K.SafeSetCVar("useUiScale", 0)
		StaticPopup_Show("DISABLE_UI")
	else
		-- Is this causing crashes?
		if C.General.MultisampleCheck == true then
			local Multisample = GetCVar("gxMultisample")
			if Multisample ~= "1" then
				K.SafeSetCVar("gxMultisample", 1)
				StaticPopup_Show("RESTART_GFX")
			end
		end

		-- Install default if we never ran budsUI on this character
		if not charSettings.Install then
			StaticPopup_Show("INSTALL_UI")
		end
	end

	-- Welcome message
	if C.General.WelcomeMessage == true then
		print("|cffffe02e"..L_WELCOME_LINE_1..K.Version.." "..K.Client..", "..format("|cff%02x%02x%02x%s|r", K.Color.r * 255, K.Color.g * 255, K.Color.b * 255, K.Name)..".|r")
		print("|cffffe02e"..L_WELCOME_LINE_2_1.."|cffffe02e"..L_WELCOME_LINE_2_2.."|r")
	end

	self:UnregisterEvent("ADDON_LOADED")
end)