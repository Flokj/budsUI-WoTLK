--[[ # Element: HappinessIndicator
Handles the visibility and updating of player pet happiness. ]]

local _, ns = ...
local oUF = ns.oUF

local GetPetHappiness = GetPetHappiness
local HasPetUI = HasPetUI

local function Update(self, event, unit)
	if(not unit or self.unit ~= unit) then return end

	local element = self.HappinessIndicator

	-- Callback: HappinessIndicator:PreUpdate() - called before the element is updated
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local _, hunterPet = HasPetUI()
	local happiness, damagePercentage = GetPetHappiness()

	if(hunterPet and happiness) then
		if(happiness == 1) then
			element:SetTexCoord(0.375, 0.5625, 0, 0.359375)
		elseif(happiness == 2) then
			element:SetTexCoord(0.1875, 0.375, 0, 0.359375)
		elseif(happiness == 3) then
			element:SetTexCoord(0, 0.1875, 0, 0.359375)
		end

		element:Show()
	else
		return element:Hide()
	end

	-- Callback: HappinessIndicator:PostUpdate(unit, happiness, damagePercentage) - called after the element is updated
	if(element.PostUpdate) then
		return element:PostUpdate(unit, happiness, damagePercentage)
	end
end

local function Path(self, ...)
	-- Override: HappinessIndicator.Override(self, event, ...) - override the internal update function
	return (self.HappinessIndicator.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local element = self.HappinessIndicator
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_HAPPINESS', Path)

		if(element:IsObjectType('Texture') and not element:GetTexture()) then
			element:SetTexture([[Interface\PetPaperDollFrame\UI-PetHappiness]])
		end

		return true
	end
end

local function Disable(self)
	local element = self.HappinessIndicator
	if(element) then
		element:Hide()

		self:UnregisterEvent('UNIT_HAPPINESS', Path)
	end
end

oUF:AddElement('HappinessIndicator', Path, Enable, Disable)