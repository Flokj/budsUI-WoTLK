-- GUI for budsUI (by Fernir, Tukz and Tohveli, Shestak)
local _G = _G
local unpack = unpack
local sub = string.sub
local max = math.max
local print = print
local format = string.format
local pairs, type = pairs, type

local CreateFrame = CreateFrame
local Locale = GetLocale()
local name = UnitName("player")
local realm = GetRealmName()

if (Locale == "enGB") then
	Locale = "enUS"
end

local function Print(...)
	-- Robust logging: Check if budsUI global exists before indexing
	if _G["budsUI"] and _G["budsUI"].unpack then
		local K, _, _, _ = _G["budsUI"]:unpack()
		if K and K.Print then
			K.Print(...)
			return
		end
	end
	-- Fallback to standard print if core is not ready
	print("|cff388bdbbudsUI_Config|r:", ...)
end

-- Removed legacy InitSavedVariables

local ALLOWED_GROUPS = {
	["General"] = 1,
	["Profiles"] = 2,
	["ActionBar"] = 3,
	["Announcements"] = 4,
	["Automation"] = 5,
	["Bag"] = 6,
	["Blizzard"] = 7,
	["Aura"] = 8,
	["Chat"] = 9,
	["Cooldown"] = 10,
	["Error"] = 11,
	["Filger"] = 12,
	["Loot"] = 13,
	["Minimap"] = 14,
	["Misc"] = 15,
	["Nameplate"] = 16,
	["PowerBar"] = 17,
	["PulseCD"] = 18,
	["Skins"] = 19,
	["Tooltip"] = 20,
	["Unitframe"] = 21,
}

