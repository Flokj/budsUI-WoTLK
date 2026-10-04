--[[-----------------------------------------------------------------------------
Addon: budsUI
File: Modules/UnitFrames/HealPrediction.lua
Purpose:
  Incoming heals + absorb shields for the oUF health bars on WoW 3.3.5.
  The client has no prediction APIs for either, so both are
  reconstructed: LibHealComm-4.0 plus an own-cast fallback for heals, and a
  known-shield table decremented from the combat log for absorbs. Health
  bars opt in through Prediction.CreateBars and refresh through
  Prediction.Refresh / Prediction.Follow.

  Ported from FrostAtomUI Modules/HealPrediction.lua (Interface 30300) to
  the budsUI engine: Engine/UnitFrames table instead of the ns module
  framework, C.Unitframe keys instead of ns.Config, Module.Texture()
  instead of ns.Media.blank. No retail-only API.
-----------------------------------------------------------------------------]]

local Engine = select(2, ...)
local K, C = Engine:unpack()
local Module = Engine.UnitFrames
if not Module then return end

local UnitGUID, UnitName = UnitGUID, UnitName
local UnitExists, UnitCanAssist = UnitExists, UnitCanAssist
local UnitCastingInfo, UnitHealthMax = UnitCastingInfo, UnitHealthMax
local GetSpellInfo, GetTime = GetSpellInfo, GetTime
local pairs, next, wipe, select = pairs, next, wipe, select

local LibStub = LibStub
local HealComm = LibStub and LibStub("LibHealComm-4.0", true) or nil

local Prediction = {}
Prediction.CHANGED = "budsUI_PREDICTION_CHANGED"
Module.HealPrediction = Prediction

local HEALCOMM_WINDOW = 3
local HEALCOMM_CALLBACKS = {
	"HealComm_HealStarted",
	"HealComm_HealUpdated",
	"HealComm_HealDelayed",
	"HealComm_HealStopped",
}
local CAST_GRACE = 0.3
local FALLBACK_CAST_TIME = 3
local TICK_INTERVAL = 0.25
local BREAK_WINDOW = 0.5
local CHAIN_JUMP_RATIO = 0.6
local DIVINE_AEGIS_RATIO = 0.3
local GLOW_WIDTH = 6
local MIN_WIDTH = 1

local HEAL_SPELLS = {
	[48071] = 2050, -- Flash Heal
	[48063] = 4300, -- Greater Heal
	[48120] = 2240, -- Binding Heal
	[48782] = 5170, -- Holy Light
	[48785] = 830, -- Flash of Light
	[49273] = 3250, -- Healing Wave
	[49276] = 1740, -- Lesser Healing Wave
	[55459] = 1130, -- Chain Heal
	[48378] = 4090, -- Healing Touch
	[50464] = 2040, -- Nourish
	[48443] = 2360, -- Regrowth
}

local DIVINE_AEGIS = 47753 -- Divine Aegis

local SHIELDS = {}

local function addShield(amount, duration, fraction, ...)
	local info = { amount = amount, duration = duration, fraction = fraction }
	for i = 1, select("#", ...) do
		SHIELDS[select(i, ...)] = info
	end
end

addShield(4000, 30, nil, 17, 592, 600, 3747, 6065, 6066, 10898, 10899, 10900, 10901, 25217, 25218, 48065, 48066) -- Power Word: Shield
addShield(1500, 12, nil, DIVINE_AEGIS)
addShield(1500, 6, nil, 58597) -- Sacred Shield
addShield(5000, 60, nil, 11426, 13031, 13032, 13033, 27134, 33405, 43038, 43039) -- Ice Barrier
addShield(3000, 60, nil, 1463, 8494, 8495, 10191, 10192, 10193, 27131, 43019, 43020) -- Mana Shield
addShield(2500, 30, nil, 543, 8457, 8458, 10223, 10225, 27128, 43010) -- Fire Ward
addShield(2500, 30, nil, 6143, 8461, 8462, 10177, 28609, 32796, 43012) -- Frost Ward
addShield(3500, 30, nil, 6229, 11739, 11740, 28610, 47890, 47891) -- Shadow Ward
addShield(8000, 7, 0.5, 48707) -- Anti-Magic Shell
addShield(10000, 10, nil, 50461) -- Anti-Magic Zone
addShield(8000, 30, nil, 7812, 19438, 19440, 19441, 19442, 19443, 27273, 47985, 47986) -- Sacrifice
addShield(1500, 10, nil, 62606) -- Savage Defense

