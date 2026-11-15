-- budsUI :: Modules/UnitFrames/Elements/Bars.lua

local Engine = select(2, ...)
local K, C = Engine:unpack()
local Module = Engine.UnitFrames
local Build = Module.Build
local oUF = Engine.oUF or _G.budsUF

local CreateFrame = CreateFrame
local UnitClass = UnitClass
local UnitIsPlayer = UnitIsPlayer
local UnitReaction = UnitReaction
local UnitCanAttack = UnitCanAttack
local UnitGUID = UnitGUID
local UnitThreatSituation = UnitThreatSituation

-- A bordered status bar box: our backdrop, border, and addon texture.
-- The empty part of the bar shows the backdrop, matching the rest of the UI.
local function CreateBox(parent, height)
	local bar = CreateFrame("StatusBar", nil, parent)
	bar:SetStatusBarTexture(Module.Texture())
	if height then
		bar:SetHeight(height)
	end
	K.CreateGradientBackground(bar, 0.9)
	K.CreateBorder(bar)
	return bar
end
Module.CreateBox = CreateBox

-- Bar shading
-- Backdrop tint: empty bar part tinted dark like the fill; runs from PostUpdateColor.
local BACKDROP_TINT = 0.22
local BACKDROP_ALPHA = 0.9

local function AddBackdropTint(bar)
	local tint = bar:CreateTexture(nil, "BACKGROUND", nil, -6)
	tint:SetTexture(Module.Texture())
	tint:SetAllPoints()
	tint:SetVertexColor(0.2, 0.2, 0.2, BACKDROP_ALPHA)
	bar.KKUI_Tint = tint
	return tint
end

local function ShadeBar(bar)
	if not bar.KKUI_Tint then
		return
	end
	local texture = bar:GetStatusBarTexture()
	if not texture then
		return
	end
	local r, g, b = texture:GetVertexColor()
	if not r then
		return
	end
	bar.KKUI_Tint:SetVertexColor(r * BACKDROP_TINT, g * BACKDROP_TINT, b * BACKDROP_TINT, BACKDROP_ALPHA)
end

local function AddShading(bar)
	if C.Unitframe.BarBackdrop then
		AddBackdropTint(bar)
		return true
	end
	return false
end

-- Health

-- Incoming heals + absorbs ride over the health fill as own/other/absorb segments.
-- State lives in Module.HealPrediction; this file only refreshes from the bar's PostUpdate.
local function RefreshPrediction(health, unit)
	if not health.prediction then
		return
	end
	local HealPrediction = Module.HealPrediction
	if not HealPrediction then
		return
	end
	local guid = unit and UnitGUID(unit)
	if not guid then
		return
	end
	HealPrediction.Follow(health)
	HealPrediction.Refresh(health, guid, unit, C.Unitframe.HealthPrediction, C.Unitframe.AbsorbShields)
end

-- Health border colour
-- Threat and class colour own it via fields, decided here: dispel > threat > class > default.
local function UnitBorderColor(frame, unit)
	local colors = frame.colors
	if not colors then
		return nil
	end

	if UnitIsPlayer(unit) then
		local _, class = UnitClass(unit)
		if class then
			return colors.class[class]
		end
		return nil
	end

	local reaction = UnitReaction(unit, "player")
	if reaction then
		return colors.reaction[reaction]
	end
	return nil
end

function Module.RefreshHealthBorder(self)
	local health = self.Health
	if not health or not health.SetBackdropBorderColor then
		return
	end

	-- Border priority for a healer's eyes: a dispellable debuff wins over
	-- threat, which wins over the optional class-coloured border.
	local color = self.__dispelColor or self.__threatColor
	if not color and C.Unitframe.ClassColorBorder then
		color = self.__unitColor
	end

	if color then
		if color.GetRGB then
			health:SetBackdropBorderColor(color:GetRGB())
		else
			health:SetBackdropBorderColor(color[1], color[2], color[3])
		end
	else
		health:SetBackdropBorderColor()
	end
end

