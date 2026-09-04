local K, C, L, _ = select(2, ...):unpack()
if C.Tooltip.Enable ~= true or C.Tooltip.SpellID ~= true then return end

local _G = _G
local match = string.match
local select = select
local tonumber = tonumber
local strfind = string.find
local IsModifierKeyDown = IsModifierKeyDown
local GetSpell, GetText, GetName = GetSpell, GetText, GetName
local GetGlyphSocketInfo = GetGlyphSocketInfo
local hooksecurefunc = hooksecurefunc
local UnitAura = UnitAura

--	Spell/Item IDs(idTip by Silverwind)
local debuginfo = false
local function addLine(self, id, isItem)
	for i = 1, self:NumLines() do
		local line = _G[self:GetName().."TextLeft"..i]
		if not line then break end
		local text = line:GetText()
		if text and (text:match(L_TOOLTIP_ITEM_ID) or text:match(L_TOOLTIP_SPELL_ID)) then return end
	end
	if isItem then
		self:AddLine("|cffffffff"..L_TOOLTIP_ITEM_ID.." "..id)
	else
		self:AddLine("|cffffffff"..L_TOOLTIP_SPELL_ID.." "..id)
	end
	self:Show()
end

GameTooltip:HookScript("OnTooltipSetSpell", function(self)
	local id = select(3, self:GetSpell())
	if id then addLine(self, id) end
end)

hooksecurefunc(GameTooltip, "SetUnitAura", function(self, ...)
	-- WoW 3.3.5 Compatibility: UnitAura returns only 10 values, not 11
	-- spellID (11th value) was added in Cataclysm 4.0
	-- In 3.3.5 we cannot show spell IDs from auras, only spell names
	local name = select(1, UnitAura(...))
	if name and debuginfo == true and IsModifierKeyDown() then 
		K.Print("Aura: "..name.." (SpellID not available in 3.3.5)")
	end
	-- Note: We skip adding the ID line since it's not available in 3.3.5
end)

hooksecurefunc("SetItemRef", function(link, ...)
	local id = tonumber(link:match("spell:(%d+)"))
	if id then addLine(ItemRefTooltip, id) end
end)

hooksecurefunc(GameTooltip, "SetGlyph", function(self, ...)
	local id = select(4, GetGlyphSocketInfo(...))
	if id then addLine(self, id) end
end)

local function attachItemTooltip(self)
	local link = select(2, self:GetItem())
	if not link then return end
	local id = select(3, strfind(link, "^|%x+|Hitem:(%-?%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%-?%d+):(%-?%d+)"))
	if id then addLine(self, id, true) end
end

GameTooltip:HookScript("OnTooltipSetItem", attachItemTooltip)
ItemRefTooltip:HookScript("OnTooltipSetItem", attachItemTooltip)
ItemRefShoppingTooltip1:HookScript("OnTooltipSetItem", attachItemTooltip)
ItemRefShoppingTooltip2:HookScript("OnTooltipSetItem", attachItemTooltip)
ShoppingTooltip1:HookScript("OnTooltipSetItem", attachItemTooltip)
ShoppingTooltip2:HookScript("OnTooltipSetItem", attachItemTooltip)

SlashCmdList.SHOWSPELLID = function()
	if not debuginfo then
		debuginfo = true
	else
		debuginfo = false
	end
end

SLASH_SHOWSPELLID1 = "/showid"
SLASH_SHOWSPELLID2 = "/si"
SLASH_SHOWSPELLID3 = "/ыш"