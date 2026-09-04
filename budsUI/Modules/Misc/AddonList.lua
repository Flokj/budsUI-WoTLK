local K, C, L, _ = select(2, ...):unpack()

local _G = _G
local unpack = unpack
local select = select
local sort = table.sort
local tinsert = table.insert
local GetAddOnInfo = GetAddOnInfo
local CreateFrame = CreateFrame
local UIParent = UIParent
local GetNumAddOns = GetNumAddOns
local GetAddOnDependencies = GetAddOnDependencies
local InCombatLockdown = InCombatLockdown
local EnableAllAddOns = EnableAllAddOns
local DisableAddOn = DisableAddOn
local EnableAddOn = EnableAddOn
local ReloadUI = ReloadUI

local AddonList
local menuWasShown

local CloseButton
local EnableAllButton
local ReloadButton
local DisableAllButton
local ScrollFrame, ScrollBar

local function CreateAddonsList()
	if AddonList then return end

	AddonList = CreateFrame("Frame", "AddonList", UIParent)
	tinsert(UISpecialFrames, "AddonList")
	AddonList:SetSize(385, 512)
	AddonList:SetPoint("CENTER", UIParent, 0, 24)
	AddonList:EnableMouse(true)
	AddonList:SetMovable(true)
	AddonList:SetUserPlaced(false)
	AddonList:SetClampedToScreen(true)
	AddonList:SetScript("OnMouseDown", function(self) self:StartMoving() end)
	AddonList:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)
	AddonList:SetFrameStrata("DIALOG")

	CloseButton = CreateFrame("Button", "AddonListCloseButton", AddonList, "UIPanelCloseButton")
	CloseButton:SetSize(30, 30)
	CloseButton:SetPoint("TOPRIGHT", AddonList, "TOPRIGHT", 5, -4)
	CloseButton:SetScript("OnClick", function() AddonList:Hide() end)

	local t = AddonList:CreateTexture(nil, "BACKGROUND")
	t:SetTexture([[Interface\HelpFrame\HelpFrame-TopLeft]])
	t:SetSize(128, 256)
	t:SetPoint("TOPLEFT")

	t = AddonList:CreateTexture(nil, "BACKGROUND")
	t:SetTexture([[Interface\HelpFrame\HelpFrame-Top]])
	t:SetSize(177, 256)
	t:SetPoint("TOPLEFT", 128, 0)

	t = AddonList:CreateTexture(nil, "BACKGROUND")
	t:SetTexture([[Interface\HelpFrame\HelpFrame-TopRight]])
	t:SetSize(128, 256)
	t:SetPoint("TOPRIGHT", 48, 0)

	t = AddonList:CreateTexture(nil, "BACKGROUND")
	t:SetTexture([[Interface\HelpFrame\HelpFrame-Bottom]])
	t:SetSize(177, 256)
	t:SetPoint("BOTTOMLEFT", 128, 0)

	t = AddonList:CreateTexture(nil, "BACKGROUND")
	t:SetTexture([[Interface\HelpFrame\HelpFrame-BotLeft]])
	t:SetSize(128, 256)
	t:SetPoint("BOTTOMLEFT")

	t = AddonList:CreateTexture(nil, "BACKGROUND")
	t:SetTexture([[Interface\HelpFrame\HelpFrame-BotRight]])
	t:SetSize(128, 256)
	t:SetPoint("BOTTOMRIGHT", 48, 0)

	t = AddonList:CreateTexture(nil, "ARTWORK")
	t:SetTexture([[Interface\DialogFrame\UI-DialogBox-Header]])
	t:SetSize(328, 64)
	t:SetPoint("TOP", 0, 12)

	local title = AddonList:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOP", t, 0, -14)
	title:SetText("AddOns")

	local info = AddonList:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	info:SetPoint("TOPLEFT", 26, -30)
	info:SetPoint("RIGHT", -22, -30)

	ScrollFrame = CreateFrame("ScrollFrame", "AddonListScrollFrame", AddonList, "UIPanelScrollFrameTemplate")
	ScrollBar = _G["AddonListScrollFrameScrollBar"]
	local MainAddonFrame = CreateFrame("Frame", "AddonListFrame", ScrollFrame)

	ScrollFrame:SetPoint("TOPLEFT", AddonList, "TOPLEFT", 5, -58)
	ScrollFrame:SetPoint("BOTTOMRIGHT", AddonList, "BOTTOMRIGHT", -32, 52)
	ScrollFrame:SetScrollChild(MainAddonFrame)

	local UpdateAddonList = function()
		local self = MainAddonFrame
		self:SetPoint("TOPLEFT")
		self:SetWidth(ScrollFrame:GetWidth())
		self:SetHeight(ScrollFrame:GetHeight())
		self.addons = self.addons or {}

		for i = 1, GetNumAddOns() do
			self.addons[i] = select(1, GetAddOnInfo(i))
		end
		sort(self.addons)

		local oldb
		local countAll, countOn, countOff = 0, 0, 0

		for i, v in ipairs(self.addons) do
			local name, title, notes, enabled, loadable, reason = GetAddOnInfo(v)

			if name then
				local CheckButtonName = "AddonListEntry" .. i
				local CheckButton = _G[CheckButtonName]
				if not CheckButton then
					CheckButton = CreateFrame("CheckButton", CheckButtonName, self, "OptionsCheckButtonTemplate")
				end
				CheckButton:SetChecked(enabled)

				CheckButton:EnableMouse(true)
				CheckButton:Enable()

				CheckButton.title = title .. "|n"
				CheckButton.tooltip = ""
				if notes then
					CheckButton.tooltip = CheckButton.tooltip .. "|cffffffff" .. notes .. "|r|n"
				end
				if GetAddOnDependencies(v) then
					CheckButton.tooltip = CheckButton.tooltip .. "|n|cffff4400Dependencies: |r"
					for j = 1, select("#", GetAddOnDependencies(v)) do
						CheckButton.tooltip = CheckButton.tooltip .. select(j, GetAddOnDependencies(v))
						if j > 1 then
							CheckButton.tooltip = CheckButton.tooltip .. ", "
						end
					end
					CheckButton.tooltip = CheckButton.tooltip .. "|r"
				end

				if i == 1 then
					CheckButton:SetPoint("TOPLEFT", self, "TOPLEFT", 10, -10)
				else
					CheckButton:SetPoint("TOP", oldb, "BOTTOM", 0, 6)
				end

				CheckButton:SetScript("OnEnter", function(self)
					GameTooltip:ClearLines()
					GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
					GameTooltip:AddLine(self.title, nil, nil, nil, true)
					if self.tooltip and self.tooltip ~= "" then
						GameTooltip:AddLine(self.tooltip, nil, nil, nil, true)
					end
					GameTooltip:Show()
				end)
				CheckButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

				CheckButton:SetScript("OnClick", function()
					local _, _, _, enabled = GetAddOnInfo(name)
					if enabled then
						DisableAddOn(name)
					else
						EnableAddOn(name)
					end
				end)

				if loadable and (enabled and (reason == "DEP_DEMAND_LOADED" or reason == "DEMAND_LOADED")) then
					_G[CheckButtonName .. "Text"]:SetTextColor(1.0, 0.78, 0.0)
					countOff = countOff + 1
				elseif enabled and reason == "DEP_DISABLED" then
					_G[CheckButtonName .. "Text"]:SetTextColor(1.0, 0.1, 0.1)
					countOff = countOff + 1
				elseif enabled then
					_G[CheckButtonName .. "Text"]:SetTextColor(1.0, 1.0, 1.0)
					countOn = countOn + 1
				else
					countOff = countOff + 1
					_G[CheckButtonName .. "Text"]:SetTextColor(0.5, 0.5, 0.5)
				end

				countAll = countAll + 1
				_G[CheckButtonName .. "Text"]:SetText(title)
				oldb = CheckButton
			end
		end

		info:SetText(string.format("|cffffffff%d|r AddOns: |cffffffff%d|r |cff00ff00Enabled|r, |cffffffff%d|r |cffff0000Disabled|r", countAll, countOn, countOff))
	end

	AddonList:SetScript("OnShow", function()
		PlaySound("igMainMenuOption")
		UpdateAddonList()
	end)

	AddonList:SetScript("OnHide", function(self)
		PlaySound("igMainMenuOptionCheckBoxOn")
		self:ClearAllPoints()
		self:SetPoint("CENTER", UIParent, 0, 24)
		if menuWasShown then
			ShowUIPanel(GameMenuFrame)
			menuWasShown = nil
		end
	end)

	AddonList:Hide()

	ReloadButton = CreateFrame("Button", "AddonListReloadButton", AddonList, "UIPanelButtonTemplate")
	ReloadButton:SetSize(105, 21)
	ReloadButton:SetPoint("BOTTOM", AddonList, "BOTTOM", 0, 21)
	ReloadButton:SetText("Reload UI")
	ReloadButton:SetScript("OnClick", function() ReloadUI() end)

	EnableAllButton = CreateFrame("Button", "AddonListEnableAllButton", AddonList, "UIPanelButtonTemplate")
	EnableAllButton:SetSize(105, 21)
	EnableAllButton:SetPoint("BOTTOMLEFT", AddonList, "BOTTOMLEFT", 7, 21)
	EnableAllButton:SetText("Enable All")
	EnableAllButton:SetScript("OnClick", function()
		EnableAllAddOns()
		UpdateAddonList()
	end)

	DisableAllButton = CreateFrame("Button", "AddonListDisableAllButton", AddonList, "UIPanelButtonTemplate")
	DisableAllButton:SetSize(105, 21)
	DisableAllButton:SetPoint("BOTTOMRIGHT", AddonList, "BOTTOMRIGHT", -6, 21)
	DisableAllButton:SetText("Disable All")
	DisableAllButton:SetScript("OnClick", function()
		for _, v in pairs(MainAddonFrame.addons) do
			local name = GetAddOnInfo(v)
			if name then
				DisableAddOn(name)
			end
		end
		UpdateAddonList()
	end)
