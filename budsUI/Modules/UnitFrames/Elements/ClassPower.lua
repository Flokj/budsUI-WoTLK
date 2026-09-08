--[[-----------------------------------------------------------------------------
Addon: budsUI
File: Modules/UnitFrames/Elements/ClassPower.lua
Purpose:
	Class resources above the player frame: combo points for rogues and
	feral druids, death knight runes.

	Only the widget the player's class can actually use is built, so a
	warrior never reserves empty space above their health bar.

	Ported from KkthnxUI retail to WoW 3.3.5: holy power, chi, soul shards,
	arcane charges, essence, and stagger do not exist here. Combo points ride
	on classic oUF's CPoints element, runes on its Runes element.
-----------------------------------------------------------------------------]]

local Engine = select(2, ...)
local K, C = Engine:unpack()
local Module = Engine.UnitFrames
local Build = Module.Build

local CreateFrame = CreateFrame

local MAX_POINTS = 5
local MAX_RUNES = 6

-- Per-point colours for combo points, a red to green ramp.
local COMBO_COLORS = {
	{ 0.85, 0.27, 0.27 },
	{ 0.90, 0.45, 0.25 },
	{ 0.90, 0.68, 0.28 },
	{ 0.62, 0.80, 0.35 },
	{ 0.35, 0.80, 0.45 },
}

-- Spread `count` segments across the holder width. Called from the element's
-- PostUpdate and again whenever the holder resizes, since the real width only
-- exists after the spawn pass.
local function LayoutSegments(holder, count)
	local bars = holder.bars
	local width = holder:GetWidth()
	if not width or width <= 1 or count < 1 then
		return
	end

	local spacing = C.Unitframe.ClassPower.Spacing
	local barWidth = (width - spacing * (count - 1)) / count

	for i = 1, #bars do
		local bar = bars[i]
		bar:ClearAllPoints()
		bar:SetWidth(barWidth)
		if i == 1 then
			bar:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
			bar:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 0)
		else
			bar:SetPoint("TOPLEFT", bars[i - 1], "TOPRIGHT", spacing, 0)
			bar:SetPoint("BOTTOMLEFT", bars[i - 1], "BOTTOMRIGHT", spacing, 0)
		end
	end

	holder.count = count
end

local function OnHolderResize(holder)
	LayoutSegments(holder, holder.count or 1)
end

-- Build the holder plus its segments. Returns the holder and the segment
-- array; the caller wires whichever oUF element drives them.
local function CreateSegmented(self, total)
	local db = C.Unitframe.ClassPower
	local holder = CreateFrame("Frame", nil, self)
	Module.StackUp(self, holder, db.Height)

	local bars = {}
	for i = 1, total do
		local bar = CreateFrame("StatusBar", nil, holder)
		bar:SetStatusBarTexture(Module.Texture())
		bar:SetMinMaxValues(0, 1)
		bar:SetValue(0)
		K.CreateBackground(bar, 0.08, 0.08, 0.08, 0.9)
		K.CreateBorder(bar, 10)
		bars[i] = bar
	end

	holder.bars = bars
	holder.count = total
	holder:SetScript("OnSizeChanged", OnHolderResize)

	self.ClassPowerHolder = holder
	return holder, bars
end

function Build.ClassPower(self)
	if K.Class ~= "ROGUE" and K.Class ~= "DRUID" then
		return
	end

	local holder, points = CreateSegmented(self, MAX_POINTS)
	LayoutSegments(holder, MAX_POINTS)

	for i = 1, #points do
		local col = COMBO_COLORS[i] or COMBO_COLORS[#COMBO_COLORS]
		points[i]:SetStatusBarColor(col[1], col[2], col[3])
		points[i]:Hide()
	end

	points.PostUpdate = function(element, cp)
		cp = cp or 0
		for i = 1, #element do
			if i <= cp then
				element[i]:SetValue(1)
			else
				element[i]:SetValue(0)
			end
		end
	end

	self.ComboPoints = points
	return points
end

function Build.Runes(self)
	if K.Class ~= "DEATHKNIGHT" then
		return
	end

	local holder, bars = CreateSegmented(self, MAX_RUNES)
	LayoutSegments(holder, MAX_RUNES)

	-- Rune type colours follow budsUI's rune palette when available.
	for i, bar in ipairs(bars) do
		bar:SetStatusBarColor(0.5, 0.5, 0.5)
	end

	self.Runes = holder
	for i, bar in ipairs(bars) do
		holder[i] = bar
	end
	return holder
end

-- No-op on 3.3.5 (monks do not exist). Kept so the player style reads
-- unchanged.
function Build.Stagger(self)
	return nil
end