local healBase = {}
for spellId, amount in pairs(HEAL_SPELLS) do
	local name = GetSpellInfo(spellId)
	if name then
		healBase[name] = amount
	end
end

local casterTargets = { player = "target", target = "targettarget", focus = "focustarget" }
local LOOKUP_UNITS = { "player", "target", "focus", "mouseover", "pet" }

local function addGroupUnits(prefix, count)
	for i = 1, count do
		local unit = prefix .. i
		casterTargets[unit] = unit .. "target"
		LOOKUP_UNITS[#LOOKUP_UNITS + 1] = unit
	end
end
addGroupUnits("party", 4)
addGroupUnits("arena", 5)

local casts = {}
local shields = {}
local learnedHeals = {}
local learnedShields = {}
local lastCrit = {}
local sentSpell, sentTarget
local enabled = false
-- Health bars that opted in through CreateBars. Moved up here (the donor
-- declares it beside layout) so changed() below can refresh them directly.
-- oUF unit frames cannot take custom events, so there is no event to fire:
-- a state change walks this list instead of ns:Fire(CHANGED).
local bars = {}

-- Own event frame (never an oUF frame: those route unit events through
-- their own unit field and have no RegisterUnitEvent method). Plain
-- RegisterEvent catches every unit's casts; the handlers filter through
-- casterTargets.
local eventFrame = CreateFrame("Frame")
eventFrame:Hide()

local ticker = CreateFrame("Frame")
ticker:Hide()

local function changed(guid)
	if not guid then
		return
	end
	local showHeal, showAbsorb = C.Unitframe.HealthPrediction, C.Unitframe.AbsorbShields
	for i = 1, #bars do
		local bar = bars[i]
		local p = bar.prediction
		if p and p.guid == guid and bar:IsShown() then
			Prediction.Refresh(bar, guid, p.unit, showHeal, showAbsorb)
		end
	end
end

local function getOrCreate(parent, key)
	local child = parent[key]
	if not child then
		child = {}
		parent[key] = child
	end
	return child
end

local function startTicker()
	ticker.untilTick = TICK_INTERVAL
	ticker:Show()
end

local function unitByName(name)
	if not name or name == "" then
		return
	end
	for i = 1, #LOOKUP_UNITS do
		local unit = LOOKUP_UNITS[i]
		if UnitName(unit) == name then
			return unit
		end
	end
end

local function unitByGUID(guid)
	for i = 1, #LOOKUP_UNITS do
		local unit = LOOKUP_UNITS[i]
		if UnitGUID(unit) == guid then
			return unit
		end
	end
end

local function castDest(unit, caster, spell)
	if unit == "player" and sentSpell == spell then
		local target = unitByName(sentTarget)
		if target then
			return UnitGUID(target)
		end
	end
	local target = casterTargets[unit]
	if UnitExists(target) and UnitCanAssist(unit, target) then
		return UnitGUID(target)
	end
	return caster
end

local function castExpires(unit)
	local _, _, _, _, _, endTime = UnitCastingInfo(unit)
	return endTime and endTime / 1000 + CAST_GRACE or GetTime() + FALLBACK_CAST_TIME
end

local function onCastSent(_, unit, spell, _, target)
	if unit == "player" then
		sentSpell, sentTarget = spell, target
	end
end

local function onCastStart(_, unit, spell)
	local base = healBase[spell]
	if not base or not casterTargets[unit] then
		return
	end
	local caster = UnitGUID(unit)
	if not caster then
		return
	end

	local cast = getOrCreate(casts, caster)
	local previous = cast.dest
	local learned = learnedHeals[caster]
	cast.spell = spell
	cast.amount = learned and learned[spell] or base
	cast.dest = castDest(unit, caster, spell)
	cast.expires = castExpires(unit)
	if previous ~= cast.dest then
		changed(previous)
	end
	changed(cast.dest)
	startTicker()
end

local function pendingCast(unit, spell)
	if not healBase[spell] or not casterTargets[unit] then
		return
	end
	local caster = UnitGUID(unit)
	local cast = caster and casts[caster]
	if cast and cast.dest and cast.spell == spell then
		return cast
	end
end

local function onCastDelayed(_, unit, spell)
	local cast = pendingCast(unit, spell)
	if cast then
		cast.expires = castExpires(unit)
	end
end

local function onCastStop(_, unit, spell)
	local cast = pendingCast(unit, spell)
	if not cast or UnitCastingInfo(unit) == spell then
		return
	end
	local dest = cast.dest
	cast.dest = nil
	changed(dest)
end

local function learnHeal(sourceGUID, spellName, amount)
	local learned = getOrCreate(learnedHeals, sourceGUID)
	local previous = learned[spellName]
	if not previous then
		learned[spellName] = amount
	elseif amount >= previous * CHAIN_JUMP_RATIO then
		learned[spellName] = (previous + amount) * 0.5
	end
end

local function onHeal(sourceGUID, destGUID, _, spellName, _, amount, _, _, critical)
	if not amount then
		return
	end
	if critical then
		lastCrit[destGUID] = amount
	elseif healBase[spellName] and sourceGUID then
		learnHeal(sourceGUID, spellName, amount)
	end
end

local function shieldAmount(sourceGUID, destGUID, spellId, info)
	local learned = learnedShields[sourceGUID]
	local amount = learned and learned[spellId]
	if amount then
		return amount
	end
	if spellId == DIVINE_AEGIS then
		local crit = lastCrit[destGUID]
		if crit then
			return crit * DIVINE_AEGIS_RATIO
		end
	elseif info.fraction then
		local unit = unitByGUID(destGUID)
		if unit then
			return UnitHealthMax(unit) * info.fraction
		end
	end
	return info.amount
end

local function onAuraApplied(sourceGUID, destGUID, spellId)
	local info = SHIELDS[spellId]
	if not info or not destGUID then
		return
	end
	local shield = getOrCreate(getOrCreate(shields, destGUID), spellId)
	shield.source = sourceGUID
	shield.amount = shieldAmount(sourceGUID, destGUID, spellId, info)
	shield.absorbed = 0
	shield.lastAbsorb = 0
	shield.expires = GetTime() + info.duration
	changed(destGUID)
	startTicker()
end

local function removeShield(set, destGUID, spellId)
	set[spellId] = nil
	if not next(set) then
		shields[destGUID] = nil
	end
end

local function onAuraRemoved(_, destGUID, spellId)
	local set = shields[destGUID]
	local shield = set and set[spellId]
	if not shield then
		return
	end
	local info = SHIELDS[spellId]
	local source = shield.source
	if
		source
		and not info.fraction
		and spellId ~= DIVINE_AEGIS
		and shield.absorbed > 0
		and GetTime() - shield.lastAbsorb < BREAK_WINDOW
	then
		getOrCreate(learnedShields, source)[spellId] = shield.absorbed
	end
	removeShield(set, destGUID, spellId)
	changed(destGUID)
end

local function absorb(destGUID, amount)
	-- tonumber guard: a shifted/misaligned payload must degrade to "no
	-- absorb", never to a string-vs-number comparison crash inside a
	-- combat-log handler.
	amount = tonumber(amount)
	local set = shields[destGUID]
	if not set or not amount or amount <= 0 then
		return
	end
	local now = GetTime()
	local last
	for _, shield in pairs(set) do
		shield.lastAbsorb = now
		last = shield
		local left = shield.amount - shield.absorbed
		if amount > 0 and left > 0 then
			local taken = amount < left and amount or left
			shield.absorbed = shield.absorbed + taken
			amount = amount - taken
		end
	end
	if amount > 0 then
		last.absorbed = last.absorbed + amount
	end
	changed(destGUID)
end

local function onUnitDied(_, destGUID)
	if shields[destGUID] then
		shields[destGUID] = nil
		changed(destGUID)
	end
end

-- The 3.3.5 CLEU layout is disputed between the two available sources, so it
-- is detected at runtime instead of trusting either one: the donor
-- (Modules/HealPrediction.lua + Core_Events.lua, and LibHealComm-4.0.lua line
-- 2307) assumes NO hideCaster, while StatusHealth.lua claims hideCaster IS
-- present. The discriminator is reliable because hideCaster is a boolean and
-- GUIDs are strings like "Player-1097-08F2A6B1".
local HAS_HIDECASTER = nil

local function looksLikeGUID(value)
	return type(value) == "string" and value:find("-", 1, true) ~= nil
end

-- Raw payload is (timestamp, subEvent, arg3, ...): arg3 is hideCaster when
-- boolean, otherwise already sourceGUID. Returns true/false once the layout
-- is validated, nil while inconclusive (nil/filtered args) so the caller
-- keeps re-evaluating instead of locking in a guess from nils.
local function detectHideCaster(arg3, arg4)
	if type(arg3) == "boolean" then
		if arg4 == nil then
			return nil
		end
		return true
	end
	if arg3 == nil then
		return nil
	end
	-- Boolean test inconclusive: fall back to the string-shape test.
	if looksLikeGUID(arg3) then
		return false
	end
	if looksLikeGUID(arg4) then
		return true
	end
	return nil
end

-- Absorbed-amount slots in NORMALIZED extras, stated once here. Donor
-- positions (SpecializedAbsorbs-1.0.lua, verified on this client, whose CLEU
-- header is the no-hideCaster shape this file normalizes to):
--   SWING_DAMAGE:         amount, overkill, school, resisted, blocked, absorbed (slot 6)
--   SPELL/RANGE/DAMAGE_SHIELD/SPLIT/BUILDING damage:
--                         spellID, spellName, spellSchool, amount, overkill,
--                         school, resisted, blocked, absorbed (slot 9)
--   ENVIRONMENTAL_DAMAGE: envType, amount, overkill, school, resisted, blocked,
--                         absorbed (slot 7)
-- Offsets are into normalized extras, so they hold under either raw layout.
-- SPELL_HEAL extras (LibHealComm-4.0.lua: spellID, spellName, spellSchool,
-- amount, overheal, absorbed, critical): onHeal below consumes slot 4, the
-- heal amount, never spellID, under either layout.
local ABSORB_SLOT = {
	SWING_DAMAGE = 6,
	SPELL_DAMAGE = 9,
	SPELL_PERIODIC_DAMAGE = 9,
	RANGE_DAMAGE = 9,
	DAMAGE_SHIELD = 9,
	DAMAGE_SPLIT = 9,
	SPELL_BUILDING_DAMAGE = 9,
	ENVIRONMENTAL_DAMAGE = 7,
}

-- Single choke point for damage-absorb resolution. tonumber() rejects
-- non-numbers (GUID strings, spellIDs, missTypes); a numeric value <= 0 is
-- genuinely "no absorb" and must NOT fall through to an earlier field (damage
-- amount/school), which would credit a fake absorb. The backwards scan runs
-- only when the documented slot holds non-nil garbage (a shifted shape), so
-- a nil slot degrades to "no absorb".
local function resolveDamageAbsorb(event, ...)
	local slot = ABSORB_SLOT[event]
	local count = select("#", ...)
	if not slot or count < slot then
		return nil
	end
	local raw = select(slot, ...)
	if raw == nil then
		return nil
	end
	local candidate = tonumber(raw)
	if candidate then
		if candidate > 0 then
			return candidate
		end
		return nil
	end
	for i = count, 1, -1 do
		local fallback = tonumber(select(i, ...))
		if fallback and fallback > 0 then
			return fallback
		end
	end
	return nil
end

local cleuHandlers = {
	SPELL_HEAL = onHeal,
	SPELL_AURA_APPLIED = onAuraApplied,
	SPELL_AURA_REFRESH = onAuraApplied,
	SPELL_AURA_REMOVED = onAuraRemoved,
	UNIT_DIED = onUnitDied,
	UNIT_DESTROYED = onUnitDied,
	SWING_DAMAGE = function(_, destGUID, ...)
		absorb(destGUID, resolveDamageAbsorb("SWING_DAMAGE", ...))
	end,
	ENVIRONMENTAL_DAMAGE = function(_, destGUID, ...)
		absorb(destGUID, resolveDamageAbsorb("ENVIRONMENTAL_DAMAGE", ...))
	end,
	SWING_MISSED = function(_, destGUID, missType, amount)
		if missType == "ABSORB" then
			absorb(destGUID, tonumber(amount))
		end
	end,
}

-- All six spell-damage-family events share absorbed slot 9 (see ABSORB_SLOT).
local function onSpellDamage(_, destGUID, ...)
	absorb(destGUID, resolveDamageAbsorb("SPELL_DAMAGE", ...))
end

local function onSpellMissed(_, destGUID, _, _, _, missType, amount)
	if missType == "ABSORB" then
		absorb(destGUID, tonumber(amount))
	end
end

for _, event in ipairs({
	"SPELL_DAMAGE",
	"SPELL_PERIODIC_DAMAGE",
	"RANGE_DAMAGE",
	"DAMAGE_SHIELD",
	"DAMAGE_SPLIT",
	"SPELL_BUILDING_DAMAGE",
}) do
	cleuHandlers[event] = onSpellDamage
end
for _, event in ipairs({ "SPELL_MISSED", "SPELL_PERIODIC_MISSED", "RANGE_MISSED", "DAMAGE_SHIELD_MISSED" }) do
	cleuHandlers[event] = onSpellMissed
end

local function onCombatLog(_, _, event, sourceGUID, _, _, destGUID, _, _, a1, a2, a3, a4, a5, a6, a7, a8, a9)
	local handler = cleuHandlers[event]
	if handler then
		handler(sourceGUID, destGUID, a1, a2, a3, a4, a5, a6, a7, a8, a9)
	end
end

-- Normalize the raw CLEU payload to the donor's (subEvent, sourceGUID,
-- sourceName, sourceFlags, destGUID, destName, destFlags, ...extras) shape.
-- The client layout is detected at runtime (see detectHideCaster) because the
-- two available sources disagree about hideCaster; nothing here assumes one
-- source "must have normalized" it. destGUID is raw arg 7 with hideCaster,
-- raw arg 6 without. onCombatLog above and every handler index stay exactly
-- as the donor has them -- zero handler index edits.
local function DispatchCombatLog(blizzEvent, ...)
	if select("#", ...) < 2 then
		return
	end
	local subEvent = select(2, ...)
	if type(subEvent) ~= "string" then
		return
	end
	if HAS_HIDECASTER == nil then
		-- Cache the layout only from an event whose apparent sourceGUID
		-- looks like a real GUID; otherwise keep re-evaluating on later
		-- events instead of locking in a guess from nils.
		local arg3, arg4 = select(3, ...), select(4, ...)
		local apparent = (type(arg3) == "boolean") and arg4 or arg3
		if looksLikeGUID(apparent) then
			local detected = detectHideCaster(arg3, arg4)
			if detected ~= nil then
				HAS_HIDECASTER = detected
			end
		end
	end
	local hasHide = HAS_HIDECASTER
	if hasHide == nil then
		-- No locked layout yet (early nil-heavy events): decide per event
		-- without caching so a bad first guess cannot stick.
		hasHide = detectHideCaster(select(3, ...), select(4, ...))
	end
	if hasHide then
		-- hideCaster present: strip timestamp AND hideCaster.
		onCombatLog(blizzEvent, blizzEvent, subEvent, select(4, ...))
	else
		-- hideCaster absent: strip timestamp only.
		onCombatLog(blizzEvent, blizzEvent, subEvent, select(3, ...))
	end
