local K, C = select(2, ...):unpack()

local _G = _G
local select = select
local find = string.find
local IsAltKeyDown = IsAltKeyDown
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetMerchantItemLink = GetMerchantItemLink
local GetBuybackItemLink = GetBuybackItemLink

-- ALT+RightClick to buy a stack
local _MerchantItemButton_OnModifiedClick = MerchantItemButton_OnModifiedClick
function MerchantItemButton_OnModifiedClick(self, ...)
	if IsAltKeyDown() then
		local id = self:GetID()
		local link = GetMerchantItemLink(id)

		if link then
			local maxStack = select(8, GetItemInfo(link))

			if maxStack and maxStack > 1 then
				local stack = GetMerchantItemMaxStack(id)

				if stack > 1 then
					BuyMerchantItem(id, stack)
					return
				else
					local _, _, _, quantity, numAvailable = GetMerchantItemInfo(id)
					quantity = math.ceil(maxStack / quantity)

					if numAvailable > -1 and numAvailable < quantity then
						quantity = numAvailable
					end

					if quantity > 1 then
						BuyMerchantItem(id, quantity)
						return
					end
				end
			end

			BuyMerchantItem(id)
			return
		end
	end
	_MerchantItemButton_OnModifiedClick(self, ...)
end

-- Item level on vendor goods (same filter as bags: wearable gear only)
if C.Misc.ItemLevel then
	local ilvlFrame = CreateFrame("Frame")

	local function GetButtonText(button)
		local text = button.BudsItemLevel
		if not text then
			local font, _, flags = NumberFontNormal:GetFont()
			text = button:CreateFontString(nil, "OVERLAY")
			text:SetFont(font, 12, flags)
			text:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
			button.BudsItemLevel = text
		end
		return text
	end

	local function UpdateMerchantIlvl()
		if not MerchantFrame or not MerchantFrame:IsShown() then return end
		for i = 1, MERCHANT_ITEMS_PER_PAGE do
			local index = (MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE + i
			local button = _G["MerchantItem" .. i .. "ItemButton"]
			if button then
				local text = GetButtonText(button)
				text:SetText("")
				if button:IsShown() then
					local link = GetMerchantItemLink(index)
					if link then
						local _, _, rarity, itemLevel, _, _, _, _, equipLoc = GetItemInfo(link)
						if itemLevel and itemLevel > 1 and rarity and rarity > 1 and equipLoc and equipLoc ~= ""
							and equipLoc ~= "INVTYPE_BAG" and equipLoc ~= "INVTYPE_TABARD"
							and equipLoc ~= "INVTYPE_AMMO" and equipLoc ~= "INVTYPE_QUIVER" then
							local r, g, b = GetItemQualityColor(rarity)
							text:SetText(itemLevel)
							text:SetTextColor(r, g, b)
						end
					end
				end
			end
		end
	end

	local function UpdateBuybackIlvl()
		if not MerchantFrame or not MerchantFrame:IsShown() then return end
		for index = 1, BUYBACK_ITEMS_PER_PAGE do
			local button = _G["MerchantItem" .. index .. "ItemButton"]
			if button then
				local text = GetButtonText(button)
				text:SetText("")
				if button:IsShown() then
					local link = GetBuybackItemLink(index)
					if link then
						local _, _, rarity, itemLevel, _, _, _, _, equipLoc = GetItemInfo(link)
						if itemLevel and itemLevel > 1 and rarity and rarity > 1 and equipLoc and equipLoc ~= ""
							and equipLoc ~= "INVTYPE_BAG" and equipLoc ~= "INVTYPE_TABARD"
							and equipLoc ~= "INVTYPE_AMMO" and equipLoc ~= "INVTYPE_QUIVER" then
							local r, g, b = GetItemQualityColor(rarity)
							text:SetText(itemLevel)
							text:SetTextColor(r, g, b)
						end
					end
				end
			end
		end
	end

	hooksecurefunc("MerchantFrame_UpdateMerchantInfo", UpdateMerchantIlvl)
	hooksecurefunc("MerchantFrame_UpdateBuybackInfo", UpdateBuybackIlvl)

	ilvlFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
	ilvlFrame:SetScript("OnEvent", function()
		if MerchantFrame and MerchantFrame:IsShown() then
			if MerchantFrame.selectedTab == 1 then
				UpdateMerchantIlvl()
			else
				UpdateBuybackIlvl()
			end
		end
	end)
end