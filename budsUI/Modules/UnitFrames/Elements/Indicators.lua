--[[-----------------------------------------------------------------------------
Addon: budsUI
File: Modules/UnitFrames/Elements/Indicators.lua
Purpose:
	The small status icons: raid marker, combat, resting, leader, role, ready
	check, resurrect, summon.

	Every icon sits inside the health bar rather than poking out above it.
	Group frames are laid out by a secure header, so anything that overflowed
	the frame would land on the neighbour above.

	Threat is the exception: instead of yet another icon it recolours the
	health border, which is far easier to read mid pull.

	Ported from KkthnxUI retail to WoW 3.3.5:
	- classic oUF Threat PostUpdate signature (element, unit, status, r,g,b);
	- dispel highlight scans with UnitAura (no C_UnitAuras);
	- no phase indicator (no phasing API);
	- resting/combat use the Blizzard state icon with 3.3.5 texcoords;
	- group role shows a tank/healer letter (no role icon art on 3.3.5);
	- no quest indicator (no quest-mob unit API on 3.3.5).
-----------------------------------------------------------------------------]]

local Engine = select(2, ...)
local K, C = Engine:unpack()
local Module = Engine.UnitFrames
local Build = Module.Build
local oUF = Engine.oUF or _G.budsUF

local CreateFrame = CreateFrame
local DebuffTypeColor = DebuffTypeColor
local UnitExists = UnitExists
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitIsUnit = UnitIsUnit

-- ---------------------------------------------------------------------------
-- Mouseover and target-select highlight
-- ---------------------------------------------------------------------------

-- Show the select texture while this frame's unit is the current target. Runs
-- for every frame on PLAYER_TARGET_CHANGED, so a party member lighting up the
-- moment you target them is handled without a per-unit event.
local function SelectUpdate(self)
	local highlight = self.KKUI_Select
	if not highlight then
		return
	end
	local unit = self.unit
	local isTarget = unit and UnitExists(unit) and UnitIsUnit(unit, "target")
	-- 3.3.5 has no Region:SetShown (MoP+); branch explicitly.
	if isTarget then
		highlight:Show()
	else
		highlight:Hide()
	end
end

local function SelectForceUpdate(element)
	return SelectUpdate(element.__owner)
end

local function SelectEnable(self)
	if self.KKUI_SelectHighlight then
		self.KKUI_SelectHighlight.__owner = self
		self.KKUI_SelectHighlight.ForceUpdate = SelectForceUpdate
		self:RegisterEvent("PLAYER_TARGET_CHANGED", SelectUpdate, true)
		return true
	end
end

local function SelectDisable(self)
	if self.KKUI_SelectHighlight then
		self:UnregisterEvent("PLAYER_TARGET_CHANGED", SelectUpdate)
	end
end

oUF:AddElement("KKUI_SelectHighlight", SelectUpdate, SelectEnable, SelectDisable)

-- A hover texture shown while the cursor is over the frame, and a select
-- texture shown while the frame's unit is the target. Both sit over the
-- health bar as a flat additive tint: accent for the cursor, gold for the
-- target.
local function TintOverlay(anchor, sublevel, color, alpha)
	local tex = anchor:CreateTexture(nil, "OVERLAY", nil, sublevel)
	tex:SetPoint("TOPLEFT", anchor, "TOPLEFT", -1, 1)
	tex:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 1, -1)
	tex:SetTexture(color[1], color[2], color[3], alpha)
	tex:SetBlendMode("ADD")
	tex:Hide()
	return tex
end

function Build.Highlight(self)
	local anchor = self.Health or self

	local hover = TintOverlay(anchor, 6, K.Colors.accent, K.GradientAlpha.hover)
	self.KKUI_Hover = hover
	self:HookScript("OnEnter", function()
		hover:Show()
	end)
	self:HookScript("OnLeave", function()
		hover:Hide()
	end)

	-- The target-select glow is only wanted on the group frames, where picking
	-- a member out of the grid matters.
	if self.mystyle == "party" or self.mystyle == "raid" then
		local selectTex = TintOverlay(anchor, 7, K.Colors.gold, K.GradientAlpha.select)
		self.KKUI_Select = selectTex

		-- Marker so oUF enables the select element (it drives KKUI_Select).
		self.KKUI_SelectHighlight = self.KKUI_SelectHighlight or {}
	end
