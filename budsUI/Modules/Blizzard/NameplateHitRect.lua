local K, C, L, _ = select(2, ...):unpack()
if C.Nameplate.Enable ~= true then return end

-- Secure-frame HitRect hack ported from FrostAtom (_hermes_refs/frostatom/HitRect.lua).
-- WotLK 3.3.5 nameplate frames ARE PROTECTED (IsProtected() returns true), so plain
-- frame:SetSize() / EnableMouse() from addon code is filtered or errors during
-- combat lockdown. The ONLY working hack resizes the plate's CLICK RECT from
-- INSIDE a registered secure handler:
--   * one hidden SecureFrameTemplate marker per plate holds the wanted size in
--     its clamp rect (marker:SetClampRectInsets(-width, 0, 0, -height));
--   * a SecureHandlerBaseTemplate header WrapScripts every plate's OnShow/OnHide
--     with a sweep body that walks WorldFrame children, counts explicitly
--     protected plates, and calls plate:SetSize(markerWidth, markerHeight) from
--     within the protected environment (works in combat);
--   * a pulse marker + combat state-driver frames re-trigger the sweep while
--     in combat; insecure Update() only writes the marker clamp rect and bumps
--     the pulse counter during lockdown, queuing the direct SetSize for
--     PLAYER_REGEN_ENABLED.
-- budsUI adaptation: no FrostAtom module/db/config deps; plates are tracked in
-- this file's own list (fed by every Update call). Only used for the
-- nameplate blacklist: hidden plates get hit rect (w, 0).

local CreateFrame = CreateFrame
local WorldFrame = WorldFrame
local InCombatLockdown = InCombatLockdown
local RegisterStateDriver = RegisterStateDriver
local wipe = wipe

local MARKER_OFFSET = -100
local SPARE_MARKERS = 40
local PRE_BODY = "return nil, true"
local SWEEP_BODY = [[
	wipe(plateList)
	worldFrame:GetChildList(plateList)
	local index = 0
	for i = 1, #plateList do
		local plate = plateList[i]
		local _, explicit = plate:IsProtected()
		if explicit then
			index = index + 1
			local marker = markers[index]
			if marker then
				local width, height = marker:GetRect()
				if width and width > 1 then
					if abs(plate:GetWidth() - width) > 0.01 or abs(plate:GetHeight() - height) > 0.01 then
						plate:SetWidth(width)
						plate:SetHeight(height)
					end
				end
			end
		end
	end
]]
local TICK_BODY = [[
	local counter = pulse:GetRect()
	if counter ~= lastCounter then
		lastCounter = counter
]] .. SWEEP_BODY .. [[
	end
	self:Hide()
]]
local FAST_BODY = [[stateDriver:SetAttribute("updatetime", 0)]]
local SLOW_BODY = [[stateDriver:SetAttribute("updatetime", 0.2)]]
local SETUP_BODY = [[
	worldFrame = self:GetFrameRef("worldFrame")
	stateDriver = self:GetFrameRef("stateDriver")
	pulse = self:GetFrameRef("pulse")
	markers = newtable()
	plateList = newtable()
]]
local ADD_MARKER_BODY = [[tinsert(markers, self:GetFrameRef("marker"))]]
local PULSE_CYCLE = 500

local header, pulse, markerParent
local markers = {}
local wrapped = {}
local pending = {}
local counter = 1
local defaultWidth

-- Plates seen via Update(); replaces FrostAtom's NamePlates.plates list.
local knownPlates = {}
local knownSet = {}

local function createMarker()
	local marker = CreateFrame("Frame", nil, markerParent, "SecureFrameTemplate")
	marker:SetSize(1, 1)
	marker:SetPoint("TOPRIGHT", WorldFrame, "BOTTOMLEFT", MARKER_OFFSET, MARKER_OFFSET)
	return marker
end

