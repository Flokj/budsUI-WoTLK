--[[ # Element: Raid Role Indicator
Handles indicator visibility and updating based on the unit's raid assignment (main tank or main assist). ]]

local _, ns = ...
local oUF = ns.oUF

local MAINTANK_ICON = [[Interface\GROUPFRAME\UI-GROUP-MAINTANKICON]]
local MAINASSIST_ICON = [[Interface\GROUPFRAME\UI-GROUP-MAINASSISTICON]]

local function Update(self, event)
	local element = self.RaidRoleIndicator
	local unit = self.unit

	-- Callback: RaidRoleIndicator:PreUpdate() - called before the element is updated
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local role, isShown
	if(UnitInRaid(unit) and not UnitHasVehicleUI(unit)) then
		if(GetPartyAssignment('MAINTANK', unit)) then
			isShown = true
			role = 'MAINTANK'
			element:SetTexture(MAINTANK_ICON)
		elseif(GetPartyAssignment('MAINASSIST', unit)) then
			isShown = true
			role = 'MAINASSIST'
			element:SetTexture(MAINASSIST_ICON)
		end
	end

	if element.combatHide and UnitAffectingCombat(unit) then
		element:Hide()
	elseif isShown then
		element:Show()
	else
		element:Hide()
	end

	-- Callback: RaidRoleIndicator:PostUpdate(role) - called after the element is updated
	if(element.PostUpdate) then
		return element:PostUpdate(role)
	end
end

local function Path(self, ...)
	-- Override: RaidRoleIndicator.Override(self, event, ...) - override the internal update function
	return (self.RaidRoleIndicator.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self)
	local element = self.RaidRoleIndicator
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_FLAGS', Path)
		self:RegisterEvent('PARTY_MEMBERS_CHANGED', Path, true)
		self:RegisterEvent('PLAYER_REGEN_DISABLED', Path, true)
		self:RegisterEvent('PLAYER_REGEN_ENABLED', Path, true)

		return true
	end
end

local function Disable(self)
	local element = self.RaidRoleIndicator
	if(element) then
		element:Hide()

		self:UnregisterEvent('UNIT_FLAGS', Path)
		self:UnregisterEvent('PARTY_MEMBERS_CHANGED', Path)
		self:UnregisterEvent('PLAYER_REGEN_DISABLED', Path)
		self:UnregisterEvent('PLAYER_REGEN_ENABLED', Path)
	end
end

oUF:AddElement('RaidRoleIndicator', Path, Enable, Disable)
