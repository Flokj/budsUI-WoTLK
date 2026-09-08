--[[-----------------------------------------------------------------------------
Addon: budsUI
File: Modules/UnitFrames/Elements/Texts.lua
Purpose:
	Text on and around a unit: the name above the health bar, and the health
	and power values centred on their bars.

	Ported from KkthnxUI retail to WoW 3.3.5: health/power numbers are plain
	values here (no secret numbers, no UnitHealthPercent API), driven from
	the bar's own PostUpdate straight into SetFormattedText.
-----------------------------------------------------------------------------]]

local Engine = select(2, ...)
local K, C = Engine:unpack()
local Module = Engine.UnitFrames
local Build = Module.Build

local UnitIsConnected = UnitIsConnected
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local ShortValue = K.ShortValue

local function NewText(parent, size)
	local text = parent:CreateFontString(nil, "OVERLAY")
	K.SetFont(text, size, K.FontOutlineStyle())
	text:SetWordWrap(false)
	return text
end
Module.NewText = NewText

-- A centered label on a shade strip that spans the anchor's width and sits
-- just above it. Shared by the name (over the health bar) and the level
-- (over the portrait) so both are laid out and sized identically. Returns
-- the font string, the strip is attached as text.BG.
function Module.GradientLabel(self, anchor, size, yOffset)
	size = size or 12
	local shade = K.CreateTextShade(self, "BACKGROUND", -2)
	local height = size + 6
	local bottom = (yOffset or 6) - 3

	-- Span the anchor width and sit above it at a fixed height. Sizing from
	-- the name fontstring instead collapsed the strip to nothing on any frame
	-- whose name had not populated yet.
	local holder = shade.Holder
	holder:SetPoint("LEFT", anchor, "LEFT", 0, 0)
	holder:SetPoint("RIGHT", anchor, "RIGHT", 0, 0)
	holder:SetPoint("BOTTOM", anchor, "TOP", 0, bottom)
	holder:SetHeight(height)

	shade:SetColor(K.StripColor[1], K.StripColor[2], K.StripColor[3], K.GradientAlpha.strip)
	shade:Show()

	-- The text lives on the holder, not on the unit frame: the holder is a
	-- child frame, and child frames always draw above their parent's own
	-- regions, so a parented-to-self label would end up under the strip.
	local text = NewText(holder, size)
	text:SetJustifyH("CENTER")
	text:SetPoint("BOTTOM", anchor, "TOP", 0, yOffset or 6)
	text.BG = holder

	return text
end

-- ---------------------------------------------------------------------------
-- Name
-- ---------------------------------------------------------------------------

-- Name above the health bar. Pushed onto the upward stack so it always sits
-- directly on top of health with nothing overlapping it.
function Build.Name(self, size)
	local name = Module.GradientLabel(self, self.Health or self, size or 12)
	-- The explicit |r closes the name colour so the AFK flag keeps its own grey.
	self:Tag(name, "[buds:namecolor][buds:name]|r[buds:afkdnd]")
	self.Name = name
	self.__stackUp = name.BG or name
	return name
end

-- Name on the health bar itself. Group and companion frames use this: they
-- are laid out by a header or packed tight, so nothing may spill outside the
-- frame.
function Build.NameCenter(self, size, yOffset, tag, rightPad)
	local name = NewText(self.Health, size or 11)
	name:SetJustifyH(rightPad and "LEFT" or "CENTER")
	name:SetPoint("LEFT", self.Health, "LEFT", 3, yOffset or 0)
	name:SetPoint("RIGHT", self.Health, "RIGHT", -(rightPad or 3), yOffset or 0)
	self:Tag(name, tag or "[buds:namecolor][buds:name]")
	self.Name = name
	return name
end

-- ---------------------------------------------------------------------------
-- Bar values
-- ---------------------------------------------------------------------------

function Module.UpdateHealthText(element, unit, cur, max)
	local text = element.__kkuiText
	if not text then
		return
	end

	if not UnitIsConnected(unit) then
		text:SetText(PLAYER_OFFLINE)
		return
	end
	if UnitIsDeadOrGhost(unit) then
		text:SetText(DEAD)
		return
	end

	cur = cur or UnitHealth(unit) or 0
	max = max or UnitHealthMax(unit) or 1

	local mode = C.Unitframe.HealthFormat
	if mode == "Current" then
		text:SetText(ShortValue(cur))
	elseif mode == "Percent" then
		if max <= 0 then
			text:SetText("")
		elseif cur >= max then
			text:SetText(ShortValue(cur))
		else
			text:SetFormattedText("%d%%", cur / max * 100)
		end
	else
		if max <= 0 then
			text:SetText("")
		elseif cur >= max then
			-- Full health reads as just the value, no redundant 100%.
			text:SetText(ShortValue(cur))
		else
			text:SetFormattedText("%s - %d%%", ShortValue(cur), cur / max * 100)
		end
	end
end

function Module.UpdatePowerText(element, unit, cur, max)
	local text = element.__kkuiText
	if not text then
		return
	end

	cur = cur or UnitPower(unit) or 0
	max = max or UnitPowerMax(unit) or 1

	local mode = C.Unitframe.PowerFormat
	if mode == "Current" then
		text:SetText(ShortValue(cur))
	elseif mode == "Percent" then
		if max <= 0 then
			text:SetText("")
		else
			text:SetFormattedText("%d%%", cur / max * 100)
		end
	else
		if max <= 0 then
			text:SetText("")
		else
			text:SetFormattedText("%s  %d%%", ShortValue(cur), cur / max * 100)
		end
	end
end

-- Health value, centred on the health bar.
function Build.HealthText(self, size, yOffset, anchor)
	if C.Unitframe.HealthFormat == "None" then
		return
	end
	local text = NewText(self.Health, size or 12)
	if anchor == "RIGHT" then
		text:SetPoint("RIGHT", self.Health, "RIGHT", -3, yOffset or 0)
		text:SetJustifyH("RIGHT")
	else
		text:SetPoint("CENTER", self.Health, "CENTER", 0, yOffset or 0)
		text:SetJustifyH("CENTER")
	end

	self.Health.__kkuiText = text
	self.HealthValue = text
	return text
end

-- Power value, centred on the power bar.
function Build.PowerText(self, size)
	if not self.Power or C.Unitframe.PowerFormat == "None" then
		return
	end
	local text = NewText(self.Power, size or 11)
	text:SetPoint("CENTER", self.Power, "CENTER", 0, 0)
	text:SetJustifyH("CENTER")

	self.Power.__kkuiText = text
	self.PowerValue = text
	return text
end
