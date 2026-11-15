--[[ # Element: ComboPoints
Handles the visibility and updating of the player's combo points. ]]

local _, ns = ...
local oUF = ns.oUF

local GetComboPoints = GetComboPoints
local UnitHasVehicleUI = UnitHasVehicleUI

local MAX_COMBO_POINTS = MAX_COMBO_POINTS

local function Update(self, event, unit)
	if(unit == 'pet') then return end

	local element = self.ComboPoints

	-- Callback: ComboPoints:PreUpdate() - called before the element is updated
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local cp
	if(UnitHasVehicleUI('player')) then
		cp = GetComboPoints('vehicle', 'target')
	else
		cp = GetComboPoints('player', 'target')
	end

	for i = 1, MAX_COMBO_POINTS do
		if(i <= cp) then
			element[i]:Show()
		else
			element[i]:Hide()
		end
	end

	-- Callback: ComboPoints:PostUpdate(cp) - called after the element is updated
	if(element.PostUpdate) then
		return element:PostUpdate(cp)
	end
end

local function Path(self, ...)
	-- Override: ComboPoints.Override(self, event, ...) - override the internal update function
	return (self.ComboPoints.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local element = self.ComboPoints
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_COMBO_POINTS', Path, true)
		self:RegisterEvent('PLAYER_TARGET_CHANGED', Path, true)

		for index = 1, MAX_COMBO_POINTS do
			local cp = element[index]
			if(cp:IsObjectType('Texture') and not cp:GetTexture()) then
				cp:SetTexture([[Interface\ComboFrame\ComboPoint]])
				cp:SetTexCoord(0, 0.375, 0, 1)
			end
		end

		return true
	end
end

local function Disable(self)
	local element = self.ComboPoints
	if(element) then
		for index = 1, MAX_COMBO_POINTS do
			element[index]:Hide()
		end

		self:UnregisterEvent('UNIT_COMBO_POINTS', Path)
		self:UnregisterEvent('PLAYER_TARGET_CHANGED', Path)
	end
end

oUF:AddElement('ComboPoints', Path, Enable, Disable)