local function Local(o)
	local K, L, _ = budsUI:unpack()
	-- Actionbar Settings
	if o == "UIConfigActionBar" then o = ACTIONBAR_LABEL end
	if o == "UIConfigActionBarBottomBars" then o = L_GUI_ACTIONBAR_BOTTOMBARS end
	if o == "UIConfigActionBarButtonSize" then o = L_GUI_ACTIONBAR_BUTTON_SIZE end
	if o == "UIConfigActionBarButtonSpace" then o = L_GUI_ACTIONBAR_BUTTON_SPACE end
	if o == "UIConfigActionBarEnable" then o = L_GUI_ACTIONBAR_ENABLE end
	if o == "UIConfigActionBarEquipBorder" then o = L_GUI_ACTIONBAR_EQUIP_BORDER end
	if o == "UIConfigActionBarHotkey" then o = L_GUI_ACTIONBAR_HOTKEY end
	if o == "UIConfigActionBarMacro" then o = L_GUI_ACTIONBAR_MACRO end
	if o == "UIConfigActionBarOutOfMana" then o = L_GUI_ACTIONBAR_OUT_OF_MANA end
	if o == "UIConfigActionBarOutOfRange" then o = L_GUI_ACTIONBAR_OUT_OF_RANGE end
	if o == "UIConfigActionBarPetBarHide" then o = L_GUI_ACTIONBAR_PETBAR_HIDE end
	if o == "UIConfigActionBarPetBarHorizontal" then o = L_GUI_ACTIONBAR_PETBAR_HORIZONTAL end
	if o == "UIConfigActionBarRightBars" then o = L_GUI_ACTIONBAR_RIGHTBARS end
	if o == "UIConfigActionBarSelfcast" then o = L_GUI_ACTIONBAR_SELFCAST end
	if o == "UIConfigActionBarShowGrid" then o = L_GUI_ACTIONBAR_GRID end
	if o == "UIConfigActionBarSplitBars" then o = L_GUI_ACTIONBAR_SPLIT_BARS end
	if o == "UIConfigActionBarStanceBarHide" then o = L_GUI_ACTIONBAR_STANCEBAR_HIDE end
	if o == "UIConfigActionBarStanceBarHorizontal" then o = L_GUI_ACTIONBAR_STANCEBAR_HORIZONTAL end
	if o == "UIConfigActionBarToggleMode" then o = L_GUI_ACTIONBAR_TOGGLE_MODE end
	-- Announcement Settings
	if o == "UIConfigAnnouncements" then o = L_GUI_ANNOUNCEMENTS end
	if o == "UIConfigAnnouncementsBad_Gear" then o = L_GUI_ANNOUNCEMENTS_BAD_GEAR end
	if o == "UIConfigAnnouncementsFeasts" then o = L_GUI_ANNOUNCEMENTS_FEASTS end
	if o == "UIConfigAnnouncementsInterrupt" then o = L_GUI_ANNOUNCEMENTS_INTERRUPT end
	if o == "UIConfigAnnouncementsPortals" then o = L_GUI_ANNOUNCEMENTS_PORTALS end
	if o == "UIConfigAnnouncementsPullCountdown" then o = L_GUI_ANNOUNCEMENTS_PULL_COUNTDOWN end
	if o == "UIConfigAnnouncementsSaySapped" then o = L_GUI_ANNOUNCEMENTS_SAY_SAPPED end
	if o == "UIConfigAnnouncementsSpells" then o = L_GUI_ANNOUNCEMENTS_SPELLS end
	if o == "UIConfigAnnouncementsSpellsFromAll" then o = L_GUI_ANNOUNCEMENTS_SPELLS_FROM_ALL end
	if o == "UIConfigAnnouncementsToys" then o = L_GUI_ANNOUNCEMENTS_TOY_TRAIN end
	-- Automation Settings
	if o == "UIConfigAutomation" then o = L_GUI_AUTOMATION end
	if o == "UIConfigAutomationAutoCollapse" then o = L_GUI_AUTOMATION_AUTOCOLLAPSE end
	if o == "UIConfigAutomationAutoInvite" then o = L_GUI_AUTOMATION_ACCEPTINVITE end
	if o == "UIConfigAutomationDeclineDuel" then o = L_GUI_AUTOMATION_DECLINEDUEL end
	if o == "UIConfigAutomationLoggingCombat" then o = L_GUI_AUTOMATION_LOGGING_COMBAT end
	if o == "UIConfigAutomationResurrection" then o = L_GUI_AUTOMATION_RESURRECTION end
	if o == "UIConfigAutomationScreenShot" then o = L_GUI_AUTOMATION_SCREENSHOT end
	if o == "UIConfigAutomationSellGreyRepair" then o = L_GUI_AUTOMATION_SELLGREY_N_REPAIR end
	if o == "UIConfigAutomationTabBinder" then o = L_GUI_AUTOMATION_TAB_BINDER end
	-- Bag Settings
	if o == "UIConfigBag" then o = L_GUI_BAGS end
	if o == "UIConfigBagHideSoulBag" then o = L_GUI_BAGS_HIDE_SOULBAG end
	if o == "UIConfigBagBagColumns" then o = L_GUI_BAGS_BAG end
	if o == "UIConfigBagBankColumns" then o = L_GUI_BAGS_BANK end
	if o == "UIConfigBagButtonSize" then o = L_GUI_BAGS_BUTTON_SIZE end
	if o == "UIConfigBagButtonSpace" then o = L_GUI_BAGS_BUTTON_SPACE end
	if o == "UIConfigBagEnable" then o = L_GUI_BAGS_ENABLE end
	-- Blizzard Settings
	if o == "UIConfigBlizzard" then o = L_GUI_BLIZZARD end
	if o == "UIConfigBlizzardCapturebar" then o = L_GUI_BLIZZARD_CAPTUREBAR end
	if o == "UIConfigBlizzardClassColor" then o = L_GUI_BLIZZARD_CLASS_COLOR end
	if o == "UIConfigBlizzardDarkTextures" then o = L_GUI_BLIZZARD_DARK_TEXTURES end
	if o == "UIConfigBlizzardDarkTexturesColor" then o = L_GUI_BLIZZARD_DARK_TEXTURES_COLOR end
	if o == "UIConfigBlizzardDurability" then o = L_GUI_BLIZZARD_DURABILITY end
	if o == "UIConfigBlizzardMoveAchievements" then o = L_GUI_BLIZZARD_ACHIEVEMENTS end
	if o == "UIConfigBlizzardReputations" then o = L_GUI_BLIZZARD_REPUTATIONS end
	-- Auras Settings
	if o == "UIConfigAura" then o = L_GUI_AURA end
	if o == "UIConfigAuraCastBy" then o = L_GUI_AURA_CAST_BY end
	if o == "UIConfigAuraClassColorBorder" then o = L_GUI_AURA_CLASSCOLOR_BORDER end
	if o == "UIConfigAuraEnable" then o = L_GUI_AURA_ENABLE end
	if o == "UIConfigAuraBuffSize" then o = L_GUI_AURA_PLAYER_BUFF_SIZE end
	-- Chat Settings
	if o == "UIConfigChat" then o = CHAT end
	if o == "UIConfigChatCombatLog" then o = L_GUI_CHAT_CL_TAB end
	if o == "UIConfigChatDamageMeterSpam" then o = L_GUI_CHAT_DAMAGE_METER_SPAM end
	if o == "UIConfigChatEnable" then o = L_GUI_CHAT_ENABLE end
	if o == "UIConfigChatFading" then o = L_GUI_CHAT_FADING end
	if o == "UIConfigChatFilter" then o = L_GUI_CHAT_SPAM end
	if o == "UIConfigChatHeight" then o = L_GUI_CHAT_HEIGHT end
	if o == "UIConfigChatFadeTime" then o = L_GUI_CHAT_FADE_TIME end
	if o == "UIConfigChatOutline" then o = L_GUI_CHAT_OUTLINE end
	if o == "UIConfigChatSpam" then o = L_GUI_CHAT_GOLD end
	if o == "UIConfigChatSticky" then o = L_GUI_CHAT_STICKY end
	if o == "UIConfigChatTabsMouseover" then o = L_GUI_CHAT_TABS_MOUSEOVER end
	if o == "UIConfigChatTabsOutline" then o = L_GUI_CHAT_TABS_OUTLINE end
	if o == "UIConfigChatWhispSound" then o = L_GUI_CHAT_WHISP end
	if o == "UIConfigChatWidth" then o = L_GUI_CHAT_WIDTH end
	if o == "UIConfigChatHideTextures" then o = L_GUI_CHAT_HIDE_TEXTURES end
	-- Cooldown Settings
	if o == "UIConfigCooldown" then o = L_GUI_COOLDOWN end
	if o == "UIConfigCooldownEnable" then o = L_GUI_COOLDOWN_ENABLE end
	if o == "UIConfigCooldownFontSize" then o = L_GUI_COOLDOWN_FONT_SIZE end
	if o == "UIConfigCooldownThreshold" then o = L_GUI_COOLDOWN_THRESHOLD end
	-- Error Settings
	if o == "UIConfigError" then o = L_GUI_ERROR end
	if o == "UIConfigErrorBlack" then o = L_GUI_ERROR_BLACK end
	if o == "UIConfigErrorWhite" then o = L_GUI_ERROR_WHITE end
	if o == "UIConfigErrorCombat" then o = L_GUI_ERROR_HIDE_COMBAT end
	-- Filger
	if o == "UIConfigFilger" then o = L_GUI_FILGER end
	if o == "UIConfigFilgerBuffsSize" then o = L_GUI_FILGER_BUFFS_SIZE end
	if o == "UIConfigFilgerCooldownSize" then o = L_GUI_FILGER_COOLDOWN_SIZE end
	if o == "UIConfigFilgerEnable" then o = L_GUI_FILGER_ENABLE end
	if o == "UIConfigFilgerMaxTestIcon" then o = L_GUI_FILGER_MAX_TEST_ICON end
	if o == "UIConfigFilgerPvPSize" then o = L_GUI_FILGER_PVP_SIZE end
	if o == "UIConfigFilgerShowTooltip" then o = L_GUI_FILGER_SHOW_TOOLTIP end
	if o == "UIConfigFilgerTestMode" then o = L_GUI_FILGER_TEST_MODE end
	-- General Settings
	if o == "UIConfigGeneral" then o = GENERAL_LABEL end
	if o == "UIConfigGeneralAutoScale" then o = L_GUI_GENERAL_AUTOSCALE end
	if o == "UIConfigGeneralMultisampleCheck" then o = L_GUI_GENERAL_MULTISAMPLE_CHECK end
	if o == "UIConfigGeneralReplaceBlizzardFonts" then o = L_GUI_GENERAL_REPLACE_BLIZZARD_FONTS end
	if o == "UIConfigGeneralUIScale" then o = L_GUI_GENERAL_UISCALE end
	if o == "UIConfigGeneralBubbleFontSize" then o = L_GUI_GENERAL_CHATBUBBLE_FONTSIZE end
	if o == "UIConfigGeneralBubbleBackdrop" then o = L_GUI_GENERAL_CHATBUBBLE_NOBACKDROP end
	if o == "UIConfigGeneralDeveloperMode" then o = L_GUI_GENERAL_DEVELOPER_MODE end
	if o == "UIConfigGeneralWelcomeMessage" then o = L_GUI_GENERAL_WELCOME_MESSAGE end
	-- Loot Settings
	if o == "UIConfigLoot" then o = LOOT end
	if o == "UIConfigLootConfirmDisenchant" then o = L_GUI_LOOT_AUTODE end
	if o == "UIConfigLootAutoGreed" then o = L_GUI_LOOT_AUTOGREED end
	if o == "UIConfigLootLootFilter" then o = L_GUI_LOOT_BETTER_LOOTFILTER end
	if o == "UIConfigLootIconSize" then o = L_GUI_LOOT_ICON_SIZE end
	if o == "UIConfigLootEnable" then o = L_GUI_LOOT_ENABLE end
	if o == "UIConfigLootGroupLoot" then o = L_GUI_LOOT_ROLL_ENABLE end
	if o == "UIConfigLootWidth" then o = L_GUI_LOOT_WIDTH end
	-- Minimap Settings
	if o == "UIConfigMinimap" then o = L_GUI_MINIMAP end
	if o == "UIConfigMinimapCollectButtons" then o = L_GUI_MINIMAP_COLLECTBUTTONS end
	if o == "UIConfigMinimapEnable" then o = L_GUI_MINIMAP_ENABLEMINIMAP end
	if o == "UIConfigMinimapPing" then o = L_GUI_MINIMAP_PING end
	if o == "UIConfigMinimapSize" then o = L_GUI_MINIMAP_MINIMAPSIZE end
	-- Misc Settings
	if o == "UIConfigMisc" then o = L_GUI_MISC end
	if o == "UIConfigMiscAFKCamera" then o = L_GUI_MISC_SPIN_CAMERA end
	if o == "UIConfigMiscAlreadyKnown" then o = L_GUI_MISC_ALREADY_KNOWN end
	if o == "UIConfigMiscArmory" then o = L_GUI_MISC_ARMORY_LINK end
	if o == "UIConfigMiscBGSpam" then o = L_GUI_MISC_HIDE_BG_SPAM end
	if o == "UIConfigMiscDurabilityWarning" then o = L_GUI_MISC_DURABILITY_WARNINIG end
	if o == "UIConfigMiscEnhancedMail" then o = L_GUI_MISC_ENCHANCED_MAIL end
	if o == "UIConfigMiscHatTrick" then o = L_GUI_MISC_HATTRICK end
	if o == "UIConfigMiscInviteKeyword" then o = L_GUI_MISC_INVKEYWORD end
	if o == "UIConfigMiscItemLevel" then o = L_GUI_MISC_ITEM_LEVEL end
	if o == "UIConfigMiscSpeedyLoad" then o = L_GUI_MISC_SPEEDYLOAD end
	-- Nameplates Settings
	if o == "UIConfigNameplate" then o = UNIT_NAMEPLATES end
	if o == "UIConfigNameplateAdditionalHeight" then o = L_GUI_NAMEPLATE_AD_HEIGHT end
	if o == "UIConfigNameplateAdditionalWidth" then o = L_GUI_NAMEPLATE_AD_WIDTH end
	if o == "UIConfigNameplateAuraSize" then o = L_GUI_NAMEPLATE_DEBUFFS_SIZE end
	if o == "UIConfigNameplateBadColor" then o = L_GUI_NAMEPLATE_BAD_COLOR end
	if o == "UIConfigNameplateClassIcons" then o = L_GUI_NAMEPLATE_CLASS_ICON end
	if o == "UIConfigNameplateCombat" then o = L_GUI_NAMEPLATE_COMBAT end
	if o == "UIConfigNameplateEnable" then o = L_GUI_NAMEPLATE_ENABLE end
	if o == "UIConfigNameplateEnhanceThreat" then o = L_GUI_NAMEPLATE_THREAT end
	if o == "UIConfigNameplateGoodColor" then o = L_GUI_NAMEPLATE_GOOD_COLOR end
	if o == "UIConfigNameplateHealthValue" then o = L_GUI_NAMEPLATE_HEALTH end
	if o == "UIConfigNameplateHeight" then o = L_GUI_NAMEPLATE_HEIGHT end
	if o == "UIConfigNameplateNameAbbreviate" then o = L_GUI_NAMEPLATE_NAME_ABBREV end
	if o == "UIConfigNameplateNearColor" then o = L_GUI_NAMEPLATE_NEAR_COLOR end
	if o == "UIConfigNameplateCastBar" then o = L_GUI_NAMEPLATE_CASTBAR end
	if o == "UIConfigNameplateCastBarName" then o = L_GUI_NAMEPLATE_CASTBAR_NAME end
	if o == "UIConfigNameplateAuras" then o = L_GUI_NAMEPLATE_SHOW_DEBUFFS end
	if o == "UIConfigNameplateWidth" then o = L_GUI_NAMEPLATE_WIDTH end
	-- PowerBar Settings
	if o == "UIConfigPowerBar" then o = L_GUI_POWERBAR end
	if o == "UIConfigPowerBarEnable" then o = L_GUI_POWERBAR_ENABLE end
	if o == "UIConfigPowerBarFontOutline" then o = L_GUI_POWERBAR_FONT_OUTLINE end
	if o == "UIConfigPowerBarHeight" then o = L_GUI_POWERBAR_HEIGHT end
	if o == "UIConfigPowerBarDKRuneBar" then o = L_GUI_POWERBAR_HIDE_BLIZZ_RUNEBAR end
	if o == "UIConfigPowerBarCombo" then o = L_GUI_POWERBAR_SHOW_COMBO end
	if o == "UIConfigPowerBarMaelstrom" then o = L_GUI_POWERBAR_SHOW_MAELSTROM end
	if o == "UIConfigPowerBarMaelstromSize" then o = L_GUI_POWERBAR_MAELSTROM_SIZE end
	if o == "UIConfigPowerBarMaelstromPulse" then o = L_GUI_POWERBAR_MAELSTROM_PULSE end
	if o == "UIConfigPowerBarMaelstromPulseAt" then o = L_GUI_POWERBAR_MAELSTROM_PULSE_AT end
	if o == "UIConfigPowerBarMana" then o = L_GUI_POWERBAR_SHOW_MANA end
	if o == "UIConfigPowerBarRage" then o = L_GUI_POWERBAR_SHOW_RAGE end
	if o == "UIConfigPowerBarRune" then o = L_GUI_POWERBAR_SHOW_RUNE end
	if o == "UIConfigPowerBarRuneCooldown" then o = L_GUI_POWERBAR_SHOW_RUNE_CD end
	if o == "UIConfigPowerBarValueAbbreviate" then o = L_GUI_POWERBAR_VALUE_SHORT end
	if o == "UIConfigPowerBarWidth" then o = L_GUI_POWERBAR_WIDTH end
	-- PulseCD Settings
	if o == "UIConfigPulseCD" then o = L_GUI_PULSECD end
	if o == "UIConfigPulseCDEnable" then o = L_GUI_PULSECD_ENABLE end
	if o == "UIConfigPulseCDSize" then o = L_GUI_PULSECD_SIZE end
	if o == "UIConfigPulseCDSound" then o = L_GUI_PULSECD_SOUND end
	if o == "UIConfigPulseCDAnimationScale" then o = L_GUI_PULSECD_ANIM_SCALE end
	if o == "UIConfigPulseCDHoldTime" then o = L_GUI_PULSECD_HOLD_TIME end
	if o == "UIConfigPulseCDThreshold" then o = L_GUI_PULSECD_THRESHOLD end
	-- Skins Settings
	if o == "UIConfigSkins" then o = L_GUI_SKINS end
	if o == "UIConfigSkinsChatBubble" then o = L_GUI_SKINS_CHAT_BUBBLE end
	if o == "UIConfigSkinsCLCRet" then o = L_GUI_SKINS_CLCR end
	if o == "UIConfigSkinsDBM" then o = L_GUI_SKINS_DBM end
	if o == "UIConfigSkinsMinimapButtons" then o = L_GUI_SKINS_MINIMAP_BUTTONS end
	if o == "UIConfigSkinsRecount" then o = L_GUI_SKINS_RECOUNT end
	if o == "UIConfigSkinsSkada" then o = L_GUI_SKINS_SKADA end
	if o == "UIConfigSkinsSpy" then o = L_GUI_SKINS_SPY end
	if o == "UIConfigSkinsWeakAuras" then o = L_GUI_SKINS_WEAKAURAS end
	if o == "UIConfigSkinsWorldMap" then o = L_GUI_SKINS_WORLDMAP end
	-- Tooltip Settings
	if o == "UIConfigTooltipScale" then o = L_GUI_TOOLTIP_SCALE end
	if o == "UIConfigTooltip" then o = L_GUI_TOOLTIP end
	if o == "UIConfigTooltipAchievements" then o = L_GUI_TOOLTIP_ACHIEVEMENTS end
	if o == "UIConfigTooltipArenaExperience" then o = L_GUI_TOOLTIP_ARENA_EXPERIENCE end
	if o == "UIConfigTooltipCursor" then o = L_GUI_TOOLTIP_CURSOR end
	if o == "UIConfigTooltipEnable" then o = L_GUI_TOOLTIP_ENABLE end
	if o == "UIConfigTooltipHealthValue" then o = L_GUI_TOOLTIP_HEALTH end
	if o == "UIConfigTooltipHideCombat" then o = L_GUI_TOOLTIP_HIDE_COMBAT end
	if o == "UIConfigTooltipHideButtons" then o = L_GUI_TOOLTIP_HIDE end
	if o == "UIConfigTooltipInstanceLock" then o = L_GUI_TOOLTIP_INSTANCE_LOCK end
	if o == "UIConfigTooltipItemCount" then o = L_GUI_TOOLTIP_ITEM_COUNT end
	if o == "UIConfigTooltipItemIcon" then o = L_GUI_TOOLTIP_ICON end
	if o == "UIConfigTooltipQualityBorder" then o = L_GUI_TOOLTIP_QUALITY_BORDER end
	if o == "UIConfigTooltipRaidIcon" then o = L_GUI_TOOLTIP_RAID_ICON end
	if o == "UIConfigTooltipRank" then o = L_GUI_TOOLTIP_RANK end
	if o == "UIConfigTooltipRealm" then o = L_GUI_TOOLTIP_REALM end
	if o == "UIConfigTooltipSpellID" then o = L_GUI_TOOLTIP_SPELL_ID end
	if o == "UIConfigTooltipTalents" then o = L_GUI_TOOLTIP_TALENTS end
	if o == "UIConfigTooltipTarget" then o = L_GUI_TOOLTIP_TARGET end
	if o == "UIConfigTooltipTitle" then o = L_GUI_TOOLTIP_TITLE end
	if o == "UIConfigTooltipWhoTargetting" then o = L_GUI_TOOLTIP_WHO_TARGETTING end
	-- Unitframe Settings
	if o == "UIConfigUnitframe" then o = L_GUI_UNITFRAME end
	if o == "UIConfigUnitframeComboFrame" then o = L_GUI_UNITFRAME_COMBOFRAME end
	if o == "UIConfigUnitframeSmoothBars" then o = L_GUI_UNITFRAME_SMOOTH_BARS end
	if o == "UIConfigUnitframeAuraOffsetY" then o = L_GUI_UNITFRAME_AURA_OFFSETY end
	if o == "UIConfigUnitframeBetterPowerColors" then o = L_GUI_UNITFRAME_BETTER_POWER_COLOR end
	if o == "UIConfigUnitframeCastBarScale" then o = L_GUI_UNITFRAME_CASTBAR_SCALE end
	if o == "UIConfigUnitframeClassHealth" then o = L_GUI_UNITFRAME_CLASS_HEALTH end
	if o == "UIConfigUnitframeClassIcon" then o = L_GUI_UNITFRAME_CLASS_ICON end
	if o == "UIConfigUnitframeCombatFeedback" then o = L_GUI_UNITFRAME_COMBAT_FEEDBACK end
	if o == "UIConfigUnitframeEnable" then o = L_GUI_UNITFRAME_ENABLE end
	if o == "UIConfigUnitframeEnhancedFrames" then o = L_GUI_UNITFRAME_ENHANCED_UNITFRAMES end
	if o == "UIConfigUnitframeGroupNumber" then o = L_GUI_UNITFRAME_GROUP_NUMBER end
	if o == "UIConfigUnitframePvPIcon" then o = L_GUI_UNITFRAME_HIDE_PVPICON end
	if o == "UIConfigUnitframeLargeAuraSize" then o = L_GUI_UNITFRAME_LARGE_AURA end
	if o == "UIConfigUnitframeOutline" then o = L_GUI_UNITFRAME_OUTLINE end
	if o == "UIConfigUnitframePercentHealth" then o = L_GUI_UNITFRAME_PERCENT_HEALTH end
	if o == "UIConfigUnitframeScale" then o = L_GUI_UNITFRAME_SCALE end
	if o == "UIConfigUnitframeSmallAuraSize" then o = L_GUI_UNITFRAME_SMALL_AURA end
	-- Profiles settings
	if o == "UIConfigProfiles" then o = L_GUI_PROFILES or "Profiles" end

	K.option = o