end

ticker:SetScript("OnUpdate", function(self, elapsed)
	local untilTick = self.untilTick - elapsed
	if untilTick > 0 then
		self.untilTick = untilTick
		return
	end
	self.untilTick = TICK_INTERVAL

	local now = GetTime()
	local active = false
	for _, cast in pairs(casts) do
		local dest = cast.dest
		if dest then
			if cast.expires < now then
				cast.dest = nil
				changed(dest)
			else
				active = true
			end
		end
	end
	for guid, set in pairs(shields) do
		local removed = false
		for spellId, shield in pairs(set) do
			if shield.expires < now then
				set[spellId] = nil
				removed = true
			end
		end
		if removed then
			if not next(set) then
				shields[guid] = nil
			end
			changed(guid)
		end
	end
	if not active and not next(shields) then
		self:Hide()
	end
end)

local function keepOnlyKey(t, keptKey)
	for key in pairs(t) do
		if key ~= keptKey then
			t[key] = nil
		end
	end
end

local function reset()
	local playerGUID = UnitGUID("player")
	wipe(casts)
	wipe(shields)
	wipe(lastCrit)
	keepOnlyKey(learnedHeals, playerGUID)
	keepOnlyKey(learnedShields, playerGUID)
	sentSpell, sentTarget = nil, nil
	ticker:Hide()
