-- budsUI :: Modules/UnitFrames/Elements/Texts.lua

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

-- Centered label on a shade strip spanning the anchor's width, just above it.
-- Shared by name (health) and level (portrait); strip attaches as text.BG.
function Module.GradientLabel(self, anchor, size, yOffset)
	size = size or 12

	-- The holder always exists (even transparent): the upward stack anchors to it,
	-- so their position derives from the bar geometry instead of the bare font string.
	local shade = K.CreateTextShade(self, "BACKGROUND", -2)
	local height = size + 6
	local bottom = (yOffset or 6) - 3

	-- Span the anchor width at a fixed height; sizing from the name fontstring collapsed when empty.
	local holder = shade.Holder
	holder:SetPoint("LEFT", anchor, "LEFT", 0, 0)
	holder:SetPoint("RIGHT", anchor, "RIGHT", 0, 0)
	holder:SetPoint("BOTTOM", anchor, "TOP", 0, bottom)
	holder:SetHeight(height)

	if C.Unitframe.NameBackground ~= false then
		shade:SetColor(K.StripColor[1], K.StripColor[2], K.StripColor[3], K.GradientAlpha.strip)
	else
		shade:SetColor(0, 0, 0, 0)
	end
	shade:Show()

	-- Text lives on the holder (a child frame draws above its parent), else it ends up under the strip.
	local text = NewText(holder, size)
	text:SetJustifyH("CENTER")
	text:SetPoint("BOTTOM", anchor, "TOP", 0, yOffset or 6)
	text.BG = holder

	return text
end

-- Name

-- Name above the health bar. Pushed onto the upward stack so it always sits
-- directly on top of health with nothing overlapping it.
function Build.Name(self, size, withLevel)
	local name = Module.GradientLabel(self, self.Health or self, size or 12)
	-- The explicit |r closes the name colour so the AFK flag keeps its own grey.
	if withLevel and not self.PortraitHolder then
		-- No side portrait: level rides after the name, like Kkthnx.
		self:Tag(name, "[buds:namecolor][buds:name]|r [buds:diff][buds:level]|r[buds:afkdnd]")
	else
		self:Tag(name, "[buds:namecolor][buds:name]|r[buds:afkdnd]")
	end
	self.Name = name
	self.__stackUp = name.BG or name
	return name
end

-- Name on the health bar (group/companion frames): nothing may spill outside the frame.
function Build.NameCenter(self, size, yOffset, tag, rightPad)
	local name = NewText(self.Health, size or 11)
	name:SetJustifyH(rightPad and "LEFT" or "CENTER")
	name:SetPoint("LEFT", self.Health, "LEFT", 3, yOffset or 0)
	name:SetPoint("RIGHT", self.Health, "RIGHT", -(rightPad or 3), yOffset or 0)
	self:Tag(name, tag or "[buds:namecolor][buds:name]")
	self.Name = name
	return name
end

-- Bar values

local function HealthColorHex(pct)
	local r, g, b
	if pct < 20 then
		r, g, b = 1, 0.1, 0.1
	elseif pct < 35 then
		r, g, b = 1, 0.5, 0
	elseif pct < 80 then
		r, g, b = 1, 0.9, 0.3
	else
		r, g, b = 1, 1, 1
	end
	return K.RGBToHex(r, g, b)
end

-- Main units show value + threshold-coloured percent; others just the coloured percent (KkthnxUI style).
local function IsMainUnit(unit)
	return unit == "player" or unit == "target" or unit == "focus" or (unit and unit:sub(1, 5) == "party")
end

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
			if IsMainUnit(unit) then
				-- Full health reads as just the value, no redundant 100%.
				text:SetText(ShortValue(cur))
			else
				text:SetFormattedText("%s%d%%|r", HealthColorHex(100), 100)
			end
		else
			local pct = cur / max * 100
			if IsMainUnit(unit) then
				text:SetFormattedText("%s - %s%d%%|r", ShortValue(cur), HealthColorHex(pct), pct)
			else
				text:SetFormattedText("%s%d%%|r", HealthColorHex(pct), pct)
			end
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
