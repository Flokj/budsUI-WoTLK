local K, C, L, _ = select(2, ...):unpack()
if C.Nameplate.Enable ~= true then return end

-- Port of the standalone "NamePlateAuras" addon (see _hermes_refs/NamePlateAuras/).
-- Adapted to the budsUI namespace: no setfenv/namespace magic, everything is
-- local here except the two entry points exposed on K for Nameplate.lua:
--   K.NamePlateAuras_Update(plate, unitID) -- full aura refresh for one plate
--   K.NamePlateAuras_Hide(plate)           -- release all aura icons of a plate
-- WoW 3.3.5 quirk: UnitAura returns only 10 values (no 11th spellID), so
-- spellID-dependent filtering is guarded and degrades gracefully (nil spellID).

local next, type, unpack = next, type, unpack
local floor = math.floor
local MathMin = math.min
local MathCeil = math.ceil
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

-- Table pool (donor table.lua) — declared at the VERY TOP of the file, before
-- ANY function that could call TableNew/TableDel. Lua locals are only visible
-- AFTER their declaration, so a pool declared lower would leave earlier
-- functions resolving TableNew/TableDel to a nil global
-- ("attempt to call global 'TableNew'").
local tableCache = setmetatable({}, {__mode = "k"})
local function TableNew()
	local n = #tableCache
	if n == 0 then
		return {}
	end
	local t = tableCache[n]
	tableCache[n] = nil
	return t
end
local function TableDel(tbl)
	if tbl then
		wipe(tbl)
		tableCache[#tableCache + 1] = tbl
	end
	return nil
end

-- Config (geometry sourced from build config C.Nameplate, donor defaults as fallback)
local USE_MODERN_BORDER = false
local SPACE = 0
local SIZE = C.Nameplate.AuraSize or 24
local IN_ROW = 6
local OFFSET_Y = C.Nameplate.AuraOffsetY or 22
local SIZE_HIGHLIGHT = C.Nameplate.AuraSizeHighlight or 28
local IN_ROW_HIGHLIGHT = 4
local OFFSET_Y_HIGHLIGHT = 2

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
		if type(v) == "table" and v.spellId then
			v.spellId = k
		end
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

-- Duration defaults for combat-log auras (seconds by spellID; copied from
-- FrostAtomUI AuraData.lua CC_DURATIONS + DEFENSIVE_DURATIONS). The combat
-- log carries no duration/expiry, so applied auras fall back to these tables
-- (by spellID, then by spell name); truly unknown spells fall back to
-- FALLBACK_AURA_DURATION so they still render with a timer.
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
	[54748] = 20, [31884] = 20, [61025] = 10, [33786] = 6, [16166] = 12,
	[17116] = 12, [53271] = 4, [1044] = 6, [10278] = 10, [20066] = 6,
}

local FALLBACK_AURA_DURATION = 8

local durationsByName = {}
for _id, _dur in next, DURATION_DEFAULTS_BY_ID do
	local _name = GetSpellInfo(_id)
	if _name and _dur > 0 then
		durationsByName[_name] = _dur
	end
end

local function DurationFor(spellId, spellName)
	return DURATION_DEFAULTS_BY_ID[spellId] or durationsByName[spellName] or FALLBACK_AURA_DURATION
end

-- GUID-keyed aura cache (FrostAtomUI Auras.lua model).
-- auraCache[guid] = map of spellName -> entry
-- entry = { spellId, name, texture, count, duration, expires, isHighlight, debuffType }
-- Fed by two sources:
--   1. COMBAT_LOG_EVENT_UNFILTERED (backbone; covers token-less enemy plates)
--   2. ExactScanIntoCache via UnitAura whenever a unit token exists (exact refresh)
local auraCache = {}
local guidPlates = {}
local playerGUID, petGUID = nil, nil

local function IsGuidString(s)
	return type(s) == "string" and s:sub(1, 2) == "0x"
end

