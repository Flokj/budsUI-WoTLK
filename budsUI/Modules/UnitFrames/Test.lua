--[[-----------------------------------------------------------------------------
Addon: budsUI
File: Modules/UnitFrames/Test.lua
Purpose:
	Config mode. Instead of drawing throwaway mock frames, this forces the
	real single frames to show with the player's own data, which is the
	sturdiest way to preview them.

	Ported from KkthnxUI retail to WoW 3.3.5:
	- no C_Timer (3.3.5); the follow-up child sweep runs on a one-shot
	  OnUpdate shim instead;
	- secure headers cannot conjure phantom units while solo on 3.3.5, so the
	  party/raid preview shows whoever is really in the group.

	Nothing here runs in combat.
-----------------------------------------------------------------------------]]

local Engine = select(2, ...)
local K, C = Engine:unpack()
local Module = Engine.UnitFrames
if not Module then return end

local ipairs = ipairs
local InCombatLockdown = InCombatLockdown
local RegisterStateDriver = RegisterStateDriver
local RegisterUnitWatch = RegisterUnitWatch
local UnregisterUnitWatch = UnregisterUnitWatch

-- The standalone frames, by module key. Boss frames live in a numbered list
-- and are handled alongside these.
local INDIVIDUAL = { "Player", "Target", "TargetOfTarget", "Pet", "Focus", "FocusTarget" }

-- Header show gates cleared during config mode so the header renders while
-- solo, then restored on the way out.
local GATES = { "showRaid", "showParty", "showSolo" }

-- One-shot delay without C_Timer: runs func on the next frame update.
local delayFrame
local function AfterNextFrame(func)
	if not delayFrame then
		delayFrame = CreateFrame("Frame")
	end
	delayFrame:SetScript("OnUpdate", function(self)
		self:SetScript("OnUpdate", nil)
		func()
	end)
end

-- ---------------------------------------------------------------------------
-- Force a single frame
-- ---------------------------------------------------------------------------

-- Point a frame at the player, keep it shown through a forced unit watch, and
-- refresh its elements so it fills with live data.
local function ForceFrame(frame)
	if not frame or frame.__budsForced then
		return
	end
	frame.__budsForced = true
	frame.__realUnit = frame.unit
	frame.unit = "player"
	frame.__unit = "player"
	frame:EnableMouse(false)
	UnregisterUnitWatch(frame)
	RegisterUnitWatch(frame, true)
	frame:Show()
	if frame.UpdateAllElements then
		frame:UpdateAllElements("budsUI_ConfigMode")
	end
end

local function UnforceFrame(frame)
	if not frame or not frame.__budsForced then
		return
	end
	frame.__budsForced = nil
	frame.unit = frame.__realUnit
	frame.__unit = frame.__realUnit
	frame.__realUnit = nil
	frame:EnableMouse(true)
	UnregisterUnitWatch(frame)
	RegisterUnitWatch(frame)
	if frame.UpdateAllElements then
		frame:UpdateAllElements("budsUI_ConfigMode")
	end
end

-- ---------------------------------------------------------------------------
-- Group headers
-- ---------------------------------------------------------------------------
local function ForEachChild(header, func)
	local i = 1
	local child = header:GetAttribute("child" .. i)
	while child do
		func(child)
		i = i + 1
		child = header:GetAttribute("child" .. i)
	end
end

local function ForceHeader(header)
	if not header then
		return
	end
	header.__cfgSaved = {}
	for _, key in ipairs(GATES) do
		header.__cfgSaved[key] = header:GetAttribute(key)
		header:SetAttribute(key, nil)
	end
	header.__cfgStart = header:GetAttribute("startingIndex")

	RegisterStateDriver(header, "visibility", "show")
	header:Show()
	header:SetAttribute("startingIndex", header.__testStart or -4)
	ForEachChild(header, ForceFrame)
	-- The secure header can finish spawning its children on the next frame,
	-- so sweep once more then. ForceFrame is idempotent.
	AfterNextFrame(function()
		if header.__cfgSaved then
			ForEachChild(header, ForceFrame)
		end
	end)
end

local function UnforceHeader(header, visibility)
	if not header then
		return
	end
	ForEachChild(header, UnforceFrame)
	if header.__cfgSaved then
		for _, key in ipairs(GATES) do
			header:SetAttribute(key, header.__cfgSaved[key])
		end
		header.__cfgSaved = nil
	end
	header:SetAttribute("startingIndex", header.__cfgStart or 1)
	header.__cfgStart = nil
	RegisterStateDriver(header, "visibility", visibility)
end

local function PartyVisibility()
	local visibility = "[group:party,nogroup:raid] show; hide"
	if C.Unitframe.Party.ShowSolo then
		visibility = "[nogroup] show; " .. visibility
	end
	return visibility
end

-- ---------------------------------------------------------------------------
-- Enter / exit
-- ---------------------------------------------------------------------------
function Module:EnterConfigMode()
	if InCombatLockdown() then
		return
	end
	for _, key in ipairs(INDIVIDUAL) do
		ForceFrame(self[key])
	end
	if self.Boss then
		for _, frame in ipairs(self.Boss) do
			ForceFrame(frame)
		end
	end
	ForceHeader(self.Party)
	ForceHeader(self.Raid)
end

function Module:ExitConfigMode()
	if InCombatLockdown() then
		return
	end
	for _, key in ipairs(INDIVIDUAL) do
		UnforceFrame(self[key])
	end
	if self.Boss then
		for _, frame in ipairs(self.Boss) do
			UnforceFrame(frame)
		end
	end
	UnforceHeader(self.Party, PartyVisibility())
	UnforceHeader(self.Raid, "[group:raid] show; hide")
end
