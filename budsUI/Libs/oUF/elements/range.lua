--[[ # Element: Range Fader
Changes the opacity of a unit frame based on whether the unit is in the player's range (offline = in range). ]]

local _, ns = ...
local oUF = ns.oUF

local _FRAMES = {}
local OnRangeFrame

local next, tinsert, tremove = next, tinsert, tremove

local CreateFrame = CreateFrame
local UnitInRange = UnitInRange
local UnitIsConnected = UnitIsConnected

local function Update(self, event)
	local element = self.Range
	local unit = self.unit

	-- Callback: Range:PreUpdate() - called before the element is updated
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local inRange, checkedRange
	local connected = UnitIsConnected(unit)
	if(connected) then
		inRange, checkedRange = UnitInRange(unit)
		if(checkedRange and not inRange) then
			self:SetAlpha(element.outsideAlpha)
		else
			self:SetAlpha(element.insideAlpha)
		end
	else
		self:SetAlpha(element.insideAlpha)
	end

	-- Callback: Range:PostUpdate(self, inRange, checkedRange, connected) - called after the element is updated
	if(element.PostUpdate) then
		return element:PostUpdate(self, inRange, checkedRange, connected)
	end
end

local function Path(self, ...)
	-- Override: Range.Override(self, event) - override the internal update function
	return (self.Range.Override or Update) (self, ...)
end

-- Internal updating method
local timer = 0
local function OnRangeUpdate(_, elapsed)
	timer = timer + elapsed

	if(timer >= .20) then
		for _, object in next, _FRAMES do
			if(object:IsShown()) then
				Path(object, 'OnUpdate')
			end
		end

		timer = 0
	end
end

local function Enable(self)
	local element = self.Range
	if(element) then
		element.__owner = self
		element.insideAlpha = element.insideAlpha or 1
		element.outsideAlpha = element.outsideAlpha or 0.55

		if not OnRangeFrame then
			OnRangeFrame = CreateFrame('Frame')
			OnRangeFrame:SetScript('OnUpdate', OnRangeUpdate)
		end

		tinsert(_FRAMES, self)
		OnRangeFrame:Show()

		return true
	end
end

local function Disable(self)
	local element = self.Range
	if(element) then
		self:SetAlpha(element.insideAlpha)

		for index, frame in next, _FRAMES do
			if frame == self then
				tremove(_FRAMES, index)
				break
			end
		end

		if #_FRAMES == 0 then
			OnRangeFrame:Hide()
		end
	end
end

oUF:AddElement('Range', Path, Enable, Disable)