end

local CAST_EVENTS = {
	UNIT_SPELLCAST_SENT = onCastSent,
	UNIT_SPELLCAST_START = onCastStart,
	UNIT_SPELLCAST_DELAYED = onCastDelayed,
	UNIT_SPELLCAST_STOP = onCastStop,
	UNIT_SPELLCAST_FAILED = onCastStop,
	UNIT_SPELLCAST_INTERRUPTED = onCastStop,
}

-- The donor's event mixin called cast handlers as handler(event, unit,
-- spell, ...). Dispatch the same way so every handler above is verbatim.
eventFrame:SetScript("OnEvent", function(_, event, ...)
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		DispatchCombatLog(event, ...)
	elseif event == "PLAYER_ENTERING_WORLD" then
		reset()
	else
		local handler = CAST_EVENTS[event]
		if handler then
			handler(event, ...)
		end
	end
end)

local function onHealCommHeal(_, _, _, _, _, ...)
	for i = 1, select("#", ...) do
		changed((select(i, ...)))
	end
end

local function onHealCommGUID(_, guid)
	changed(guid)
end

local function setHealComm(value)
	if not HealComm then
		return
	end
	if value then
		for i = 1, #HEALCOMM_CALLBACKS do
			HealComm.RegisterCallback(Prediction, HEALCOMM_CALLBACKS[i], onHealCommHeal)
		end
		HealComm.RegisterCallback(Prediction, "HealComm_ModifierChanged", onHealCommGUID)
		HealComm.RegisterCallback(Prediction, "HealComm_GUIDDisappeared", onHealCommGUID)
	else
		HealComm.UnregisterAllCallbacks(Prediction)
	end
