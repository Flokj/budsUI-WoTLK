local K, C, L, _ = select(2, ...):unpack()
if C.Nameplate.Enable ~= true then return end

-- FrostAtomUI Modules/NamePlates/Totems.lua, ported to budsUI's skinned
-- Blizzard plates: a totem plate shows a clickable icon instead of the UI.

local GetTime = GetTime
local band = bit.band
local sub = string.sub
local max, tonumber, ceil = math.max, tonumber, math.ceil
local wipe = wipe
local CreateFrame = CreateFrame

local Data = K.NameplateTotemData
if not Data then return end

local TICK_EVENTS = Data.TICK_EVENTS
local spells = Data.spells
local byEntry = Data.byEntry
local byName = Data.byName
local tickSpells = Data.tickSpells
local learned = {}

local summons = {}
local ownerSlots = {}
local claimed = {}
local timed = {}

local REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
local GUID_CREATURE = "F13"
local ICON_CROP = 0.08
local HOVER_ALPHA = 0.15
local DURATION_BAR_HEIGHT = 2
local TIMER_INTERVAL = 0.1
local TARGET_SCALE = 1.2
-- FrostAtom primitives 1:1: ns.Media (WHITE8x8, UI-Tooltip-Border, ARIALN),
-- ns.CreateBackdrop(9.2, 2), NamePlates.BORDER_INSET — no budsUI theming.
local BORDER_INSET = 3
local BACKDROP_INSET = 2
local TOTEM_EDGE_SIZE = 8 * 1.15
local PULSE_EDGE_SIZE = 8
local HIT_PADDING = 4
local BLANK = "Interface\\Buttons\\WHITE8x8"
local BORDER = "Interface\\Tooltips\\UI-Tooltip-Border"
local TIMER_FONT = "Fonts\\ARIALN.ttf"
local THEME_BACKDROP_COLOR = { 0.06, 0.06, 0.06, 0.9 }
local THEME_BORDER_COLOR = { 0.35, 0.35, 0.35, 1 }
local DECIMAL_THRESHOLD = 3
local EXPIRING_COLOR = { 1, 0, 0 }
local SECONDS_COLOR = { 1, 1, 0 }
local MINUTES_COLOR = { 1, 1, 1 }
local REACTION_COLORS = {
	hostile = { 1, 0.15, 0.15 },
	neutral = { 1, 0.85, 0.1 },
	friendly = { 0.15, 1, 0.15 },
}

local function SetShown(frame, shown)
	if shown then
		frame:Show()
	else
		frame:Hide()
	end
end

local skinned = {} -- every skinned plate (Blizzard recycles them)
local mode = {} -- plate -> true while rendering the totem icon

-- Creature entry from guid (0xF13...).
local function entryOf(guid)
	if guid and sub(guid, 3, 5) == GUID_CREATURE then
		return tonumber(sub(guid, 7, 12), 16)
	end
end

local function plateName(frame)
	local hp = frame.hp
	if not hp then return nil end
	if hp.oldname then
		local n = hp.oldname:GetText()
		if n then return n end
	end
	return hp.name and hp.name:GetText() or nil
end

-- Totem spellId for a plate: by creature entry, then by name.
local function identify(frame)
	local entry = entryOf(frame.guid)
	if entry then
		return byEntry[entry]
	end
	local name = plateName(frame)
	return name and (learned[name] or byName[name]) or nil
end

local function setTimerText(timer, remain)
	if remain <= DECIMAL_THRESHOLD then
		timer:SetTextColor(EXPIRING_COLOR[1], EXPIRING_COLOR[2], EXPIRING_COLOR[3])
		timer:SetFormattedText("%.1f", remain)
	elseif remain <= 60 then
		timer:SetTextColor(SECONDS_COLOR[1], SECONDS_COLOR[2], SECONDS_COLOR[3])
		timer:SetFormattedText("%d", ceil(remain))
	else
		timer:SetTextColor(MINUTES_COLOR[1], MINUTES_COLOR[2], MINUTES_COLOR[3])
		timer:SetFormattedText("%dm", ceil(remain / 60))
	end
end

local function release(plate)
	local guid = plate.totemSummon
	if guid then
		plate.totemSummon = nil
		if claimed[guid] == plate then
			claimed[guid] = nil
		end
	end
	timed[plate] = nil
	local totem = plate.totem
	if totem then
		totem.timer:Hide()
		totem.bar:Hide()
		totem.pulse:Hide()
	end
