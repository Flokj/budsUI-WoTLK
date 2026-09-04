local K, C, L = select(2, ...):unpack()
if C.Misc.ItemLevel ~= true then return end

local _G = _G
local pairs = pairs

local GetInventoryItemID = GetInventoryItemID
local GetInventorySlotInfo = GetInventorySlotInfo
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local InCombatLockdown = InCombatLockdown
local IsAddOnLoaded = IsAddOnLoaded

local slots = {
	"HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "WristSlot", 
	"MainHandSlot", "SecondaryHandSlot", "RangedSlot", "HandsSlot",	"WaistSlot", 
	"LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot"
}

local frame = CreateFrame("Frame")
local updatePendingCombat = false

local function CreateButtonsText(baseName)
	for _, slot in pairs(slots) do
		local button = _G[baseName..slot]
		if button and not button.t then
			local font, _, flags = NumberFontNormal:GetFont()
			button.t = button:CreateFontString(nil, "OVERLAY")
			button.t:SetFont(font, 12, flags)
			button.t:SetPoint("TOP", button, "TOP", 0, -3)
			button.t:SetText("")
		end
	end
end

local function UpdateButtonsText(baseName)
	local unit
	if baseName == "Character" then
		unit = "player"
		if InCombatLockdown() then
			updatePendingCombat = true
			frame:RegisterEvent("PLAYER_REGEN_ENABLED")
			return
		end
	elseif baseName == "Inspect" then
		if not (InspectFrame and InspectFrame:IsShown()) then return end
		unit = InspectFrame.unit
	end

	if not unit then return end

	for _, slot in pairs(slots) do
		local button = _G[baseName..slot]
		if button and button.t then
			local slotID = GetInventorySlotInfo(slot)
			local itemID = GetInventoryItemID(unit, slotID)

			if itemID then
				local _, _, rarity, itemLevel = GetItemInfo(itemID)
				if itemLevel then
					button.t:SetText(itemLevel)
					if rarity and rarity > 1 then
						local r, g, b = GetItemQualityColor(rarity)
						button.t:SetTextColor(r, g, b)
					else
						button.t:SetTextColor(1, 1, 1)
					end
				end
			else
				button.t:SetText("")
			end
		end
	end
end

local function InitInspectUI()
	CreateButtonsText("Inspect")
	InspectFrame:HookScript("OnShow", function()
		UpdateButtonsText("Inspect")
	end)
	if hooksecurefunc then
		hooksecurefunc("InspectFrame_UnitChanged", function()
			UpdateButtonsText("Inspect")
		end)
	end
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")

frame:SetScript("OnEvent", function(self, event, arg1)
	if event == "PLAYER_LOGIN" then
		CreateButtonsText("Character")
		UpdateButtonsText("Character")

		if IsAddOnLoaded("Blizzard_InspectUI") or InspectFrame then
			InitInspectUI()
		else
			self:RegisterEvent("ADDON_LOADED")
		end

	elseif event == "ADDON_LOADED" and arg1 == "Blizzard_InspectUI" then
		InitInspectUI()
		self:UnregisterEvent("ADDON_LOADED")

	elseif event == "UNIT_INVENTORY_CHANGED" then
		if arg1 == "player" then
			UpdateButtonsText("Character")
		elseif InspectFrame and InspectFrame:IsShown() and arg1 == InspectFrame.unit then
			UpdateButtonsText("Inspect")
		end

	elseif event == "GET_ITEM_INFO_RECEIVED" then
		UpdateButtonsText("Character")
		if InspectFrame and InspectFrame:IsShown() then
			UpdateButtonsText("Inspect")
		end

	elseif event == "PLAYER_REGEN_ENABLED" then
		if updatePendingCombat then
			updatePendingCombat = false
			UpdateButtonsText("Character")
		end
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
end)