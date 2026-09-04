local K, _ = select(2, ...):unpack()

local _G = _G
local select = select
local find = string.find
local IsAltKeyDown = IsAltKeyDown
local GetItemInfo = GetItemInfo

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