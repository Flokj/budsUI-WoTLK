local K, C = select(2, ...):unpack()
if C.Tooltip.Enable ~= true or C.Tooltip.Talents ~= true then return end

-- Target talent display originally based on TipTacTalents by Aezay.
-- Talent data and tooltip presentation are separate from the inspect queue,
-- as in FrostAtomUI. Keep budsUI's existing text format and TipTac cache API.
local Inspect = K.Inspect
local tooltip = GameTooltip
local talents = CreateFrame("Frame", "TipTacTalents")
local cache, current = {}, {}
local CACHE_SIZE, CACHE_TIME = 25, 900
local TALENTS_PREFIX = TALENTS..":|cffffffff "
talents.cache, talents.current = cache, current

local function tooltipUnit()
	local name, unit = tooltip:GetUnit()
	if unit then return unit end
	local focus = GetMouseFocus()
	unit = focus and (focus.unit or focus.GetAttribute and focus:GetAttribute("unit"))
	if unit then return unit end
	if name and UnitName("mouseover") == name then return "mouseover" end
end

local function readTalents(inspect, guid, unit, name)
	local group = GetActiveTalentGroup(inspect)
	local data = { guid = guid, unit = unit, name = name, time = GetTime() }
	local best = 1
	for tab = 1, 3 do
		local _, _, points = GetTalentTabInfo(tab, inspect, nil, group)
		if points == nil then return end
		data[tab] = points
		if points > data[best] then best = tab end
	end
	data.tree = GetTalentTabInfo(best, inspect, nil, group)
	local format = TipTac_Config and TipTac_Config.talentFormat or 1
	if data[best] == 0 then
		data.format = L_TOOLTIP_NO_TALENT
	elseif format == 2 then
		data.format = data.tree
	elseif format == 3 then
		data.format = data[1].."/"..data[2].."/"..data[3]
	else
		if not data.tree then return end
		data.format = data.tree.." ("..data[1].."/"..data[2].."/"..data[3]..")"
	end
	return data
end

local function findEntry(guid)
	if not guid then return end
	for i = 1, #cache do
		if cache[i].guid == guid then return cache[i] end
	end
end

local function store(data)
	local size = TipTac_Config and TipTac_Config.talentCacheSize or CACHE_SIZE
	size = math.max(0, math.floor(tonumber(size) or CACHE_SIZE))
	for i = #cache, 1, -1 do
		if cache[i].guid == data.guid then table.remove(cache, i) end
	end
	while #cache > 0 and #cache >= size do table.remove(cache, 1) end
	if size > 0 then cache[#cache + 1] = data end
end

local freshData
Inspect:RegisterTalentCallback(function(guid, unit, name)
	local data = readTalents(true, guid, unit, name)
	if not data then return end
	store(data)
	-- Rebuild only the visible tooltip for this GUID; never reopen a hidden
	-- or fading tooltip. Cache replies even if the unit token disappeared.
	if not tooltip:IsShown() or tooltip.fadeOut then return end
	local tipUnit = tooltipUnit()
	if tipUnit and UnitGUID(tipUnit) == guid then
		freshData = data
		tooltip:SetUnit(tipUnit)
		freshData = nil
	end
end)

tooltip:HookScript("OnTooltipSetUnit", function(self)
	local unit = tooltipUnit()
	wipe(current)
	if not unit or not UnitIsPlayer(unit) then return end
	local guid = UnitGUID(unit)
	if not guid then return end
	local level = UnitLevel(unit)
	if level < 10 and level ~= -1 then return end
	local data
	if UnitIsUnit(unit, "player") then
		data = readTalents(false, guid, unit, UnitName(unit))
	else
		data = freshData and freshData.guid == guid and freshData or findEntry(guid)
		-- Cached data is usable out of range and in combat. The manager
		-- waits for a safe send and refreshes stale data after 15 minutes.
		if not data or not data.time or GetTime() - data.time >= CACHE_TIME then
			Inspect:Request(unit, nil, true)
		end
	end
	current.guid, current.name, current.unit = guid, UnitName(unit), unit
	if data and data.format then
		current.tree, current.format = data.tree, data.format
		current[1], current[2], current[3] = data[1], data[2], data[3]
		self:AddLine(TALENTS_PREFIX..data.format)
	end
end)