end

local function updateTimer(plate, now, textDue)
	local record = summons[plate.totemSummon]
	local remain = record and record.expires - now
	if not remain or remain <= 0 then
		release(plate)
		return
	end
	local totem = plate.totem
	if textDue and totem.timer:IsShown() then
		setTimerText(totem.timer, remain)
		totem.bar:SetWidth(max(totem.iconSize * remain / record.duration, 0.1))
	end
	local pulse = record.pulse
	if pulse and totem.pulse:IsShown() then
		totem.pulse.bar:SetValue((now - record.lastTick) % pulse.period / pulse.period)
	end
end

-- 0.1s ticker for timer text, duration bar and pulse (hidden when idle).
local ticker = CreateFrame("Frame")
ticker:Hide()
ticker.nextTick = 0
ticker:SetScript("OnUpdate", function(self)
	local now = GetTime()
	local textDue = now >= self.nextTick
	if textDue then
		self.nextTick = now + TIMER_INTERVAL
	end
	for plate in pairs(timed) do
		updateTimer(plate, now, textDue)
	end
	if not next(timed) then
		self:Hide()
	end
end)

local function findSummon(plate, spellId, now)
	local guid = plate.guid
	if guid then
		local record = summons[guid]
		return record and record.expires > now and guid or nil
	end
	local name, hostile = plateName(plate), plate.isFriendly ~= true
	local found
	for other, record in pairs(summons) do
		if
			record.spellId == spellId
			and record.name == name
			and record.hostile == hostile
			and record.expires > now
			and not claimed[other]
		then
			if found then
				return
			end
			found = other
		end
	end
	return found
end

local function bind(plate)
	local spellId = plate.totemSpell
	if not spellId then
		return
	end
	local now = GetTime()
	local guid = (C.Nameplate.TotemTimer or C.Nameplate.TotemPulse) and findSummon(plate, spellId, now)
	if guid == plate.totemSummon then
		return
	end
	release(plate)
	if not guid then
		return
	end
	local record = summons[guid]
	local showTimer = C.Nameplate.TotemTimer and record.summoned
	local showPulse = C.Nameplate.TotemPulse and record.pulse ~= nil
	if not showTimer and not showPulse then
		return
	end
	local owner = claimed[guid]
	if owner and owner ~= plate then
		release(owner)
	end
	claimed[guid] = plate
	plate.totemSummon = guid
	timed[plate] = true
	local totem = plate.totem
	SetShown(totem.timer, showTimer)
	SetShown(totem.bar, showTimer)
	SetShown(totem.pulse, showPulse)
	ticker.nextTick = 0
	ticker:Show()
end

local function dismiss(guid)
	local record = summons[guid]
	if not record then
		return
	end
	summons[guid] = nil
	local slots = record.owner and ownerSlots[record.owner]
	if slots and slots[record.slot] == guid then
		slots[record.slot] = nil
	end
	local plate = claimed[guid]
	if plate then
		release(plate)
	end
end

local function prune(now)
	for guid, record in pairs(summons) do
		if record.expires <= now then
			dismiss(guid)
		end
	end
end

-- FrostAtom setSize: holder = iconSize + BORDER_INSET*2, icon inset 3.
local function sizedTotem(totem, iconSize)
	totem.iconSize = iconSize
	local size = iconSize + BORDER_INSET * 2
	totem:SetSize(size, size)
end

-- Snapshot the stock click zone the first time we take the plate over.
local function rememberHit(plate)
	if not plate.totemW then
		local w, h = plate:GetWidth(), plate:GetHeight()
		if w and w > 1 then
			plate.totemW, plate.totemH = w, h
		end
	end
end

-- Give the stock click zone back (icon mode off or plate recycled).
local function restoreHit(plate)
	if plate.totemConcealed or plate.totemHit then
		plate.totemConcealed = nil
		plate.totemHit = nil
		local w = plate.totemW
		if w and w > 1 and K.NameplateHitRect_Update then
			K.NameplateHitRect_Update(plate, w, plate.totemH or plate:GetHeight(), false)
		end
	end
	plate.totemW, plate.totemH = nil, nil
end