end

local function setEnabled(value)
	if value == enabled then
		return
	end
	enabled = value
	if value then
		for event in pairs(CAST_EVENTS) do
			eventFrame:RegisterEvent(event)
		end
		eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		eventFrame:Show()
	else
		eventFrame:UnregisterAllEvents()
		eventFrame:Hide()
		reset()
	end
	setHealComm(value)
end

local function coveredByHealComm(caster)
	return HealComm and HealComm:GetCasterHealAmount(caster, HealComm.CASTED_HEALS) ~= nil
end

local function getIncoming(guid)
	if not enabled or not guid then
		return 0, 0
	end
	local now = GetTime()
	local playerGUID = UnitGUID("player")
	local total, own = 0, 0
	if HealComm then
		local window = now + HEALCOMM_WINDOW
		local amount = HealComm:GetHealAmount(guid, HealComm.ALL_HEALS, window)
		if amount then
			local modifier = HealComm:GetHealModifier(guid)
			total = amount * modifier
			local mine = HealComm:GetHealAmount(guid, HealComm.ALL_HEALS, window, playerGUID)
			if mine then
				own = mine * modifier
			end
		end
	end
	for caster, cast in pairs(casts) do
		if cast.dest == guid and cast.expires > now and not coveredByHealComm(caster) then
			total = total + cast.amount
			if caster == playerGUID then
				own = own + cast.amount
			end
		end
	end
	return total, own
