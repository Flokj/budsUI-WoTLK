local K, C = select(2, ...):unpack()
if (C.Tooltip.Enable ~= true or C.Tooltip.Talents ~= true) and (not C.InternalCooldowns or C.InternalCooldowns.Enable ~= true) then return end

-- FrostAtomUI's serialized inspect queue, adapted to budsUI's engine.
-- Publishes talent and gear callbacks.
local TICK = 0.1
local SEND_INTERVAL = 1.5
local URGENT_DELAY = 0.2
local MANUAL_BACKOFF = 2
local TIMEOUT = 5
local MAX_RETRIES = 4

local TREE1_TALENTS = {
	DEATHKNIGHT = 48979, DRUID = 16814, HUNTER = 19552, MAGE = 11210,
	PALADIN = 20205, PRIEST = 14522, ROGUE = 14162, SHAMAN = 16039,
	WARLOCK = 18827, WARRIOR = 12282,
}
local lookupUnits = { "mouseover", "target", "focus", "targettarget", "focustarget" }
for i = 1, 4 do
	lookupUnits[#lookupUnits + 1] = "party"..i
	lookupUnits[#lookupUnits + 1] = "party"..i.."target"
end
for i = 1, 40 do lookupUnits[#lookupUnits + 1] = "raid"..i end

local Inspect = {}
K.Inspect = Inspect
local pending, retries, inspected = {}, {}, {}
local callbacks = {}
local gearCallbacks = {}
local gearGuid, gearUnit, gearTries, gearAt
local request
local urgentGuid, urgentTime
local lastSend, manualTime = -SEND_INTERVAL, -MANUAL_BACKOFF
local queue = CreateFrame("Frame")
queue:Hide()

function Inspect:RegisterTalentCallback(callback)
	callbacks[#callbacks + 1] = callback
end

function Inspect:RegisterGearCallback(callback)
	gearCallbacks[#gearCallbacks + 1] = callback
end

function Inspect:UnitByGUID(guid, hint)
	if hint and UnitGUID(hint) == guid then return hint end
	for i = 1, #lookupUnits do
		local unit = lookupUnits[i]
		if UnitGUID(unit) == guid then return unit end
	end
end

local function isInspectable(unit)
	return unit and UnitExists(unit) and UnitIsPlayer(unit)
		and not UnitIsUnit(unit, "player")
		and (UnitLevel(unit) >= 10 or UnitLevel(unit) == -1)
		and not UnitCanAttack("player", unit)
end

local function isReachable(unit)
	return UnitIsVisible(unit) and UnitIsConnected(unit)
		and CanInspect(unit) and CheckInteractDistance(unit, 1)
end

function Inspect:Request(unit, maxAge, urgent)
	if not isInspectable(unit) then return end
	local guid = UnitGUID(unit)
	if not guid then return end
	local now = GetTime()
	if maxAge and inspected[guid] and now - inspected[guid] < maxAge then return end
	if request and request.guid == guid then return end
	pending[guid] = unit
	if urgent then urgentGuid, urgentTime = guid, now end
	queue:Show()
end

local function fail(guid, hint)
	-- External requests are tracked for identity, not adopted for retries.
	if not pending[guid] then return end
	local count = (retries[guid] or 0) + 1
	if count > MAX_RETRIES then
		retries[guid], pending[guid] = nil, nil
	else
		retries[guid] = count
		pending[guid] = hint
		queue:Show()
	end
end

local function talentsMatchClass(class)
	local id = class and TREE1_TALENTS[class]
	local expected = id and GetSpellInfo(id)
	if not expected then return true end
	for i = 1, GetNumTalents(1, true) do
		if GetTalentInfo(1, i, true) == expected then return true end
	end
	return false
end

local function send(now)
	if InCombatLockdown() or (InspectFrame and InspectFrame:IsShown())
	or (Examiner and Examiner:IsShown()) then return end
	if now < lastSend + SEND_INTERVAL or now < manualTime + MANUAL_BACKOFF then return end
	if urgentGuid then
		if now < urgentTime + URGENT_DELAY then return end
		local unit = Inspect:UnitByGUID(urgentGuid, pending[urgentGuid])
		urgentGuid = nil
		if unit and isInspectable(unit) and isReachable(unit) then
			NotifyInspect(unit)
			return
		end
	end
	for guid, hint in pairs(pending) do
		local unit = Inspect:UnitByGUID(guid, hint)
		if not unit or not isInspectable(unit) then
			pending[guid], retries[guid] = nil, nil
		elseif isReachable(unit) then
			NotifyInspect(unit)
			return
		end
	end
end

local function isGearComplete(unit)
	for slot = 1, 18 do
		if GetInventoryItemID(unit, slot) and not GetInventoryItemLink(unit, slot) then
			return false
		end
	end
	return true
end

local function checkGear(now)
	local unit = Inspect:UnitByGUID(gearGuid, gearUnit)
	if not unit then
		gearGuid = nil
		return
	end
	gearUnit = unit
	if gearTries < 10 and not isGearComplete(unit) then
		gearTries = gearTries + 1
		gearAt = now + 0.3
		return
	end
	local guid = gearGuid
	gearGuid = nil
	for i = 1, #gearCallbacks do
		gearCallbacks[i](guid, unit)
	end
end

queue:SetScript("OnUpdate", function(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed < TICK then return end
	self.elapsed = 0
	local now = GetTime()
	if request and now - request.time > TIMEOUT then
		local expired = request
		request = nil
		fail(expired.guid, expired.unit)
	end
	if gearGuid and now >= gearAt then
		checkGear(now)
	end
	-- 3.3.5 drops replies for targets superseded by another NotifyInspect.
	if not request and not gearGuid then send(now) end
	if not request and not gearGuid and not urgentGuid and not next(pending) then self:Hide() end
end)

hooksecurefunc("NotifyInspect", function(unit)
	-- Track every actual send, including Blizzard and other addons. Pending
	-- requests stay queued if somebody else takes over the client's target.
	request = nil
	local guid = UnitGUID(unit)
	if not guid or not UnitIsPlayer(unit) or UnitCanAttack("player", unit) then return end
	lastSend = GetTime()
	local _, class = UnitClass(unit)
	request = { guid = guid, unit = unit, name = UnitName(unit), class = class, time = lastSend }
	queue:Show()
end)

hooksecurefunc("InspectUnit", function() manualTime = GetTime() end)
hooksecurefunc("ClearInspectPlayer", function() request = nil end)

queue:RegisterEvent("INSPECT_TALENT_READY")
queue:RegisterEvent("PLAYER_ENTERING_WORLD")
queue:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_ENTERING_WORLD" then
		wipe(pending)
		wipe(retries)
		request, urgentGuid, gearGuid = nil, nil, nil
		queue:Hide()
		return
	end
	local ready = request
	if not ready then return end
	request = nil
	if ready.guid == UnitGUID("player") then return end
	if not talentsMatchClass(ready.class) then
		fail(ready.guid, ready.unit)
		return
	end
	retries[ready.guid], pending[ready.guid] = nil, nil
	if urgentGuid == ready.guid then urgentGuid = nil end
	inspected[ready.guid] = GetTime()
	local unit = Inspect:UnitByGUID(ready.guid, ready.unit)
	if unit then
		for i = 1, #callbacks do callbacks[i](ready.guid, unit, ready.name) end
	end
	if #gearCallbacks > 0 and ready.guid then
		gearGuid = ready.guid
		gearUnit = ready.unit
		gearTries = 0
		gearAt = GetTime() + 0.1
		queue:Show()
	end
end)
