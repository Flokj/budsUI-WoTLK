local _, ns = ...
local oUF = ns.oUF
local Private = oUF.Private

local argcheck = Private.argcheck
local frame_metatable = Private.frame_metatable

-- Backport CombatLogGetCurrentEventInfo for 3.3.5a
local function CombatLogGetCurrentEventInfo()
    -- Just return all the args from the combat log event
    return CombatLogGetCurrentEventInfoArgs()
end

-- Helper: capture the latest event args
local combatLogArgs = {}
local function SaveCombatLogArgs(...)
    wipe(combatLogArgs)
    for i = 1, select('#', ...) do
        combatLogArgs[i] = select(i, ...)
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
f:SetScript('OnEvent', function(_, _, ...)
    SaveCombatLogArgs(...)
end)

-- Internal function used above
function CombatLogGetCurrentEventInfoArgs()
    return unpack(combatLogArgs)
end

local event_metatable = {
	__call = function(funcs, ...)
		for self, func in next, funcs do
			if (self:IsVisible()) then
				func(self, ...)
			end
		end
	end,
}

local self_metatable = {
	__call = function(funcs, self, ...)
		for _, func in next, funcs do
			func(self, ...)
		end
	end
}

local listener = CreateFrame('Frame')
listener.activeEvents = 0

local function filter(_, event, ...)
	if(listener[event]) then
		listener[event](event, ...)
	end
end

listener:SetScript('OnEvent', function(self, event)
	filter(CombatLogGetCurrentEventInfo())
end)

--[[ CombatEvents: frame:RegisterCombatEvent(event, handler) - register a combat log event handler. --]]
function frame_metatable.__index:RegisterCombatEvent(event, handler)
	argcheck(event, 2, 'string')
	argcheck(handler, 3, 'function')

	if(not listener[event]) then
		listener[event] = setmetatable({}, event_metatable)
		listener.activeEvents = listener.activeEvents + 1
	end

	local current = listener[event][self]

	if(current) then
		for _, func in next, current do
			if(func == handler) then return end
		end

		table.insert(current, handler)
	else
		-- even with a single handler we want to make sure the frame is visible
		listener[event][self] = setmetatable({handler}, self_metatable)
	end

	if(listener.activeEvents > 0) then
		listener:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
	end
end

--[[ CombatEvents: frame:UnregisterCombatEvent(event, handler) - remove a combat log event handler. --]]
function frame_metatable.__index:UnregisterCombatEvent(event, handler)
	argcheck(event, 2, 'string')

	if(not listener[event]) then return end

	local cleanUp = false
	local current = listener[event][self]
	if(current) then
		for i, func in next, current do
			if(func == handler) then
				current[i] = nil

				break
			end
		end

		if(not next(current)) then
			cleanUp = true
		end
	end

	if(cleanUp) then
		listener[event][self] = nil

		if(not next(listener[event])) then
			listener[event] = nil
			listener.activeEvents = listener.activeEvents - 1

			if(listener.activeEvents <= 0) then
				listener:UnregisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
			end
		end
	end
end
