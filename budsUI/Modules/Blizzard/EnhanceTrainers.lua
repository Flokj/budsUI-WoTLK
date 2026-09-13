--[[-----------------------------------------------------------------------------
Addon: budsUI
File: Modules/Blizzard/EnhanceTrainers.lua
Purpose:
	Enhanced class trainer window, ported from Leatrix Plus (WotLK):
	double-wide frame, taller skill list with extra rows and a
	"Train All" button with cost tooltip.

	Leatrix's ElvUI compatibility block is intentionally dropped:
	budsUI is not ElvUI and never loads its skins.
-----------------------------------------------------------------------------]]

local K, C, L, _ = select(2, ...):unpack()

if not C["Blizzard"].EnhanceTrainers then return end

local _G = _G
local CreateFrame = CreateFrame
local IsAddOnLoaded = IsAddOnLoaded

local GetNumTrainerServices = GetNumTrainerServices
local GetTrainerServiceInfo = GetTrainerServiceInfo
local GetTrainerServiceCost = GetTrainerServiceCost
local BuyTrainerService = BuyTrainerService
local GetCoinTextureString = GetCoinTextureString

local TRADEWIN_TOP = [[Interface\AddOns\]] .. K.Directory .. [[\Media\Textures\TradeSkill\Leatrix_Plus.blp]]
local DETAIL_BG = [[Interface\AddOns\]] .. K.Directory .. [[\Media\Textures\TradeSkill\Parchment.blp]]

-- Increased height of the skill trainer frame and extra skills listed
local tall, numTallTrainers = 73, 17

