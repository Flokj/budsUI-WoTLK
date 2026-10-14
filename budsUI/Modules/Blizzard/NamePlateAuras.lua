local K, C, L, _ = select(2, ...):unpack()
if C.Nameplate.Enable ~= true then return end

-- FrostAtomUI donor architecture (see _hermes_refs/FrostAtomUI/Modules/NamePlates/Auras.lua):
-- shared guid-keyed aura cache + pools, event-driven (CLEU + UNIT_AURA) with
-- markDirty + deferred single-frame flush, a 0.1s ticker that only refreshes
-- timer text, and dirty-checked drawing. No scheduled per-guid UnitAura scans.
--
-- Public API (kept for Nameplate.lua, which must call only these two):
--   K.NamePlateAuras_Update(plate, unitOrGuid) -- bind plate, scan if needed, redraw via flush
--   K.NamePlateAuras_Hide(plate)               -- release bind + icons
-- WoW 3.3.5 quirk: UnitAura returns only 10 values (no 11th spellID), so all
-- cache matching is by spellId when known with a spell-name fallback.

local next, type, unpack = next, type, unpack
local floor = math.floor
local MathMin = math.min
local MathCeil = math.ceil
local tremove = table.remove
local sort = table.sort
local wipe = wipe
local GetTime = GetTime
local GetSpellInfo = GetSpellInfo
local UnitAura = UnitAura
local UnitGUID = UnitGUID
local UnitName = UnitName
local UnitExists = UnitExists
local UnitCreatureType = UnitCreatureType
local CreateFrame = CreateFrame
local match = string.match

-- Config (geometry sourced from build config C.Nameplate, donor defaults as fallback)
local USE_MODERN_BORDER = false
local SPACE = 0
local SIZE = C.Nameplate.AuraSize or 24
local IN_ROW = 6
local OFFSET_Y = C.Nameplate.AuraOffsetY or 22
local SIZE_HIGHLIGHT = C.Nameplate.AuraSizeHighlight or 28
local IN_ROW_HIGHLIGHT = 4
local OFFSET_Y_HIGHLIGHT = 2

local TIMER_INTERVAL = 0.1
local SWEEP_INTERVAL = 10

-- Units with a UNIT_AURA event feed (donor EVENT_UNITS: target/focus/arenaX/bossX).
-- Plates bound to these tokens are refreshed purely by UNIT_AURA; every other
-- token is scanned on bind / on the update pass (donor onUnitAdded/onPass).
-- Native Frame:RegisterUnitEvent does NOT exist in 3.3.5 (added in Patch
-- 5.0.4), so this is a plain RegisterEvent("UNIT_AURA") with the handler
-- filtering to EVENT_UNITS. This matches the donor (their RegisterUnitEvent
-- is an EventMixin wrapper over plain RegisterEvent) and ElvUI-7 (30300).
local EVENT_UNITS = {
	target = true,
	focus = true,
	boss1 = true, boss2 = true, boss3 = true, boss4 = true,
	arena1 = true, arena2 = true, arena3 = true, arena4 = true, arena5 = true,
}

