--[[-----------------------------------------------------------------------------
Addon: budsUI
File: Modules/UnitFrames/Elements/Bars.lua
Purpose:
	The bar family: health (with an incoming-heals prediction bar), power,
	the druid mana strip while shapeshifted.

	Health and power are separate bordered boxes, so each one owns its own
	background and border rather than sharing one on the parent frame.

	Ported from KkthnxUI retail to WoW 3.3.5:
	- bar smoothing (Enum.StatusBarInterpolation) does not exist, dropped;
	- Midnight secret-value handling is gone;
	- absorb bars are gone (no absorb API); incoming heals ride on
	  UnitGetIncomingHeals when the client provides it.
-----------------------------------------------------------------------------]]

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
local UnitThreatSituation = UnitThreatSituation
local UnitGetIncomingHeals = UnitGetIncomingHeals

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

-- ---------------------------------------------------------------------------
-- Bar shading
-- ---------------------------------------------------------------------------
-- Backdrop tint: the empty part of the bar tinted to a dark version of the
-- fill colour, so an almost dead target still reads as its class. Run from
-- the bar's PostUpdateColor so it always sees the colour oUF just applied.
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

-- ---------------------------------------------------------------------------
-- Health
-- ---------------------------------------------------------------------------

-- Incoming heals ride on top of the health fill. Updated from the health
-- bar's own PostUpdate (oUF's classic core has no prediction element).
local function AddPrediction(health)
	if not UnitGetIncomingHeals then
		return
	end
	local healing = CreateFrame("StatusBar", nil, health)
	healing:SetStatusBarTexture(Module.Texture())
	healing:SetStatusBarColor(0.0, 0.72, 0.35, 0.35)
	healing:SetFrameLevel(health:GetFrameLevel() + 1)
	healing:SetPoint("TOP")
	healing:SetPoint("BOTTOM")
	healing:SetPoint("LEFT", health:GetStatusBarTexture(), "RIGHT", 0, 0)
	healing:SetMinMaxValues(0, 1)
	healing:SetValue(0)
	healing:Show()
	health.HealingPrediction = healing
end

local function UpdatePrediction(health, unit)
	local healing = health.HealingPrediction
	if not healing then
		return
	end
	local incoming = UnitGetIncomingHeals(unit) or 0
	local max = UnitHealthMax(unit)
	if not max or max <= 0 or incoming <= 0 then
		healing:SetValue(0)
		return
	end
	local cur = UnitHealth(unit) or 0
	healing:SetMinMaxValues(0, max)
	healing:SetValue(math.min(cur + incoming, max))
	healing:SetPoint("LEFT", health:GetStatusBarTexture(), "RIGHT", 0, 0)
end

-- ---------------------------------------------------------------------------
-- Health border colour
-- ---------------------------------------------------------------------------
-- Threat and the class colour option both want to own the health border, so
-- neither touches it directly. They set a field and call through here, and
-- this decides: dispel first, then threat, then class, then default.
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

-- Enemy fill override, run after oUF's own colouring. Players and friendly
-- units keep the colour oUF gave them. Enemies get a threat colour when that
-- option is on, and a solid hostile colour otherwise.
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
	UpdatePrediction(element, unit)
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
		health.colorClassPet = true
		health.colorReaction = true
	end
	-- Last link in oUF's colour chain either way. Without it a unit that
	-- matches none of the above keeps whatever colour the bar had last.
	health.colorHealth = true

	if C.Unitframe.HealthPrediction then
		AddPrediction(health)
	end

	self.Health = health

	-- Mouseover and target-select highlights framing the health border.
	if Build.Highlight then
		Build.Highlight(self)
	end

	return health
end

-- ---------------------------------------------------------------------------
-- Power
-- ---------------------------------------------------------------------------

-- gap lets compact frames (raid) sit the power bar tight under health instead
-- of using the standard detached gap. pinBottom anchors the bar to the
-- frame's bottom edge instead of below health, so the caller can let health
-- fill the space above (used by raid so hiding power expands health).
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

-- ---------------------------------------------------------------------------
-- Additional power (druid mana while shapeshifted)
-- ---------------------------------------------------------------------------
-- A thin strip along the bottom of the health bar, driven by classic oUF's
-- AdditionalPower element. Overlaying keeps the frame height stable whether
-- or not the player is in a form that shows it.
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

-- ---------------------------------------------------------------------------
-- Alternative power (boss encounter bars)
-- ---------------------------------------------------------------------------
-- 3.3.5 has no encounter alternate-power API, so this is a no-op kept so the
-- boss style reads unchanged.
function Build.AlternativePower(self)
	return nil
end
