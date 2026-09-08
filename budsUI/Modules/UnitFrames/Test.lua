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
	- secure headers cannot conjure phantom units, so solo each header shows
	  its player child plus spare single-unit preview frames in the group
	  style (ElvUI-style); grouped, the real members show instead.

	Nothing here runs in combat.
-----------------------------------------------------------------------------]]

local Engine = select(2, ...)
local K, C = Engine:unpack()
local Module = Engine.UnitFrames
if not Module then return end

local ipairs = ipairs
local InCombatLockdown = InCombatLockdown
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers
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

-- ---------------------------------------------------------------------------
-- Solo group previews (ElvUI-style). Secure headers only spawn children for
-- real units, so solo there would be a single player frame per header. A few
-- spare single-unit frames in the group style stand in for the missing
-- members: forced onto the player's data, laid out from the header's own
-- child geometry, hidden again on the way out. Grouped they stay hidden and
-- the real members show.
-- ---------------------------------------------------------------------------
local previewCache = {}

local function HidePreviews(list)
	if not list then
		return
	end
	for i = 1, #list do
		local f = list[i]
		if f then
			UnforceFrame(f)
			f:Hide()
		end
	end
end

local function HideAllPreviews()
	for _, list in pairs(previewCache) do
		HidePreviews(list)
	end
end

local function ShowPreviews(header, style, unitPrefix, extra)
	if not header or not extra or extra <= 0 then
		return
	end
	local w, h = header.__childW, header.__childH
	if not w or not h then
		return
	end
	local oUF = Engine.oUF or _G.budsUF
	if not oUF then
		return
	end

	local list = previewCache[style]
	if not list then
		list = {}
		previewCache[style] = list
		oUF:SetActiveStyle("budsUI_" .. style)
		for i = 1, extra do
			local f = oUF:Spawn(unitPrefix .. i, "budsUI_" .. style .. "Preview" .. i)
			f:SetSize(w, h)
			f:Hide()
			list[i] = f
		end
	end

	for i = 1, extra do
		local f = list[i]
		if f then
			f:ClearAllPoints()
			if style == "Raid" then
				-- Slot 0 is the real solo child; previews fill row-wise after
				-- it (approximates a DOWN govern, good enough for layout).
				local cols = header.__childCols or 5
				local gap = header.__childStep or Module.GAP
				f:SetPoint("TOPLEFT", header, "TOPLEFT", (i % cols) * (w + gap), -math.floor(i / cols) * (h + gap))
			else
				local step = header.__childStep or 24
				f:SetPoint("TOPLEFT", header, "TOPLEFT", 0, -i * (h + step))
			end
			ForceFrame(f)
		end
	end
end

local function ForceHeader(header, style, unitPrefix, extra)
	if not header then
		return
	end
	header.__cfgSaved = {}
	for _, key in ipairs(GATES) do
		header.__cfgSaved[key] = header:GetAttribute(key)
	end
	header.__cfgStart = header:GetAttribute("startingIndex")
	header:SetAttribute("startingIndex", 1)

	-- Grouped: the header already shows the real members, leave it alone.
	-- Solo: no group units exist, so let the header show the player child
	-- and stand spare single frames in for the missing members.
	local solo = GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0
	if solo then
		header:SetAttribute("showSolo", true)
	end

	RegisterStateDriver(header, "visibility", "show")
	header:Show()
	ForEachChild(header, ForceFrame)
	-- The secure header can finish spawning its children on the next frame,
	-- so sweep once more then. ForceFrame is idempotent.
	AfterNextFrame(function()
		if header.__cfgSaved then
			ForEachChild(header, ForceFrame)
		end
	end)

	if solo and style then
		ShowPreviews(header, style, unitPrefix, extra)
	else
		HideAllPreviews()
	end
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
	ForceHeader(self.Party, "Party", "party", 4)
	ForceHeader(self.Raid, "Raid", "raid", 9)
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
	HideAllPreviews()
end