-- Hide the skinned plate UI. The hover overlay is Blizzard-driven and
-- re-shows itself on mouseover, so its texture is emptied too: a re-show
-- of an empty texture renders nothing (kills the old-plate highlight).
local function hidePlateUI(plate)
	local hp = plate.hp
	hp:SetAlpha(0)
	if hp.backdrop then hp.backdrop:Hide() end
	if hp.oldname then hp.oldname:Hide() end
	if hp.oldlevel then hp.oldlevel:Hide() end
	if hp.boss then hp.boss:Hide() end
	if hp.elite then hp.elite:Hide() end
	local overlay = plate.overlay
	if overlay then
		overlay:SetTexture("")
		overlay:Hide()
	end
	plate.cb:Hide()
	if plate.raidicon then plate.raidicon:Hide() end
	if plate.threat then plate.threat:Hide() end
	if plate.class then plate.class:Hide() end
	if plate.class and plate.class.Glow then plate.class.Glow:Hide() end
	if plate.healerIcon then plate.healerIcon:Hide() end
end

-- Bring the skinned plate UI back (icon mode off / unfiltered / recycle).
local function showPlateUI(plate)
	local hp = plate.hp
	hp:SetAlpha(1)
	if hp.backdrop then hp.backdrop:Show() end
	if hp.oldname then hp.oldname:Show() end
	if hp.oldlevel then hp.oldlevel:Show() end
	if hp.boss then hp.boss:Show() end
	if hp.elite then hp.elite:Show() end
	if hp.name then hp.name:Show() end
	if hp.level then hp.level:Show() end
	if hp.value then hp.value:Show() end
	if hp.bg then hp.bg:Show() end
	local overlay = plate.overlay
	if overlay then
		overlay:SetTexture(1, 1, 1, 0.15)
	end
	if plate.threat then plate.threat:Show() end
	if plate.class then plate.class:Show() end
	-- cb/raidicon stay hidden on purpose - Blizzard restores them on the
	-- next hover/cast/raid target (RestoreBlacklistShow rule).
end

-- Switch the plate into icon mode: hide the skinned UI, keep the plate
-- clickable through an icon-sized hit rect (K.NameplateHitRect_Update).
local function enterIconMode(plate, spellId)
	if mode[plate] then
		return
	end
	mode[plate] = true
	rememberHit(plate)
	plate.totemConcealed = nil
	hidePlateUI(plate)
	plate.totemSpell = spellId
	plate.totem:Show()
	bind(plate)
end

-- Back to a full skinned nameplate after the icon was hidden/unfiltered.
local function leaveIconMode(plate)
	if not mode[plate] then
		return
	end
	mode[plate] = nil
	release(plate)
	plate.totemSpell = nil
	plate.totem:Hide()
	showPlateUI(plate)
	restoreHit(plate)
end

-- Full concealment for filtered/blacklisted totems (FrostAtom ApplyHidden
-- model): plate UI hidden, icon hidden, click rect zeroed until unfiltered.
local function concealTotem(plate)
	if mode[plate] then
		mode[plate] = nil
		release(plate)
		plate.totemSpell = nil
		plate.totem:Hide()
	end
	if not plate.totemConcealed then
		rememberHit(plate)
		plate.totemConcealed = true
		hidePlateUI(plate)
		if K.NameplateHitRect_Update then
			K.NameplateHitRect_Update(plate, plate.totemW or plate:GetWidth(), 0, true)
		end
	end
end

