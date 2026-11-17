local K, C, L, _ = select(2, ...):unpack()
if C.Aura.CastBy ~= true then return end

local format = string.format
local select = select
local pairs = pairs
local match = string.match
local GetUnitName = GetUnitName
local hooksecurefunc = hooksecurefunc
local UnitClass = UnitClass
local CUSTOM_CLASS_COLORS = CUSTOM_CLASS_COLORS
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local UnitIsPlayer = UnitIsPlayer
local UnitReaction = UnitReaction

-- Tells you who cast a buff or debuff in its tooltip(prButler by Renstrom)
local LABEL_HEX = "|cff3366ff"

local function coloredName(srcUnit)
	local src = GetUnitName(srcUnit, true)
	if srcUnit == "pet" or srcUnit == "vehicle" then
		src = format("%s (|cff%02x%02x%02x%s|r)", src, K.Color.r * 255, K.Color.g * 255, K.Color.b * 255, GetUnitName("player", true))
	else
		local partypet = srcUnit:match("^partypet(%d+)$")
		local raidpet = srcUnit:match("^raidpet(%d+)$")
		if partypet then
			src = format("%s (%s)", src, GetUnitName("party"..partypet, true))
		elseif raidpet then
			src = format("%s (%s)", src, GetUnitName("raid"..raidpet, true))
		end
	end

	if UnitIsPlayer(srcUnit) then
		local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[select(2, UnitClass(srcUnit))]
		if color then
			src = format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, src)
		end
	else
		local color = K.BetterFactionBarColors[UnitReaction(srcUnit, "player")]
		if color then
			src = format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, src)
		end
	end
	return src
end

local function addAuraSource(self, func, unit, index, filter)
	local _, _, _, _, _, _, _, srcUnit, _, _, spellId = func(unit, index, filter)
	local showId = C.Tooltip.SpellID and spellId
	if not srcUnit and not showId then return end

	local src = srcUnit and coloredName(srcUnit)
	if showId then
		local left = src and (LABEL_HEX .. L_TOOLTIP_CAST_BY .. "|r: " .. src) or " "
		self:AddDoubleLine(left, ("%s%s|r: |cffffffff%d|r"):format(LABEL_HEX, L_TOOLTIP_SPELL_ID, spellId))
	elseif src then
		self:AddDoubleLine(LABEL_HEX .. L_TOOLTIP_CAST_BY .. "|r", src)
	else
		return
	end
	self:Show()
end

local funcs = {
	SetUnitAura = UnitAura,
	SetUnitBuff = UnitBuff,
	SetUnitDebuff = UnitDebuff,
}

for k, v in pairs(funcs) do
	hooksecurefunc(GameTooltip, k, function(self, unit, index, filter)
		addAuraSource(self, v, unit, index, filter)
	end)
end