end

local NewButton = function(text, parent)

	local result = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	local label = result:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetText(text)
	result:SetWidth(label:GetWidth())
	result:SetHeight(label:GetHeight())
	result:SetFontString(label)
	result:SetNormalTexture("")
	result:SetHighlightTexture("")
	result:SetPushedTexture("")

	return result
end

local NormalButton = function(text, parent)

	local result = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	local label = result:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetJustifyH("LEFT")
	label:SetText(text)
	result:SetSize(100, 23)
	result:SetFontString(label)
	if IsAddOnLoaded("Aurora") then
		local F = unpack(Aurora)
		F.Reskin(result)
	end

	return result
end

-- Legacy PerChar popups removed

StaticPopupDialogs["RESET_ALL"] = {
	text = L_GUI_RESET_ALL,
	OnAccept = function()
		local K, C, L, _ = budsUI:unpack()
		if budsUIData and budsUIData.Profiles then
			budsUIData.Profiles[K.GetActiveProfile()] = {}
		end
		ReloadUI()
	end,
	OnCancel = function() UIConfigCover:Hide() end,
	button1 = ACCEPT,
	button2 = CANCEL,
	timeout = 0,
	whileDead = 1,
	preferredIndex = 3,
}

local function SetValue(group, option, value)
	local K, C, L, _ = budsUI:unpack()
	local activeProfile = K.GetActiveProfile()
	
	-- Safety check: If no valid profile exists, create a default one
	if not activeProfile or activeProfile == "Unknown" or not budsUIData.Profiles[activeProfile] then
		Print("|cffff0000No valid profile found. Creating default profile...|r")
		K.CreateProfile("Default")
		local realmKey = K.Realm .. "-" .. K.Name
		budsUIData.ActiveProfiles[realmKey] = "Default"
		activeProfile = "Default"
	end

	-- Validation: Ensure value is not nil
	if value == nil then return end

	if not budsUIData.Profiles[activeProfile][group] then budsUIData.Profiles[activeProfile][group] = {} end
	
	-- Store the value
	budsUIData.Profiles[activeProfile][group][option] = value
	
	-- Update live C table for instant sync!
	if C[group] then
		if type(value) == "table" and type(C[group][option]) == "table" then
			for k, v in pairs(value) do
				C[group][option][k] = v
			end
		else
			C[group][option] = value
		end
	end
