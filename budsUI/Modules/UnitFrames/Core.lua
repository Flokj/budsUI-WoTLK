--[[-----------------------------------------------------------------------------
Addon: budsUI
File: Modules/UnitFrames/Core.lua
Purpose:
	UnitFrames module entry point. Owns the shared constants, the stacking
	helpers every element builder uses, and the spawn pass. The look of an
	individual unit lives in Units/, and reusable element builders live in
	Elements/.

	Ported from KkthnxUI retail to WoW 3.3.5. Geometry is unchanged: health
	and power are two separate bordered bars stacked with a gap, so a unit's
	outer height is Height + GAP + PowerHeight.
-----------------------------------------------------------------------------]]

local Engine = select(2, ...)
local K, C = Engine:unpack()
local oUF = Engine.oUF or _G.budsUF

local Module = Engine.UnitFrames
if not Module then return end

local ipairs = ipairs
local pairs = pairs
local min = math.min
local ceil = math.ceil

local MAX_BOSS_FRAMES = MAX_BOSS_FRAMES or 4

-- ---------------------------------------------------------------------------
-- Shared helpers
-- ---------------------------------------------------------------------------
function Module.PowerHeight(cfg)
	if cfg.ShowPower == false then
		return 0
	end
	return cfg.PowerHeight or 0
end

function Module.TotalHeight(cfg, gap)
	local power = Module.PowerHeight(cfg)
	if power <= 0 then
		return cfg.Height
	end
	return cfg.Height + (gap or Module.GAP) + power
end

-- Push a widget onto the upward stack above the frame.
function Module.StackUp(self, region, height)
	local anchor = self.__stackUp or self.Health or self
	region:SetHeight(height)
	region:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, Module.GAP)
	region:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", 0, Module.GAP)
	self.__stackUp = region
	return region
end

-- Push a widget onto the downward stack below the frame.
function Module.StackDown(self, region, height)
	local anchor = self.__stackDown or self.Power or self.Health or self
	region:SetHeight(height)
	region:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -Module.GAP)
	region:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -Module.GAP)
	self.__stackDown = region
	return region
end

-- Standard mouse wiring for a unit frame or a header child.
-- Blizzard's UnitFrame_OnEnter feeds self.unit straight into
-- GameTooltip:SetUnit, which errors when the unit is nil, so guard it.
local function SafeOnEnter(self)
	if self.unit and UnitExists(self.unit) then
		UnitFrame_OnEnter(self)
	end
end