local function GetCacheSet(guid, create)
	-- Defensive: auraCache must only ever be keyed by dstGUID strings
	-- ("0x..."). A numeric key (spellId/amount/flags) would corrupt the map.
	if type(guid) ~= "string" then return nil end
	local set = auraCache[guid]
	if not set and create then
		set = {}
		auraCache[guid] = set
	end
	return set
end

local function ReleaseCacheSet(guid)
	if type(guid) ~= "string" then
		-- Drop numeric/leftover keys outright (release pooled entries too).
		local bad = auraCache[guid]
		if bad and type(bad) == "table" then
			for k, entry in next, bad do
				TableDel(entry)
				bad[k] = nil
			end
		end
		auraCache[guid] = nil
		return
	end
	local set = auraCache[guid]
	if set then
		for k, entry in next, set do
			TableDel(entry)
			set[k] = nil
		end
		auraCache[guid] = nil
	end
end

-- Forward: defined after the renderer (needs UpdateIcons); assigned below.
local RedrawGuidPlate

-- Donor filter semantics for a combat-log aura.
-- Returns "highlight" (whitelisted), "normal" (own, not blacklisted), or nil (skip).
local function ClassifyLogAura(spellName, isMineCaster)
	if not spellName then return nil end
	if isMineCaster and not SPELLS_BLACKLIST[spellName] then
		if SPELLS_WHITELIST[spellName] then return "highlight" end
		return "normal"
	end
	if SPELLS_WHITELIST[spellName] then return "highlight" end
	return nil
end

local function TextureFor(spellId, spellName)
	local _, _, icon = GetSpellInfo(spellId)
	if icon then return icon end
	local _, _, iconByName = GetSpellInfo(spellName)
	return iconByName
end

local function TrackLogAura(guid, spellId, spellName, auraType, isMineCaster)
	-- CLEU order: dstGUID(string), spellId(number), spellName(string).
	-- Reject any misordered/numeric call so a numeric cache key is impossible.
	if type(guid) ~= "string" then return end
	if type(spellName) ~= "string" then return end
	if type(spellId) ~= "number" then return end
	local class = ClassifyLogAura(spellName, isMineCaster)
	if not class then return end
	local set = GetCacheSet(guid, true)
	if not set then return end
	local entry = set[spellName]
	local now = GetTime()
	local duration = DurationFor(spellId, spellName)
	if not entry then
		entry = TableNew()
		set[spellName] = entry
	end
	entry.spellId = spellId
	entry.name = spellName
	entry.texture = TextureFor(spellId, spellName)
	entry.count = entry.count or 0
	entry.duration = duration
	entry.expires = now + duration
	entry.isHighlight = (class == "highlight")
	if auraType == "BUFF" then
		entry.debuffType = nil
	else
		entry.debuffType = "none"
	end
	if RedrawGuidPlate then RedrawGuidPlate(guid) end
end

local function DoseLogAura(guid, spellName, amount)
	if type(guid) ~= "string" then return end
	if type(spellName) ~= "string" then return end
	if type(amount) ~= "number" then return end
	local set = auraCache[guid]
	if not set then return end
	local entry = set[spellName]
	if entry then
		entry.count = amount
		if RedrawGuidPlate then RedrawGuidPlate(guid) end
	end
end

local function RemoveLogAura(guid, spellName)
	if type(guid) ~= "string" then return end
	if type(spellName) ~= "string" then return end
	local set = auraCache[guid]
	if not set then return end
	local entry = set[spellName]
	if entry then
		TableDel(entry)
		set[spellName] = nil
		if RedrawGuidPlate then RedrawGuidPlate(guid) end
	end
end

local function DiedLogAura(guid)
	if type(guid) ~= "string" then return end
	if auraCache[guid] then
		ReleaseCacheSet(guid)
		if RedrawGuidPlate then RedrawGuidPlate(guid) end
	end
end

local lastSweep = 0
local function SweepCaches(now)
	if now - lastSweep < 10 then return end
	lastSweep = now
	for guid, set in next, auraCache do
		if type(guid) ~= "string" or type(set) ~= "table" then
			ReleaseCacheSet(guid)
		else
			for name, entry in next, set do
				if type(entry) ~= "table" or (entry.expires and entry.expires > 0 and entry.expires <= now) then
					TableDel(entry)
					set[name] = nil
				end
			end
			if not next(set) and not guidPlates[guid] then
				ReleaseCacheSet(guid)
			end
		end
	end