end

local VISIBLE_GROUP = nil
local lastbutton = nil
local function ShowGroup(group, button)
	local K, _ = budsUI:unpack()

	if lastbutton then
		lastbutton:SetText(lastbutton:GetText().sub(lastbutton:GetText(), 11, -3))
	end
	if VISIBLE_GROUP then
		_G["UIConfig"..VISIBLE_GROUP]:Hide()
	end
	if _G["UIConfig"..group] then
		local o = "UIConfig"..group
		Local(o)
		_G["UIConfigTitle"]:SetText(K.option)
		local height = _G["UIConfig"..group]:GetHeight()
		_G["UIConfig"..group]:Show()
		local scrollamntmax = 400
		local scrollamntmin = scrollamntmax - 10
		local max = height > scrollamntmax and height-scrollamntmin or 1

		if max == 1 then
			_G["UIConfigGroupSlider"]:SetValue(1)
			_G["UIConfigGroupSlider"]:Hide()
		else
			_G["UIConfigGroupSlider"]:SetMinMaxValues(0, max)
			_G["UIConfigGroupSlider"]:Show()
			_G["UIConfigGroupSlider"]:SetValue(1)
		end
		_G["UIConfigGroup"]:SetScrollChild(_G["UIConfig"..group])

		local x
		if UIConfigGroupSlider:IsShown() then
			_G["UIConfigGroup"]:EnableMouseWheel(true)
			_G["UIConfigGroup"]:SetScript("OnMouseWheel", function(self, delta)
				if UIConfigGroupSlider:IsShown() then
					if delta == -1 then
						x = _G["UIConfigGroupSlider"]:GetValue()
						_G["UIConfigGroupSlider"]:SetValue(x + 10)
					elseif delta == 1 then
						x = _G["UIConfigGroupSlider"]:GetValue()
						_G["UIConfigGroupSlider"]:SetValue(x - 30)
					end
				end
			end)
		else
			_G["UIConfigGroup"]:EnableMouseWheel(false)
		end

		VISIBLE_GROUP = group
		lastbutton = button
	end
end