function Module.EnableInteraction(self, style)
	self.mystyle = style
	self:RegisterForClicks("AnyUp")
	self:SetScript("OnEnter", SafeOnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	Module.all[#Module.all + 1] = self
end

-- ---------------------------------------------------------------------------
-- Spawn table
-- ---------------------------------------------------------------------------
Module.UnitDefs = {
	{ unit = "player", key = "Player", style = "Player", mover = "PlayerFrame", point = { "BOTTOM", "UIParent", "BOTTOM", -260, 320 } },
	{ unit = "target", key = "Target", style = "Target", mover = "TargetFrame", point = { "BOTTOM", "UIParent", "BOTTOM", 260, 320 } },
	{ unit = "targettarget", key = "TargetOfTarget", style = "Small", mover = "TargetOfTargetFrame", point = { "TOPLEFT", "Target", "BOTTOMRIGHT", 6, -6 } },
	{ unit = "pet", key = "Pet", style = "Small", mover = "PetFrame", point = { "TOPRIGHT", "Player", "BOTTOMLEFT", -6, -6 } },
	{ unit = "focus", key = "Focus", style = "Focus", mover = "FocusFrame", point = { "BOTTOMRIGHT", "Player", "TOPLEFT", -60, 200 } },
	{ unit = "focustarget", key = "FocusTarget", style = "Small", mover = "FocusTargetFrame", point = { "TOPLEFT", "Focus", "BOTTOMRIGHT", 6, -6 } },
}

function Module:ResolveAnchor(token)
	if token == "UIParent" or not token then
		return UIParent
	end
	local frame = self.frames[token]
	return frame or UIParent
end

-- ---------------------------------------------------------------------------
-- Spawning
-- ---------------------------------------------------------------------------
function Module:SpawnUnit(def)
	local cfg = C.Unitframe[def.key]
	if not cfg or not cfg.Enable then
		return
	end

	oUF:SetActiveStyle("budsUI_" .. def.style)

	local frame = oUF:Spawn(def.unit, "budsUI_" .. def.key)
	frame:SetSize(cfg.Width, Module.TotalHeight(cfg))

	local point = def.point
	local mover = K.CreateMover(frame, def.mover, def.key, {
		point[1], self:ResolveAnchor(point[2]), point[3], point[4], point[5],
	}, frame:GetWidth(), frame:GetHeight())

	self.frames[def.key] = frame
	self[def.key] = frame
	frame.__mover = mover

	if frame.PortraitHolder then
		frame.PortraitHolder:SetWidth(frame:GetHeight())
	end

	return frame
end

function Module:SpawnBoss()
	local cfg = C.Unitframe.Boss
	if not cfg or not cfg.Enable then
		return
	end

	oUF:SetActiveStyle("budsUI_Boss")

	local height = Module.TotalHeight(cfg)
	local holder = CreateFrame("Frame", "budsUI_BossHolder", UIParent)
	holder:SetSize(cfg.Width, height * MAX_BOSS_FRAMES + cfg.Spacing * (MAX_BOSS_FRAMES - 1))
	K.CreateMover(holder, "BossFrames", "Boss Frames", { "BOTTOMRIGHT", UIParent, "RIGHT", -250, 140 }, holder:GetWidth(), holder:GetHeight())

	self.Boss = {}
	for i = 1, MAX_BOSS_FRAMES do
		local frame = oUF:Spawn("boss" .. i, "budsUI_Boss" .. i)
		frame:SetSize(cfg.Width, height)
		if i == 1 then
			frame:SetPoint("TOPRIGHT", holder)
		else
			frame:SetPoint("TOPRIGHT", self.Boss[i - 1], "BOTTOMRIGHT", 0, -cfg.Spacing)
		end
		self.Boss[i] = frame
	end
	self.BossHolder = holder
end

-- Group headers. The child size has to be baked into the secure init snippet
-- because a header configures its children inside the restricted environment.
local function InitialConfig(width, height)
	return ([[
		self:SetWidth(%d)
		self:SetHeight(%d)
	]]):format(width, height)
end

function Module:SpawnParty()
	local cfg = C.Unitframe.Party
	if not cfg or not cfg.Enable then
		return
	end

	local useRaid = cfg.RaidStyle
	oUF:SetActiveStyle(useRaid and "budsUI_Raid" or "budsUI_Party")

	local width, height
	if useRaid then
		local rc = C.Unitframe.Raid
		local rmode = rc.PowerMode or "All"
		local rpower = (rmode ~= "None") and (rc.PowerHeight or 0) or 0
		local rgap = rpower > 0 and (rc.PowerGap or 6) or 0
		width = rc.Width
		height = rc.Height + rgap + rpower
	else
		width = cfg.Width
		height = Module.TotalHeight(cfg)
	end

	local partySpacing = useRaid and Module.GAP or (cfg.Castbar and 36 or 24)
	local header = oUF:SpawnHeader("budsUI_Party", nil, nil,
		"showPlayer", cfg.ShowPlayer ~= false,
		"showSolo", cfg.ShowSolo,
		"showParty", true,
		"showRaid", true,
		"xOffset", 0,
		"yOffset", -partySpacing,
		"point", "TOP",
		"groupBy", "GROUP",
		"groupingOrder", "1,2,3,4,5,6,7,8",
		"sortMethod", "INDEX",
		"maxColumns", 1,
		"unitsPerColumn", 5,
		"columnSpacing", partySpacing,
		"columnAnchorPoint", "LEFT",
		"oUF-initialConfigFunction", InitialConfig(width, height))

	header:SetSize(width, height * 5 + partySpacing * 4)

	local portraitExtent = (not useRaid) and cfg.Portrait and (Module.GAP + Module.TotalHeight(cfg)) or 0
	local mover = K.CreateMover(header, "PartyFrames", "Party", { "TOPLEFT", UIParent, "TOPLEFT", 4, -300 }, width + portraitExtent, header:GetHeight())
	if portraitExtent > 0 and mover then
		header:ClearAllPoints()
		header:SetPoint("TOPLEFT", mover, "TOPLEFT", portraitExtent, 0)
	end

	local visibility = "[group:party,nogroup:raid] show; hide"
	if cfg.ShowSolo then
		visibility = "[nogroup] show; " .. visibility
	end
	RegisterStateDriver(header, "visibility", visibility)

	header.__testStart = -4
	self.Party = header
end

function Module:SpawnRaid()
	local cfg = C.Unitframe.Raid
	if not cfg or not cfg.Enable then
		return
	end

	oUF:SetActiveStyle("budsUI_Raid")

	local mode = cfg.PowerMode or "All"
	local powerHeight = (mode ~= "None") and (cfg.PowerHeight or 0) or 0
	local gap = powerHeight > 0 and (cfg.PowerGap or 6) or 0
	local height = cfg.Height + gap + powerHeight
	local cols = min(cfg.GroupsPerRow, 8)

	-- 3.3.5 has no assigned-ROLE grouping token for headers; GROUP and CLASS
	-- are supported, ROLE falls back to GROUP.
	local groupByCfg = cfg.GroupBy or "GROUP"
	local groupBy = "GROUP"
	local groupingOrder = "1,2,3,4,5,6,7,8"
	if groupByCfg == "CLASS" then
		groupBy = "CLASS"
		groupingOrder = "WARRIOR,DEATHKNIGHT,PALADIN,ROGUE,DRUID,HUNTER,MAGE,WARLOCK,PRIEST,SHAMAN"
	end

	local raidWide = cfg.RaidWide or groupByCfg ~= "GROUP"
	local perColumn = raidWide and ceil(40 / cols) or 5
	local maxColumns = raidWide and cols or 8
	local rows = raidWide and perColumn or 5

	local ORIENT = {
		DOWN_RIGHT = { point = "TOP", column = "LEFT", down = true },
		DOWN_LEFT = { point = "TOP", column = "RIGHT", down = true },
		UP_RIGHT = { point = "BOTTOM", column = "LEFT", down = false },
		UP_LEFT = { point = "BOTTOM", column = "RIGHT", down = false },
	}
	local orient = ORIENT[cfg.Orientation] or ORIENT.DOWN_RIGHT
	local yOffset = orient.down and -Module.GAP or Module.GAP

	local sortDir = cfg.SortDirection == "DESC" and "DESC" or "ASC"

	local header = oUF:SpawnHeader("budsUI_Raid", nil, nil,
		"showPlayer", true,
		"showParty", true,
		"showRaid", true,
		"showSolo", false,
		"xOffset", 0,
		"yOffset", yOffset,
		"point", orient.point,
		"groupBy", groupBy,
		"groupingOrder", groupingOrder,
		"sortMethod", "INDEX",
		"sortDir", sortDir,
		"maxColumns", maxColumns,
		"unitsPerColumn", perColumn,
		"columnSpacing", Module.GAP,
		"columnAnchorPoint", orient.column,
		"oUF-initialConfigFunction", InitialConfig(cfg.Width, height))

	header:SetSize(cols * cfg.Width + (cols - 1) * Module.GAP, height * rows + Module.GAP * (rows - 1))
	K.CreateMover(header, "RaidFrames", "Raid", { "TOPLEFT", UIParent, "TOPLEFT", 4, -180 }, header:GetWidth(), header:GetHeight())

	RegisterStateDriver(header, "visibility", "[group:raid] show; hide")

	header.__testStart = -(min(40, maxColumns * perColumn) + 1)
	self.Raid = header

	if cfg.ShowGroupNumber and groupByCfg == "GROUP" and not raidWide then
		self:BuildRaidGroupLabels(header, cols, cfg.Width)
	end
end

function Module:BuildRaidGroupLabels(header, cols, width)
	local labels = {}
	for i = 1, cols do
		local fs = header:CreateFontString(nil, "OVERLAY")
		K.SetFont(fs, 12, K.FontOutlineStyle())
		fs:SetTextColor(0.22, 0.55, 0.86)
		fs:SetText(i)
		local x = (i - 1) * (width + Module.GAP) + width * 0.5
		fs:SetPoint("BOTTOM", header, "TOPLEFT", x, 3)
		fs:Hide()
		labels[i] = fs
	end
	self.raidGroupLabels = labels

	self:RegisterEvent("RAID_ROSTER_UPDATE", "UpdateRaidGroupLabels")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "UpdateRaidGroupLabels")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateRaidGroupLabels")
	self:UpdateRaidGroupLabels()
end

function Module:UpdateRaidGroupLabels()
	local labels = self.raidGroupLabels
	if not labels then
		return
	end

	local used = 0
	-- 3.3.5 has no IsInRaid (Cataclysm+); zero members means not in a raid.
	local members = GetNumRaidMembers()
	for i = 1, members do
		local _, _, subgroup = GetRaidRosterInfo(i)
		if subgroup and subgroup > used then
			used = subgroup
		end
	end

	for i, fs in ipairs(labels) do
		-- 3.3.5 has no Region:SetShown (MoP+); branch explicitly.
		if i <= used then
			fs:Show()
		else
			fs:Hide()
		end
	end
end

-- ---------------------------------------------------------------------------
-- Disable the default UI frames we replace.
-- In 3.3.5 there is no compact raid container; the raid groups are plain
-- RaidGroup1..8 headers, hidden here when our raid frames are enabled.
-- ---------------------------------------------------------------------------
function Module:DisableBlizzardRaid()
	if InCombatLockdown() then
		return
	end

	local hidden = _G.budsUI_HiddenParent
	if not hidden then
		hidden = CreateFrame("Frame", "budsUI_HiddenParent", UIParent)
		hidden:Hide()
	end

	for i = 1, 8 do
		local group = _G["RaidGroup" .. i]
		if group then
			group:UnregisterAllEvents()
			group:Hide()
			group:SetParent(hidden)
		end
	end
end

-- ---------------------------------------------------------------------------
-- Lifecycle (runs at file load; oUF and the config are already up)
-- ---------------------------------------------------------------------------
function Module:Init()
	if not C.Unitframe.Enable then
		return
	end
	if not oUF then
		return
	end

	if Module.ApplyUnitColors then
		Module.ApplyUnitColors()
	end

	for name, style in pairs(Module.Styles) do
		oUF:RegisterStyle("budsUI_" .. name, style)
	end

	-- Our frames replace Blizzard's (Init only runs with C.Unitframe.Enable),
	-- so always hand the units to oUF: no toggle, no overlap.
	for _, def in ipairs(Module.UnitDefs) do
		oUF:DisableBlizzard(def.unit)
	end
	oUF:DisableBlizzard("party")
	oUF:DisableBlizzard("boss")

	if C.Unitframe.Party.Enable or C.Unitframe.Raid.Enable then
		self:DisableBlizzardRaid()
	end

	for _, def in ipairs(Module.UnitDefs) do
		self:SpawnUnit(def)
	end

	self:SpawnBoss()
	self:SpawnParty()
	self:SpawnRaid()

	K.RefreshBorderColors()
end

-- ---------------------------------------------------------------------------
-- Test / preview mode (out of combat only).
-- Forces the real single frames to show with the player's data. Secure group
-- headers cannot conjure phantom units on 3.3.5, so party/raid previews show
-- whoever is really in the group.
-- ---------------------------------------------------------------------------
function Module:ToggleTest()
	if InCombatLockdown() then
		K.Print("Cannot toggle test mode in combat.")
		return
	end

	self.testMode = not self.testMode
	local on = self.testMode

	if on then
		self:EnterConfigMode()
		K.Print("Unit frame test mode ON. Single frames are forced on with your data so you can position them.")
	else
		self:ExitConfigMode()
		K.Print("Unit frame test mode OFF.")
	end
end