end

-- Small helper so every icon below is one line.
local function Icon(parent, size, ...)
	local texture = parent:CreateTexture(nil, "OVERLAY")
	texture:SetSize(size, size)
	texture:SetPoint(...)
	return texture
end

-- ---------------------------------------------------------------------------
-- Threat on the health border
-- ---------------------------------------------------------------------------
local function ThreatPostUpdate(element, unit, status, r, g, b)
	local frame = element.__owner
	frame.__threatColor = (status and status > 0) and { r, g, b } or nil
	Module.RefreshHealthBorder(frame)
end

function Build.Threat(self)
	-- Called from Build.Indicators, so a style that also asks for it directly
	-- must not end up with a second orphaned texture on every frame.
	if self.ThreatIndicator then
		return self.ThreatIndicator
	end
	-- oUF wants a widget it can show, hide, and tint. We only care about the
	-- colour it hands to PostUpdate, so the widget itself stays invisible.
	local proxy = self.Health:CreateTexture(nil, "OVERLAY")
	proxy:SetSize(1, 1)
	proxy:SetPoint("CENTER")
	proxy:SetAlpha(0)
	proxy.PostUpdate = ThreatPostUpdate

	self.ThreatIndicator = proxy
	return proxy
end

-- ---------------------------------------------------------------------------
-- Dispellable debuff highlight (party / raid)
-- ---------------------------------------------------------------------------
local function DispelColor(dtype)
	local c = dtype and DebuffTypeColor[dtype]
	if c then
		return c.r, c.g, c.b
	end
end

-- Colour the health border for the first dispellable debuff on the unit.
-- Implemented as a real oUF element so oUF drives it on UNIT_AURA and
-- re-runs it when a header child is handed a new unit.
local function DispelUpdate(self, _, unit)
	if unit and unit ~= self.unit then
		return
	end
	unit = self.unit
	if not unit then
		return
	end

	local color
	for i = 1, 40 do
		local name, _, _, _, dtype = UnitAura(unit, i, "HARMFUL")
		if not name then
			break
		end
		-- Only highlight debuffs this class can actually remove, so it never
		-- nags about a school that cannot be dispelled.
		if dtype and K.CanDispel and K.CanDispel[dtype] then
			local r, g, b = DispelColor(dtype)
			if r then
				color = { r, g, b }
				break
			end
		end
	end

	self.__dispelColor = color
	Module.RefreshHealthBorder(self)
end

local function DispelPath(self, ...)
	return (self.DispelHighlight.Override or DispelUpdate)(self, ...)
end

local function DispelForceUpdate(element)
	return DispelPath(element.__owner, "ForceUpdate", element.__owner.unit)
end

local function DispelEnable(self)
	local element = self.DispelHighlight
	if element then
		element.__owner = self
		element.ForceUpdate = DispelForceUpdate
		self:RegisterEvent("UNIT_AURA", DispelPath)
		return true
	end
end

local function DispelDisable(self)
	local element = self.DispelHighlight
	if element then
		self:UnregisterEvent("UNIT_AURA", DispelPath)
		self.__dispelColor = nil
		Module.RefreshHealthBorder(self)
	end
end

oUF:AddElement("DispelHighlight", DispelPath, DispelEnable, DispelDisable)

-- The element only needs a truthy table for oUF to enable and drive it, the
-- work happens on the shared health border, so there is no widget to position.
function Build.DispelHighlight(self)
	self.DispelHighlight = {}
end