local loaded
function CreateUIConfig()
	if InCombatLockdown() and not loaded then Print(format("|cffffe02e%s|r", ERR_NOT_IN_COMBAT)) return end
	local K, C, L, _ = budsUI:unpack()

	if UIConfigMain then
		ShowGroup("General")
		UIConfigMain:Show()
		return
	end

	-- Main Frame
	UIConfigMain = CreateFrame("Frame", "UIConfigMain", UIParent)
	local UIConfigMain = UIConfigMain
	UIConfigMain:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 200)
	UIConfigMain:SetSize(780, 520)
	UIConfigMain:SetBackdrop(K.Backdrop)
	UIConfigMain:SetBackdropColor(unpack(C["Media"].Backdrop_Color))
	UIConfigMain:SetBackdropBorderColor(K.Color.r, K.Color.g, K.Color.b)
	UIConfigMain:SetFrameStrata("DIALOG")
	UIConfigMain:SetFrameLevel(20)
	tinsert(UISpecialFrames, "UIConfigMain")

	-- Version Title
	local TitleBoxVer = CreateFrame("Frame", "TitleBoxVer", UIConfigMain)
	TitleBoxVer:SetSize(180, 24)
	TitleBoxVer:SetPoint("TOPLEFT", UIConfigMain, "TOPLEFT", 23, -15)

	local TitleBoxVerText = TitleBoxVer:CreateFontString("UIConfigTitleVer", "OVERLAY", "GameFontNormal")
	TitleBoxVerText:SetPoint("CENTER")
	TitleBoxVerText:SetText("|cff388bdbbudsUI|r "..K.Version)

	-- Main Frame Title
	local TitleBox = CreateFrame("Frame", "TitleBox", UIConfigMain)
	TitleBox:SetSize(540, 24)
	TitleBox:SetPoint("TOPLEFT", TitleBoxVer, "TOPRIGHT", 15, 0)

	local TitleBoxText = TitleBox:CreateFontString("UIConfigTitle", "OVERLAY", "GameFontNormal")
	TitleBoxText:SetPoint("LEFT", TitleBox, "LEFT", 15, 0)

	-- Options Frame
	local UIConfig = CreateFrame("Frame", "UIConfig", UIConfigMain)
	UIConfig:SetPoint("TOPLEFT", TitleBox, "BOTTOMLEFT", 10, -15)
	UIConfig:SetSize(520, 400)

	local UIConfigBG = CreateFrame("Frame", "UIConfigBG", UIConfig)
	UIConfigBG:SetPoint("TOPLEFT", -10, 10)
	UIConfigBG:SetPoint("BOTTOMRIGHT", 10, -10)

	-- Group Frame
	local groups = CreateFrame("ScrollFrame", "UIConfigCategoryGroup", UIConfig)
	groups:SetPoint("TOPLEFT", TitleBoxVer, "BOTTOMLEFT", 10, -15)
	groups:SetSize(160, 400)

	local groupsBG = CreateFrame("Frame", "groupsBG", UIConfig)
	groupsBG:SetPoint("TOPLEFT", groups, -10, 10)
	groupsBG:SetPoint("BOTTOMRIGHT", groups, 10, -10)

	local UIConfigCover = CreateFrame("Frame", "UIConfigCover", UIConfigMain)
	UIConfigCover:SetPoint("TOPLEFT", 0, 0)
	UIConfigCover:SetPoint("BOTTOMRIGHT", 0, 0)
	UIConfigCover:SetFrameLevel(UIConfigMain:GetFrameLevel() + 20)
	UIConfigCover:EnableMouse(true)
	UIConfigCover:SetScript("OnMouseDown", function(self) print(L_GUI_MAKE_SELECTION) end)
	UIConfigCover:Hide()

	-- Group Scroll
	local slider = CreateFrame("Slider", "UIConfigCategorySlider", groups)
	slider:SetPoint("TOPRIGHT", 0, 0)
	slider:SetSize(20, 400)
	slider:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
	slider:SetOrientation("VERTICAL")
	slider:SetValueStep(20)
	slider:SetScript("OnValueChanged", function(self, value) groups:SetVerticalScroll(value) end)

	if not slider.bg then
		slider.bg = CreateFrame("Frame", nil, slider)
		slider.bg:SetPoint("TOPLEFT", 0, 0)
		slider.bg:SetPoint("BOTTOMRIGHT", 0, 0)
		slider.bg:SetBackdrop(K.Backdrop)
		slider.bg:SetBackdropColor(unpack(C["Media"].Backdrop_Color))
		slider.bg:SetBackdropBorderColor(unpack(C["Media"].Border_Color))
	end

	local function sortMyTable(a, b)
		return ALLOWED_GROUPS[a] < ALLOWED_GROUPS[b]
	end
	local function pairsByKey(t, f)
		local a = {}
		for n in pairs(t) do table.insert(a, n) end
		table.sort(a, sortMyTable)
		local i = 0
		local iter = function()
			i = i + 1
			if a[i] == nil then return nil
			else return a[i], t[a[i]]
			end
		end
		return iter
	end

	local GetOrderedIndex = function(t)
		local OrderedIndex = {}

		for key in pairs(t) do table.insert(OrderedIndex, key) end
		table.sort(OrderedIndex)
		return OrderedIndex
	end

	local OrderedNext = function(t, state)
		local Key

		if (state == nil) then
			t.OrderedIndex = GetOrderedIndex(t)
			Key = t.OrderedIndex[1]
			return Key, t[Key]
		end

		Key = nil
		for i = 1, #t.OrderedIndex do
			if (t.OrderedIndex[i] == state) then Key = t.OrderedIndex[i + 1] end
		end

		if Key then return Key, t[Key] end
		t.OrderedIndex = nil
		return
	end

	local PairsByKeys = function(t) return OrderedNext, t, nil end

	local child = CreateFrame("Frame", nil, groups)
	child:SetPoint("TOPLEFT")
	local offset = 5
	for i in pairsByKey(ALLOWED_GROUPS) do
		local o = "UIConfig"..i
		Local(o)
		local button = NewButton(K.option, child)
		button:SetSize(125, 16)
		button:SetPoint("TOPLEFT", 5, -offset)
		button:SetScript("OnClick", function(self) ShowGroup(i, button) self:SetText(format("|cff%02x%02x%02x%s|r", K.Color.r*255, K.Color.g*255, K.Color.b*255, K.option)) end)
		offset = offset + 20
	end
	child:SetSize(125, offset)
	slider:SetMinMaxValues(0, max(0, offset - 400))
	slider:SetValue(1)
	groups:SetScrollChild(child)

	local x
	_G["UIConfigCategoryGroup"]:EnableMouseWheel(true)
	_G["UIConfigCategoryGroup"]:SetScript("OnMouseWheel", function(self, delta)
		if _G["UIConfigCategorySlider"]:IsShown() then
			if delta == -1 then
				x = _G["UIConfigCategorySlider"]:GetValue()
				_G["UIConfigCategorySlider"]:SetValue(x + 10)
			elseif delta == 1 then
				x = _G["UIConfigCategorySlider"]:GetValue()
				_G["UIConfigCategorySlider"]:SetValue(x - 20)
			end
		end
	end)

	local group = CreateFrame("ScrollFrame", "UIConfigGroup", UIConfig)
	UIConfigGroup = group
	group:SetPoint("TOPLEFT", 0, 5)
	group:SetSize(520, 400)

	-- Options Scroll
	local slider = CreateFrame("Slider", "UIConfigGroupSlider", group)
	slider:SetPoint("TOPRIGHT", 0, 0)
	slider:SetSize(20, 400)
	slider:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
	slider:SetOrientation("VERTICAL")
	slider:SetValueStep(20)
	slider:SetScript("OnValueChanged", function(self, value) UIConfigGroup:SetVerticalScroll(value) end)
	
	if not slider.bg then
		slider.bg = CreateFrame("Frame", nil, slider)
		slider.bg:SetPoint("TOPLEFT", 0, 0)
		slider.bg:SetPoint("BOTTOMRIGHT", 0, 0)
		slider.bg:SetBackdrop(K.Backdrop)
		slider.bg:SetBackdropColor(unpack(C["Media"].Backdrop_Color))
		slider.bg:SetBackdropBorderColor(unpack(C["Media"].Border_Color))
	end

	for i in pairs(ALLOWED_GROUPS) do
		if i ~= "Profiles" then
			local frame = CreateFrame("Frame", "UIConfig"..i, UIConfigGroup)
			frame:SetPoint("TOPLEFT")
			frame:SetWidth(225)

			local offset = 5

			if type(C[i]) ~= "table" then Error(i.." GroupName not found in config table.") return end
		for j, value in PairsByKeys(C[i]) do
			if type(value) == "boolean" then
				local button = CreateFrame("CheckButton", "UIConfig"..i..j, frame, "InterfaceOptionsCheckButtonTemplate")
				local o = "UIConfig"..i..j
				Local(o)
				_G["UIConfig"..i..j.."Text"]:SetText(K.option)
				_G["UIConfig"..i..j.."Text"]:SetFontObject(GameFontHighlight)
				_G["UIConfig"..i..j.."Text"]:SetWidth(460)
				_G["UIConfig"..i..j.."Text"]:SetJustifyH("LEFT")
				button:SetChecked(value)
				button:SetScript("OnClick", function(self) SetValue(i, j, (self:GetChecked() and true or false)) end)
				button:SetPoint("TOPLEFT", 5, -offset)
				offset = offset + 25
			elseif type(value) == "number" or type(value) == "string" then
				if (i == "PowerBar" and j == "MaelstromSize") or (i == "Unitframe" and type(value) == "number") then
					local sMin, sMax, sStep = 64, 512, 8
					if i == "Unitframe" then
						if j == "Scale" or j == "CastBarScale" then
							sMin, sMax, sStep = 0.5, 2.5, 0.05
						elseif j == "LargeAuraSize" or j == "SmallAuraSize" then
							sMin, sMax, sStep = 10, 50, 1
						elseif j == "AuraOffsetY" then
							sMin, sMax, sStep = -20, 20, 1
						else
							sMin, sMax, sStep = 0, 100, 1
						end
					end

					local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
					local o = "UIConfig"..i..j
					Local(o)
					label:SetText(K.option)
					label:SetSize(460, 20)
					label:SetJustifyH("LEFT")
					label:SetPoint("TOPLEFT", 5, -offset)

					local slider = CreateFrame("Slider", "UIConfig"..i..j.."Slider", frame, "OptionsSliderTemplate")
					slider:SetPoint("TOPLEFT", 10, -(offset + 25))
					slider:SetWidth(200)
					slider:SetMinMaxValues(sMin, sMax)
					slider:SetValueStep(sStep)
					slider:SetValue(value)

					_G[slider:GetName().."Low"]:SetText(sMin)
					_G[slider:GetName().."High"]:SetText(sMax)
					_G[slider:GetName().."Text"]:SetText(value)

					slider:SetScript("OnValueChanged", function(self, val)
						local mult = 1 / sStep
						val = math.floor(val * mult + 0.5) / mult
						_G[self:GetName().."Text"]:SetText(val)
						SetValue(i, j, val)
					end)

					offset = offset + 50
				else
					local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
					local o = "UIConfig"..i..j
					Local(o)
					label:SetText(K.option)
					label:SetSize(460, 20)
					label:SetJustifyH("LEFT")
					label:SetPoint("TOPLEFT", 5, -offset)

					local editbox = CreateFrame("EditBox", nil, frame)
					editbox:SetAutoFocus(false)
					editbox:SetMultiLine(false)
					editbox:SetSize(220, 22)
					editbox:SetMaxLetters(255)
					editbox:SetTextInsets(3, 0, 0, 0)
					editbox:SetFontObject(GameFontHighlight)
					editbox:SetPoint("TOPLEFT", 8, -(offset + 20))
					editbox:SetText(value)
					editbox:SetBackdrop(K.Backdrop)
					editbox:SetBackdropColor(unpack(C["Media"].Backdrop_Color))

					local okbutton = CreateFrame("Button", nil, frame)
					okbutton:SetHeight(editbox:GetHeight())
					okbutton:SetPoint("LEFT", editbox, "RIGHT", 2, 0)

					local oktext = okbutton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
					oktext:SetText(OKAY)
					oktext:SetPoint("CENTER", okbutton, "CENTER", -1, 0)
					okbutton:SetWidth(oktext:GetWidth() + 5)
					okbutton:Hide()

					if type(value) == "number" then
						editbox:SetScript("OnEscapePressed", function(self) okbutton:Hide() self:ClearFocus() self:SetText(value) end)
						editbox:SetScript("OnChar", function(self) okbutton:Show() end)
						editbox:SetScript("OnEnterPressed", function(self) 
							okbutton:Hide() 
							self:ClearFocus() 
							local n = tonumber(self:GetText())
							if n then
								SetValue(i, j, n)
							else
								self:SetText(value) -- Revert to current value if invalid
							end
						end)
						okbutton:SetScript("OnMouseDown", function(self) 
							editbox:ClearFocus() 
							self:Hide() 
							local n = tonumber(editbox:GetText())
							if n then
								SetValue(i, j, n)
							else
								editbox:SetText(value)
							end
						end)
					else
						editbox:SetScript("OnEscapePressed", function(self) okbutton:Hide() self:ClearFocus() self:SetText(value) end)
						editbox:SetScript("OnChar", function(self) okbutton:Show() end)
						editbox:SetScript("OnEnterPressed", function(self) okbutton:Hide() self:ClearFocus() SetValue(i, j, tostring(self:GetText())) end)
						okbutton:SetScript("OnMouseDown", function(self) editbox:ClearFocus() self:Hide() SetValue(i, j, tostring(editbox:GetText())) end)
					end

					offset = offset + 45
				end
			elseif type(value) == "table" then
				local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				local o = "UIConfig"..i..j
				Local(o)
				label:SetText(K.option)
				label:SetSize(440, 20)
				label:SetJustifyH("LEFT")
				label:SetPoint("TOPLEFT", 5, -offset)

				colorbuttonname = (label:GetText().."ColorPicker")

				local colorbutton = CreateFrame("Button", colorbuttonname, frame)
				colorbutton:SetHeight(20)
				colorbutton:SetBackdrop(K.Backdrop)
				colorbutton:SetBackdropBorderColor(unpack(value))
				colorbutton:SetBackdropColor(value[1], value[2], value[3], 0.3)
				colorbutton:SetPoint("LEFT", label, "RIGHT", 2, 0)

				local colortext = colorbutton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				colortext:SetText(COLOR)
				colortext:SetPoint("CENTER")
				colortext:SetJustifyH("CENTER")
				colorbutton:SetWidth(colortext:GetWidth() + 5)

				local oldvalue = value

				local function round(number, decimal)
					return (("%%.%df"):format(decimal)):format(number)
				end

				colorbutton:SetScript("OnMouseDown", function(self)
					if ColorPickerFrame:IsShown() then return end
					local newR, newG, newB, newA
					local fired = 0

					local r, g, b, a = self:GetBackdropBorderColor()
					r, g, b, a = round(r, 2), round(g, 2), round(b, 2), round(a, 2)
					local originalR, originalG, originalB, originalA = r, g, b, a

					local function ShowColorPicker(r, g, b, a, changedCallback)
						ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = changedCallback, changedCallback, changedCallback
						ColorPickerFrame:SetColorRGB(r, g, b)
						a = tonumber(a)
						ColorPickerFrame.hasOpacity = (a ~= nil and a ~= 1)
						ColorPickerFrame.opacity = a
						ColorPickerFrame.previousValues = {originalR, originalG, originalB, originalA}
						ColorPickerFrame:Hide()
						ColorPickerFrame:Show()
					end

					local function myColorCallback(restore)
						fired = fired + 1
						if restore ~= nil then
							-- The user bailed, we extract the old color from the table created by ShowColorPicker
							newR, newG, newB, newA = unpack(restore)
						else
							-- Something changed
							newA, newR, newG, newB = OpacitySliderFrame:GetValue(), ColorPickerFrame:GetColorRGB()
						end

						value = {newR, newG, newB, newA}
						SetValue(i, j, (value))
						self:SetBackdropBorderColor(newR, newG, newB, newA)
						self:SetBackdropColor(newR, newG, newB, 0.3)
					end

					ShowColorPicker(originalR, originalG, originalB, originalA, myColorCallback)
				end)

				offset = offset + 25
			end
		end

		frame:SetHeight(offset)
		frame:Hide()
	end
