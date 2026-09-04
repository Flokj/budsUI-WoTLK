local K, C, L, _ = select(2, ...):unpack()
if C.Automation.SellGreyRepair ~= true then return end

local format, strsub = string.format, string.sub
local select = select
local CanGuildBankRepair = CanGuildBankRepair
local CanMerchantRepair = CanMerchantRepair
local CreateFrame = CreateFrame
local GetContainerItemLink, GetContainerNumSlots = GetContainerItemLink, GetContainerNumSlots
local GetGuildBankWithdrawMoney = GetGuildBankWithdrawMoney
local GetItemInfo, GetItemCount = GetItemInfo, GetItemCount
local GetMoney = GetMoney
local GetNumPartyMembers = GetNumPartyMembers
local GetRepairAllCost = GetRepairAllCost
local RepairAllItems = RepairAllItems
local UseContainerItem = UseContainerItem

-- Auto repair and sell grey items
local itemCount, sellValue = 0, 0

local SellGreyRepair = CreateFrame("frame")
SellGreyRepair:RegisterEvent("MERCHANT_SHOW")
SellGreyRepair:SetScript("OnEvent", function(self, event)
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local item = GetContainerItemLink(bag, slot)
			if item then
				local _, _, itemRarity, _, _, _, _, _, _, _, itemSellPrice = GetItemInfo(item)

				if itemSellPrice and itemRarity == 0 then
					local itemValue = itemSellPrice * GetItemCount(item)
					ShowMerchantSellCursor(1)
					UseContainerItem(bag, slot)

					itemCount = itemCount + GetItemCount(item)
					sellValue = sellValue + itemValue
				end
			end
		end
	end

	if sellValue > 0 then
		K.Print(format(L_SELL_TRASH, itemCount, itemCount ~= 1 and "s" or "", K.FormatMoney(sellValue)))
		itemCount, sellValue = 0, 0
	end

	if CanMerchantRepair() then
		local cost, needed = GetRepairAllCost()
		if needed then
			local GuildWealth = CanGuildBankRepair() and GetGuildBankWithdrawMoney() > cost
			if GuildWealth and GetNumPartyMembers() > 5 then
				RepairAllItems(1)
				K.Print(format(L_REPAIR_BANK, K.FormatMoney(cost)))
			elseif cost < GetMoney() then
				RepairAllItems()
				K.Print(format(L_REPAIRED_FOR, K.FormatMoney(cost)))
			else
				K.Print(L_CANT_AFFORD_REPAIR)
			end
		end
	end
end)