-- Enemy fill override after oUF: players/friendlies keep oUF's colour; enemies get threat or hostile colour.
local function ColorEnemyFill(element, unit)
	if UnitIsPlayer(unit) then
		return
	end

	if not UnitCanAttack("player", unit) then
		return -- friendly npc: leave oUF's reaction colour
	end

	if C.Unitframe.ThreatHealthColor then
		local status = UnitThreatSituation("player", unit)
		if status then
			local color = K.ThreatFillColor(status, K.PlayerIsTank())
			if color then
				element:SetStatusBarColor(color[1], color[2], color[3])
				return
			end
		end
	end
end

local function OnHealthColor(element, unit)
	local frame = element.__owner
	frame.__unitColor = UnitBorderColor(frame, unit)
	Module.RefreshHealthBorder(frame)

	if element.__shaded then
		ShadeBar(element)
	end

	ColorEnemyFill(element, unit)
end

local function OnHealthUpdate(element, unit, cur, max)
	RefreshPrediction(element, unit)
	if element.__kkuiText then
		Module.UpdateHealthText(element, unit, cur, max)
	end
end

function Build.Health(self, height)
	local health = CreateBox(self, height)
	health:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
	health:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
	health.__shaded = AddShading(health)
	health.PostUpdateColor = OnHealthColor
	health.PostUpdate = OnHealthUpdate

	health.colorDisconnected = true
	health.colorTapping = true
	if C.Unitframe.ClassHealth then
		health.colorClass = true
		-- No colorClassPet: pets/vehicles report a bogus UnitClass in 3.3.5
		-- (warlock imp -> mage, other demons -> paladin). Reaction covers them.
		health.colorReaction = true
	end
	-- Last link in oUF's colour chain either way. Without it a unit that
	-- matches none of the above keeps whatever colour the bar had last.
	health.colorHealth = true

	if C.Unitframe.HealthPrediction or C.Unitframe.AbsorbShields then
		local HealPrediction = Module.HealPrediction
		if HealPrediction and HealPrediction.CreateBars then
			HealPrediction.CreateBars(health)
		end
	end

	self.Health = health

	-- Mouseover and target-select highlights framing the health border.
	if Build.Highlight then
		Build.Highlight(self)
	end

	return health
end

-- Power

-- gap: compact frames sit power tight under health; pinBottom anchors the bar to
-- the frame bottom instead of below health (raid, so hiding power expands health).
function Build.Power(self, height, gap, pinBottom)
	if not height or height <= 0 then
		return
	end

	gap = gap or Module.GAP
	local power = CreateBox(self, height)
	if pinBottom then
		power:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
		power:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
	else
		power:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 0, -gap)
		power:SetPoint("TOPRIGHT", self.Health, "BOTTOMRIGHT", 0, -gap)
	end
	power.colorPower = true
	power.frequentUpdates = true

	if AddShading(power) then
		power.PostUpdateColor = ShadeBar
	end

	local PostUpdate = power.PostUpdate
	power.PostUpdate = function(element, unit, cur, max)
		if PostUpdate then
			PostUpdate(element, unit, cur, max)
		end
		if element.__kkuiText then
			Module.UpdatePowerText(element, unit, cur, max)
		end
	end

	self.Power = power
	return power
end

-- Additional power (druid mana while shapeshifted)
-- Thin strip along the health bottom via oUF's AdditionalPower; overlay keeps height stable.
function Build.AdditionalPower(self)
	if select(2, UnitClass("player")) ~= "DRUID" then
		return
	end

	local bar = CreateFrame("StatusBar", nil, self.Health)
	bar:SetStatusBarTexture(Module.Texture())
	bar:SetHeight(4)
	bar:SetFrameLevel(self.Health:GetFrameLevel() + 3)
	bar:SetPoint("BOTTOMLEFT", self.Health, "BOTTOMLEFT", 0, 0)
	bar:SetPoint("BOTTOMRIGHT", self.Health, "BOTTOMRIGHT", 0, 0)
	bar.colorPower = true

	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetTexture(0, 0, 0, 0.6)

	self.AdditionalPower = bar
	return bar
end

-- Alternative power (boss encounter bars)
-- 3.3.5 has no alternate-power API; a no-op so the boss style reads unchanged.
function Build.AlternativePower(self)
	return nil
end
