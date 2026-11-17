local K, C, L, _ = select(2, ...):unpack()
if C.Tooltip.Enable ~= true or C.Tooltip.ItemCount ~= true then return end

local GetItemCount = GetItemCount
local CreateFrame = CreateFrame

local ItemCountConfig = {count = true}
local LABEL_HEX = "|cff3366ff"
local function labeled(label, value)
	return ("%s%s|r: |cffffffff%d|r"):format(LABEL_HEX, label, value)
end

--	Item count in tooltip(by Tukz)
GameTooltip:HookScript("OnTooltipCleared", function(self) self.UIItemTooltip = nil end)
GameTooltip:HookScript("OnTooltipSetItem", function(self)
	if ItemCountConfig and not self.UIItemTooltip and ItemCountConfig.count then
		local _, link = self:GetItem()
		local inBags = GetItemCount(link)
		local inBank = GetItemCount(link, true) - inBags
		local item_count
		if inBank > 0 and inBags > 0 then
			item_count = labeled(L_TOOLTIP_ITEM_COUNT_BAG, inBags) .. "  " .. labeled(L_TOOLTIP_ITEM_COUNT_BANK, inBank)
		elseif inBank > 0 then
			item_count = labeled(L_TOOLTIP_ITEM_COUNT_BANK, inBank)
		elseif inBags > 0 then
			item_count = labeled(L_TOOLTIP_ITEM_COUNT_BAG, inBags)
		end

		self.UIItemTooltip = 1
		if item_count then
			if C.Tooltip.SpellID then
				local id = link:match("|Hitem:(%d+):")
				if id then
					self:AddDoubleLine(item_count, labeled(L_TOOLTIP_ITEM_ID, id))
					return
				end
			end
			self:AddLine(item_count)
		end
	end
end)

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, name)
	if name ~= "budsUI" then return end
	f:UnregisterEvent("ADDON_LOADED")
	f:SetScript("OnEvent", nil)
	-- ItemCountConfig is already initialized, we can keep it local
end)