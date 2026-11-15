--[[ Element: Additional Power Bar - handles the visibility and updating of a status bar that displays the player's additional power (e.g. druid Mana). ]]

if(select(2, UnitClass('player')) ~= 'DRUID') then return end

local _, ns = ...
local oUF = ns.oUF

-- ElvUI block
local unpack = unpack
local UnitIsPlayer = UnitIsPlayer
local UnitClass = UnitClass
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitHasVehicleUI = UnitHasVehicleUI
local UnitPowerType = UnitPowerType
-- end block

-- sourced from FrameXML/AlternatePowerBar.lua
local ADDITIONAL_POWER_BAR_NAME = ADDITIONAL_POWER_BAR_NAME or 'MANA'
local ADDITIONAL_POWER_BAR_INDEX = ADDITIONAL_POWER_BAR_INDEX or 0

local function UpdateColor(self, event, unit, powertype)
	if(not (unit and unit == 'player') and powertype == ADDITIONAL_POWER_BAR_NAME) then return end
	local element = self.AdditionalPower

	local r, g, b, t
	if(element.colorPower) then
		t = self.colors.power[ADDITIONAL_POWER_BAR_INDEX]
	elseif(element.colorClass and UnitIsPlayer(unit)) then
		local _, class = UnitClass(unit)
		t = self.colors.class[class]
	elseif(element.colorSmooth) then
		r, g, b = self:ColorGradient(element.cur or 1, element.max or 1, unpack(element.smoothGradient or self.colors.smooth))
	end

	if(t) then
		r, g, b = t[1], t[2], t[3]
	end

	if(b) then
		element:SetStatusBarColor(r, g, b)

		local bg = element.bg
		if(bg) then
			local mu = bg.multiplier or 1
			bg:SetVertexColor(r * mu, g * mu, b * mu)
		end
	end

	if(element.PostUpdateColor) then
		element:PostUpdateColor(unit, r, g, b)
	end
end

local function ColorPath(self, ...)
	--[[ Override: AdditionalPower.UpdateColor(self, event, unit, ...) - fully override the widgets' color update function. --]]
	(self.AdditionalPower.UpdateColor or UpdateColor) (self, ...)
end

local function Update(self, event, unit, powertype)
	if(not (unit and unit == 'player') and powertype == ADDITIONAL_POWER_BAR_NAME) then return end

	local element = self.AdditionalPower
	--[[ Callback: AdditionalPower:PreUpdate(unit) - called before the element has been updated. --]]
	if(element.PreUpdate) then
		element:PreUpdate(unit)
	end

	local cur = UnitPower('player', ADDITIONAL_POWER_BAR_INDEX)
	local max = UnitPowerMax('player', ADDITIONAL_POWER_BAR_INDEX)

	element:SetMinMaxValues(0, max)
	element:SetValue(cur)

	element.cur = cur
	element.max = max

	--[[ Callback: AdditionalPower:PostUpdate(unit, cur, max) - called after the element has been updated. --]]
	if(element.PostUpdate) then
		return element:PostUpdate(unit, cur, max, event) -- ElvUI adds event
	end
end

local function Path(self, ...)
	--[[ Override: AdditionalPower.Override(self, event, unit, ...) - fully override the element's update process. --]]
	(self.AdditionalPower.Override or Update) (self, ...)

	ColorPath(self, ...)
end

local function ElementEnable(self)
	local element = self.AdditionalPower

	self:RegisterEvent('UNIT_MANA', Path)
	self:RegisterEvent('UNIT_MAXMANA', Path)

	element:Show()

	-- ElvUI block
	if element.PostUpdateVisibility then
		element:PostUpdateVisibility(true, not element.isEnabled)
	end

	element.isEnabled = true
	-- end block

	Path(self, 'ElementEnable', 'player', ADDITIONAL_POWER_BAR_NAME)
end

local function ElementDisable(self)
	self:UnregisterEvent('UNIT_MAXMANA', Path)
	self:UnregisterEvent('UNIT_MANA', Path)

	self.AdditionalPower:Hide()

	-- ElvUI block
	local element = self.AdditionalPower
	if element.PostUpdateVisibility then
		element:PostUpdateVisibility(false, element.isEnabled)
	end

	element.isEnabled = nil
	-- end block

	Path(self, 'ElementDisable', 'player', ADDITIONAL_POWER_BAR_NAME)
end

local function Visibility(self, event, unit)
	local element = self.AdditionalPower
	local shouldEnable

	if(not UnitHasVehicleUI('player')) then
		if((UnitPowerType('player') ~= ADDITIONAL_POWER_BAR_INDEX) and (UnitPowerMax('player', ADDITIONAL_POWER_BAR_INDEX) ~= 0)) then
			shouldEnable = true
		end
	end

	if(shouldEnable) then
		ElementEnable(self)
	else
		ElementDisable(self)
	end
end

local function VisibilityPath(self, ...)
	--[[ Override: AdditionalPower.OverrideVisibility(self, event, unit) - fully override the element's visibility update process. --]]
	(self.AdditionalPower.OverrideVisibility or Visibility) (self, ...)
end

local function ForceUpdate(element)
	VisibilityPath(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self, unit)
	local element = self.AdditionalPower
	if(element and unit == 'player') then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_DISPLAYPOWER', VisibilityPath)

		if(element:IsObjectType('StatusBar') and not element:GetStatusBarTexture()) then
			element:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
		end

		return true
	end
end

local function Disable(self)
	local element = self.AdditionalPower
	if(element) then
		ElementDisable(self)

		self:UnregisterEvent('UNIT_DISPLAYPOWER', VisibilityPath)
	end
end

oUF:AddElement('AdditionalPower', VisibilityPath, Enable, Disable)