-- Per-pass state update: identify, filter, hit rect, reaction, hover, scale.
function K.NameplateTotems_Update(plate)
	if not plate or not plate.totem or plate.hide or not plate:IsShown() then
		return
	end
	if C.Nameplate.TotemIcons ~= true then
		-- Master switch off: fall back to full plates immediately.
		if mode[plate] then
			leaveIconMode(plate)
		elseif plate.totemConcealed then
			showPlateUI(plate)
			restoreHit(plate)
		end
		return
	end
	local totem = plate.totem
	local spellId = plate.totemSpell
	if not spellId and C.Nameplate.TotemIcons == true then
		spellId = identify(plate)
		if spellId then
			plate.totemSpell = spellId
		end
	end

	-- Filter: "important" hides every other totem entirely (FrostAtomUI).
	if spellId and C.Nameplate.TotemFilter == "important" and not Data.IsImportant(spellId) then
		concealTotem(plate)
		return
	end

	if not spellId then
		if mode[plate] then
			leaveIconMode(plate)
		elseif plate.totemConcealed then
			showPlateUI(plate)
			restoreHit(plate)
		end
		return
	end

	enterIconMode(plate, spellId)
	totem.icon:SetTexture(spells[spellId].icon or "")

	-- Target bump: 1.2x while this totem is the target; 0.4s debounce
	-- so a fast target-away does not blink the size at the 0.2s cadence.
	local isTarget = GetTime() - (plate.totemTargetAt or 0) < 0.4
	local targetName = UnitName("target")
	if targetName and plateName(plate) == targetName then
		if not isTarget then
			plate.totemTargetAt = GetTime()
			isTarget = true
		end
	else
		plate.totemTargetAt = nil
	end
	local size = (C.Nameplate.TotemIconSize or 24) * (isTarget and TARGET_SCALE or 1)
	if size ~= totem.iconSize then
		sizedTotem(totem, size)
	end

	-- Clickable zone follows the icon (FrostAtom UpdateHitRect: holder
	-- width plus 2*HitPadding of slack around the icon).
	local hit = size + BORDER_INSET * 2 + HIT_PADDING * 2
	if K.NameplateHitRect_Update and hit ~= plate.totemHit then
		plate.totemHit = hit
		rememberHit(plate)
		K.NameplateHitRect_Update(plate, hit, hit, false)
	end

	-- Border by reaction (plate.plateReaction is maintained by Colorize).
	local reaction = plate.plateReaction or "hostile"
	local color = REACTION_COLORS[reaction] or REACTION_COLORS.hostile
	if color ~= totem.borderColor then
		totem.borderColor = color
		totem:SetBackdropBorderColor(color[1], color[2], color[3], 1)
		totem.edge:SetBackdropBorderColor(color[1], color[2], color[3], 1)
	end

	-- Hover highlight on the icon.
	local hovered = plate:IsMouseOver()
	if hovered ~= totem.hovered then
		totem.hovered = hovered
		SetShown(totem.hover, hovered)
	end

	-- Pulse color (config live).
	local pulseColor = C.Nameplate.TotemPulseColor or { 0.3, 0.75, 1 }
	if pulseColor ~= totem.pulseColor then
		totem.pulseColor = pulseColor
		totem.pulse.bar:SetStatusBarColor(pulseColor[1], pulseColor[2], pulseColor[3], 1)
	end
	local pulseHeight = C.Nameplate.TotemPulseHeight or 4
	if pulseHeight ~= totem.pulseHeight then
		totem.pulseHeight = pulseHeight
		-- FrostAtom: pulse holder = bar height + BORDER_INSET*2.
		totem.pulse:SetHeight(pulseHeight + BORDER_INSET * 2)
	end
end

