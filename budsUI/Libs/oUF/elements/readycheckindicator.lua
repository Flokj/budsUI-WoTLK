--[[ # Element: Ready Check Indicator
Handles indicator visibility and updating based on the unit's ready check status. ]]

local _, ns = ...
local oUF = ns.oUF
local Private = oUF.Private

local unitExists = Private.unitExists

local _G = _G
local GetReadyCheckStatus = GetReadyCheckStatus

-- fallback blizzard icons (incase a plugin fails to change icon properly)
local READY_TEX = [[Interface\RaidFrame\ReadyCheck-Ready]]
local NOT_READY_TEX = [[Interface\RaidFrame\ReadyCheck-NotReady]]
local WAITING_TEX = [[Interface\RaidFrame\ReadyCheck-Waiting]]

local function OnFinished(self)
	local element = self:GetParent()
	element:Hide()

	-- Callback: ReadyCheckIndicator:PostUpdateFadeOut() - called after the element has been faded out
	if(element.PostUpdateFadeOut) then
		element:PostUpdateFadeOut()
	end
end

local function SetIcon(element, texture)
	element:SetTexture(texture)
end

local function Update(self, event)
	local element = self.ReadyCheckIndicator
	local unit = self.unit

	-- Callback: ReadyCheckIndicator:PreUpdate() - called before the element is updated
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local status = GetReadyCheckStatus(unit)
	if(unitExists(unit) and status) then
		if(status == 'ready') then
			SetIcon(element, element.readyTexture or READY_TEX)
		elseif(status == 'notready') then
			SetIcon(element, element.notReadyTexture or NOT_READY_TEX)
		else
			SetIcon(element, element.waitingTexture or WAITING_TEX)
		end

		element.status = status
		element:Show()
	elseif(event ~= 'READY_CHECK_FINISHED') then
		element.status = nil
		element:Hide()
	end

	if(event == 'READY_CHECK_FINISHED') then
		if(element.status == 'waiting') then
			SetIcon(element, element.notReadyTexture or NOT_READY_TEX)
		end

		element.Animation:Play()
	end

	-- Callback: ReadyCheckIndicator:PostUpdate(status) - called after the element is updated
	if(element.PostUpdate) then
		return element:PostUpdate(status)
	end
end

local function Path(self, ...)
	-- Override: ReadyCheckIndicator.Override(self, event, ...) - override the internal update function
	return (self.ReadyCheckIndicator.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self, unit)
	local element = self.ReadyCheckIndicator
	unit = unit and unit:match('(%a+)%d*$')
	if(element and (unit == 'party' or unit == 'raid')) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		if not element.readyTexture then element.readyTexture = _G.READY_CHECK_READY_TEXTURE end
		if not element.notReadyTexture then element.notReadyTexture = _G.READY_CHECK_NOT_READY_TEXTURE end
		if not element.waitingTexture then element.waitingTexture = _G.READY_CHECK_WAITING_TEXTURE end

		local anim = element.Animation
		if not anim then
			anim = element:CreateAnimationGroup()
			element.Animation = anim
		end

		anim:SetScript('OnFinished', OnFinished) -- use Set to purge other scripts on reenable

		local animAlpha = anim.Alpha
		if not animAlpha then
			animAlpha = anim:CreateAnimation('Alpha')
			anim.Alpha = animAlpha
		end

		animAlpha:SetChange(-1)
		animAlpha:SetDuration(element.fadeTime or 1.5)
		animAlpha:SetStartDelay(element.finishedTime or 10)

		self:RegisterEvent('READY_CHECK', Path, true)
		self:RegisterEvent('READY_CHECK_CONFIRM', Path, true)
		self:RegisterEvent('READY_CHECK_FINISHED', Path, true)

		return true
	end
end

local function Disable(self)
	local element = self.ReadyCheckIndicator
	if(element) then
		element:Hide()

		self:UnregisterEvent('READY_CHECK', Path)
		self:UnregisterEvent('READY_CHECK_CONFIRM', Path)
		self:UnregisterEvent('READY_CHECK_FINISHED', Path)
	end
end

oUF:AddElement('ReadyCheckIndicator', Path, Enable, Disable)