local function addMarkers(count)
	for _ = #markers + 1, count do
		local marker = createMarker()
		markers[#markers + 1] = marker
		header:SetFrameRef("marker", marker)
		header:Execute(ADD_MARKER_BODY)
	end
end

local function combatFrame(body)
	local frame = CreateFrame("Frame", nil, nil, "SecureFrameTemplate")
	frame:Hide()
	header:WrapScript(frame, "OnShow", body)
	RegisterStateDriver(frame, "visibility", "[combat] show; hide")
	return frame
end

local function setup()
	markerParent = CreateFrame("Frame", nil, WorldFrame)
	pulse = createMarker()
	header = CreateFrame("Frame", nil, nil, "SecureHandlerBaseTemplate")
	header:SetFrameRef("worldFrame", WorldFrame)
	header:SetFrameRef("stateDriver", SecureStateDriverManager)
	header:SetFrameRef("pulse", pulse)
	header:Execute(SETUP_BODY)
	local guard = combatFrame(FAST_BODY)
	header:WrapScript(guard, "OnHide", SLOW_BODY)
	combatFrame(TICK_BODY)
end

local function trigger()
	counter = counter % PULSE_CYCLE + 1
	pulse:SetClampRectInsets(-counter, 0, 0, -1)
	pulse:SetClampedToScreen(true)
end

local function plateIndex(plate)
	local children = { WorldFrame:GetChildren() }
	local index = 0
	for i = 1, #children do
		local child = children[i]
		if select(2, child:IsProtected()) then
			index = index + 1
			if child == plate then
				return index
			end
		end
	end
end

local function targetSize(plate)
	if plate.hitHidden then
		return defaultWidth, 0
	end
	return plate.hitWidth, plate.hitHeight
end

local function write(plate)
	local marker = markers[plate.hitIndex]
	if not marker then
		return
	end
	local width, height = targetSize(plate)
	marker:SetClampRectInsets(-width, 0, 0, -height)
	marker:SetClampedToScreen(true)
end

local function wrap(plate)
	if not wrapped[plate] then
		wrapped[plate] = true
		header:WrapScript(plate, "OnShow", PRE_BODY, SWEEP_BODY)
		header:WrapScript(plate, "OnHide", PRE_BODY, SWEEP_BODY)
	end
end

local function apply(plate)
	plate:SetSize(targetSize(plate))
	wrap(plate)
end

local function prepare()
	if not header then
		setup()
	end
	addMarkers(#knownPlates + SPARE_MARKERS)
	for i = 1, #knownPlates do
		local plate = knownPlates[i]
		if plate.hitWidth then
			write(plate)
		end
		wrap(plate)
	end
end

-- Mirrors FrostAtom NamePlates.HitRect.Update(plate, width, height, hidden).
-- hidden=true zeroes the click rect to (w, 0): invisible AND non-interactive.
local function Update(plate, width, height, hidden)
	if not plate then return end
	if not defaultWidth then
		defaultWidth = plate:GetWidth()
	end
	if not plate.hitIndex then
		plate.hitIndex = plateIndex(plate)
	end
	if not knownSet[plate] then
		knownSet[plate] = true
		knownPlates[#knownPlates + 1] = plate
	end
	plate.hitWidth, plate.hitHeight, plate.hitHidden = width, height, hidden
	-- 3.3.5: nameplates are protected; in combat the size reaches secure code
	-- through a marker's clamp rect, applied by the WrapScript sweep.
	if InCombatLockdown() then
		write(plate)
		pending[plate] = true
		if pulse then
			trigger()
		end
		return
	end
	if not header or not markers[plate.hitIndex] then
		prepare()
	end
	write(plate)
	apply(plate)
end

K.NameplateHitRect_Update = Update

-- Self-initializing: build secure infra out of combat; flush the
-- combat-lockdown pending queue on leave-combat (FrostAtom semantics).
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function()
	prepare()
	for plate in pairs(pending) do
		if plate:IsShown() then
			apply(plate)
		end
	end
	wipe(pending)
end)

if not InCombatLockdown() then
	prepare()
end
