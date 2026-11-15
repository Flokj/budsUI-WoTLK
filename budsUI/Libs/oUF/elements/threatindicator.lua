--[[ # Element: Threat Indicator
Handles indicator visibility and updating based on the unit's current threat level. ]]

local _, ns = ...
local oUF = ns.oUF
local Private = oUF.Private

local unitExists = Private.unitExists

local UnitThreatSituation = UnitThreatSituation

local function Update(self, event, unit)
	if(unit ~= self.unit) then return end

	local element = self.ThreatIndicator
	-- Callback: ThreatIndicator:PreUpdate(unit) - called before the element is updated
	if(element.PreUpdate) then element:PreUpdate(unit) end

	local feedbackUnit = element.feedbackUnit
	unit = unit or self.unit

	local status
	-- BUG: Non-existent '*target' or '*pet' units cause UnitThreatSituation() errors
	if(unitExists(unit)) then
		if(feedbackUnit and feedbackUnit ~= unit and unitExists(feedbackUnit)) then
			status = UnitThreatSituation(feedbackUnit, unit)
		else
			status = UnitThreatSituation(unit)
		end
	end

	local r, g, b
	if(status and status > 0) then
		local color = self.colors.threat[status]
		r, g, b = color.r, color.g, color.b

		if(element.SetVertexColor) then
			element:SetVertexColor(r, g, b)
		end

		element:Show()
	else
		element:Hide()
	end

	-- Callback: ThreatIndicator:PostUpdate(unit, status, r, g, b) - called after the element is updated
	if(element.PostUpdate) then
		return element:PostUpdate(unit, status, r, g, b)
	end
end

local function Path(self, ...)
	-- Override: ThreatIndicator.Override(self, event, ...) - override the internal update function
	return (self.ThreatIndicator.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local element = self.ThreatIndicator
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_THREAT_SITUATION_UPDATE', Path)
		self:RegisterEvent('UNIT_THREAT_LIST_UPDATE', Path)

		if(element:IsObjectType('Texture') and not element:GetTexture()) then
			element:SetTexture([[Interface\RAIDFRAME\UI-RaidFrame-Threat]])
		end

		return true
	end
end

local function Disable(self)
	local element = self.ThreatIndicator
	if(element) then
		element:Hide()

		self:UnregisterEvent('UNIT_THREAT_SITUATION_UPDATE', Path)
		self:UnregisterEvent('UNIT_THREAT_LIST_UPDATE', Path)
	end
end

oUF:AddElement('ThreatIndicator', Path, Enable, Disable)