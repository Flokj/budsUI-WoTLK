local K, C, L, _ = select(2, ...):unpack()
if C.Tooltip.Enable ~= true or C.Tooltip.ItemCount ~= true then return end

local GetItemCount = GetItemCount
local CreateFrame = CreateFrame

local ItemCountConfig = {count = true}
--	Item count in tooltip(by Tukz)
GameTooltip:HookScript("OnTooltipCleared", function(self) self.UIItemTooltip = nil end)
GameTooltip:HookScript("OnTooltipSetItem", function(self)
	if ItemCountConfig and not self.UIItemTooltip and ItemCountConfig.count then
		local item, link = self:GetItem()
		local num = GetItemCount(link, true)
		local item_count = ""

		if ItemCountConfig.count and num > 1 then
			item_count = "|cffffffff"..L_TOOLTIP_ITEM_COUNT.." "..num
		end

		self:AddLine(item_count)
		self.UIItemTooltip = 1
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