local function EnhancedTrainer()
	-- Make the frame double-wide
	UIPanelWindows["ClassTrainerFrame"] = { area = "override", pushable = 0, xoffset = 0, yoffset = 12, bottomClampOverride = 140 + 12, width = 714, height = 487, whileDead = 1 }

	-- Size the frame
	_G["ClassTrainerFrame"]:SetSize(714, 487 + tall)

	-- Lower title text slightly
	_G["ClassTrainerNameText"]:ClearAllPoints()
	_G["ClassTrainerNameText"]:SetPoint("TOP", _G["ClassTrainerFrame"], "TOP", 0, -18)

	-- Expand the skill list to full height
	_G["ClassTrainerListScrollFrame"]:ClearAllPoints()
	_G["ClassTrainerListScrollFrame"]:SetPoint("TOPLEFT", _G["ClassTrainerFrame"], "TOPLEFT", 25, -75)
	_G["ClassTrainerListScrollFrame"]:SetSize(295, 336 + tall)

	-- Create additional list rows
	do
		local oldSkillsDisplayed = CLASS_TRAINER_SKILLS_DISPLAYED

		-- Position existing buttons
		for i = 1 + 1, CLASS_TRAINER_SKILLS_DISPLAYED do
			_G["ClassTrainerSkill" .. i]:ClearAllPoints()
			_G["ClassTrainerSkill" .. i]:SetPoint("TOPLEFT", _G["ClassTrainerSkill" .. (i - 1)], "BOTTOMLEFT", 0, 1)
		end

		-- Create and position new buttons
		_G.CLASS_TRAINER_SKILLS_DISPLAYED = _G.CLASS_TRAINER_SKILLS_DISPLAYED + numTallTrainers
		for i = oldSkillsDisplayed + 1, CLASS_TRAINER_SKILLS_DISPLAYED do
			local button = CreateFrame("Button", "ClassTrainerSkill" .. i, ClassTrainerFrame, "ClassTrainerSkillButtonTemplate")
			button:SetID(i)
			button:Hide()
			button:ClearAllPoints()
			button:SetPoint("TOPLEFT", _G["ClassTrainerSkill" .. (i - 1)], "BOTTOMLEFT", 0, 1)
		end

		hooksecurefunc("ClassTrainer_SetToTradeSkillTrainer", function()
			_G.CLASS_TRAINER_SKILLS_DISPLAYED = _G.CLASS_TRAINER_SKILLS_DISPLAYED + numTallTrainers
			ClassTrainerListScrollFrame:SetHeight(336 + tall)
			ClassTrainerDetailScrollFrame:SetHeight(336 + tall)
		end)

		hooksecurefunc("ClassTrainer_SetToClassTrainer", function()
			_G.CLASS_TRAINER_SKILLS_DISPLAYED = _G.CLASS_TRAINER_SKILLS_DISPLAYED + numTallTrainers - 1
			ClassTrainerListScrollFrame:SetHeight(336 + tall)
			ClassTrainerDetailScrollFrame:SetHeight(336 + tall)
		end)

		-- 3.3.5: keep the skill buttons at full width (Blizzard shrinks them
		-- when the scrollbar hides, which overlapped the old layout)
		hooksecurefunc("ClassTrainerFrame_Update", function()
			for i = 1, CLASS_TRAINER_SKILLS_DISPLAYED do
				local skillButton = _G["ClassTrainerSkill" .. i]
				if skillButton then
					skillButton:SetWidth(293)
				end
			end
		end)
	end

	-- Set highlight bar width when shown
	hooksecurefunc(_G["ClassTrainerSkillHighlightFrame"], "Show", function()
		ClassTrainerSkillHighlightFrame:SetWidth(290)
	end)

	-- Move the detail frame to the right and stretch it to full height
	_G["ClassTrainerDetailScrollFrame"]:ClearAllPoints()
	_G["ClassTrainerDetailScrollFrame"]:SetPoint("TOPLEFT", _G["ClassTrainerFrame"], "TOPLEFT", 352, -74)
	_G["ClassTrainerDetailScrollFrame"]:SetSize(296, 336 + tall)

	-- Hide detail scroll frame textures
	_G["ClassTrainerDetailScrollFrameTop"]:SetAlpha(0)
	_G["ClassTrainerDetailScrollFrameBottom"]:SetAlpha(0)

	-- Hide expand tab (left of All button)
	_G["ClassTrainerExpandTabLeft"]:Hide()

	-- Get frame textures
	local regions = { _G["ClassTrainerFrame"]:GetRegions() }

	-- Set top left texture (wide art shipped from Leatrix Plus)
	regions[2]:SetTexture(TRADEWIN_TOP)
	regions[2]:SetTexCoord(0.25, 0.75, 0, 1)
	regions[2]:SetSize(512, 512)

	-- Set top right texture
	regions[3]:ClearAllPoints()
	regions[3]:SetPoint("TOPLEFT", regions[2], "TOPRIGHT", 0, 0)
	regions[3]:SetTexture(TRADEWIN_TOP)
	regions[3]:SetTexCoord(0.75, 1, 0, 1)
	regions[3]:SetSize(256, 512)

	-- Hide bottom left and bottom right textures
	regions[4]:Hide()
	regions[5]:Hide()

	-- Hide skills list dividing bar
	regions[9]:Hide()
	ClassTrainerHorizontalBarLeft:Hide()

	-- Set skills list backdrop
	local RecipeInset = _G["ClassTrainerFrame"]:CreateTexture(nil, "ARTWORK")
	RecipeInset:SetSize(304, 361 + tall)
	RecipeInset:SetPoint("TOPLEFT", _G["ClassTrainerFrame"], "TOPLEFT", 16, -72)
	RecipeInset:SetTexture("Interface\\RAIDFRAME\\UI-RaidFrame-GroupBg")

	-- Set detail frame backdrop
	local DetailsInset = _G["ClassTrainerFrame"]:CreateTexture(nil, "ARTWORK")
	DetailsInset:SetSize(302, 339 + tall)
	DetailsInset:SetPoint("TOPLEFT", _G["ClassTrainerFrame"], "TOPLEFT", 348, -72)
	DetailsInset:SetTexture(DETAIL_BG)

	-- Move bottom button row
	_G["ClassTrainerTrainButton"]:ClearAllPoints()
	_G["ClassTrainerTrainButton"]:SetPoint("RIGHT", _G["ClassTrainerCancelButton"], "LEFT", -1, 0)

	-- Position and size close button
	_G["ClassTrainerCancelButton"]:SetSize(80, 22)
	_G["ClassTrainerCancelButton"]:SetText(CLOSE)
	_G["ClassTrainerCancelButton"]:ClearAllPoints()
	_G["ClassTrainerCancelButton"]:SetPoint("BOTTOMRIGHT", _G["ClassTrainerFrame"], "BOTTOMRIGHT", -42, 54)

	-- Position close box
	_G["ClassTrainerFrameCloseButton"]:ClearAllPoints()
	_G["ClassTrainerFrameCloseButton"]:SetPoint("TOPRIGHT", _G["ClassTrainerFrame"], "TOPRIGHT", -30, -8)

	-- Position dropdown menu
	ClassTrainerFrameFilterDropDown:ClearAllPoints()
	ClassTrainerFrameFilterDropDown:SetPoint("TOPLEFT", ClassTrainerFrame, "TOPLEFT", 501, -40)

	-- Position money frame, hide the greeting line above the list
	ClassTrainerMoneyFrame:ClearAllPoints()
	ClassTrainerMoneyFrame:SetPoint("TOPLEFT", _G["ClassTrainerFrame"], "TOPLEFT", 143, -49)
	ClassTrainerGreetingText:Hide()

	----------------------------------------------------------------------
	-- Train All button
	----------------------------------------------------------------------

	local trainAllButton = CreateFrame("Button", "budsUITrainAllButton", ClassTrainerFrame, "UIPanelButtonTemplate")
	trainAllButton:SetSize(110, 22)
	trainAllButton:SetText(L_TRAIN_ALL or "Train All")
	trainAllButton:SetPoint("BOTTOMLEFT", ClassTrainerFrame, "BOTTOMLEFT", 344, 54)

	trainAllButton:SetScript("OnEnter", function(self)
		local count, cost = 0, 0
		for i = 1, GetNumTrainerServices() do
			local _, _, isAvail = GetTrainerServiceInfo(i)
			if isAvail == "available" then
				count = count + 1
				cost = cost + GetTrainerServiceCost(i)
			end
		end
		if count > 0 then
			GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 4)
			GameTooltip:ClearLines()
			if count > 1 then
				GameTooltip:AddLine(string.format(L_TRAIN_ALL_TOOLTIP_PLURAL or "Train %d skills for %s", count, GetCoinTextureString(cost)))
			else
				GameTooltip:AddLine(string.format(L_TRAIN_ALL_TOOLTIP_SINGLE or "Train skill for %s", GetCoinTextureString(cost)))
			end
			GameTooltip:Show()
		end
	end)

	trainAllButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	trainAllButton:SetScript("OnClick", function()
		for i = 1, GetNumTrainerServices() do
			local _, _, isAvail = GetTrainerServiceInfo(i)
			if isAvail == "available" then
				BuyTrainerService(i)
			end
		end
	end)

	-- Show/hide per option, enable only when skills are available
	hooksecurefunc("ClassTrainerFrame_Update", function()
		if C["Blizzard"].TrainAllButton then
			trainAllButton:Show()
		else
			trainAllButton:Hide()
			return
		end
		local skillsAvailable = false
		for i = 1, GetNumTrainerServices() do
			local _, _, isAvail = GetTrainerServiceInfo(i)
			if isAvail == "available" then
				skillsAvailable = true
				break
			end
		end
		if skillsAvailable then
			trainAllButton:Enable()
		else
			trainAllButton:Disable()
		end
		if trainAllButton:IsMouseOver() and skillsAvailable then
			trainAllButton:GetScript("OnEnter")(trainAllButton)
		end
	end)
end

-- Run once the Blizzard trainer UI has loaded
if IsAddOnLoaded("Blizzard_TrainerUI") then
	EnhancedTrainer()
else
	local waitFrame = CreateFrame("Frame")
	waitFrame:RegisterEvent("ADDON_LOADED")
	waitFrame:SetScript("OnEvent", function(self, _, arg1)
		if arg1 == "Blizzard_TrainerUI" then
			EnhancedTrainer()
			waitFrame:UnregisterAllEvents()
		end
	end)
end