end

local function OpenAddonList()
	if InCombatLockdown() then
		if ERR_NOT_IN_COMBAT then
			DEFAULT_CHAT_FRAME:AddMessage("|cffffe02e" .. ERR_NOT_IN_COMBAT .. "|r")
		end
		return
	end
	CreateAddonsList()
	PlaySound("igMainMenuOption")
	if GameMenuFrame and GameMenuFrame:IsShown() then
		menuWasShown = true
		HideUIPanel(GameMenuFrame)
	end
	AddonList:Show()
end

SLASH_KPACKADDONLIST1 = "/addons"
SLASH_KPACKADDONLIST2 = "/acp"
SlashCmdList["KPACKADDONLIST"] = function()
	OpenAddonList()
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	if not GameMenuFrame then return end

	local AddonListButton = CreateFrame("Button", "GameMenuButtonAddOns", GameMenuFrame, "GameMenuButtonTemplate")
	AddonListButton:SetText("AddOns")

	if GameMenuButtonMacros then
		AddonListButton:SetPoint("TOP", GameMenuButtonMacros, "BOTTOM", 0, -1)
	end
	AddonListButton:SetScript("OnClick", OpenAddonList)

	local offset = 26
	if _G.GameMenuButtonMoveAnything then
		offset = offset + 26
		_G.GameMenuButtonMoveAnything:ClearAllPoints()
		_G.GameMenuButtonMoveAnything:SetPoint("TOP", AddonListButton, "BOTTOM", 0, -1)
		if GameMenuButtonLogout then
			GameMenuButtonLogout:SetPoint("TOP", _G.GameMenuButtonMoveAnything, "BOTTOM", 0, -16)
		end
	elseif GameMenuButtonLogout then
		GameMenuButtonLogout:SetPoint("TOP", AddonListButton, "BOTTOM", 0, -16)
	end

	GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + offset)
end)