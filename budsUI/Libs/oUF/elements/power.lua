--[[ Element: Power Bar - handles the updating of a status bar that displays the unit's power. ]]

local _, ns = ...
local oUF = ns.oUF

local unpack = unpack

local GetPetHappiness = GetPetHappiness
local UnitClass = UnitClass
local UnitIsConnected = UnitIsConnected
local UnitIsPlayer = UnitIsPlayer
local UnitIsTapped = UnitIsTapped
local UnitIsTappedByPlayer = UnitIsTappedByPlayer
local UnitIsUnit = UnitIsUnit
local UnitPlayerControlled = UnitPlayerControlled
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType
local UnitReaction = UnitReaction

local function UpdateColor(self, event, unit)
	if(self.unit ~= unit) then return end
	local element = self.Power

	local ptype, ptoken, altR, altG, altB = UnitPowerType(unit)
	local r, g, b, t
	if(element.colorDisconnected and element.disconnected) then
		t = self.colors.disconnected
	elseif(element.colorTapping and not UnitPlayerControlled(unit) and (UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) and not UnitIsTappedByAllThreatList(unit))) then
		t = self.colors.tapped
	elseif(element.colorThreat and not UnitPlayerControlled(unit) and UnitThreatSituation('player', unit)) then
		t =  self.colors.threat[UnitThreatSituation('player', unit)]
	elseif(element.colorHappiness and UnitIsUnit(unit, 'pet') and GetPetHappiness()) then
		t = self.colors.happiness[GetPetHappiness()]
	elseif(element.colorPower) then
		t = self.colors.power[ptoken or ptype]
		if(not t) then
			if(element.GetAlternativeColor) then
				r, g, b = element:GetAlternativeColor(unit, ptype, ptoken, altR, altG, altB)
			elseif(altR) then
				r, g, b = altR, altG, altB
			end
		end
	elseif(element.colorClass and UnitIsPlayer(unit)) or
		(element.colorClassNPC and not UnitIsPlayer(unit)) or
		(element.colorClassPet and UnitPlayerControlled(unit) and not UnitIsPlayer(unit)) then
		local _, class = UnitClass(unit)
		t = self.colors.class[class]
	elseif(element.colorReaction and UnitReaction(unit, 'player')) then
		t = self.colors.reaction[UnitReaction(unit, 'player')]
	elseif(element.colorSmooth) then
		r, g, b = self:ColorGradient(element.cur or 1, element.max or 1, unpack(element.smoothGradient or self.colors.smooth))
	end

	if(t) then
		r, g, b = t[1], t[2], t[3]
	end

	element:SetStatusBarTexture(element.texture)

	if(b) then
		element:SetStatusBarColor(r, g, b)
	end

	local bg = element.bg
	if(bg and b) then
		local mu = bg.multiplier or 1
		bg:SetVertexColor(r * mu, g * mu, b * mu)
	end

	if(element.PostUpdateColor) then
		element:PostUpdateColor(unit, r, g, b)
	end
end

local function ColorPath(self, ...)
	--[[ Override: Power.UpdateColor(self, event, unit) - fully override the widgets' color update function. --]]
	(self.Power.UpdateColor or UpdateColor) (self, ...)
end

local function Update(self, event, unit)
	if(self.unit ~= unit) then return end
	local element = self.Power

	--[[ Callback: Power:PreUpdate(unit) - called before the element has been updated. --]]
	if(element.PreUpdate) then
		element:PreUpdate(unit)
	end

	local cur, max = UnitPower(unit), UnitPowerMax(unit)
	local disconnected = not UnitIsConnected(unit)
	if max == 0 then
		max = 1
	end

	element:SetMinMaxValues(0, max)

	if(disconnected) then
		element:SetValue(max)
	else
		element:SetValue(cur)
	end

	element.cur = cur
	element.max = max
	element.disconnected = disconnected

	--[[ Callback: Power:PostUpdate(unit, cur, max) - called after the element has been updated. --]]
	if(element.PostUpdate) then
		element:PostUpdate(unit, cur, max)
	end
end

local function Path(self, ...)
	--[[ Override: Power.Override(self, event, unit, ...) - fully override the internal update function. --]]
	(self.Power.Override or Update) (self, ...);

	ColorPath(self, ...)
end

local function ForceUpdate(element)
	Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

--[[ Power:SetColorDisconnected(state) - toggles coloring if the unit is offline. --]]
local function SetColorDisconnected(element, state)
	if(element.colorDisconnected ~= state) then
		element.colorDisconnected = state
		if(element.colorDisconnected) then
			element.__owner:RegisterEvent('UNIT_CONNECTION', ColorPath)
		else
			element.__owner:UnregisterEvent('UNIT_CONNECTION', ColorPath)
		end
	end
end

--[[ Power:SetColorTapping(state) - toggles coloring if the unit isn't tapped by the player. --]]
local function SetColorTapping(element, state)
	if(element.colorTapping ~= state) then
		element.colorTapping = state
		if(element.colorTapping) then
			element.__owner:RegisterEvent('UNIT_FACTION', ColorPath)
		else
			element.__owner:UnregisterEvent('UNIT_FACTION', ColorPath)
		end
	end
end

--[[ Power:SetColorThreat(state) - toggles coloring by the unit's threat status. --]]
local function SetColorThreat(element, state)
	if(element.colorThreat ~= state) then
		element.colorThreat = state
		if(element.colorThreat) then
			element.__owner:RegisterEvent('UNIT_THREAT_LIST_UPDATE', ColorPath)
		else
			element.__owner:UnregisterEvent('UNIT_THREAT_LIST_UPDATE', ColorPath)
		end
	end
end

--[[ Power:SetColorHappiness(state) - toggles coloring by the unit's happiness status. --]]
local function SetColorHappiness(element, state)
	if(element.colorHappiness ~= state) then
		element.colorHappiness = state
		if(element.colorHappiness) then
			element.__owner:RegisterEvent('UNIT_HAPPINESS', ColorPath)
		else
			element.__owner:UnregisterEvent('UNIT_HAPPINESS', ColorPath)
		end
	end
end


local function onPowerUpdate(self)
	if(self.disconnected) then return end

	local unit = self.__owner.unit
	local power = UnitPower(unit)

	if(power ~= self.power) then
		self.power = power

		return Path(self.__owner, 'OnPowerUpdate', unit)
	end
end

--[[ Power:SetFrequentUpdates(state) - toggles frequent updates. --]]
local function SetFrequentUpdates(element, state)
	--if(not unit or (unit ~= 'player' and unit ~= 'pet')) then return end

	if(element.frequentUpdates ~= state) then
		element.frequentUpdates = state
		if(element.frequentUpdates and not element:GetScript('OnUpdate')) then
			element:SetScript('OnUpdate', onPowerUpdate)

			element.__owner:UnregisterEvent('UNIT_MANA', Path)
			element.__owner:UnregisterEvent('UNIT_RAGE', Path)
			element.__owner:UnregisterEvent('UNIT_FOCUS', Path)
			element.__owner:UnregisterEvent('UNIT_ENERGY', Path)
			element.__owner:UnregisterEvent('UNIT_RUNIC_POWER', Path)
		elseif(not element.frequentUpdates and element:GetScript('OnUpdate')) then
			element:SetScript('OnUpdate', nil)

			element.__owner:RegisterEvent('UNIT_MANA', Path)
			element.__owner:RegisterEvent('UNIT_RAGE', Path)
			element.__owner:RegisterEvent('UNIT_FOCUS', Path)
			element.__owner:RegisterEvent('UNIT_ENERGY', Path)
			element.__owner:RegisterEvent('UNIT_RUNIC_POWER', Path)
		end
	end
end

local function Enable(self, unit)
	local element = self.Power
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate
		element.SetColorDisconnected = SetColorDisconnected
		element.SetColorTapping = SetColorTapping
		element.SetColorThreat = SetColorThreat
		element.SetColorHappiness = SetColorHappiness
		element.SetFrequentUpdates = SetFrequentUpdates

		if(element.colorDisconnected) then
			self:RegisterEvent('UNIT_CONNECTION', ColorPath)
		end

		if(element.colorTapping) then
			self:RegisterEvent('UNIT_FACTION', ColorPath)
		end

		if(element.colorThreat) then
			self:RegisterEvent('UNIT_THREAT_LIST_UPDATE', ColorPath)
		end

		if(element.colorHappiness) then
			self:RegisterEvent('UNIT_HAPPINESS', ColorPath)
		end

		if(element.frequentUpdates and (unit == 'player' or unit == 'pet')) then
			element:SetScript('OnUpdate', onPowerUpdate)
		else
			self:RegisterEvent('UNIT_MANA', Path)
			self:RegisterEvent('UNIT_RAGE', Path)
			self:RegisterEvent('UNIT_FOCUS', Path)
			self:RegisterEvent('UNIT_ENERGY', Path)
			self:RegisterEvent('UNIT_RUNIC_POWER', Path)
		end

		self:RegisterEvent('UNIT_MAXMANA', Path)
		self:RegisterEvent('UNIT_MAXRAGE', Path)
		self:RegisterEvent('UNIT_MAXFOCUS', Path)
		self:RegisterEvent('UNIT_MAXENERGY', Path)
		self:RegisterEvent('UNIT_MAXRUNIC_POWER', Path)
		self:RegisterEvent('UNIT_DISPLAYPOWER', Path)

		if(element:IsObjectType('StatusBar')) then
			element.texture = element:GetStatusBarTexture() and element:GetStatusBarTexture():GetTexture() or [[Interface\TargetingFrame\UI-StatusBar]]
			element:SetStatusBarTexture(element.texture)
		end

		element:Show()

		return true
	end
end

local function Disable(self)
	local element = self.Power
	if(element) then
		element:Hide()

		if(element:GetScript('OnUpdate')) then
			element:SetScript('OnUpdate', nil)
		else
			self:UnregisterEvent('UNIT_MANA', Path)
			self:UnregisterEvent('UNIT_RAGE', Path)
			self:UnregisterEvent('UNIT_FOCUS', Path)
			self:UnregisterEvent('UNIT_ENERGY', Path)
			self:UnregisterEvent('UNIT_RUNIC_POWER', Path)
		end

		self:UnregisterEvent('UNIT_MAXMANA', Path)
		self:UnregisterEvent('UNIT_MAXRAGE', Path)
		self:UnregisterEvent('UNIT_MAXFOCUS', Path)
		self:UnregisterEvent('UNIT_MAXENERGY', Path)
		self:UnregisterEvent('UNIT_MAXRUNIC_POWER', Path)
		self:UnregisterEvent('UNIT_DISPLAYPOWER', Path)

		self:UnregisterEvent('UNIT_CONNECTION', ColorPath)
		self:UnregisterEvent('UNIT_THREAT_LIST_UPDATE', ColorPath)
		self:UnregisterEvent('UNIT_FACTION', ColorPath)
		self:UnregisterEvent('UNIT_HAPPINESS', ColorPath)
	end
end

oUF:AddElement('Power', Path, Enable, Disable)