end

-- Exact UnitAura scan into the guid's cache (FrostAtomUI exactScan spirit).
-- Authoritative while a token exists: replaces the set wholesale, keeping the
-- donor whitelist/blacklist/isMine filter semantics and the real
-- duration/expirationTime (including 0 = timeless, no timer).
local function ExactScanIntoCache(unit, guid)
	if type(guid) ~= "string" then return end
	if type(unit) ~= "string" then return end
	local set = GetCacheSet(guid, true)
	if not set then return end
	for k, entry in next, set do
		TableDel(entry)
		set[k] = nil
	end

	local index, filter = 0, nil
	local spellName, texture, count, debuffType, duration, expirationTime, caster, spellID
	local value
	while true do
		index = index + 1
		-- 3.3.5: UnitAura returns only 10 values, spellID (11th) is always nil here
		spellName, _, texture, count, debuffType, duration, expirationTime, caster, _, _, spellID = UnitAura(unit, index, filter)
		if spellName then
			value = SPELLS_WHITELIST[spellName]
			if ((caster == "player" or caster == "pet" or caster == "vehicle") and not SPELLS_BLACKLIST[spellName]) or
				(value and (type(value) ~= "table" or ((not value.spellId or value.spellId == spellID) and not value.isMine))) then

				local entry = TableNew()
				entry.spellId = spellID
				entry.name = spellName
				entry.texture = texture
				entry.count = count
				entry.duration = duration
				entry.expires = expirationTime
				entry.isHighlight = not not value
				if filter == "HARMFUL" then
					entry.debuffType = debuffType or "none"
				else
					entry.debuffType = nil
				end
				local old = set[spellName]
				if old then TableDel(old) end
				set[spellName] = entry
			end
		else
			if not filter then
				filter, index = "HARMFUL", 0
			else
				break
			end
		end
	end
end