end

local function getAbsorb(guid)
	local set = enabled and guid and shields[guid]
	if not set then
		return 0, false
	end
	local now = GetTime()
	local total, shielded = 0, false
	for _, shield in pairs(set) do
		if shield.expires > now then
			shielded = true
			local left = shield.amount - shield.absorbed
			if left > 0 then
				total = total + left
			end
		end
	end
	return total, shielded
end

local function setWidth(texture, width)
	if texture.width ~= width then
		texture.width = width
		texture:SetWidth(width)
	end
end

local function showSegment(texture, fill, offset, width)
	texture:SetPoint("TOPLEFT", fill, "TOPRIGHT", offset, 0)
	texture:SetPoint("BOTTOMLEFT", fill, "BOTTOMRIGHT", offset, 0)
	setWidth(texture, width)
	texture:Show()
end

local function layout(bar)
	local p = bar.prediction
	local value = bar:GetValue()
	p.value = value
	local _, max = bar:GetMinMaxValues()
	local width = bar:GetWidth()
	if not p.active or max <= 0 or width <= 0 then
		p.ownHeal:Hide()
		p.heal:Hide()
		p.absorb:Hide()
		p.glow:Hide()
		return
	end

	local fill = bar:GetStatusBarTexture()
	local missing = max - value
	if missing < 0 then
		missing = 0
	end

	local incoming = p.incoming
	local heal = incoming < missing and incoming or missing
	local own = p.own < heal and p.own or heal
	local ownWidth = own * width / max
	if ownWidth >= MIN_WIDTH then
		showSegment(p.ownHeal, fill, 0, ownWidth)
	else
		ownWidth = 0
		p.ownHeal:Hide()
	end

	local healWidth = (heal - own) * width / max
	if healWidth >= MIN_WIDTH then
		showSegment(p.heal, fill, ownWidth, healWidth)
		healWidth = healWidth + ownWidth
	else
		healWidth = ownWidth
		p.heal:Hide()
	end

	local room = missing - heal
	local amount = p.absorbAmount
	local shield = amount < room and amount or room
	local absorbWidth = shield * width / max
	if absorbWidth >= MIN_WIDTH then
		showSegment(p.absorb, fill, healWidth, absorbWidth)
	else
		p.absorb:Hide()
	end

	-- 3.3.5 has no Region:SetShown (MoP+); branch explicitly.
	if p.shielded and (amount > room or amount <= 0) then
		p.glow:Show()
	else
		p.glow:Hide()
	end