end

	-- Create Profiles Frame
	local function UpdateProfileList()
		local K, C, L, _ = budsUI:unpack()
		if not _G["UIConfigProfiles"] then return end
		local frame = _G["UIConfigProfiles"]
		
		-- Clear existing dynamic children
		if frame.dynamicElements then
			for _, el in pairs(frame.dynamicElements) do
				if el.Hide then el:Hide() end
			end
		end
		frame.dynamicElements = {}
		
		local activeProfile = K.GetActiveProfile()
		local offset = 10
		
		-- ============================================================
		-- 1. PROFILE DROPDOWN
		-- ============================================================
		if not frame.profileDropdown then
			local dropdownLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			dropdownLabel:SetPoint("TOPLEFT", 10, -offset)
			dropdownLabel:SetText(L_GUI_PROFILES_ACTIVE or "Active Profile:")
			frame.dropdownLabel = dropdownLabel
			
			local dropdown = CreateFrame("Frame", "budsUIProfileDropdown", frame, "UIDropDownMenuTemplate")
			dropdown:SetPoint("TOPLEFT", 0, -(offset + 18))
			UIDropDownMenu_SetWidth(dropdown, 250)
			frame.profileDropdown = dropdown
		end
		
		UIDropDownMenu_SetText(frame.profileDropdown, "|cff388bdb" .. activeProfile .. "|r")
		UIDropDownMenu_Initialize(frame.profileDropdown, function(self, level)
			local info = UIDropDownMenu_CreateInfo()
			for pName, _ in pairs(budsUIData.Profiles) do
				info.text = pName
				info.checked = (pName == activeProfile)
				info.func = function()
					K.SetProfile(pName)
					ReloadUI()
				end
				UIDropDownMenu_AddButton(info, level)
			end
		end)
		offset = offset + 60
		
		-- ============================================================
		-- 2. CREATE NEW PROFILE
		-- ============================================================
		if not frame.createLabel then
			local lbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			lbl:SetPoint("TOPLEFT", 10, -offset)
			lbl:SetText(L_GUI_PROFILES_CREATE or "Create New Profile")
			frame.createLabel = lbl
		else
			frame.createLabel:SetPoint("TOPLEFT", 10, -offset)
		end
		offset = offset + 18
		
		if not frame.createEdit then
			local edit = CreateFrame("EditBox", nil, frame)
			edit:SetSize(220, 20)
			edit:SetAutoFocus(false)
			edit:SetFontObject(GameFontHighlight)
			edit:SetBackdrop(K.Backdrop)
			edit:SetBackdropColor(0, 0, 0, 0.5)
			edit:SetBackdropBorderColor(unpack(C["Media"].Border_Color))
			edit:SetTextInsets(5, 5, 0, 0)
			frame.createEdit = edit
			
			local btn = NormalButton(L_GUI_PROFILES_CREATE or "Create", frame)
			btn:SetSize(100, 22)
			btn:SetScript("OnClick", function()
				local newName = frame.createEdit:GetText()
				if newName and newName ~= "" and not budsUIData.Profiles[newName] then
					K.CreateProfile(newName, activeProfile)
					frame.createEdit:SetText("")
					Print("|cff388bdb" .. newName .. "|r created.")
					UpdateProfileList()
				end
			end)
			frame.createBtn = btn
		end
		frame.createEdit:SetPoint("TOPLEFT", 20, -offset)
		frame.createBtn:SetPoint("LEFT", frame.createEdit, "RIGHT", 5, 0)
		offset = offset + 30
		
		-- ============================================================
		-- 3. RENAME PROFILE
		-- ============================================================
		if not frame.renameLabel then
			local lbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			lbl:SetText("Rename Profile")
			frame.renameLabel = lbl
		end
		frame.renameLabel:SetPoint("TOPLEFT", 10, -offset)
		offset = offset + 18
		
		if not frame.renameEdit then
			local edit = CreateFrame("EditBox", nil, frame)
			edit:SetSize(220, 20)
			edit:SetAutoFocus(false)
			edit:SetFontObject(GameFontHighlight)
			edit:SetBackdrop(K.Backdrop)
			edit:SetBackdropColor(0, 0, 0, 0.5)
			edit:SetBackdropBorderColor(unpack(C["Media"].Border_Color))
			edit:SetTextInsets(5, 5, 0, 0)
			frame.renameEdit = edit
			
			local btn = NormalButton("Rename", frame)
			btn:SetSize(100, 22)
			btn:SetScript("OnClick", function()
				local newName = frame.renameEdit:GetText()
				if newName and newName ~= "" and newName ~= activeProfile then
					if K.RenameProfile(activeProfile, newName) then
						Print("|cff388bdb" .. activeProfile .. "|r renamed to |cff388bdb" .. newName .. "|r. Reloading...")
						ReloadUI()
					else
						Print("|cffff0000Rename failed.|r Name already exists or invalid.")
					end
				end
			end)
			frame.renameBtn = btn
		end
		frame.renameEdit:SetPoint("TOPLEFT", 20, -offset)
		frame.renameEdit:SetText(activeProfile)
		frame.renameBtn:SetPoint("LEFT", frame.renameEdit, "RIGHT", 5, 0)
		offset = offset + 35
		
		-- ============================================================
		-- 4. SAVE PROFILE
		-- ============================================================
		if not frame.saveBtn then
			local btn = NormalButton("Save Profile", frame)
			btn:SetWidth(330)
			btn:SetHeight(22)
			btn:SetScript("OnClick", function()
				if K.SaveProfile() then
					Print("|cff388bdb" .. activeProfile .. "|r saved.")
				end
			end)
			frame.saveBtn = btn
		end
		frame.saveBtn:SetPoint("TOPLEFT", 20, -offset)
		offset = offset + 30
		
		-- ============================================================
		-- 5. DELETE PROFILE
		-- ============================================================
		if not frame.deleteBtn then
			local btn = NormalButton("|cffff0000Delete Profile|r", frame)
			btn:SetWidth(330)
			btn:SetHeight(22)
			btn:SetScript("OnClick", function()
				local profileCount = 0
				for _ in pairs(budsUIData.Profiles) do profileCount = profileCount + 1 end
				if profileCount <= 1 then
					Print("|cffff0000Cannot delete the last profile.|r")
					return
				end
				StaticPopupDialogs["BUDSUI_DELETE_PROFILE"] = {
					text = "Delete profile |cff388bdb" .. activeProfile .. "|r?\n\nThis cannot be undone. A new default profile will be created.",
					button1 = ACCEPT,
					button2 = CANCEL,
					OnAccept = function()
						K.DeleteProfile(activeProfile)
						-- Assign first remaining profile
						for pName, _ in pairs(budsUIData.Profiles) do
							K.SetProfile(pName)
							break
						end
						ReloadUI()
					end,
					timeout = 0,
					whileDead = 1,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show("BUDSUI_DELETE_PROFILE")
			end)
			frame.deleteBtn = btn
		end
		frame.deleteBtn:SetPoint("TOPLEFT", 20, -offset)
		offset = offset + 40
		
		-- ============================================================
		-- 6. IMPORT / EXPORT
		-- ============================================================
		if not frame.ioLabel then
			local lbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			lbl:SetText("Import / Export")
			frame.ioLabel = lbl
		end
		frame.ioLabel:SetPoint("TOPLEFT", 10, -offset)
		offset = offset + 18
		
		if not frame.ioBox then
			local scrollFrame = CreateFrame("ScrollFrame", "budsUIProfileIOScroll", frame, "UIPanelScrollFrameTemplate")
			scrollFrame:SetSize(330, 80)
			scrollFrame:SetBackdrop(K.Backdrop)
			scrollFrame:SetBackdropColor(0, 0, 0, 0.5)
			scrollFrame:SetBackdropBorderColor(unpack(C["Media"].Border_Color))
			frame.ioScroll = scrollFrame
			
			local editBox = CreateFrame("EditBox", "budsUIProfileIOEdit", scrollFrame)
			editBox:SetMultiLine(true)
			editBox:SetAutoFocus(false)
			editBox:SetFontObject(GameFontHighlightSmall)
			editBox:SetWidth(310)
			editBox:SetTextInsets(5, 5, 5, 5)
			editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
			scrollFrame:SetScrollChild(editBox)
			frame.ioBox = editBox
		end
		frame.ioScroll:SetPoint("TOPLEFT", 20, -offset)
		offset = offset + 90
		
		if not frame.exportBtn then
			local btn = NormalButton("Export", frame)
			btn:SetSize(160, 22)
			btn:SetScript("OnClick", function()
				local data = K.ExportProfile(activeProfile)
				if data then
					frame.ioBox:SetText(data)
					frame.ioBox:HighlightText()
					frame.ioBox:SetFocus()
					Print("Profile exported. Press Ctrl+C to copy.")
				end
			end)
			frame.exportBtn = btn
		end
		frame.exportBtn:SetPoint("TOPLEFT", 20, -offset)
		
		if not frame.importBtn then
			local btn = NormalButton("Import", frame)
			btn:SetSize(160, 22)
			btn:SetScript("OnClick", function()
				local data = frame.ioBox:GetText()
				if data and data ~= "" then
					local importName = activeProfile .. " (Import)"
					if K.ImportProfile(importName, data) then
						K.SetProfile(importName)
						Print("|cff388bdb" .. importName .. "|r imported. Reloading...")
						ReloadUI()
					else
						Print("|cffff0000Import failed.|r Invalid data or profile name already exists.")
					end
				end
			end)
			frame.importBtn = btn
		end
		frame.importBtn:SetPoint("LEFT", frame.exportBtn, "RIGHT", 10, 0)
		offset = offset + 30

		if not frame.ioHint then
			local lbl = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			lbl:SetText("Copy with Ctrl+C / Paste with Ctrl+V")
			lbl:SetJustifyH("LEFT")
			lbl:SetTextColor(0.8, 0.8, 0.8)
			frame.ioHint = lbl
		end
		frame.ioHint:SetPoint("TOPLEFT", 20, -offset)
		offset = offset + 35
		
		frame:SetHeight(offset + 20)
	end

	local profilesFrame = CreateFrame("Frame", "UIConfigProfiles", UIConfigGroup)
	profilesFrame:SetPoint("TOPLEFT")
	profilesFrame:SetSize(520, 500)
	profilesFrame:Hide()
	profilesFrame:SetScript("OnShow", UpdateProfileList)

	local reset = NormalButton(DEFAULT, UIConfigMain)
	reset:SetPoint("TOPLEFT", UIConfig, "BOTTOMLEFT", -10, -25)
	reset:SetScript("OnClick", function(self)
		UIConfigCover:Show()
		StaticPopup_Show("RESET_ALL")
	end)

	local close = NormalButton(CLOSE, UIConfigMain)
	close:SetPoint("TOPRIGHT", UIConfig, "BOTTOMRIGHT", 10, -25)
	close:SetScript("OnClick", function(self) PlaySound("igMainMenuOption") UIConfigMain:Hide() end)

	local load = NormalButton(APPLY, UIConfigMain)
	load:SetPoint("RIGHT", close, "LEFT", -4, 0)
	load:SetScript("OnClick", function(self) ReloadUI() end)

	local totalreset = NormalButton(L_GUI_BUTTON_RESET, UIConfigMain)
	totalreset:SetWidth(120)
	totalreset:SetPoint("TOPLEFT", groupsBG, "BOTTOMLEFT", 0, -15)
	totalreset:SetScript("OnClick", function(self)
		StaticPopup_Show("RESET_UI")
	end)

	local bgSkins = {TitleBox, TitleBoxVer, UIConfigBG, groupsBG}
	for _, sb in pairs(bgSkins) do
		sb:SetBackdrop(K.Backdrop)
		sb:SetBackdropColor(unpack(C["Media"].Backdrop_Color))
		sb:SetBackdropBorderColor(unpack(C["Media"].Border_Color))
	end

	-- Mascot
	local MascotFrame = CreateFrame("Frame", nil, UIConfigMain)
	MascotFrame:SetSize(128, 128)
	MascotFrame:SetPoint("BOTTOMRIGHT", UIConfigMain, "BOTTOMRIGHT", 10, 35)
	MascotFrame:SetFrameLevel(UIConfigMain:GetFrameLevel() + 30)
	MascotFrame:EnableMouse(true)

	local Mascot = MascotFrame:CreateTexture(nil, "OVERLAY")
	Mascot:SetAllPoints()
	Mascot:SetTexture("Interface\\AddOns\\budsUI\\Media\\assets\\buds_shot.tga")

	MascotFrame:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:ClearLines()
		GameTooltip:AddLine("|cff388bdbBuds|r")
		GameTooltip:AddLine("Level 420", 1, 1, 1)
		GameTooltip:AddDoubleLine("Race:", "Hybrid", 1, 1, 1, 0.2, 1, 0.2)
		GameTooltip:AddDoubleLine("Class:", "Sativa", 1, 1, 1, 1, 0.8, 0)
		GameTooltip:Show()
	end)

	MascotFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	ShowGroup("General")
	loaded = true
