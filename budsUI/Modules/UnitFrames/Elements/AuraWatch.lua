--[[-----------------------------------------------------------------------------
Addon: budsUI
File: Modules/UnitFrames/Elements/AuraWatch.lua
Purpose:
	Corner Aura Watch for party and raid frames. Small dots (or icons) in the
	frame corners light up when one of the tracked auras from AuraWatchList
	is present, so a healer can read their heals over time without squinting
	at the debuff row. Registered as our own oUF element so it refreshes on
	UNIT_AURA like everything else.

	Ported from KkthnxUI retail to WoW 3.3.5: aura data comes from UnitAura
	(no C_UnitAuras), which also returns the spell id here.
-----------------------------------------------------------------------------]]

local Engine = select(2, ...)
local K, C = Engine:unpack()
local Module = Engine.UnitFrames
local Build = Module.Build
local oUF = Engine.oUF or _G.budsUF

local CreateFrame = CreateFrame
local UnitAura = UnitAura
local UnitIsUnit = UnitIsUnit

-- Where each named corner sits on the health bar, with a small inset so the
-- dot clears the border.
local CORNERS = {
	TOPLEFT = { "TOPLEFT", 2, -2 },
	TOPRIGHT = { "TOPRIGHT", -2, -2 },
	BOTTOMLEFT = { "BOTTOMLEFT", 2, 2 },
	BOTTOMRIGHT = { "BOTTOMRIGHT", -2, 2 },
	CENTER = { "CENTER", 0, 0 },
}

-- ---------------------------------------------------------------------------
-- Corner widgets
-- ---------------------------------------------------------------------------

-- Build one corner widget on demand: a dot plus a hidden icon/swipe so a
-- single widget can render either style depending on the matched entry.
local function GetCorner(element, corner)
	if element.corners[corner] then
		return element.corners[corner]
	end

	local anchor = CORNERS[corner] or CORNERS.TOPLEFT
	local host = element.__owner.Health or element.__owner
	local size = element.size or 8

	local button = CreateFrame("Frame", nil, element)
	button:SetSize(size, size)
	button:SetPoint(anchor[1], host, anchor[1], anchor[2], anchor[3])
	button:SetFrameLevel(host:GetFrameLevel() + 5)
	button:Hide()

	local dot = button:CreateTexture(nil, "OVERLAY")
	dot:SetAllPoints()
	dot:SetTexture("Interface\\Buttons\\WHITE8X8")
	button.Dot = dot

	local icon = button:CreateTexture(nil, "OVERLAY")
	icon:SetAllPoints()
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	icon:Hide()
	button.Icon = icon
	K.CreateBorder(button, 10)
	button:SetBackdropBorderColor(0, 0, 0, 0)

	local cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cd:SetAllPoints()
	cd:SetReverse(true)
	K.StyleCooldownSwipe(cd)
	cd:Hide()
	button.Cooldown = cd

	local count = button:CreateFontString(nil, "OVERLAY")
	K.SetFont(count, 12, K.FontOutlineStyle())
	count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -1)
	button.Count = count

	element.corners[corner] = button
	return button
end

-- Show a matched entry in its corner, either as a plain coloured dot or as
-- the spell icon with its swipe.
local function ShowEntry(element, entry, icon, count, duration, expiration)
	local button = GetCorner(element, entry.corner or "TOPLEFT")

	if entry.style == "icon" then
		button.Dot:Hide()
		button.Icon:SetTexture(icon)
		button.Icon:Show()
		button:SetBackdropBorderColor(0, 0, 0, 1)

		if duration and expiration and duration > 0 then
			button.Cooldown:SetCooldown(expiration - duration, duration)
			button.Cooldown:Show()
		else
			button.Cooldown:Hide()
		end
	else
		button.Icon:Hide()
		button.Cooldown:Hide()
		button:SetBackdropBorderColor(0, 0, 0, 0)
		local c = entry.color or { 1, 1, 1 }
		button.Dot:SetVertexColor(c[1], c[2], c[3])
		button.Dot:Show()
	end

	if count and count > 1 then
		button.Count:SetText(count)
	else
		button.Count:SetText("")
	end

	button:Show()
end

-- ---------------------------------------------------------------------------
-- oUF element
-- ---------------------------------------------------------------------------

local function Update(self, _, unit)
	if unit and unit ~= self.unit then
		return
	end
	local element = self.AuraWatch
	unit = self.unit
	if not unit or not element.watch then
		return
	end

	-- Hide last pass first, then relight only what is present now.
	for _, button in pairs(element.corners) do
		button:Hide()
	end

	for _, filter in ipairs(element.filters) do
		for i = 1, 40 do
			local name, _, icon, count, _, duration, expiration, caster, _, _, spellId = UnitAura(unit, i, filter)
			if not name then
				break
			end
			local entry = spellId and element.watch[spellId]
			if entry then
				if not entry.mine or (caster and (UnitIsUnit(caster, "player") or UnitIsUnit(caster, "pet") or UnitIsUnit(caster, "vehicle"))) then
					ShowEntry(element, entry, icon, count, duration, expiration)
				end
			end
		end
	end
end

local function Path(self, ...)
	return (self.AuraWatch.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, "ForceUpdate", element.__owner.unit)
end

local function Enable(self)
	local element = self.AuraWatch
	if element then
		element.__owner = self
		element.ForceUpdate = ForceUpdate
		self:RegisterEvent("UNIT_AURA", Path)
		return true
	end
end

local function Disable(self)
	local element = self.AuraWatch
	if element then
		self:UnregisterEvent("UNIT_AURA", Path)
		for _, button in pairs(element.corners) do
			button:Hide()
		end
	end
end

oUF:AddElement("AuraWatch", Path, Enable, Disable)

-- ---------------------------------------------------------------------------
-- Builder
-- ---------------------------------------------------------------------------

-- Attaches the watch to a group frame. size is the dot/icon edge in pixels.
function Build.AuraWatch(self, size)
	if not C.Unitframe.AuraWatch then
		return
	end
	local watch = K.AuraWatch
	if not watch or not next(watch) then
		return
	end

	local element = CreateFrame("Frame", nil, self)
	element:SetAllPoints(self.Health or self)
	element.size = size or 8
	element.corners = {}
	element.watch = watch
	-- Both lists so a tracked debuff (rare) can share the system with buffs.
	element.filters = { "HELPFUL", "HARMFUL" }

	self.AuraWatch = element
	return element
end