end

-- Fallbacks mirror the C.Unitframe defaults in Config/Settings.lua, so bars
-- from older profiles (missing the new keys) still tint correctly.
local FALLBACK_HEAL = { 0, 0.72, 0.35, 0.8 }
local FALLBACK_OWN = { 0, 0.9, 0.5, 0.9 }
local FALLBACK_ABSORB = { 0.4, 0.7, 1, 0.8 }

local function applyColors(bar)
	local p = bar.prediction
	local heal = C.Unitframe.HealthPredictionColor or FALLBACK_HEAL
	local own = C.Unitframe.HealthPredictionOwnColor or FALLBACK_OWN
	local absorbColor = C.Unitframe.AbsorbColor or FALLBACK_ABSORB
	p.heal:SetVertexColor(heal[1], heal[2], heal[3], heal[4])
	p.ownHeal:SetVertexColor(own[1], own[2], own[3], own[4])
	local r, g, b = absorbColor[1], absorbColor[2], absorbColor[3]
	p.absorb:SetVertexColor(r, g, b, absorbColor[4])
	-- Texture:SetGradientAlpha does not exist on 3.3.5, so the overflow glow
	-- is a flat vertex-alpha texture on ADD blend (set at creation) instead
	-- of a horizontal gradient.
	p.glow:SetVertexColor(r, g, b, 0.55)