end

do
	function SlashCmdList.RESETCONFIG()
		if UIConfigMain and UIConfigMain:IsShown() then UIConfigCover:Show() end
		StaticPopup_Show("RESET_ALL")
	end
	SLASH_RESETCONFIG1 = "/resetconfig"
end

do
	local frame = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
	frame:Hide()

	frame.name = "|cff388bdbbudsUI|r"
	frame:SetScript("OnShow", function(self)
		if self.show then return end
		local K, _ = budsUI:unpack()
		local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		title:SetPoint("TOPLEFT", 16, -16)
		title:SetText("Info:")

		local subtitle = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		subtitle:SetWidth(400)
		subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
		subtitle:SetJustifyH("LEFT")
		subtitle:SetText("GitHub: |cff388bdbhttps://github.com/Budtender3000/budsUI|r\nRelease: |cff388bdbhttps://github.com/Budtender3000/budsUI/releases/tag/v0.6.1|r")

		local titleAuthor = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		titleAuthor:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -16)
		titleAuthor:SetText("Author:")

		local subtitleAuthor = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		subtitleAuthor:SetWidth(400)
		subtitleAuthor:SetPoint("TOPLEFT", titleAuthor, "BOTTOMLEFT", 0, -8)
		subtitleAuthor:SetJustifyH("LEFT")
		subtitleAuthor:SetText("|cff388bdbBudtender3000 with Buds|r")

		local titleThanks = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		titleThanks:SetPoint("TOPLEFT", subtitleAuthor, "BOTTOMLEFT", 0, -16)
		titleThanks:SetText("Special Thanks:")

		local subtitleThanks = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		subtitleThanks:SetWidth(400)
		subtitleThanks:SetPoint("TOPLEFT", titleThanks, "BOTTOMLEFT", 0, -8)
		subtitleThanks:SetJustifyH("LEFT")
		subtitleThanks:SetText("Kkthnx (Original-Author), Shestak (Basis-Framework), DuffedUI")

		local titleLegacy = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		titleLegacy:SetPoint("TOPLEFT", subtitleThanks, "BOTTOMLEFT", 0, -16)
		titleLegacy:SetText("Legacy Credits:")

		local subtitleLegacy = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		subtitleLegacy:SetWidth(400)
		subtitleLegacy:SetPoint("TOPLEFT", titleLegacy, "BOTTOMLEFT", 0, -8)
		subtitleLegacy:SetJustifyH("LEFT")
		subtitleLegacy:SetText("ALZA, AcidWeb, Aezay, Affli, Ailae, Allez, Ammo, Astromech, Beoko, Bitbyte, Blamdarot, Bozo, Bunny67, Caellian, Califpornia, Camealion, Chiril, Crum, CrusaderHeimdall, Cybey, Dawn, Don Kaban, Dridzt, Duffed, Durcyn, Eclipse, Egingell, Elv22, Evilpaul, Evl, Favorit, Fernir, Foof, Freebaser, freesay, |ccfff7d0aGoldpaw|r, Gorlasch, Gsuz, Haleth, Haste, Hoochie, Hungtar, HyPeRnIcS, Hydra, Ildyria, Jaslm, Karl_w_w, Karudon, Katae, Kellett, Kemayo, Killakhan, Kraftman, Kunda, Leatrix, Magdain, |cFFFF69B4Magicnachos|r, Meurtcriss, Monolit, MrRuben5, Myrilandell of Lothar, Nathanyel, Nefarion, Nightcracker, Nils Ruesch, Partha, Phanx, Rahanprout, Renstrom, RustamIrzaev, SDPhantom, Safturento, Sara.Festung, |cFFA335EEShroudy|r, Sildor, Silverwind, SinaC, Slakah, Soeters, Starlon, Suicidal Katt, |ccf1eff00Swiver|r, Syzgyn, Tekkub, Telroth, Thalyra, Thizzelle, Tia Lynn, Tohveli, Tukz, Tuller, Veev, Villiv, Wetxius, Woffle of Dark Iron, Wrug, Xuerian, Yleaf, Zork, g0st, gi2k15, iSpawnAtHome, m2jest1c, p3lim, sticklord, Bunny67, freesay")

		local titleTrans = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		titleTrans:SetPoint("TOPLEFT", subtitleLegacy, "BOTTOMLEFT", 0, -16)
		titleTrans:SetText("Translation:")

		local subtitleTrans = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		subtitleTrans:SetWidth(400)
		subtitleTrans:SetPoint("TOPLEFT", titleTrans, "BOTTOMLEFT", 0, -8)
		subtitleTrans:SetJustifyH("LEFT")
		subtitleTrans:SetText("Buds")

		local version = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		version:SetPoint("BOTTOMRIGHT", -16, 16)
		version:SetText("Version: "..K.Version)

		self.show = true
	end)

	InterfaceOptions_AddCategory(frame)