-- Spell lists (verbatim IDs from donor spells.lua, keyed by spellID here and
-- converted to spell names with GetSpellInfo at load, like the donor does)
local SPELLS_WHITELIST_BY_ID = {
	--=== Other ===--
	[24364] = true, -- Free Action 5s
	[6615] = true, -- Free Action 30s
	[39965] = true, -- Frost Grenade
	[55536] = true, -- Frostweave Net
	[13099] = true, -- Net-o-Matic
	[30217] = true, -- Adamantite Grenade
	[67769] = true, -- Cobalt Frag Bomb
	[30216] = true, -- Fel Iron Bomb
	[20549] = true, -- War Stomp(Tauren/Stun/2s)
	[25046] = true, -- Arcane Torrent(Blood Elph/Silence/2s)
	[17116] = true, -- nature swiftness(Shaman/Druid)
	[23335] = true, -- Alliance flag(warsong)
	[23333] = true, -- Horde flag(warsong)
	[34976] = true, -- Eyes flag
	[70338] = true, -- Necrotic Plague
	--[72148] = true, -- Enrage (dublicate warrior enrage by spell name)

	--[29703] = true, -- Dazed(-50% move.speed/%.s)

	--=== Warrior ===--
	[46924] = true, -- Bladestorm
	[47486] = true, -- Mortal Strike
	[23920] = true, -- Spell Reflection
	[19306] = true, -- Counterattack(retal)
	[58373] = true, -- Glyph of Hamstring
	[23694] = true, -- Improved Hamstring
	[12809] = true, -- Concussion Blow
	[20253] = true, -- Intercept (also Warlock Felguard ability)
	[5246] = true, -- Intimidating Shout(Fear/8s)
	[12798] = true, -- Revenge Stun
	[46968] = true, -- Shockwave
	[18498] = true, -- Silenced - Gag Order
	[676] = true, -- Disarm
	[871] = true, -- Shield Wall

	--[1715] = true, -- Hamstring(-50% move.speed/15s)
	--[12323] = true, -- Piercing Howl (-50% move.speed/6s)

	--=== Hunter ===--
	[34471] = true, -- Beast Within
	[53271] = true, -- Masters Call(freedom)
	[19263] = true, -- Deterence
	[49050] = true, -- Aimed Shot(mortal)
	[60210] = true, -- Freezing Arrow Effect
	[3355] = true, -- Freezing Trap Effect
	[19185] = true, -- Entrapment(talent trap)
	[1513] = true, -- Scare Beast (Fear/works against Druids in most forms and Shamans using Ghost Wolf)
	[19503] = true, -- Scatter Shot
	[19386] = true, -- Wyvern Sting
	[34490] = true, -- Silencing Shot
	[53359] = true, -- Chimera Shot - Scorpid(Disarm)

	--pet
	[50245] = true, -- Pin (Crab)
	[54706] = true, -- Venom Web Spray (Silithid)
	[4167] = true, -- Web (Spider)
	[54644] = true, -- Froststorm Breath (Chimera)
	[50271] = true, -- Tendon Rip (Hyena)
	[24394] = true, -- Intimidation(pet)
	[50519] = true, -- Sonic Blast (Bat)
	[50541] = true, -- Snatch (Bird of Prey)
	[50518] = true, -- Ravage (Ravager)

	--[35101] = true, -- Concussive Barrage(Himera shot(-50 move.speed/4s))
	--[5116] = true, -- Concussive Shot(-50 move.speed/4s-6s)
	--[13810] = true, -- Frost Trap Aura (no duration, lasts as long as you stand in it)
	--[61394] = true, -- Glyph of Freezing Trap(broke trap == -30% move.speed/4s)
	--[2974] = true, -- Wing Clip(melle -50% move.speed/10s)

	--=== Druid ===--
	[33786] = true, -- Cyclone
	[339] = true, -- Entangling Roots
	[2637] = true, -- Hibernate (works against Druids in most forms and Shamans using Ghost Wolf)
	[22570] = true, -- Maim
	[9005] = true, -- Pounce
	[69369] = true, -- Predator's Swiftness(Feral/Proc)

	--[58179] = true, -- Infected Wounds(feral(-50 move.speed))
	--[61391] = true, -- Typhoon(Sova(-50 move.speed))

	--=== Shaman ===--
	[8178] = true, -- Grounding Totem Effect
	[64695] = true, -- Earthgrab (Storm, Earth and Fire)
	[63685] = true, -- Freeze (Frozen Power)
	[5211] = true, -- Bash (also Shaman Spirit Wolf ability)
	[39796] = true, -- Stoneclaw Stun
	[51514] = true, -- Hex (although effectively a silence+disarm effect, it is conventionally thought of as a "CC", plus you can trinket out of it)
	[16166] = true, -- Elemental mastery

	--[3600] = true, -- Earthbind (5 second duration per pulse, but will keep re-applying the debuff as long as you stand within the pulse radius)
	--[8056] = true, -- Frost Shock(-50% move.speed/8s)
	--[8034] = true, -- Frostbrand Attack(ench(-50% move.speed/8s)

	--=== Warlock ===--
	[710] = true, -- Banish
	[6358] = true, -- Seduction
	[6789] = true, -- Death Coil
	[5782] = true, -- Fear
	[5484] = true, -- Howl of Terror
	[30283] = true, -- Shadowfury
	[6358] = true, -- Seduction (Succubus)
	[24259] = true, -- Spell Lock (Felhunter)
	[7922] = true, -- Charge Stun (Demon)
	[18118] = true, -- Aftermath(-70% move.speed/5s)

	--[18223] = true, -- Curse of Exhaustion(-30% move.speed/12s)

	--=== Mage ===--
	[45438] = true, -- Ice Block
	[54748] = true, -- Burning Determination
	[61025] = true, -- Polymorph(snake)
	[118] = true, -- Polymorph(sheep)
	[33395] = true, -- Freeze (Water Elemental)
	[122] = true, -- Frost Nova
	[11071] = true, -- Frostbite
	[55080] = true, -- Shattered Barrier
	[44572] = true, -- Deep Freeze
	[31661] = true, -- Dragon's Breath
	[12355] = true, -- Impact
	[18469] = true, -- Silenced - Improved Counterspell
	[64346] = true, -- Fiery Payback(Disarm)
	[48108] = true, -- Hot streak(Firemage/Proc)
	[74396] = true, -- Fingers of frost(Frostmage/Proc)

	--[11113] = true, -- Blast Wave(fire (-50 move.speed/6s)
	--[6136] = true, -- Chilled (generic effect, used by lots of spells [looks weird on Improved Blizzard, might want to comment out])
	--[120] = true, -- Cone of Cold(-50 move.speed/8s)
	--[116] = true, -- Frostbolt(-40 move.speed/5s)
	--[47610] = true, -- Frostfire Bolt(-40 move.speed/9s)
	--[31589] = true, -- Slow(arcane (-60% move.speed/15s))

	--=== Rogue ===--
	[31224] = true, -- Cloack of Shadows
	[1776] = true, -- Gouge
	[57975] = true, -- Wound Poison VII(mortal)
	[2094] = true, -- Blind
	[1833] = true, -- Cheap Shot
	[408] = true, -- Kidney Shot
	[6770] = true, -- Sap
	[1330] = true, -- Garrote - Silence
	[18425] = true, -- Silenced - Improved Kick
	[51722] = true, -- Dismantle(Disarm)
	[31125] = true, -- Blade Twisting(-70% move.speed/4s)

	--[26679] = true, -- Deadly Throw(-50% move.speed/6s)
	--[3409] = true, -- Crippling Poison(-70% move.speed/t.s)

	--=== Paladin ===--
	[1044] = true, -- Hand of Freedom
	[642] = true, -- Divine Shield(babol)
	[10278] = true, -- Hand of Protection (BOP)
	[20066] = true, -- Repentance
	[853] = true, -- Hammer of Justice
	[2812] = true, -- Holy Wrath (works against Warlocks using Metamorphasis and Death Knights using Lichborne)
	[20170] = true, -- Stun (Seal of Justice proc)
	[10326] = true, -- Turn Evil (Fear/works against Warlocks using Metamorphasis and Death Knights using Lichborne)
	[63529] = true, -- Shield of the Templar
	[31884] = true, -- Avenging Wrath
	[6940] = true, -- Hand of Sacrifice(30%)
	[64205] = true, -- Divane Sacrifice(Mas sacra)

	--[20184] = true, -- Judgement of Justice (100% movement snare; druids and shamans might want this though)

	--=== Priest ===--
	[47585] = true, -- Dispersion
	[605] = true, -- Mind Control
	[64044] = true, -- Psychic Horror
	[64058] = true, -- Psychic Horror (Disarm/duplicate debuff names not allowed atm, need to figure out how to support this later)
	[8122] = true, -- Psychic Scream(Fear/8s)
	[9484] = true, -- Shackle Undead (works against Death Knights using Lichborne)
	[15487] = true, -- Silence
	[33206] = true, -- Pain Supression(-40% damage taken)

	--[15407] = true, -- Mind Flay(-50 move.speed/t.s)

	--=== Death night ===--
	[48792] = true, -- Icebound Fortitude
	[48707] = true, -- Anti-Magic Shield
	[47481] = true, -- Gnaw (Ghoul(Stun/3s))
	[51209] = true, -- Hungering Cold
	[47476] = true, -- Strangulate(Silence/5s)
	[50461] = true, -- Anti-Magic Zone

	--[45524] = true, -- Chains of Ice
	--[55666] = true, -- Desecration (no duration, lasts as long as you stand in it)
	--[58617] = true, -- Glyph of Heart Strike(-50 move.speed)
	--[50436] = true, -- Icy Clutch (Chilblains)
}

local SPELLS_BLACKLIST_BY_ID = {
	[30070] = true,
	[12721] = true,
	[46857] = true,
	[49054] = true,
	[5116] = true,
	[35101] = true,
	[63468] = true,
	[20736] = true,
	[25810] = true,
	[34655] = true,
	[30981] = true,
	--[30708] = true,

	-- Self buffs
	[48162] = true,
	[48074] = true,
	[48170] = true,
	[43002] = true,
	[48470] = true,
	[25898] = true,
	[25899] = true,

	--[2974] = true,
}

-- Convert spellID-keyed tables to spell-name-keyed tables (donor convert()).
-- GetSpellInfo resolves the name; unknown IDs are skipped.
local function ConvertSpellTable(t)
	local r = {}
	for k, v in next, t do
		local name = GetSpellInfo(k)
		if name then
			r[name] = v
		end
	end
	return r
end

local SPELLS_WHITELIST = ConvertSpellTable(SPELLS_WHITELIST_BY_ID)
local SPELLS_BLACKLIST = ConvertSpellTable(SPELLS_BLACKLIST_BY_ID)
SPELLS_WHITELIST_BY_ID = nil
SPELLS_BLACKLIST_BY_ID = nil

-- Duration defaults for combat-log auras (seconds by spellID; ported from
-- FrostAtomUI AuraData.lua CC_DURATIONS + DEFENSIVE_DURATIONS). The combat
-- log carries no duration/expiry, so applied auras fall back to these tables
-- (by spellID, then by spell name) or to learned real durations below.
-- Unknown spells are SKIPPED on the CLEU path (donor semantics: no timer, no
-- icon) and picked up by the exact UnitAura scan when a token exists.
local DURATION_DEFAULTS_BY_ID = {
	-- CC
	[118] = 10, [6770] = 10, [1776] = 4, [2094] = 10, [1833] = 4,
	[408] = 6, [1330] = 3, [18425] = 2, [51722] = 10, [5782] = 10,
	[5484] = 8, [6358] = 10, [6789] = 3, [30283] = 3, [24259] = 3,
	[710] = 6, [8122] = 8, [64044] = 3, [64058] = 10, [15487] = 5,
	[9484] = 10, [853] = 6, [20066] = 6, [10326] = 10, [2812] = 3,
	[63529] = 3, [20170] = 2, [33786] = 6, [5211] = 4, [22570] = 5,
	[9005] = 3, [2637] = 10, [339] = 10, [45334] = 4, [19503] = 4,
	[3355] = 10, [60210] = 10, [19386] = 6, [34490] = 3, [24394] = 3,
	[53359] = 10, [19306] = 5, [19185] = 2, [64803] = 3, [64804] = 4,
	[50519] = 2, [50518] = 2, [50541] = 6, [53148] = 1, [50245] = 4,
	[54706] = 4, [4167] = 4, [1513] = 10, [12355] = 2, [44572] = 5,
	[31661] = 5, [122] = 8, [33395] = 8, [18469] = 2, [55021] = 4,
	[55080] = 8, [12494] = 5, [64346] = 6, [5246] = 8, [20511] = 8,
	[676] = 10, [12809] = 5, [46968] = 4, [7922] = 1.5, [20253] = 3,
	[30153] = 3, [23694] = 5, [58373] = 5, [18498] = 3, [47476] = 5,
	[49203] = 10, [47481] = 3, [51514] = 10, [39796] = 3, [58861] = 2,
	[64695] = 5, [63685] = 5, [60995] = 3, [22703] = 2, [605] = 10,
	[20549] = 2, [25046] = 2, [28730] = 2, [50613] = 2, [39965] = 5,
	[55536] = 3, [30216] = 3, [30217] = 3, [67769] = 3, [13181] = 10,
	-- Defensive / own buffs worth highlighting
	[642] = 12, [498] = 12, [1022] = 10, [1044] = 6, [6940] = 12,
	[64205] = 10, [31821] = 6, [45438] = 10, [31224] = 5, [5277] = 15,
	[51713] = 6, [48707] = 5, [48792] = 12, [49039] = 10, [46924] = 6,
	[871] = 12, [23920] = 5, [12975] = 20, [18499] = 10, [55694] = 10,
	[20230] = 12, [19263] = 5, [34471] = 10, [54216] = 4, [33206] = 8,
	[47788] = 10, [47585] = 6, [22812] = 12, [61336] = 20, [30823] = 15,
	[54748] = 20, [31884] = 20, [61025] = 10, [16166] = 12,
	[17116] = 12, [53271] = 4, [10278] = 10,
}

local durationsByName = {}
for _id, _dur in next, DURATION_DEFAULTS_BY_ID do
	local _name = GetSpellInfo(_id)
	if _name and _dur > 0 then
		durationsByName[_name] = _dur
	end
end

-- Learned real durations (donor `learned` table): exact scans feed real
-- `duration` values here (max wins, keyed by spellId and by name for 3.3.5
-- where UnitAura has no spellID); combat-log auras prefer them over static
-- defaults. This is donor Data.Duration(spellId, name, learned).
local learned = {}
local function learn(spellId, spellName, duration)
	if type(duration) ~= "number" or duration <= 0 then return end
	if spellId and (learned[spellId] or 0) < duration then
		learned[spellId] = duration
	end
	if type(spellName) == "string" and (learned[spellName] or 0) < duration then
		learned[spellName] = duration
	end
end

local function Duration(spellId, spellName)
	return (spellId and learned[spellId]) or learned[spellName]
		or (spellId and DURATION_DEFAULTS_BY_ID[spellId]) or durationsByName[spellName]
end

-- Aura classification (donor AuraData.ClassifyDebuff/ClassifyBuff, adapted to
-- the 3.3.5 whitelist/blacklist filter model since donor SpellDB/DRData/
-- LoseControlData do not exist here). Filtering happens here at insert time;
-- everything cached is shown (see kindShown).
local KIND_OWN_CC, KIND_CC, KIND_DEFENSIVE = 1, 2, 3
local KIND_OWN, KIND_PURGE, KIND_OTHER = 4, 5, 6

local function ClassifyDebuff(spellId, name, own)
	if SPELLS_WHITELIST[name] then
		return own and KIND_OWN_CC or KIND_CC
	elseif own and not SPELLS_BLACKLIST[name] then
		return KIND_OWN
	end
end

local function ClassifyBuff(spellId, name)
	if SPELLS_WHITELIST[name] then
		return KIND_DEFENSIVE
	end
end

local function kindShown(kind)
	if kind == KIND_OWN_CC or kind == KIND_CC then
		return true
	elseif kind == KIND_DEFENSIVE or kind == KIND_PURGE then
		return true
	elseif kind == KIND_OWN then
		return true
	elseif kind == KIND_OTHER then
		return true
	end
	return false
end

-- Shared aura cache (donor model): cache[guid] is an ORDERED list of entries
-- {spellId, name, icon, count, duration, expires, kind, debuffType} with
-- set/entry pool reuse. guidPlates[guid] is the single plate bound to a guid.
local cache = {}
local setPool, entryPool = {}, {}
local dirty = {}
local pendingScans = {}
local guidPlates = {}
local playerGUID, petGUID = nil, nil

local function getSet(guid)
	local set = cache[guid]
	if not set then
		local count = #setPool
		set = setPool[count] or {}
		setPool[count] = nil
		cache[guid] = set
	end
	return set
end

local function clearSet(set)
	for i = #set, 1, -1 do
		entryPool[#entryPool + 1] = set[i]
		set[i] = nil
	end
end

local function releaseSet(guid)
	local set = cache[guid]
	if set then
		clearSet(set)
		cache[guid] = nil
		setPool[#setPool + 1] = set
	end
end

local function addEntry(set)
	local count = #entryPool
	local entry = entryPool[count] or {}
	entryPool[count] = nil
	set[#set + 1] = entry
	return entry
end

-- 3.3.5: entries scanned from UnitAura have no spellId, so match by spellId
-- when both sides know it, otherwise fall back to the spell name.
local function findEntry(set, spellId, name)
	for i = 1, #set do
		local entry = set[i]
		if spellId and entry.spellId and entry.spellId == spellId then
			return entry, i
		elseif entry.name == name then
			return entry, i
		end
	end
end

local function removeEntry(set, index)
	entryPool[#entryPool + 1] = tremove(set, index)
end

local function auraOrder(a, b)
	if a.kind ~= b.kind then
		return a.kind < b.kind
	end
	local aExpires, bExpires = a.expires, b.expires
	return (aExpires > 0 and aExpires or math.huge) < (bExpires > 0 and bExpires or math.huge)
end

local function fill(entry, spellId, name, icon, count, duration, expires, kind, debuffType)
	entry.spellId = spellId
	entry.name = name
	entry.icon = icon
	entry.count = count or 0
	entry.duration = duration or 0
	entry.expires = expires or 0
	entry.kind = kind
	entry.debuffType = debuffType
end

local function addAura(set, spellId, name, icon, count, duration, expires, kind, debuffType)
	fill(addEntry(set), spellId, name, icon, count, duration, expires, kind, debuffType)
	learn(spellId, name, duration)
end

-- Forward: updatePlate is defined with the renderer below; flush only runs
-- deferred (after the whole file is loaded), so the upvalue is set by then.
local updatePlate

local function flush()
	for guid in pairs(dirty) do
		dirty[guid] = nil
		local plate = guidPlates[guid]
		if plate then
			updatePlate(plate)
		end
	end
end

-- Donor ns.Defer(dirty, flush) equivalent via the prebuilt Core/Scheduler:
-- all changes within one frame collapse into a single flush that redraws ONLY
-- dirty plates. Synchronous fallback if the Scheduler is unavailable.
local function deferFlush()
	if K.Defer then
		K.Defer(dirty, flush)
	else
		flush()
	end
end

local function markDirty(guid)
	if type(guid) ~= "string" then return end
	dirty[guid] = true
	deferFlush()
end

local function isOwn(caster)
	return caster == "player" or caster == "pet" or caster == "vehicle"
end

-- Authoritative exact scan (donor exactScan): replaces the guid's set wholesale
-- from UnitAura while a token exists, keeping the whitelist/blacklist/isMine
-- filter semantics and the real duration/expirationTime (0 = timeless).
local SCAN_FILTERS = { "HELPFUL", "HARMFUL" }
local function exactScan(unit, guid)
	if type(guid) ~= "string" or type(unit) ~= "string" then return end
	if not UnitExists(unit) then return end
	local set = getSet(guid)
	clearSet(set)

	local spellName, texture, count, debuffType, duration, expirationTime, caster
	for f = 1, 2 do
		local filter = SCAN_FILTERS[f]
		local index = 0
		while true do
			index = index + 1
			if index > 40 then break end
			-- 3.3.5: UnitAura returns only 10 values, spellID is always nil here
			spellName, _, texture, count, debuffType, duration, expirationTime, caster = UnitAura(unit, index, filter)
			if not spellName then break end
			local kind
			if filter == "HARMFUL" then
				kind = ClassifyDebuff(nil, spellName, isOwn(caster))
			else
				kind = ClassifyBuff(nil, spellName)
			end
			if kind then
				addAura(set, nil, spellName, texture, count, duration, expirationTime, kind,
					filter == "HARMFUL" and (debuffType or "none") or nil)
			end
		end
	end

	sort(set, auraOrder)
	markDirty(guid)
end

local function flushScans()
	for guid in pairs(pendingScans) do
		pendingScans[guid] = nil
		local plate = guidPlates[guid]
		local unit = plate and plate.__auraUnit
		if unit and UnitExists(unit) then
			exactScan(unit, guid)
		end
	end
end

-- Donor syncLive: a plate bound to a live unit token owns exact data, so CLEU
-- estimates for that guid are skipped (UNIT_AURA / deferred scan carries the
-- truth instead). Non-EVENT_UNITS tokens get a deferred exact scan.
local function syncLive(guid)
	local plate = guidPlates[guid]
	local unit = plate and plate.__auraUnit
	if not unit or not UnitExists(unit) then
		return false
	end
	if not EVENT_UNITS[unit] then
		pendingScans[guid] = true
		if K.Defer then
			K.Defer(pendingScans, flushScans)
		else
			flushScans()
		end
	end
	return true
end

local function pruneUntimed(guid)
	local set = cache[guid]
	if not set then return end
	for i = #set, 1, -1 do
		if set[i].expires == 0 then
			removeEntry(set, i)
		end
	end
	if not set[1] and not guidPlates[guid] then
		releaseSet(guid)
	else
		markDirty(guid)
	end
end

local function TextureFor(spellId, spellName)
	local _, _, icon = GetSpellInfo(spellId)
	if icon then return icon end
	local _, _, iconByName = GetSpellInfo(spellName)
	return iconByName
end

local function onAuraApplied(srcGUID, dstGUID, spellId, spellName, auraType)
	if type(dstGUID) ~= "string" or type(spellName) ~= "string" then return end
	if syncLive(dstGUID) then return end
	local kind
	if auraType == "BUFF" then
		kind = ClassifyBuff(spellId, spellName)
	else
		local mine = type(srcGUID) == "string" and (srcGUID == playerGUID or srcGUID == petGUID)
		kind = ClassifyDebuff(spellId, spellName, mine)
	end
	if not kind then return end
	local duration = Duration(spellId, spellName)
	if not duration or duration <= 0 then return end
	local now = GetTime()
	local set = getSet(dstGUID)
	local entry = findEntry(set, spellId, spellName)
	if not entry then
		entry = addEntry(set)
		fill(entry, spellId, spellName, TextureFor(spellId, spellName), 0, duration, now + duration, kind,
			auraType == "BUFF" and nil or "none")
	else
		entry.duration = duration
		entry.expires = now + duration
		entry.kind = kind
	end
	learn(spellId, spellName, duration)
	sort(set, auraOrder)
	markDirty(dstGUID)
end

local function onAuraDose(dstGUID, spellId, spellName, amount)
	if type(dstGUID) ~= "string" or type(spellName) ~= "string" then return end
	local set = cache[dstGUID]
	if not set or syncLive(dstGUID) then return end
	local entry = findEntry(set, spellId, spellName)
	if entry and type(amount) == "number" then
		entry.count = amount
		markDirty(dstGUID)
	end
end

local function onAuraRemoved(dstGUID, spellId, spellName)
	if type(dstGUID) ~= "string" or type(spellName) ~= "string" then return end
	local set = cache[dstGUID]
	if not set or syncLive(dstGUID) then return end
	local _, index = findEntry(set, spellId, spellName)
	if index then
		removeEntry(set, index)
		markDirty(dstGUID)
	end
end

local function onUnitDied(dstGUID)
	if type(dstGUID) ~= "string" then return end
	if cache[dstGUID] then
		releaseSet(dstGUID)
		markDirty(dstGUID)
	end
end

-- Combat-log listener: backbone feed for token-less enemy plates.
-- 3.3.5 CLEU args: (timestamp, subEvent, srcGUID, srcName, srcFlags,
-- dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount?)
-- Best-effort by design: every branch is type-guarded and the whole dispatch
-- runs inside pcall so one malformed event can never break the addon.
local function HandleCombatLogEvent(timestamp, subEvent, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, a1, a2, a3, a4, a5)
	if subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REFRESH" then
		-- a1=spellId(number), a2=spellName(string), a4=auraType
		if type(a1) == "number" and type(a2) == "string" then
			onAuraApplied(srcGUID, dstGUID, a1, a2, a4)
		end
	elseif subEvent == "SPELL_AURA_APPLIED_DOSE" or subEvent == "SPELL_AURA_REMOVED_DOSE" then
		-- a2=spellName(string), a5=new stack count(number); never use a5 as a key
		if type(a2) == "string" and type(a5) == "number" then
			onAuraDose(dstGUID, a1, a2, a5)
		end
	elseif subEvent == "SPELL_AURA_REMOVED" or subEvent == "SPELL_AURA_BROKEN" or subEvent == "SPELL_AURA_BROKEN_SPELL" then
		if type(a2) == "string" then
			onAuraRemoved(dstGUID, a1, a2)
		end
	elseif subEvent == "UNIT_DIED" or subEvent == "UNIT_DESTROYED" or subEvent == "UNIT_DISSIPATES" then
		onUnitDied(dstGUID)
	end
end

local function sweep(now)
	for guid, set in next, cache do
		if type(guid) ~= "string" or type(set) ~= "table" then
			releaseSet(guid)
		else
			local removed = false
			for i = #set, 1, -1 do
				local expires = set[i].expires
				if expires and expires > 0 and expires <= now then
					removeEntry(set, i)
					removed = true
				end
			end
			if removed then
				markDirty(guid)
			end
			if not set[1] and not guidPlates[guid] then
				releaseSet(guid)
			end
		end
	end
end

local function sweepTick(_, now)
	sweep(now or GetTime())
end

local function WipeAuraCache()
	-- next() traversal while deleting can skip keys; drain via first-key loop.
	local guid = next(cache)
	while guid do
		releaseSet(guid)
		guid = next(cache)
	end
	for guidPlate in next, guidPlates do
		guidPlates[guidPlate] = nil
	end
	for dirtyGuid in next, dirty do
		dirty[dirtyGuid] = nil
	end
	for pendingGuid in next, pendingScans do
		pendingScans[pendingGuid] = nil
	end
end

local function IsGuidString(s)
	return type(s) == "string" and s:sub(1, 2) == "0x"
end

local function StripBaseName(name)
	if not name then return nil end
	return match(name, "^[^%-]+") or name
end

-- Plate-name skips for the guid (token-less) path. The engine still applies
-- the UnitCreatureType/name skips on the token path; this mirrors them where
-- no token exists to query (totems have no token, so match by suffix).
local PLATE_AURA_SKIPS = {
	["Viper"] = true,
	["Venomous Snake"] = true,
	["Army of the Dead Ghoul"] = true,
}

local function PlateNameSkipped(base)
	if not base then return true end
	if PLATE_AURA_SKIPS[base] then return true end
	if base:sub(-5) == "Totem" then return true end
	return false
end

-- Time formatting (FrostAtom CooldownTimer ceil semantics: display never below reality)
local TIMER_DECIMAL_THRESHOLD = 3
local TIMER_UPDATE_INTERVAL = 0.1
local TIMER_TICK_MARGIN = 0.01
local function ShortTime(x, isColored)
	if x < 0 then
		return nil
	elseif x < 3 then
		if isColored then
			return ("|cffff0000%.01f|r"):format(x)
		else
			return ("%.01f"):format(x)
		end
	elseif x < 60 then
		if isColored then
			return ("|cffffff00%d|r"):format(math.ceil(x))
		else
			return ("%d"):format(math.ceil(x))
		end
	elseif x <= 3600 then
		return ("%dm"):format(math.ceil(x / 60))
	else
		if isColored then
			return ("|cffbbbbbb%dh|r"):format(math.ceil(x / 3600))
		else
			return ("%dh"):format(math.ceil(x / 3600))
		end
	end
end

-- Faithful port of FrostAtom CooldownTimer.untilTextChanges: seconds until
-- the displayed text must change, so SetText only fires on value changes.
local function TimerUntilChange(remain)
	if remain <= TIMER_DECIMAL_THRESHOLD then
		return TIMER_UPDATE_INTERVAL
	end
	local unit
	if remain <= 60 then
		unit = 1
	elseif remain <= 3600 then
		unit = 60
	else
		unit = 3600
	end
	local step = remain - (math.ceil(remain / unit) - 1) * unit + TIMER_TICK_MARGIN
	local maxStep = remain - TIMER_DECIMAL_THRESHOLD + TIMER_TICK_MARGIN
	if step > maxStep then
		step = maxStep
	end
	if step < 0 then
		step = 0
	end
	return step
end

-- Debuff-type border colors
-- NOTE: 3.3.5 DebuffTypeColor has only Magic/Curse/Disease/Poison -- there is
-- deliberately NO "none" entry. The combat-log path stores debuffType = "none"
-- (unknown type), so the renderer MUST guard this lookup (see updatePlate);
-- an unguarded unpack(debuffType2colors["none"]) throws and aborts the pass.
local debuffType2colors = {}
for k, v in next, DebuffTypeColor do
	debuffType2colors[k] = {v.r, v.g, v.b}
end

-- Icon pool (donor icon.lua visuals on the budsUI plate layout)
local unusedIcons = {}

local function GetFreeIcon(parent)
	local frame = tremove(unusedIcons) or nil
	if not frame then
		frame = CreateFrame("Frame")
		local texture = frame:CreateTexture(nil, "BORDER")
		if USE_MODERN_BORDER then
			texture:SetPoint("TOPRIGHT", -2, -2)
			texture:SetPoint("BOTTOMLEFT", 2, 2)
			texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		else
			texture:SetAllPoints()
			local border = frame:CreateTexture(nil, "OVERLAY")
			border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
			border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
			border:SetAllPoints()
			frame.border = border
		end
		frame.texture = texture

		local count = frame:CreateFontString(nil, "ARTWORK")
		count:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
		count:SetJustifyH("LEFT")
		count:SetPoint("BOTTOMRIGHT")
		frame.count = count

		local timer = frame:CreateFontString(nil, "OVERLAY")
		timer:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
		timer:SetPoint("CENTER")
		frame.timer = timer
	end
	frame.__pooled = nil
	frame:SetParent(parent)
	frame:SetFrameStrata("HIGH")
	frame._strata = "HIGH"
	frame:Show()
	return frame
end

local function ReleaseIcon(icon)
	if not icon then return nil end
	-- Idempotent: container OnHide AND explicit Hide can both fire for the
	-- same plate hide (Blizzard recycles nameplate frames), so never pool
	-- the same icon frame twice (that would share one frame between two
	-- plates and look flaky/missing).
	if icon.__pooled then return nil end
	icon.__pooled = true
	icon.duration = nil
	icon.endTime = nil
	icon.remain = nil
	icon.nextUpdate = nil
	-- Dirty-check state (see updatePlate): cleared so a pooled frame reused
	-- on another plate can never skip its first layout/texture/border paint.
	icon._ahl = nil
	icon._asize = nil
	icon._apointX = nil
	icon._apointY = nil
	icon._tex = nil
	icon._countVal = nil
	icon._expires = nil
	icon._borderKey = nil
	icon._strata = nil
	if icon.border then
		icon.border:Hide()
		icon.border:SetVertexColor(1, 1, 1)
	end
	if icon.timer then icon.timer:SetText(nil) end
	if icon.count then icon.count:SetText(nil) end
	icon:ClearAllPoints()
	icon:SetParent(nil)
	icon:Hide()
	unusedIcons[#unusedIcons + 1] = icon
	return nil
end

-- Engine (donor main.lua layout on the budsUI plate)
local function GetPointsByIndex(index, offsetY, size, inRow, count)
	local column = index % inRow
	local row = floor(index / inRow)
	local inThisRow = MathMin(inRow, count - (row * inRow))
	local indent = -(size + SPACE) / 2 * (inThisRow - 1)
	return indent + column * (size + SPACE), offsetY + row * (size + SPACE)
end

local function AuraIcons_OnHide(self)
	for i = #self, 1, -1 do
		self[i] = ReleaseIcon(self[i])
	end
end

local function hideAll(plate)
	local auraIcons = plate.__auraIcons
	if auraIcons then
		for i = #auraIcons, 1, -1 do
			auraIcons[i] = ReleaseIcon(auraIcons[i])
		end
		auraIcons:Hide()
	end
end

-- Drawing (donor updatePlate-style, dirty-checked): SetSize only when the size
-- changes, no ClearAllPoints per icon unless the slot/size/position moved,
-- texture/border/count only on change. Timer text is NEVER touched here beyond
-- arming (duration/endTime); the 0.1s ticker owns all countdown text.
function updatePlate(plate)
	local guid = plate.__auraGuid
	local set = guid and cache[guid]
	if not (C.Nameplate.Auras == true and set and set[1] and plate:IsShown()) then
		hideAll(plate)
		return
	end

	-- Icons float above the health bar (budsUI plate layout), like the donor
	-- floats them above the nameplate frame. The container is HIGH strata so
	-- icons render above the plate even when plate levels shift.
	local anchor = plate.hp or plate
	if not anchor then
		hideAll(plate)
		return
	end
	local auraIcons = plate.__auraIcons
	if not auraIcons then
		auraIcons = CreateFrame("Frame", nil, anchor)
		auraIcons:SetFrameStrata("HIGH")
		auraIcons:SetScript("OnHide", AuraIcons_OnHide)
		plate.__auraIcons = auraIcons
	end
	auraIcons:SetParent(anchor)
	if not auraIcons:IsShown() then
		auraIcons:Show()
	end

	local now = GetTime()
	-- First pass: count visible rows so highlight/normal grids can center.
	local countNormal, countHighlight = 0, 0
	for i = 1, #set do
		local entry = set[i]
		local expires = entry.expires
		if (expires == 0 or expires > now) and kindShown(entry.kind) then
			if entry.kind == KIND_OWN_CC or entry.kind == KIND_CC then
				countHighlight = countHighlight + 1
			else
				countNormal = countNormal + 1
			end
		end
	end

	local normalRows = MathCeil(countNormal / IN_ROW)
	local offsetHighlight = normalRows == 0 and OFFSET_Y or OFFSET_Y + normalRows * (SIZE + SPACE) + OFFSET_Y_HIGHLIGHT

	local indexNormal, indexHighlight = 0, 0
	local shown = 0
	for i = 1, #set do
		local entry = set[i]
		local expires = entry.expires
		if (expires == 0 or expires > now) and kindShown(entry.kind) then
			shown = shown + 1
			local icon = auraIcons[shown]
			if not icon then
				icon = GetFreeIcon(auraIcons)
				auraIcons[shown] = icon
			end

			local isH = (entry.kind == KIND_OWN_CC or entry.kind == KIND_CC) and true or false
			local sz = isH and SIZE_HIGHLIGHT or SIZE
			local px, py
			if isH then
				px, py = GetPointsByIndex(indexHighlight, offsetHighlight, SIZE_HIGHLIGHT, IN_ROW_HIGHLIGHT, countHighlight)
				indexHighlight = indexHighlight + 1
			else
				px, py = GetPointsByIndex(indexNormal, OFFSET_Y, SIZE, IN_ROW, countNormal)
				indexNormal = indexNormal + 1
			end
			-- Dirty-checked layout: pool reuse is the only reason anchors go
			-- stale, so ClearAllPoints/SetPoint/SetSize run only when the
			-- slot, size, or computed x/y actually moved.
			if icon._strata ~= "HIGH" then
				icon:SetFrameStrata("HIGH")
				icon._strata = "HIGH"
			end
			if icon._ahl ~= isH or icon._asize ~= sz or icon._apointX ~= px or icon._apointY ~= py then
				icon:ClearAllPoints()
				icon:SetPoint("BOTTOM", anchor, "TOP", px, py)
				if icon._asize ~= sz then
					icon:SetSize(sz, sz)
				end
				icon._ahl, icon._asize, icon._apointX, icon._apointY = isH, sz, px, py
			end

			-- Arm/disarm the countdown; the ticker owns the text itself.
			local exp = expires
			if icon._expires ~= exp then
				icon._expires = exp
				if exp == 0 then
					icon.duration, icon.endTime = nil, nil
					icon.remain, icon.nextUpdate = nil, nil
					icon.timer:SetText(nil)
				else
					icon.duration, icon.endTime = entry.duration, exp
					icon.remain = exp - now
					icon.nextUpdate = 0
				end
			end

			-- Guarded color lookup: the combat-log path stores debuffType =
			-- "none" (unknown type) and 3.3.5 DebuffTypeColor has no "none"
			-- key. Unknown/"none" renders with NO colored border; the exact
			-- scan re-colors it once a real UnitAura debuffType is known.
			local borderColor = entry.debuffType and debuffType2colors[entry.debuffType]
			local borderKey = entry.debuffType or false
			if icon._borderKey ~= borderKey then
				icon._borderKey = borderKey
				if borderColor then
					if USE_MODERN_BORDER then
						icon:SetBackdropBorderColor(unpack(borderColor))
					else
						icon.border:SetVertexColor(unpack(borderColor))
						icon.border:Show()
					end
				else
					if USE_MODERN_BORDER then
						icon:SetBackdropBorderColor(0, 0, 0)
					else
						icon.border:Hide()
					end
				end
			end

			if icon._tex ~= entry.icon then
				icon._tex = entry.icon
				if entry.icon then
					icon.texture:SetTexture(entry.icon)
				end
			end
			local cnt = (entry.count or 0) > 1 and entry.count or nil
			if icon._countVal ~= cnt then
				icon._countVal = cnt
				icon.count:SetText(cnt)
			end
		end
	end

	for i = #auraIcons, shown + 1, -1 do
		auraIcons[i] = ReleaseIcon(auraIcons[i])
	end

	if shown == 0 then
		auraIcons:Hide()
	end
end

-- Timer ticker (donor updateTimers): 0.1s, ONLY timer text. Never touches
-- icon layout. Expired entries mark their guid dirty so the flush drops them.
local function updateAllTimers(_, now)
	now = now or GetTime()
	for guid, plate in next, guidPlates do
		local auraIcons = plate.__auraIcons
		if auraIcons and plate:IsShown() then
			for i = 1, #auraIcons do
				local icon = auraIcons[i]
				if icon and icon.endTime then
					local remain = icon.endTime - now
					if remain > 0 then
						icon.remain = remain
						if not icon.nextUpdate or icon.nextUpdate == 0 or remain <= icon.nextUpdate then
							icon.timer:SetText(ShortTime(remain, true))
							icon.nextUpdate = remain - TimerUntilChange(remain)
						end
					else
						icon.endTime = nil
						icon.remain = nil
						icon.nextUpdate = nil
						markDirty(guid)
					end
				end
			end
		end
	end
end

-- GUID-or-token entry point (donor UnitAdded/Pass model):
--   * fresh bind with a unit token -> exact UnitAura scan once (covers
--     EVENT_UNITS target-switches where no UNIT_AURA fires), then markDirty
--   * fresh bind with a bare guid  -> paint the combat-log cache via markDirty
--   * steady bind, token NOT in EVENT_UNITS -> exactScan now (donor onUnitAdded/
--     onPass for the rest); steady EVENT_UNITS / steady guid -> nothing, the
--     UNIT_AURA / CLEU / timer ticker drive all future redraws via markDirty.
-- The old "return if not unitID" guard is gone so the cache path works.
function K.NamePlateAuras_Update(plate, unitOrGuid)
	if C.Nameplate.Auras ~= true then return end
	if not plate or not unitOrGuid then
		K.NamePlateAuras_Hide(plate)
		return
	end
	local guid, unit = nil, nil
	if IsGuidString(unitOrGuid) then
		guid = unitOrGuid
	elseif type(unitOrGuid) == "string" and UnitExists(unitOrGuid) then
		unit = unitOrGuid
		guid = UnitGUID(unit)
		if type(guid) ~= "string" then
			K.NamePlateAuras_Hide(plate)
			return
		end
		if UnitCreatureType(unit) == "Totem" then return end
		local uname = UnitName(unit)
		if uname == "Viper" or uname == "Venomous Snake" or uname == "Army of the Dead Ghoul" then return end
	else
		-- Unknown key (stale token or guid without 0x prefix):
		-- never create numeric cache keys; only accept real guid strings.
		K.NamePlateAuras_Hide(plate)
		return
	end
	-- Guid-path name skips (no token to query for creature type).
	if not unit then
		local hp = plate.hp
		local oldname = hp and hp.oldname and hp.oldname:GetText()
		if PlateNameSkipped(StripBaseName(oldname)) then
			K.NamePlateAuras_Hide(plate)
			return
		end
	end
	-- Register plate for event-driven redraws; drop stale binding.
	local prev = plate.__auraGuid
	if prev and prev ~= guid and guidPlates[prev] == plate then
		guidPlates[prev] = nil
	end
	plate.__auraGuid = guid
	plate.__auraUnit = unit
	guidPlates[guid] = plate
	if prev ~= guid then
		if unit then
			exactScan(unit, guid)
		else
			markDirty(guid)
		end
	elseif unit and not EVENT_UNITS[unit] then
		exactScan(unit, guid)
	end
end

function K.NamePlateAuras_Hide(plate)
	if not plate then return end
	local auraGuid = plate.__auraGuid
	if auraGuid then
		if guidPlates[auraGuid] == plate then
			guidPlates[auraGuid] = nil
		end
		plate.__auraGuid = nil
		plate.__auraUnit = nil
		pruneUntimed(auraGuid)
	end
	hideAll(plate)
	-- Also cover the legacy container field if an old-skinned plate has one
	if plate.icons and plate.icons ~= plate.__auraIcons and type(plate.icons) == "table" then
		for _, icon in next, plate.icons do
			if type(icon) == "table" and icon.Hide then icon:Hide() end
		end
	end
end

-- Event contour (donor plugin Log + UNIT_AURA + world/pet hooks), plain
-- budsUI-style frames, every dispatch guarded + pcall.
-- 3.3.5 has no native Frame:RegisterUnitEvent (it was added in Patch 5.0.4),
-- so UNIT_AURA is registered via plain RegisterEvent and the handler filters
-- to EVENT_UNITS — this matches both the donor (whose EventMixin:RegisterUnitEvent
-- is its own bus over a plain RegisterEvent) and ElvUI-7 (30300 reference,
-- which uses header:RegisterEvent('UNIT_AURA') + unit filter).
local function onUnitAura(unit)
	if not EVENT_UNITS[unit] then return end
	local guid = UnitGUID(unit)
	if guid and guidPlates[guid] then
		exactScan(unit, guid)
	end
end

local cleuFrame = CreateFrame("Frame")
cleuFrame:SetScript("OnEvent", function(self, event, ...)
	if C.Nameplate.Auras ~= true then return end
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local ok, err = pcall(HandleCombatLogEvent, ...)
		if not ok and C.General and C.General.DeveloperMode then
			K.Print("NamePlateAuras CLEU error:", err)
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		playerGUID = UnitGUID("player")
		petGUID = UnitGUID("pet")
		local ok, err = pcall(WipeAuraCache)
		if not ok and C.General and C.General.DeveloperMode then
			K.Print("NamePlateAuras wipe error:", err)
		end
	elseif event == "UNIT_PET" then
		local unit = ...
		if unit == "player" then
			petGUID = UnitGUID("pet")
		end
	end
end)

local unitFrame = CreateFrame("Frame")
unitFrame:SetScript("OnEvent", function(self, event, unit)
	if C.Nameplate.Auras ~= true then return end
	if event == "UNIT_AURA" then
		local ok, err = pcall(onUnitAura, unit)
		if not ok and C.General and C.General.DeveloperMode then
			K.Print("NamePlateAuras UNIT_AURA error:", err)
		end
	end
end)

if C.Nameplate.Auras == true then
	cleuFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	cleuFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	cleuFrame:RegisterEvent("UNIT_PET")
	unitFrame:RegisterEvent("UNIT_AURA")
	playerGUID = UnitGUID("player")
	petGUID = UnitGUID("pet")

	-- Donor timers: one 0.1s ticker for countdown text, one 10s sweep.
	-- Multiplexed on the prebuilt Core/Scheduler (donor ns tickers equivalent).
	if K.Scheduler and K.Scheduler.AddTicker then
		K.Scheduler.AddTicker("NamePlateAurasTimers", updateAllTimers, TIMER_INTERVAL)
		K.Scheduler.AddTicker("NamePlateAurasSweep", sweepTick, SWEEP_INTERVAL)
	else
		local fallback = CreateFrame("Frame")
		local timerAccum, sweepAccum = 0, 0
		fallback:SetScript("OnUpdate", K.SafeOnUpdate(function(self, elapsed)
			if C.Nameplate.Auras ~= true then return end
			timerAccum = timerAccum + elapsed
			sweepAccum = sweepAccum + elapsed
			if timerAccum >= TIMER_INTERVAL then
				timerAccum = 0
				updateAllTimers(nil, GetTime())
			end
			if sweepAccum >= SWEEP_INTERVAL then
				sweepAccum = 0
				sweep(GetTime())
			end
		end, "NamePlateAurasFallback"))
		fallback:Show()
	end
end