end

local function onSizeChanged(bar)
	if bar.prediction.active then
		layout(bar)
	end
end

local function createOverlay(bar, subLevel)
	local texture = bar:CreateTexture(nil, "ARTWORK", nil, subLevel)
	texture:SetTexture(Module.Texture())
	texture:Hide()
	return texture
end

function Prediction.CreateBars(bar)
	-- Build.Health runs once per frame, but never double-book the same bar.
	if bar.prediction then
		return
	end
	local heal = createOverlay(bar, 1)
	local ownHeal = createOverlay(bar, 1)
	local absorbTexture = createOverlay(bar, 1)
	local glow = createOverlay(bar, 2)
	glow:SetBlendMode("ADD")
	glow:SetWidth(GLOW_WIDTH)
	glow:SetPoint("TOPRIGHT")
	glow:SetPoint("BOTTOMRIGHT")

	bar.prediction = {
		heal = heal,
		ownHeal = ownHeal,
		absorb = absorbTexture,
		glow = glow,
		incoming = 0,
		own = 0,
		absorbAmount = 0,
		shielded = false,
		active = false,
	}
	applyColors(bar)
	bar:HookScript("OnSizeChanged", onSizeChanged)
	bars[#bars + 1] = bar
end

function Prediction.SetValues(bar, incoming, absorbAmount, shielded, own)
	local p = bar.prediction
	if not p then
		return
	end
	p.incoming = incoming
	p.own = own or 0
	p.absorbAmount = absorbAmount
	p.shielded = shielded
	p.active = incoming > 0 or shielded
	layout(bar)
end

function Prediction.Refresh(bar, guid, unit, showHeal, showAbsorb)
	local p = bar.prediction
	if not p then
		return
	end
	p.guid = guid
	p.unit = unit
	local incoming, own = 0, 0
	if showHeal then
		incoming, own = getIncoming(guid)
		if not C.Unitframe.HealthPredictionSplit then
			own = 0
		end
	end
	local absorbAmount, shielded = 0, false
	if showAbsorb then
		absorbAmount, shielded = getAbsorb(guid)
	end
	Prediction.SetValues(bar, incoming, absorbAmount, shielded, own)
end

function Prediction.Follow(bar)
	local p = bar.prediction
	if not p then
		return
	end
	if p.active and bar:GetValue() ~= p.value then
		layout(bar)
	end
end

local function applyConfig()
	local uf = C.Unitframe
	setEnabled((uf and uf.Enable and (uf.HealthPrediction or uf.AbsorbShields)) or false)
	for i = 1, #bars do
		applyColors(bars[i])
	end
end

-- budsUI has no config-watch framework; apply once at load (C is fully
-- built by now) and expose ApplyConfig for a later reload path.
function Prediction.ApplyConfig()
	applyConfig()
end

applyConfig()
