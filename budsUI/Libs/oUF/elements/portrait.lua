--[[ # Element: Portraits
Handles the updating of the unit's portrait. ]]

local _, ns = ...
local oUF = ns.oUF

local SetPortraitTexture = SetPortraitTexture
local UnitGUID = UnitGUID
local UnitIsConnected = UnitIsConnected
local UnitIsUnit = UnitIsUnit
local UnitIsVisible = UnitIsVisible

local function Update(self, event, unit)
	if(not unit or not UnitIsUnit(self.unit, unit)) then return end

	local element = self.Portrait

	-- Callback: Portrait:PreUpdate(unit) - called before the element is updated
	if(element.PreUpdate) then element:PreUpdate(unit) end

	local guid = UnitGUID(unit)
	local isAvailable = UnitIsConnected(unit) and UnitIsVisible(unit)
	if(event ~= 'OnUpdate' or element.guid ~= guid or element.state ~= isAvailable) then
		if(element:IsObjectType('PlayerModel')) then
			if(not isAvailable) then
				element:SetModelScale(4.25)
				element:SetCamera(0)
				element:SetPosition(0, 0, -1.5)
				element:SetModel([[Interface\Buttons\TalkToMeQuestionMark.m2]])
			elseif(element.guid ~= guid or event == 'UNIT_MODEL_CHANGED') then
				element:ClearModel()
				element:SetUnit(unit)
				element:SetModelScale(1)
				element:SetCamera(0)
				element:SetPosition(0, 0, 0)
			else
				element:SetCamera(0)
			end
		else
			SetPortraitTexture(element, unit)
		end

		element.guid = guid
		element.state = isAvailable
	end

	-- Callback: Portrait:PostUpdate(unit) - called after the element is updated
	if(element.PostUpdate) then
		return element:PostUpdate(unit)
	end
end

local function Path(self, ...)
	-- Override: Portrait.Override(self, event, unit) - override the internal update function
	return (self.Portrait.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self, unit)
	local element = self.Portrait
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_PORTRAIT_UPDATE', Path)
		self:RegisterEvent('UNIT_MODEL_CHANGED', Path)
		self:RegisterEvent('UNIT_CONNECTION', Path)

		-- Party members' model updates are handled via PARTY_MEMBER_ENABLE (from quest tracking).
		if(unit == 'party') then
			self:RegisterEvent('PARTY_MEMBER_ENABLE', Path)
		end

		element:Show()

		return true
	end
end

local function Disable(self)
	local element = self.Portrait
	if(element) then
		element:Hide()

		self:UnregisterEvent('UNIT_PORTRAIT_UPDATE', Path)
		self:UnregisterEvent('UNIT_MODEL_CHANGED', Path)
		self:UnregisterEvent('PARTY_MEMBER_ENABLE', Path)
		self:UnregisterEvent('UNIT_CONNECTION', Path)
	end
end

oUF:AddElement('Portrait', Path, Enable, Disable)