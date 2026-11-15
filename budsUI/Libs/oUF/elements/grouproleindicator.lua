--[[ # Element: Group Role Indicator
Toggles indicator visibility based on the unit's group role (tank, healer or damager). ]]

local _, ns = ...
local oUF = ns.oUF

local UnitGroupRolesAssigned = UnitGroupRolesAssigned

local function Update(self, event)
	local element = self.GroupRoleIndicator

	-- Callback: GroupRoleIndicator:PreUpdate() - called before the element is updated
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local isTank, isHealer, isDamage = UnitGroupRolesAssigned(self.unit)
	if(isTank or isHealer or isDamage) then
		local role = isTank and "tank" or isHealer and "healer" or isDamage and "dps"
		element:SetTexture("Interface\\AddOns\\ElvUI\\media\\textures\\" .. role)
		element:Show()
	else
		element:Hide()
	end

	-- Callback: GroupRoleIndicator:PostUpdate(isTank, isHealer, isDamage) - called after the element is updated
	if(element.PostUpdate) then
		return element:PostUpdate(isTank, isHealer, isDamage)
	end
end

local function Path(self, ...)
	-- Override: GroupRoleIndicator.Override(self, event, ...) - override the internal update function
	return (self.GroupRoleIndicator.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self)
	local element = self.GroupRoleIndicator
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		if(self.unit == 'player') then
			self:RegisterEvent('PLAYER_ROLES_ASSIGNED', Path, true)
		else
			self:RegisterEvent('PARTY_MEMBERS_CHANGED', Path, true)
		end

		if(element:IsObjectType('Texture') and not element:GetTexture()) then
			element:SetTexture([[Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES]])
		end

		return true
	end
end

local function Disable(self)
	local element = self.GroupRoleIndicator
	if(element) then
		element:Hide()

		self:UnregisterEvent('PLAYER_ROLES_ASSIGNED', Path)
		self:UnregisterEvent('PARTY_MEMBERS_CHANGED', Path)
	end
end

oUF:AddElement('GroupRoleIndicator', Path, Enable, Disable)