-- ---------------------------------------------------------------------------
-- Indicator sets
-- ---------------------------------------------------------------------------
-- Corners are assigned once, here and in the sets below, so no two icons
-- ever land on the same one:
--   top left     resting, leader, assistant
--   top center   raid marker (double size, reads over the bar middle)
--   bottom left  group role
--   bottom right raid role
-- Text always runs down the middle, so it stays clear of all four.
function Build.Indicators(self, size)
	local health = self.Health

	-- Own raised holder: the marker hangs above the bar, where the name
	-- strip holder and the border edge (both above health's own layers)
	-- would otherwise paint over it.
	local markerSize = size or 24
	local holder = CreateFrame("Frame", nil, health)
	holder:SetSize(markerSize, markerSize)
	holder:SetPoint("TOP", health, "TOP", 0, 8)
	holder:SetFrameLevel(health:GetFrameLevel() + 5)
	local marker = holder:CreateTexture(nil, "OVERLAY")
	marker:SetAllPoints()
	self.RaidTargetIndicator = marker

	Build.Threat(self)
end

-- No phasing API on 3.3.5. No-op kept so styles read unchanged.
function Build.PhaseIndicator(self)
	return nil
end

-- Player only: combat and resting flags on the Blizzard state icon.
function Build.PlayerIndicators(self)
	local health = self.Health

	local combat = Icon(health, 20, "LEFT", health, "LEFT", 4, 0)
	combat:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
	combat:SetTexCoord(0.5, 1, 0, 0.49)
	self.CombatIndicator = combat

	local anchor = self.Portrait or health
	local rest = CreateFrame("Frame", nil, self)
	rest:SetSize(22, 22)
	rest:SetPoint("CENTER", anchor, "TOPLEFT", 3, -3)
	rest:SetFrameLevel(self:GetFrameLevel() + 6)
	local tex = rest:CreateTexture(nil, "OVERLAY")
	tex:SetAllPoints()
	tex:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
	tex:SetTexCoord(0, 0.5, 0, 0.421875)
	rest.Icon = tex
	self.RestingIndicator = rest
end

-- No quest-mob unit API on 3.3.5. No-op kept so styles read unchanged.
function Build.QuestIndicator(self)
	return nil
end

-- Fade a frame while its unit is out of range, so an unreachable target or
-- group member reads as dimmed. oUF drives the alpha from its range check.
function Build.Range(self)
	if not C.Unitframe.RangeFade then
		return
	end
	self.Range = {
		insideAlpha = 1,
		outsideAlpha = C.Unitframe.RangeAlpha or 0.4,
	}
	return self.Range
end

-- Party and raid: everything a healer needs to see on a roster.
function Build.GroupIndicators(self)
	local health = self.Health

	-- Leader and assistant share a corner. Only one can ever be shown.
	self.LeaderIndicator = Icon(health, 12, "TOPLEFT", health, "TOPLEFT", 1, -1)
	self.AssistantIndicator = Icon(health, 12, "TOPLEFT", health, "TOPLEFT", 1, -1)

	-- 3.3.5 ships no role icon art; a small letter reads just as well and can
	-- never render as a green square. Only tank and healer are worth showing.
	local roleText = health:CreateFontString(nil, "OVERLAY")
	K.SetFont(roleText, 12, K.FontOutlineStyle())
	roleText:SetPoint("BOTTOMLEFT", health, "BOTTOMLEFT", 2, 0)
	roleText:Hide()
	self.GroupRoleIndicator = Icon(health, 1, "BOTTOMLEFT", health, "BOTTOMLEFT", 0, 0)
	self.GroupRoleIndicator:SetAlpha(0)
	-- oUF's default role updater points the texture at ElvUI's media (our oUF
	-- copy is verbatim ElvUI-7, so it stays untouched); override it so only
	-- the letter PostUpdate below runs and that path is never touched.
	self.GroupRoleIndicator.Override = function(frame)
		local element = frame.GroupRoleIndicator
		if element.PostUpdate then
			return element:PostUpdate(UnitGroupRolesAssigned(frame.unit))
		end
	end
	self.GroupRoleIndicator.PostUpdate = function(_, isTank, isHealer)
		if isTank then
			roleText:SetText("T")
			roleText:SetTextColor(0.5, 0.7, 1)
			roleText:Show()
		elseif isHealer then
			roleText:SetText("+")
			roleText:SetTextColor(0.4, 0.9, 0.4)
			roleText:Show()
		else
			roleText:Hide()
		end
	end

	self.RaidRoleIndicator = Icon(health, 11, "BOTTOMRIGHT", health, "BOTTOMRIGHT", -1, 1)

	-- Transient overlays. They only appear for a few seconds at a time, so
	-- they are allowed to sit right over the middle of the bar.
	self.ReadyCheckIndicator = Icon(health, 16, "CENTER", health, "CENTER", 0, 0)
	self.ResurrectIndicator = Icon(health, 18, "CENTER", health, "CENTER", 0, 0)
	self.SummonIndicator = Icon(health, 18, "CENTER", health, "CENTER", 0, 0)

	-- Fade members who are out of range so they read as unreachable.
	Build.Range(self)
end