end

-- Button in GameMenuButton frame
--local button = CreateFrame("Button", "GameMenuButtonContinue", GameMenuFrame, "GameMenuButtonTemplate")
--button:SetText("|cff388bdbbudsUI|r")
--button:SetPoint("TOP", "GameMenuButtonContinue", "BOTTOM", 0, -13)
--
--GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + button:GetHeight()+ 5)
--button:SetScript("OnClick", function()
--	PlaySound("igMainMenuOption")
--	HideUIPanel(GameMenuFrame)
--	if not UIConfigMain or not UIConfigMain:IsShown() then
--		CreateUIConfig()
--	else
--		UIConfigMain:Hide()
--	end
--end)

do
	SLASH_CONFIG1 = "/kc"
	SLASH_CONFIG2 = "/buds"
	SLASH_CONFIG3 = "/config"
	SLASH_CONFIG4 = "/cfg"
	SLASH_CONFIG5 = "/configui"
	function SlashCmdList.CONFIG(msg, editbox)
		if not UIConfigMain or not UIConfigMain:IsShown() then
			PlaySound("igMainMenuOption")
			CreateUIConfig()
		else
			PlaySound("igMainMenuOption")
			UIConfigMain:Hide()
		end
	end

	-- Button in GameMenuButton frame
	local UIConfigButton = CreateFrame("Frame")
	UIConfigButton:RegisterEvent("PLAYER_LOGIN")
	UIConfigButton:SetScript("OnEvent", function(self, event)

		-- WoW 3.3.5 Compatibility: GameMenuFrame and its child buttons (GameMenuButtonUIOptions,
		-- GameMenuButtonKeybindings) don't exist in WoW 3.3.5. These elements were added in later
		-- expansions. We check for their existence before attempting to integrate our config button
		-- into the game menu. If these elements are missing, the config is still accessible via
		-- the /buds slash command, providing graceful degradation on older clients.
		local Menu = GameMenuFrame
		local Interface = GameMenuButtonUIOptions
		local KeyBinds = GameMenuButtonKeybindings

		-- Early return if GameMenuButtonUIOptions doesn't exist (WoW 3.3.5)
		-- This prevents nil errors when trying to access Interface properties below
		if not Interface then
			return
		end

		local InterfaceX = Interface:GetWidth()
		local InterfaceY = Interface:GetHeight()

		Menu:SetHeight(GameMenuFrame:GetHeight() + UIConfigButton:GetHeight() + 21)

		local button = CreateFrame("BUTTON", "GameMenuTukuiButtonOptions", Menu, "GameMenuButtonTemplate")
		button:SetSize(InterfaceX, InterfaceY)
		button:SetPoint("TOP", Interface, "BOTTOM", 0, -1)
		button:SetText("|cff388bdbbudsUI|r")

		button:SetScript("OnClick", function(self)
			local Config = UIConfigMain
			if Config and Config:IsShown() then
				UIConfigMain:Hide()
			else
				CreateUIConfig()
				HideUIPanel(Menu)
			end
		end)

		-- WoW 3.3.5 Compatibility: GameMenuButtonKeybindings may not exist in older clients
		-- If it exists, reposition it below our custom config button to maintain proper menu layout
		-- If it doesn't exist, the menu will simply not include this repositioning step
		if KeyBinds then
			KeyBinds:ClearAllPoints()
			KeyBinds:SetPoint("TOP", button, "BOTTOM", 0, -1)
		end
	end)
end