-- Build the icon stack once per skinned plate (Nameplate.lua SkinObjects).
function K.NameplateTotems_Setup(frame)
	if not frame or not frame.hp or frame.totem then
		return
	end
	skinned[frame] = true

	local totem = CreateFrame("Frame", nil, frame)
	-- FrostAtom snapTotem: icon top sits HIT_PADDING above the plate top,
	-- centered on the plate width.
	totem:SetPoint("TOP", frame, "TOP", 0, HIT_PADDING)
	totem:SetBackdrop({
		edgeFile = BORDER,
		edgeSize = TOTEM_EDGE_SIZE,
		bgFile = BLANK,
		insets = { top = BACKDROP_INSET, left = BACKDROP_INSET, bottom = BACKDROP_INSET, right = BACKDROP_INSET },
	})
	totem:SetBackdropColor(THEME_BACKDROP_COLOR[1], THEME_BACKDROP_COLOR[2], THEME_BACKDROP_COLOR[3], THEME_BACKDROP_COLOR[4])
	totem:SetBackdropBorderColor(THEME_BORDER_COLOR[1], THEME_BORDER_COLOR[2], THEME_BORDER_COLOR[3], 1)
	totem:SetFrameLevel(frame.hp:GetFrameLevel() + 2)
	totem:Hide()

	-- Second edge-only stroke over the same bounds (FrostAtom totem.edge).
	local edge = CreateFrame("Frame", nil, totem)
	edge:SetAllPoints()
	edge:SetFrameLevel(totem:GetFrameLevel() + 1)
	edge:SetBackdrop({
		edgeFile = BORDER,
		edgeSize = TOTEM_EDGE_SIZE,
	})
	totem.edge = edge

	local icon = totem:CreateTexture(nil, "ARTWORK")
	icon:SetPoint("TOPLEFT", totem, "TOPLEFT", BORDER_INSET, -BORDER_INSET)
	icon:SetPoint("BOTTOMRIGHT", totem, "BOTTOMRIGHT", -BORDER_INSET, BORDER_INSET)
	icon:SetTexCoord(ICON_CROP, 1 - ICON_CROP, ICON_CROP, 1 - ICON_CROP)
	totem.icon = icon

	local hover = totem:CreateTexture(nil, "OVERLAY")
	hover:SetAllPoints(icon)
	hover:SetTexture(BLANK)
	hover:SetBlendMode("ADD")
	hover:SetVertexColor(1, 1, 1, HOVER_ALPHA)
	hover:Hide()
	totem.hover = hover

	local bar = edge:CreateTexture(nil, "OVERLAY")
	bar:SetTexture(BLANK)
	bar:SetHeight(DURATION_BAR_HEIGHT)
	bar:SetPoint("BOTTOMLEFT", icon)
	bar:SetVertexColor(0.75, 0.4, 0)
	bar:Hide()
	totem.bar = bar

	local timer = edge:CreateFontString(nil, "OVERLAY")
	timer:SetPoint("CENTER", icon)
	timer:SetFont(TIMER_FONT, 15, "OUTLINE")
	timer:Hide()
	totem.timer = timer

	-- Pulse holder: NamePlates.CreateHolder geometry, edgeSize 8.
	local pulse = CreateFrame("Frame", nil, totem)
	pulse:SetPoint("BOTTOMLEFT", totem, "TOPLEFT", 0, 3)
	pulse:SetPoint("BOTTOMRIGHT", totem, "TOPRIGHT", 0, 3)
	pulse:SetHeight((C.Nameplate.TotemPulseHeight or 4) + BORDER_INSET * 2)
	pulse:SetBackdrop({
		edgeFile = BORDER,
		edgeSize = PULSE_EDGE_SIZE,
		bgFile = BLANK,
		insets = { top = BACKDROP_INSET, left = BACKDROP_INSET, bottom = BACKDROP_INSET, right = BACKDROP_INSET },
	})
	pulse:SetBackdropColor(THEME_BACKDROP_COLOR[1], THEME_BACKDROP_COLOR[2], THEME_BACKDROP_COLOR[3], THEME_BACKDROP_COLOR[4])
	pulse:SetBackdropBorderColor(THEME_BORDER_COLOR[1], THEME_BORDER_COLOR[2], THEME_BORDER_COLOR[3], 1)
	pulse:SetFrameLevel(totem:GetFrameLevel() + 1)
	pulse:Hide()

	local pulseBar = CreateFrame("StatusBar", nil, pulse)
	pulseBar:SetPoint("TOPLEFT", pulse, "TOPLEFT", BORDER_INSET, -BORDER_INSET)
	pulseBar:SetPoint("BOTTOMRIGHT", pulse, "BOTTOMRIGHT", -BORDER_INSET, BORDER_INSET)
	pulseBar:SetFrameLevel(pulse:GetFrameLevel() + 1)
	pulseBar:SetMinMaxValues(0, 1)
	pulseBar:SetStatusBarTexture(BLANK)
	local pulseColor = C.Nameplate.TotemPulseColor or { 0.3, 0.75, 1 }
	pulseBar:SetStatusBarColor(pulseColor[1], pulseColor[2], pulseColor[3], 1)
	pulse.bar = pulseBar
	totem.pulse = pulse

	sizedTotem(totem, C.Nameplate.TotemIconSize or 24)
	totem.pulseHeight = C.Nameplate.TotemPulseHeight or 4
	totem.pulseColor = pulseColor
	mode[frame] = nil
	frame.totem = totem
end

-- Totem icon must never leak through the blacklist: hide and release.
-- ApplyBlacklistHide zeroes the click zone on its own.
function K.NameplateTotems_OnBlacklisted(plate)
	if not plate or not plate.totem then
		return
	end
	concealTotem(plate)
end