-- Build the donor-renderer aura list from cache[guid], pruning expired
-- entries. Returned list (and its entries) are pool copies that UpdateIcons
-- releases as before; cache entries stay owned by the cache.
local function BuildAuraInfoFromCache(guid, now)
	local auraInfo = TableNew()
	if type(guid) ~= "string" then return auraInfo end
	local set = auraCache[guid]
	if type(set) ~= "table" then return auraInfo end
	if set then
		for name, entry in next, set do
			if type(entry) ~= "table" then
				set[name] = nil
			elseif entry.expires and entry.expires > 0 and entry.expires <= now then
				TableDel(entry)
				set[name] = nil
			else
				local t = TableNew()
				t.texture = entry.texture
				t.count = entry.count
				t.expirationTime = entry.expires
				t.isHighlight = entry.isHighlight
				t.spellID = entry.spellId
				t.debuffType = entry.debuffType
				auraInfo[#auraInfo + 1] = t
			end
		end
		if not next(set) and not guidPlates[guid] then
			ReleaseCacheSet(guid)
		end
	end
	return auraInfo
end

-- Combat-log listener: backbone feed for token-less enemy plates.
-- 3.3.5 CLEU args: (timestamp, subEvent, srcGUID, srcName, srcFlags,
-- dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount?)
-- Best-effort by design: every branch is type-guarded and the whole dispatch
-- runs inside pcall so one malformed event can never break the addon.
local function HandleCombatLogEvent(timestamp, subEvent, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, a1, a2, a3, a4, a5)
	if subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REFRESH" then
		-- a1=spellId(number), a2=spellName(string), a4=auraType; guid=dstGUID(string)
		if type(dstGUID) == "string" and type(a1) == "number" and type(a2) == "string" then
			local mine = (type(srcGUID) == "string" and (srcGUID == playerGUID or srcGUID == petGUID))
			TrackLogAura(dstGUID, a1, a2, a4, mine)
		end
	elseif subEvent == "SPELL_AURA_APPLIED_DOSE" or subEvent == "SPELL_AURA_REMOVED_DOSE" then
		-- a2=spellName(string), a5=new stack count(number); never use a5 as a key
		if type(dstGUID) == "string" and type(a2) == "string" and type(a5) == "number" then
			DoseLogAura(dstGUID, a2, a5)
		end
	elseif subEvent == "SPELL_AURA_REMOVED" or subEvent == "SPELL_AURA_BROKEN" or subEvent == "SPELL_AURA_BROKEN_SPELL" then
		if type(dstGUID) == "string" and type(a2) == "string" then
			RemoveLogAura(dstGUID, a2)
		end
	elseif subEvent == "UNIT_DIED" or subEvent == "UNIT_DESTROYED" or subEvent == "UNIT_DISSIPATES" then
		if type(dstGUID) == "string" then
			DiedLogAura(dstGUID)
		end
	end
end

local function WipeAuraCache()
	-- next() traversal while deleting can skip keys; drain via first-key loop.
	local guid = next(auraCache)
	while guid do
		ReleaseCacheSet(guid)
		guid = next(auraCache)
	end
	for guid2 in next, guidPlates do
		guidPlates[guid2] = nil
	end
end

local auraLog = CreateFrame("Frame")
auraLog:SetScript("OnEvent", function(self, event, ...)
	if C.Nameplate.Auras ~= true then return end
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local ok, err = pcall(HandleCombatLogEvent, ...)
		if not ok and C.General and C.General.DeveloperMode then
			K.Print("NamePlateAuras CLEU error:", err)
		end
		local ok2, err2 = pcall(SweepCaches, GetTime())
		if not ok2 and C.General and C.General.DeveloperMode then
			K.Print("NamePlateAuras sweep error:", err2)
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
if C.Nameplate.Auras == true then
	auraLog:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	auraLog:RegisterEvent("PLAYER_ENTERING_WORLD")
	auraLog:RegisterEvent("UNIT_PET")
	playerGUID = UnitGUID("player")
	petGUID = UnitGUID("pet")
end

-- Time formatting (donor math.lua)
local function MathRound(x)
	return floor(x + 0.51)
end
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
			return ("|cffffff00%d|r"):format(MathRound(x))
		else
			return MathRound(x)
		end
	elseif x <= 3600 then
		return ("%dm"):format(MathRound(x / 60))
	else
		if isColored then
			return ("|cffbbbbbb%dh|r"):format(MathRound(x / 3600))
		else
			return ("%dh"):format(MathRound(x / 3600))
		end
	end
end

-- Debuff-type border colors
local debuffType2colors = {}
for k, v in next, DebuffTypeColor do
	debuffType2colors[k] = {v.r, v.g, v.b}
end

-- Icon pool (donor icon.lua)
local unusedIcons = {}

local function Icon_OnUpdate(self, elapsed)
	if self.texturePath then
		self.texture:SetTexture(self.texturePath)
		self.texturePath = nil
	end

	local remain = self.remain
	if not remain then return end
	remain = remain - elapsed
	if remain < 0 then
		self.timer:SetText(nil)
		self.remain = nil
	else
		self.timer:SetText(ShortTime(remain, true))
		self.remain = remain
	end
end

local function CreateIcon()
	local icon = CreateFrame("Frame")
	icon:SetScript("OnUpdate", Icon_OnUpdate)

	local texture = icon:CreateTexture(nil, "BORDER")
	if USE_MODERN_BORDER then
		texture:SetPoint("TOPRIGHT", -2, -2)
		texture:SetPoint("BOTTOMLEFT", 2, 2)
		texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	else
		texture:SetAllPoints()

		local border = icon:CreateTexture(nil, "OVERLAY")
		border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
		border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
		border:SetAllPoints()

		icon.border = border
	end
	icon.texture = texture

	local count = icon:CreateFontString(nil, "ARTWORK")
	count:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
	count:SetJustifyH("LEFT")
	count:SetPoint("BOTTOMRIGHT")
	icon.count = count

	local timer = icon:CreateFontString(nil, "OVERLAY")
	timer:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
	timer:SetPoint("CENTER")
	icon.timer = timer

	return icon
end

local function GetFreeIcon(parent)
	local frame = table.remove(unusedIcons) or CreateIcon()
	frame.__pooled = nil
	frame:SetParent(parent)
	frame:SetFrameStrata("HIGH")
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
	icon.remain = nil
	icon.texturePath = nil
	if icon.timer then icon.timer:SetText(nil) end
	if icon.count then icon.count:SetText(nil) end
	icon:ClearAllPoints()
	icon:SetParent(nil)
	icon:Hide()
	unusedIcons[#unusedIcons + 1] = icon
	return nil
end

-- Engine (donor main.lua)
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

local function IsMine(caster)
	return caster == "player" or caster == "pet" or caster == "vehicle"
end

-- NOTE: the old token-only CollectInfo(unitID) collector was replaced by
-- ExactScanIntoCache (UnitAura -> GUID cache) + BuildAuraInfoFromCache
-- (GUID cache -> UpdateIcons list). UpdateIcons below is the untouched donor
-- renderer; do not retune its visual values.

local function UpdateIcons(plate, auraInfo)
	local auraInfoN = #auraInfo
	local auraIcons = plate.__auraIcons

	if auraInfoN == 0 then
		if auraIcons then
			for i = #auraIcons, 1, -1 do
				auraIcons[i] = ReleaseIcon(auraIcons[i])
			end
		end
		TableDel(auraInfo)
		return
	end

	-- Icons float above the health bar (budsUI plate layout), like the donor
	-- floats them above the nameplate frame. The container is HIGH strata so
	-- icons render above the plate even when plate levels shift; icons are
	-- re-anchored every refresh (ClearAllPoints) because pool reuse would
	-- otherwise stack stale anchors from a previous plate.
	local anchor = plate.hp or plate
	if not anchor then
		for i = 1, auraInfoN do
			TableDel(auraInfo[i])
		end
		TableDel(auraInfo)
		return
	end
	if not auraIcons then
		auraIcons = CreateFrame("Frame", nil, anchor)
		auraIcons:SetFrameStrata("HIGH")
		auraIcons:SetScript("OnHide", AuraIcons_OnHide)
		plate.__auraIcons = auraIcons
	end
	auraIcons:SetParent(anchor)
	auraIcons:SetFrameStrata("HIGH")
	if not auraIcons:IsShown() then
		auraIcons:Show()
	end

	local countNormal, countHighlight = 0, 0
	for i = 1, auraInfoN do
		if auraInfo[i].isHighlight then
			countHighlight = countHighlight + 1
		else
			countNormal = countNormal + 1
		end
	end

	local normalRows = MathCeil(countNormal / IN_ROW)
	local offsetHighlight = normalRows == 0 and OFFSET_Y or OFFSET_Y + normalRows * (SIZE + SPACE) + OFFSET_Y_HIGHLIGHT
	local curTime = GetTime()

	local indexNormal, indexHighlight = 0, 0
	local icon, info
	for i = 1, auraInfoN do
		icon, info = auraIcons[i], auraInfo[i]
		if not icon then
			icon = GetFreeIcon(auraIcons)
			auraIcons[i] = icon
		end

		icon:SetFrameStrata("HIGH")
		icon:ClearAllPoints()
		if info.isHighlight then
			icon:SetPoint("BOTTOM", anchor, "TOP", GetPointsByIndex(indexHighlight, offsetHighlight, SIZE_HIGHLIGHT, IN_ROW_HIGHLIGHT, countHighlight))
			icon:SetSize(SIZE_HIGHLIGHT, SIZE_HIGHLIGHT)
			indexHighlight = indexHighlight + 1
		else
			icon:SetPoint("BOTTOM", anchor, "TOP", GetPointsByIndex(indexNormal, OFFSET_Y, SIZE, IN_ROW, countNormal))
			icon:SetSize(SIZE, SIZE)
			indexNormal = indexNormal + 1
		end

		if info.expirationTime == 0 then
			icon.remain = nil
			icon.timer:SetText(nil)
		else
			icon.remain = info.expirationTime - curTime
		end

		if info.debuffType then
			if USE_MODERN_BORDER then
				icon:SetBackdropBorderColor(unpack(debuffType2colors[info.debuffType]))
			else
				icon.border:SetVertexColor(unpack(debuffType2colors[info.debuffType]))
				icon.border:Show()
			end
		else
			if USE_MODERN_BORDER then
				icon:SetBackdropBorderColor(0, 0, 0)
			else
				icon.border:Hide()
			end
		end

		icon.texturePath = info.texture
		icon.count:SetText((info.count or 0) > 1 and info.count or nil)

		auraInfo[i] = nil
		TableDel(info)
	end

	for i = #auraIcons, auraInfoN + 1, -1 do
		auraIcons[i] = ReleaseIcon(auraIcons[i])
	end

	TableDel(auraInfo)
end

-- Draw one plate purely from cache[guid] (used for token AND guid paths).
local function DrawCachedPlate(plate, guid)
	UpdateIcons(plate, BuildAuraInfoFromCache(guid, GetTime()))
end

-- Immediate combat-log driven redraw for the plate showing this guid.
RedrawGuidPlate = function(guid)
	if type(guid) ~= "string" then return end
	local plate = guidPlates[guid]
	if plate and plate.IsShown and plate:IsShown() then
		DrawCachedPlate(plate, guid)
	end
end

-- GUID-or-token entry point (FrostAtomUI model):
--   * unit token -> exact UnitAura scan refreshes that guid's cache, then draw merged cache
--   * bare guid   -> draw purely from the combat-log cache (token-less enemy plates)
-- The old "return if not unitID" guard is gone so the cache path works.
function K.NamePlateAuras_Update(plate, unitOrGuid)
	if C.Nameplate.Auras ~= true then return end
	if not plate or not unitOrGuid then
		K.NamePlateAuras_Hide(plate)
		return
	end
	local guid = nil
	if IsGuidString(unitOrGuid) then
		guid = unitOrGuid
	elseif UnitExists(unitOrGuid) then
		local unit = unitOrGuid
		guid = UnitGUID(unit)
		if type(guid) ~= "string" then
			K.NamePlateAuras_Hide(plate)
			return
		end
		local name = UnitName(unit)
		if UnitCreatureType(unit) == "Totem" then return end
		if name == "Viper" then return end
		if name == "Venomous Snake" then return end
		if name == "Army of the Dead Ghoul" then return end
		ExactScanIntoCache(unit, guid)
	else
		-- Unknown key (stale token, number, or guid without 0x prefix):
		-- never create numeric cache keys; only accept real guid strings.
		if not IsGuidString(unitOrGuid) then
			K.NamePlateAuras_Hide(plate)
			return
		end
		guid = unitOrGuid
	end
	-- Register plate for combat-log driven redraws; drop stale binding
	local prev = plate.__auraGuid
	if prev and prev ~= guid and guidPlates[prev] == plate then
		guidPlates[prev] = nil
	end
	plate.__auraGuid = guid
	guidPlates[guid] = plate
	DrawCachedPlate(plate, guid)
end

function K.NamePlateAuras_Hide(plate)
	if not plate then return end
	local auraGuid = plate.__auraGuid
	if auraGuid then
		if guidPlates[auraGuid] == plate then
			guidPlates[auraGuid] = nil
		end
		plate.__auraGuid = nil
	end
	local auraIcons = plate.__auraIcons
	if auraIcons then
		for i = #auraIcons, 1, -1 do
			auraIcons[i] = ReleaseIcon(auraIcons[i])
		end
	end
	-- Also cover the legacy container field if an old-skinned plate has one
	if plate.icons and plate.icons ~= auraIcons and type(plate.icons) == "table" then
		for _, icon in ipairs(plate.icons) do
			if icon.Hide then icon:Hide() end
		end
	end
end
