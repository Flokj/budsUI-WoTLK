--[[ # Element: Resting Indicator
Toggles indicator visibility based on the player's resting status. ]]

local _, ns = ...
local oUF = ns.oUF

local function Update(self, event)
	local element = self.RestingIndicator

	-- Callback: RestingIndicator:PreUpdate() - called before the element is updated
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local isResting = IsResting()
	if(isResting) then
		element:Show()
	else
		element:Hide()
	end

	-- Callback: RestingIndicator:PostUpdate(isResting) - called after the element is updated
	if(element.PostUpdate) then
		return element:PostUpdate(isResting)
	end
end

local function Path(self, ...)
	-- Override: RestingIndicator.Override(self, event) - override the internal update function
	return (self.RestingIndicator.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self, unit)
	local element = self.RestingIndicator
	if(element and UnitIsUnit(unit, 'player')) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('PLAYER_UPDATE_RESTING', Path, true)

		if(element:IsObjectType('Texture') and not element:GetTexture()) then
			element:SetTexture([[Interface\CharacterFrame\UI-StateIcon]])
			element:SetTexCoord(0, 0.5, 0, 0.421875)
		end

		return true
	end
end

local function Disable(self)
	local element = self.RestingIndicator
	if(element) then
		element:Hide()

		self:UnregisterEvent('PLAYER_UPDATE_RESTING', Path)
	end
end

oUF:AddElement('RestingIndicator', Path, Enable, Disable)