-- Plate hidden: release the claim so the guid can bind to a new plate.
-- Blizzard recycles stock frames, so the skinned UI must come back too.
function K.NameplateTotems_OnPlateHide(plate)
	if not plate or not plate.totem then
		return
	end
	if mode[plate] then
		leaveIconMode(plate)
	else
		showPlateUI(plate)
		restoreHit(plate)
	end
	mode[plate] = nil
	plate.totemSpell = nil
	plate.totemSummon = nil
	timed[plate] = nil
	plate.totemHit = nil
	plate.totemTargetAt = nil
	if plate.guid and claimed[plate.guid] == plate then
		claimed[plate.guid] = nil
	end
	plate.totem.timer:Hide()
	plate.totem.bar:Hide()
	plate.totem.pulse:Hide()
	plate.totem:Hide()
end

-- Re-bind plates after a summon was learned from the combat log.
local function refreshNamed(name)
	for plate in pairs(skinned) do
		if plate:IsShown() and not plate.hide and plateName(plate) == name then
			if mode[plate] then
				bind(plate)
			else
				K.NameplateTotems_Update(plate)
			end
		end
	end
end

local function onSummon(srcGUID, dstGUID, dstName, dstFlags, spellId)
	local data = spells[spellId]
	if not data then
		return
	end
	local now = GetTime()
	prune(now)
	local slots = ownerSlots[srcGUID]
	if not slots then
		slots = {}
		ownerSlots[srcGUID] = slots
	end
	local previous = slots[data.slot]
	if previous then
		dismiss(previous)
	end
	slots[data.slot] = dstGUID
	summons[dstGUID] = {
		spellId = spellId,
		name = dstName,
		owner = srcGUID,
		slot = data.slot,
		duration = data.duration,
		expires = now + data.duration,
		hostile = band(dstFlags, REACTION_HOSTILE) ~= 0,
		summoned = true,
		pulse = data.pulse,
		lastTick = now,
	}
	if dstName then
		learned[dstName] = spellId
		refreshNamed(dstName)
	end
end

local function ownerTotem(owner, spellId)
	local slots = ownerSlots[owner]
	if not slots then
		return
	end
	for _, guid in pairs(slots) do
		local record = summons[guid]
		local pulse = record and record.pulse
		if pulse and pulse.ticks[spellId] then
			return record
		end
	end
end

local function onTick(srcGUID, srcName, srcFlags, spellId)
	local now = GetTime()
	local record = summons[srcGUID] or ownerTotem(srcGUID, spellId)
	if record then
		local pulse = record.pulse
		if pulse and pulse.ticks[spellId] then
			record.lastTick = now
		end
		return
	end
	local entry = entryOf(srcGUID)
	local summonSpell = entry and byEntry[entry]
	local data = summonSpell and spells[summonSpell]
	local pulse = data and data.pulse
	if not pulse or not pulse.ticks[spellId] or not srcName then
		return
	end
	summons[srcGUID] = {
		spellId = summonSpell,
		name = srcName,
		slot = data.slot,
		duration = data.duration,
		expires = now + data.duration,
		hostile = band(srcFlags, REACTION_HOSTILE) ~= 0,
		pulse = pulse,
		lastTick = now,
	}
	learned[srcName] = summonSpell
	refreshNamed(srcName)
end

-- Stock 3.3.5 CLEU handler args: self, event, timestamp, subEvent, ...
-- (no hideCaster, no raid flags).
local COMBAT_LOG = CreateFrame("Frame")
COMBAT_LOG:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
COMBAT_LOG:SetScript("OnEvent", function(_, _, _, event, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId)
	if TICK_EVENTS[event] then
		if tickSpells[spellId] then
			onTick(srcGUID, srcName, srcFlags, spellId)
		end
	elseif event == "SPELL_SUMMON" then
		onSummon(srcGUID, dstGUID, dstName, dstFlags, spellId)
	elseif (event == "UNIT_DIED" or event == "UNIT_DESTROYED") and summons[dstGUID] then
		dismiss(dstGUID)
	end
end)

-- Player zoning: drop every claim (FrostAtom onEnteringWorld).
local WORLD = CreateFrame("Frame")
WORLD:RegisterEvent("PLAYER_ENTERING_WORLD")
WORLD:SetScript("OnEvent", function()
	for plate in pairs(timed) do
		release(plate)
	end
	wipe(summons)
	wipe(ownerSlots)
	wipe(claimed)
	-- learned persists: names stay identifiable after a summon was seen.
end)
