local K, C, L, _ = select(2, ...):unpack()

local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc
local SetCVar = SetCVar

-- Kill all stuff on default UI that we don't need
local frame = CreateFrame("Frame", nil, UIParent)
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon, ...)

	if addon == "Blizzard_AchievementUI" then
		if C.Tooltip.Enable then
			hooksecurefunc("AchievementFrameCategories_DisplayButton", function(button) button.showTooltipFunc = nil end)
		end
	end

	CharacterModelFrameRotateLeftButton:Kill()
	CharacterModelFrameRotateRightButton:Kill()
	if addon == "Blizzard_InspectUI" then
		if InspectFrame then
			InspectModelRotateLeftButton:Kill()
			InspectModelRotateRightButton:Kill()
		end
	end

	-- Don't kill UI scale controls - causes errors in Blizzard code
	-- budsUI overrides scale in PixelPerfect.lua anyway
	-- VideoOptionsResolutionPanelUIScaleSlider:Kill()
	-- VideoOptionsResolutionPanelUseUIScale:Kill()
	
	TutorialFrameAlertButton:Kill()
	
	-- Disable TalkingHeadFrame to prevent Blizzard creatureID errors
	if TalkingHeadFrame then
		TalkingHeadFrame:UnregisterAllEvents()
		TalkingHeadFrame:Hide()
		TalkingHeadFrame:HookScript("OnShow", function(self) self:Hide() end)
	end

	if C.Chat.Enable then
		InterfaceOptionsSocialPanelChatStyle:EnableMouse(false)
		InterfaceOptionsSocialPanelChatStyleButton:Hide()
		InterfaceOptionsSocialPanelChatStyle:SetAlpha(0)
	end

	if not (IsAddOnLoaded("Stuf") or IsAddOnLoaded("PitBull4") or IsAddOnLoaded("ShadowedUnitFrames") or IsAddOnLoaded("XPerl")) then
		PartyMemberBackground:Kill()
		InterfaceOptionsUnitFramePanelPartyBackground:Kill()
	end

	if C.Minimap.Enable then
		InterfaceOptionsDisplayPanelRotateMinimap:Kill()
	end

	if C.ActionBar.Enable then
		InterfaceOptionsActionBarsPanelBottomLeft:Kill()
		InterfaceOptionsActionBarsPanelBottomRight:Kill()
		InterfaceOptionsActionBarsPanelRight:Kill()
		InterfaceOptionsActionBarsPanelRightTwo:Kill()
		InterfaceOptionsActionBarsPanelAlwaysShowActionBars:Kill()
	end

	if not (IsAddOnLoaded("Stuf") or IsAddOnLoaded("PitBull4") or IsAddOnLoaded("ShadowedUnitFrames") or IsAddOnLoaded("XPerl")) then
		SetCVar("fullSizeFocusFrame", 1)
		InterfaceOptionsUnitFramePanelFullSizeFocusFrame:Kill()
	end

	if C.Nameplate.Enable then
		InterfaceOptionsCombatPanelEnemyCastBarsOnNameplates:Kill()
		SetCVar("ShowClassColorInNameplate", 1)
		if C.Nameplate.EnhanceThreat == true then
			InterfaceOptionsDisplayPanelAggroWarningDisplay:Kill()
		end
	end
end)