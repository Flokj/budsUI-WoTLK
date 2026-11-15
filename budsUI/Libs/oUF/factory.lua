local _, ns = ...
local oUF = ns.oUF
local Private = oUF.Private

local argcheck = Private.argcheck

local queue = {}
local factory = CreateFrame('Frame')
factory:SetScript('OnEvent', function(self, event, ...)
	return self[event](self, event, ...)
end)

factory:RegisterEvent('PLAYER_LOGIN')
factory.active = true

function factory:PLAYER_LOGIN()
	if(not self.active) then return end

	for _, func in next, queue do
		func(oUF)
	end

	-- Avoid creating dupes.
	table.wipe(queue)
end

--[[ Factory: oUF:Factory(func) - call func now if logged in and active, else queue it until PLAYER_LOGIN. --]]
function oUF:Factory(func)
	argcheck(func, 2, 'function')

	-- Call the function directly if we're active and logged in.
	if(IsLoggedIn() and factory.active) then
		return func(self)
	else
		table.insert(queue, func)
	end
end

--[[ Factory: oUF:EnableFactory() - enable the factory. --]]
function oUF:EnableFactory()
	factory.active = true
end

--[[ Factory: oUF:DisableFactory() - disable the factory. --]]
function oUF:DisableFactory()
	factory.active = nil
end

--[[ Factory: oUF:RunFactoryQueue() - run queued functions (needs login + active factory). --]]
function oUF:RunFactoryQueue()
	factory:PLAYER_LOGIN()
end
