local K, C, L, _ = select(2, ...):unpack()
if C.Filger.Enable ~= true or IsAddOnLoaded("Stuf") or IsAddOnLoaded("PitBull4") or IsAddOnLoaded("ShadowedUnitFrames") or IsAddOnLoaded("XPerl") then return end

K.Frames = K.Frames or {}
local function SafeCreateFrame(name, parent)
	local success, frame = pcall(CreateFrame, "Frame", name, parent)
	if not success then
		print("|cffFF0000budsUI:|r Failed to create frame: " .. name)
		return CreateFrame("Frame") -- return an anonymous frame as fallback
	end
	return frame
end

K.Frames.COOLDOWN_Anchor = SafeCreateFrame("budsUI_COOLDOWN_Anchor", UIParent)
K.Frames.PVE_PVP_CC_Anchor = SafeCreateFrame("budsUI_PVE_PVP_CC_Anchor", UIParent)
K.Frames.PVE_PVP_DEBUFF_Anchor = SafeCreateFrame("budsUI_PVE_PVP_DEBUFF_Anchor", UIParent)
K.Frames.P_BUFF_ICON_Anchor = SafeCreateFrame("budsUI_P_BUFF_ICON_Anchor", UIParent)
K.Frames.P_PROC_ICON_Anchor = SafeCreateFrame("budsUI_P_PROC_ICON_Anchor", UIParent)
K.Frames.SPECIAL_P_BUFF_ICON_Anchor = SafeCreateFrame("budsUI_SPECIAL_P_BUFF_ICON_Anchor", UIParent)
K.Frames.T_BUFF_Anchor = SafeCreateFrame("budsUI_T_BUFF_Anchor", UIParent)
K.Frames.T_DEBUFF_ICON_Anchor = SafeCreateFrame("budsUI_T_DEBUFF_ICON_Anchor", UIParent)
K.Frames.T_DE_BUFF_BAR_Anchor = SafeCreateFrame("budsUI_T_DE_BUFF_BAR_Anchor", UIParent)

-- Update the local references so the rest of the file doesn't need to change
local COOLDOWN_Anchor = K.Frames.COOLDOWN_Anchor
local PVE_PVP_CC_Anchor = K.Frames.PVE_PVP_CC_Anchor
local PVE_PVP_DEBUFF_Anchor = K.Frames.PVE_PVP_DEBUFF_Anchor
local P_BUFF_ICON_Anchor = K.Frames.P_BUFF_ICON_Anchor
local P_PROC_ICON_Anchor = K.Frames.P_PROC_ICON_Anchor
local SPECIAL_P_BUFF_ICON_Anchor = K.Frames.SPECIAL_P_BUFF_ICON_Anchor
local T_BUFF_Anchor = K.Frames.T_BUFF_Anchor
local T_DEBUFF_ICON_Anchor = K.Frames.T_DEBUFF_ICON_Anchor
local T_DE_BUFF_BAR_Anchor = K.Frames.T_DE_BUFF_BAR_Anchor

local function P_BUFF(id) return {spellID = id, unitID = "player", caster = "player", filter = "BUFF"} end
local function P_BUFF_ALL(id) return {spellID = id, unitID = "player", caster = "all", filter = "BUFF"} end
local function T_DEBUFF(id) return {spellID = id, unitID = "target", caster = "player", filter = "DEBUFF"} end
local function T_DEBUFF_ALL(id) return {spellID = id, unitID = "target", caster = "all", filter = "DEBUFF"} end
local function T_BUFF(id) return {spellID = id, unitID = "target", caster = "player", filter = "BUFF"} end
local function F_DEBUFF(id) return {spellID = id, unitID = "focus", caster = "player", filter = "DEBUFF"} end
local function F_DEBUFF_ALL(id) return {spellID = id, unitID = "focus", caster = "all", filter = "DEBUFF"} end
local function CD(id, s) return {spellID = id, size = s, filter = "CD"} end

C["filger_spells"] = {
	["DRUID"] = {
		{
			Name = "P_BUFF_ICON",
			Direction = "LEFT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", P_BUFF_ICON_Anchor},

			-- Lifebloom
			P_BUFF(33763),
			-- Rejuvenation
			P_BUFF(774),
			-- Regrowth
			P_BUFF(8936),
			-- Abolish Poison
			P_BUFF(2893),
			-- Savage roar
			P_BUFF(52610),
			-- Innervate
			P_BUFF_ALL(29166),
			-- Barkskin
			P_BUFF(22812),
			-- Bloodlust
			P_BUFF_ALL(2825),
			-- Heroism
			P_BUFF_ALL(32182),
			-- Survival Instincts
			P_BUFF(61336),
			-- Hyperspeed Accelerators
			P_BUFF(54999),
		},

		{
			Name = "T_DEBUFF_ICON",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", T_DEBUFF_ICON_Anchor},

			-- Moonfire
			T_DEBUFF(48463),
			-- Insect Swarm
			T_DEBUFF(48468),
			-- Faerie Fire
			T_DEBUFF_ALL(770),
			-- Entangling Roots
			T_DEBUFF_ALL(26989),
			-- Earth and Moon
			T_DEBUFF(48511),
			-- Rake
			T_DEBUFF(59886),
			-- Rip
			T_DEBUFF(49800),
			-- Lacerate
			T_DEBUFF(48568),
			-- Pounce Bleed
			T_DEBUFF(49804),
			-- Mangle (Cat)
			T_DEBUFF_ALL(48566),
			-- Mangle (Bear)
			T_DEBUFF_ALL(48564),
		},

		{
			Name = "P_PROC_ICON",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", P_PROC_ICON_Anchor},

			-- Eclipse (Lunar)
			P_BUFF(48518),
			-- Eclipse (Solar)
			P_BUFF(48517),
			-- Clearcasting
			P_BUFF(16870),
			-- Essence of Life
			P_BUFF(60062),
			-- Siphoned Power
			P_BUFF(71636),
			-- Hyperspeed Accelerators
			P_BUFF(54999),
			-- Cultivated Power
			P_BUFF(71572),
			-- Hardened Skin
			P_BUFF(71586),
		},

		{
			Name = "T_DE/BUFF_BAR",
			Direction = "UP",
			IconSide = "LEFT",
			Mode = "BAR",
			Interval = 3,
			Alpha = 1,
			IconSize = 25,
			BarWidth = 186,
			Position = {"LEFT", T_DE_BUFF_BAR_Anchor},

			-- Lifebloom
			{ spellID = 33763, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "BUFF" },
			-- Rejuvenation
			{ spellID = 774, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "BUFF" },
			-- Regrowth
			{ spellID = 8936, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "BUFF" },
			-- Wild Growth
			{ spellID = 48438, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "BUFF" },
			-- Demoralizing Roar
			{ spellID = 99, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
		},

		{
			Name = "PVE/PVP_CC",
			Direction = "DOWN",
			IconSide = "LEFT",
			Mode = "BAR",
			Interval = 3,
			Alpha = 1,
			IconSize = 25,
			BarWidth = 189,
			Position = {"LEFT", PVE_PVP_CC_Anchor},

			-- Entangling Roots
			{ spellID = 53308, size = 25, barWidth = 191, unitID = "focus", caster = "all", filter = "DEBUFF" },
			-- Cyclone
			{ spellID = 33786, size = 25, barWidth = 191, unitID = "focus", caster = "all", filter = "DEBUFF" },
			-- Hibernate
			{ spellID = 2637, size = 25, barWidth = 191, unitID = "focus", caster = "all", filter = "DEBUFF" },
		},

		{
			Name = "COOLDOWN",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.CooldownSize,
			Position = {"TOP", COOLDOWN_Anchor},

			-- Wild Growth
			CD(48438, 30),
			-- Swiftmend
			CD(18562, 30),
			-- Barkskin
			CD(22812, 30),
			-- Mangle(Bear)
			CD(33878, 30),
			-- Nature's Grasp
			CD(53312, 30),
			-- Starfall
			CD(53201, 30),
			-- Growl
			CD(61676, 30),
			-- Enrage
			CD(5229, 30),
			-- Faerie Fire(Feral)
			CD(16857, 30),
			-- Feral Charge - Bear
			CD(16979, 30),
			-- Feral Charge - Cat
			CD(49376, 30),
			-- Bash
			CD(8983, 30),
			-- Maim
			CD(49802, 30),
			-- Cower
			CD(48575, 30),
		},
	},
	["HUNTER"] = {
		{
			Name = "P_BUFF_ICON",
			Direction = "LEFT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", P_BUFF_ICON_Anchor},

			-- Innervate
			P_BUFF_ALL(29166),
			-- Bloodlust
			P_BUFF_ALL(2825),
			-- Heroism
			P_BUFF_ALL(32182),
			-- Hyperspeed Accelerators
			P_BUFF(54999),
		},

		{
			Name = "T_DEBUFF_ICON",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", T_DEBUFF_ICON_Anchor},

			-- Hunter's Mark
			T_DEBUFF_ALL(1130),
			-- Serpent Sting
			T_DEBUFF(49001),
			-- Scorpid Sting
			T_DEBUFF(3043),
			-- Black Arrow
			T_DEBUFF(63672),
			-- Explosive Shot
			T_DEBUFF(60053),
		},

		{
			Name = "P_PROC_ICON",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", P_PROC_ICON_Anchor},

			-- Lock and Load
			P_BUFF(56453),
			-- Fury of the Five Flights
			P_BUFF(60314),
			-- Greatness
			P_BUFF(60233),
			-- Mjolnir Runestone
			P_BUFF(65019),
			-- Quick Shots
			P_BUFF(6150),
			-- Master Tactician
			P_BUFF(34837),
			-- Master Tactician
			P_BUFF(53224),
			-- Expose Weakness
			P_BUFF(34503),
			-- Exploit Weakness 2t10 proc
			P_BUFF(70728),
			-- Stinger 4t10 proc
			P_BUFF(71007),
			-- Power of the Taunka
			P_BUFF(71486),
			-- Aim of the Iron Dwarves
			P_BUFF(71491),
			-- Agility of the Vrykul
			P_BUFF(71485),
			-- Icy Rage
			P_BUFF(71401),
			-- Rapid Fire
			P_BUFF(3045),
			-- Berserking
			P_BUFF(26297),
			-- Potion of Speed
			P_BUFF(53908),
			-- Potion of Wild Magic
			P_BUFF(53909),
			-- Blood Fury
			P_BUFF(20572),
			-- Call of the Wild
			P_BUFF(53434),
			-- Hyperspeed Acceleration
			P_BUFF(54758),
			-- Frostforged Champion
			P_BUFF(72412),
		},

		{
			Name = "PVE/PVP_CC",
			Direction = "DOWN",
			IconSide = "LEFT",
			Mode = "BAR",
			Interval = 3,
			Alpha = 1,
			IconSize = 25,
			BarWidth = 189,
			Position = {"LEFT", PVE_PVP_CC_Anchor},

			-- Wyvern Sting
			{ spellID = 49012, size = 25, barWidth = 191, unitID = "focus", caster = "player", filter = "DEBUFF" },
			-- Silencing Shot
			{ spellID = 34490, size = 25, barWidth = 191, unitID = "focus", caster = "player", filter = "DEBUFF" },
		},

		{
			Name = "COOLDOWN",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.CooldownSize,
			Position = {"TOP", COOLDOWN_Anchor},

			-- Explosive Shot
			CD(53301, 30),
			-- Aimed Shot
			CD(19434, 30),
			-- Kill Shot
			CD(61006, 30),
			-- Disengage
			CD(781, 30),
			-- Misdirection
			CD(34477, 30),
			-- Kill Command
			CD(34026, 30),
			-- Feign Death
			CD(28728, 30),
			-- Freezing Trap
			CD(14311, 30),
			-- Wyvern Sting
			CD(49012, 30),
			-- Scare Beast
			CD(14327, 30),
			-- Master's Call
			CD(53271, 30),
			-- Deterrence
			CD(19263, 30),
			-- Concussive Shot
			CD(5116, 30),
			-- Counterattack
			CD(48999, 30),
			-- Mongoose Bite
			CD(53339, 30),
			-- Intimidation
			CD(19577, 30),
			-- Rapid Fire
			CD(3045, 30),
			-- Blood Fury
			CD(20572, 30),
			-- Readiness
			CD(23989, 30),
		},
	},
	["MAGE"] = {
		{
			Name = "P_BUFF_ICON",
			Direction = "LEFT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", P_BUFF_ICON_Anchor},

			-- Cultivated Power (Muradin's Spyglass)
			P_BUFF(71572),
			-- Siphoned Power (Phylactery)
			P_BUFF(71636),
			-- Surging Power
			P_BUFF(71643),
			-- Innervate
			P_BUFF_ALL(29166),
			-- Bloodlust
			P_BUFF_ALL(2825),
			-- Heroism
			P_BUFF_ALL(32182),
			-- Hyperspeed Accelerators
			P_BUFF(54999),
		},

		{
			Name = "T_DEBUFF_ICON",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", T_DEBUFF_ICON_Anchor},

			-- Arcane Blast
			{ spellID = 36032, unitID = "player", caster = "player", filter = "DEBUFF" },
			-- Improved Scorch
			T_DEBUFF_ALL(22959),
			-- Slow
			T_DEBUFF(31589),
			-- Ignite
			T_DEBUFF(12848),
			-- Living Bomb
			T_DEBUFF(55360),
			-- Arcane Blast
			{ spellID = 36032, unitID = "player", caster = "player", filter = "DEBUFF" },
		},

		{
			Name = "P_PROC_ICON",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", P_PROC_ICON_Anchor},

			-- Frostbite
			T_DEBUFF_ALL(11071),
			-- Winter's Chill
			T_DEBUFF(28593),
			-- Fingers of Frost
			P_BUFF(44544),
			-- Fireball!
			P_BUFF(57761),
			-- Hot Streak
			P_BUFF(44448),
			-- Missile Barrage
			P_BUFF(54490),
			-- Clearcasting
			P_BUFF(12536),
			-- Impact
			P_BUFF(12358),
			-- Greatness
			P_BUFF(60234),
			-- Essence of Life
			P_BUFF(60062),
		},

		{
			Name = "PVE/PVP_CC",
			Direction = "DOWN",
			IconSide = "LEFT",
			Mode = "BAR",
			Interval = 3,
			Alpha = 1,
			IconSize = 25,
			BarWidth = 189,
			Position = {"LEFT", PVE_PVP_CC_Anchor},

			-- Polymorph
			{ spellID = 118, size = 25, barWidth = 191, unitID = "focus", caster = "player", filter = "DEBUFF" },
		},

		{
			Name = "COOLDOWN",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.CooldownSize,
			Position = {"TOP", COOLDOWN_Anchor},

			-- Blink
			CD(1953, 30),
			-- Frost Nova
			CD(11831, 30),
			-- Ice Barrier
			CD(11426, 30),
			-- Counterspell
			CD(2139, 30),
			-- Deep Freeze
			CD(44572, 30),
			-- Frost Ward
			CD(6143, 30),
			-- Presence of Mind
			CD(12043, 30),
			-- Arcane Power
			CD(12042, 30),
			-- Blast Wave
			CD(42945, 30),
			-- Dragon's Breath
			CD(42950, 30),
			-- Cone of Cold
			CD(42931, 30),
			-- Will of the forsaken (undead)
			CD(7744, 30),
			-- Cold Snap
			CD(11958, 30),
			-- Ice Block
			CD(45438, 30),
			-- Evocation
			CD(12051, 30),
			-- Icy Veins
			CD(12472, 30),
			-- Fire Blast
			CD(2136, 30),
			-- Mirror Image
			CD(55342, 30),
		},
	},
	["WARRIOR"] = {
		{
			Name = "P_BUFF_ICON",
			Direction = "LEFT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", P_BUFF_ICON_Anchor},

			-- Blood Reserve
			P_BUFF(64568),
			-- Last Stand
			P_BUFF(12975),
			-- Shield Wall
			P_BUFF(871),
			-- Bloodlust
			P_BUFF_ALL(2825),
			-- Heroism
			P_BUFF_ALL(32182),
			-- Hyperspeed Accelerators
			P_BUFF(54999),
		},

		{
			Name = "T_DEBUFF_ICON",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", T_DEBUFF_ICON_Anchor},

			-- Hamstring
			T_DEBUFF_ALL(1715),
			-- Rend
			T_DEBUFF(47465),
			-- Sunder Armor
			T_DEBUFF_ALL(7386),
			-- Expose Armor
			T_DEBUFF(48669),
			-- Thunder Clap
			T_DEBUFF(6343),
			-- Infected Wounds
			T_DEBUFF_ALL(48485),
			-- Frost Fever
			T_DEBUFF_ALL(55095),
			-- Demoralizing Shout
			T_DEBUFF(1160),
			-- Demoralizing Roar
			T_DEBUFF_ALL(48560),
			-- Curse of Weakness
			T_DEBUFF_ALL(50511),
		},

		{
			Name = "P_PROC_ICON",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", P_PROC_ICON_Anchor},

			-- Sudden Death
			P_BUFF(52437),
			-- Slam!
			P_BUFF_ALL(46916),
			-- Sword and Board
			P_BUFF(50227),
			-- Greatness
			P_BUFF(60229),
			-- Strength of the Taunka
			P_BUFF(71561),
			-- Speed of the Vrykul
			P_BUFF(71560),
			-- Aim of the Iron Dwarves
			P_BUFF(71559),
		},

		{
			Name = "COOLDOWN",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.CooldownSize,
			Position = {"TOP", COOLDOWN_Anchor},

			-- Intervene
			CD(3411, 30),
			-- Shield Slam
			CD(47488, 30),
			-- Whirlwind
			CD(1680, 30),
			-- Mortal Strike
			CD(47486, 30),
			-- Thunder Clap
			CD(47502, 30),
			-- Revenge
			CD(57823, 30),
			-- Overpower
			CD(7384, 30),
			-- Pummel
			CD(6552, 30),
			-- Shield Bash
			CD(72, 30),
			-- Charge
			CD(11578, 30),
			-- Intercept
			CD(20252, 30),
			-- Spell Reflection
			CD(23920, 30),
			-- Shield Block
			CD(2565, 30),
		},
	},
	["SHAMAN"] = {
		{
			Name = "P_BUFF_ICON",
			Direction = "LEFT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", P_BUFF_ICON_Anchor},

			-- Maelstorm Weapon
			P_BUFF(51532),
			-- Shamanistic rage
			P_BUFF(30823),
			-- Bloodlust
			P_BUFF_ALL(2825),
			-- Lightning Shield
			P_BUFF(49281),
			-- Water Shield
			P_BUFF(57960),
			-- Earth Shield
			P_BUFF(49284),
			-- Heroism
			P_BUFF_ALL(32182),
			-- Innervate
			P_BUFF_ALL(29166),
			-- Hyperspeed Accelerators
			P_BUFF(54999),
		},
		{
			Name = "T_DEBUFF_ICON",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", T_DEBUFF_ICON_Anchor},

			-- Storm Strike
			T_DEBUFF(17364),
			-- Earth Shock
			T_DEBUFF(49231),
			-- Frost Shock
			T_DEBUFF(49236),
			-- Flame Shock
			T_DEBUFF(49233),
		},

		{
			Name = "P_PROC_ICON",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", P_PROC_ICON_Anchor},

			-- Clearcasting
			P_BUFF(12536),
			-- Tidal Waves
			P_BUFF(51566),
			-- Essence of Life
			P_BUFF(60062),
		},

		{
			Name = "T_DE/BUFF_BAR",
			Direction = "UP",
			IconSide = "LEFT",
			Mode = "BAR",
			Interval = 3,
			Alpha = 1,
			IconSize = 25,
			BarWidth = 186,
			Position = {"LEFT", T_DE_BUFF_BAR_Anchor},

			-- Earth Shield
			{ spellID = 49284, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "BUFF" },
			-- Riptide
			{ spellID = 61301, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "BUFF" },
			-- Ancestral Fortitude
			{ spellID = 16237, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "BUFF" },
		},

		{
			Name = "PVE/PVP_CC",
			Direction = "DOWN",
			IconSide = "LEFT",
			Mode = "BAR",
			Interval = 3,
			Alpha = 1,
			IconSize = 25,
			BarWidth = 189,
			Position = {"LEFT", PVE_PVP_CC_Anchor},

			-- Hex
			{ spellID = 51514, size = 25, barWidth = 191, unitID = "focus", caster = "player", filter = "DEBUFF" },
		},

		{
			Name = "COOLDOWN",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.CooldownSize,
			Position = {"TOP", COOLDOWN_Anchor},

			-- Earth Shock
			CD(49231, 30),
			-- Riptide
			CD(61301, 30),
			-- Thunderstorm
			CD(59159, 30),
			-- Lava Burst
			CD(60043, 30),
			-- Lava Lash
			CD(60103, 30),
			-- Chain Lightning
			CD(49271, 30),
			-- Wind Shear
			CD(57994, 30),
		},
	},
	["PALADIN"] = {
		{
			Name = "P_BUFF_ICON",
			Direction = "LEFT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", P_BUFF_ICON_Anchor},

			-- Innervate
			P_BUFF_ALL(29166),
			-- Bloodlust
			P_BUFF_ALL(2825),
			-- Heroism
			P_BUFF_ALL(32182),
			-- Hyperspeed Accelerators
			P_BUFF(54999),
		},

		{
			Name = "T_DEBUFF_ICON",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", T_DEBUFF_ICON_Anchor},

			-- Hammer of Justice
			T_DEBUFF(10308),
			-- Judgement of Light
			T_DEBUFF(20271),
			-- Judgement of Justice
			T_DEBUFF(53407),
			-- Judgement of Wisdom
			T_DEBUFF(20186),
			-- Heart of the Crusader
			T_DEBUFF(54499),
			-- Blood Corruption
			T_DEBUFF(53742),
		},

		{
			Name = "P_PROC_ICON",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", P_PROC_ICON_Anchor},

			-- Judgements of the Pure
			P_BUFF(54155),
			-- Holy Shield
			P_BUFF(53601),
			-- Infusion of Light
			P_BUFF(54149),
			-- Divine Plea
			P_BUFF(54428),
			-- Essence of Life
			P_BUFF(60062),
			-- Beacon of Light
			P_BUFF(53563),
			-- Divine Illumination
			P_BUFF(31842),
		},

		{
			Name = "COOLDOWN",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.CooldownSize,
			Position = {"TOP", COOLDOWN_Anchor},

			-- Repentance
			CD(20066, 30),
			-- Hand of Reckoning
			CD(62124, 30),
			-- Hand of Freedom
			CD(1044, 30),
			-- Judgement of Light
			CD(20271, 30),
			-- Righteous Defense
			CD(31789, 30),
			-- Exorcism
			CD(48801, 30),
			-- Hammer of Justice
			CD(10308, 30),
			-- Consecration
			CD(48819, 30),
			-- Hammer of Wrath
			CD(48806, 30),
			-- Holy Shock
			CD(48825, 30),
			-- Holy Shield
			CD(48952, 30),
			-- Avenger's Shield
			CD(48827, 30),
			-- Divine Plea
			CD(54428, 30),
			-- Shield of Righteousness
			CD(61411, 30),
			-- Holy Wrath
			CD(48817, 30),
			-- Aura Mastery
			CD(31821, 30),
			-- Crusader Strike
			CD(35395, 30),
			-- Divine Favor
			CD(20216, 30),
			-- Divine Storm
			CD(53385, 30),
			-- Hammer of the Righteous
			CD(53595, 30),
		},
	},
	["PRIEST"] = {
		{
			Name = "P_BUFF_ICON",
			Direction = "LEFT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", P_BUFF_ICON_Anchor},

			-- Power Word: Shield
			P_BUFF(48066),
			-- Renew
			P_BUFF(25222),
			-- Fade
			P_BUFF(586),
			-- Fear Ward
			P_BUFF(6346),
			-- Hand of Protection
			P_BUFF_ALL(10278),
			-- Dispersion
			P_BUFF(47585),
			-- Inner Fire
			P_BUFF(48168),
			-- Innervate
			P_BUFF_ALL(29166),
			-- Bloodlust
			P_BUFF_ALL(2825),
			-- Heroism
			P_BUFF_ALL(32182),
			-- Borrowed Time
			P_BUFF(52800),
			-- Hyperspeed Accelerators
			P_BUFF(54999),
		},

		{
			Name = "P_PROC_ICON",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", P_PROC_ICON_Anchor},

			-- Surge of Light
			P_BUFF_ALL(33151),
			-- Serendipity
			P_BUFF(63734),
			-- Greatness
			P_BUFF(60234),
			-- Essence of Life
			P_BUFF(60062),
			-- Energized
			P_BUFF(67696),
			-- Eye of the Broodmother
			P_BUFF(65007),
			-- Frostforged Sage
			P_BUFF(72416),
			-- Shadow Weaving
			P_BUFF(15258),
			-- Improved Spirit Tap
			P_BUFF_ALL(59000),
		},

		{
			Name = "T_DE/BUFF_BAR",
			Direction = "UP",
			IconSide = "LEFT",
			Mode = "BAR",
			Interval = 3,
			Alpha = 1,
			IconSize = 25,
			BarWidth = 186,
			Position = {"LEFT", T_DE_BUFF_BAR_Anchor},

			-- Renew
			{ spellID = 139, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "BUFF" },
			-- Prayer of Mending
			{ spellID = 41637, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "BUFF" },
			-- Guardian spirit
			{ spellID = 47788, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "BUFF" },
			-- Pain suspension
			{ spellID = 33206, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "BUFF" },
			-- Shadow Word: Pain
			{ spellID = 589, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
			-- Devouring Plague
			{ spellID = 2944, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
			-- Vampiric Touch
			{ spellID = 34914, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
		},

		{
			Name = "PVE/PVP_CC",
			Direction = "DOWN",
			IconSide = "LEFT",
			Mode = "BAR",
			Interval = 3,
			Alpha = 1,
			IconSize = 25,
			BarWidth = 189,
			Position = {"LEFT", PVE_PVP_CC_Anchor},

			-- Shackle undead
			{ spellID = 10955, size = 25, barWidth = 191, unitID = "focus", caster = "player", filter = "DEBUFF" },
			-- Fear
			{ spellID = 10890, size = 25, barWidth = 191, unitID = "focus", caster = "player", filter = "DEBUFF" },
		},

		{
			Name = "COOLDOWN",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.CooldownSize,
			Position = {"TOP", COOLDOWN_Anchor},

			-- Penance
			CD(53007, 30),
			-- Pain Suppression
			CD(33206, 30),
			-- Power Infusion
			CD(10060, 30),
			-- Psychic Scream
			CD(10890, 30),
			-- Circle of Healing
			CD(48089, 30),
			-- Guardian Spirit
			CD(47788, 30),
			-- Prayer of Mending
			CD(48113, 30),
			-- Silence
			CD(15487, 30),
			-- Power Word: Shield
			CD(48066, 30),
			-- Holy Fire
			CD(48135, 30),
			-- Shadow Word: Death
			CD(48158, 30),
			-- Berserking
			CD(26297, 30),
			-- Hymn of Hope
			CD(64901, 30),
			-- Divine Hymn
			CD(64843, 30),
			-- Shadowfiend
			CD(34433, 30),
			-- Dispersion
			CD(47585, 30),
			-- Psychic Horror
			CD(64044, 30),
		},
	},
	["WARLOCK"] = {
		{
			Name = "P_BUFF_ICON",
			Direction = "LEFT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", P_BUFF_ICON_Anchor},

			-- Life Tap
			P_BUFF(63321),
			-- Bloodlust
			P_BUFF_ALL(2825),
			-- Heroism
			P_BUFF_ALL(32182),
			-- Phylactery of the Nameless Lich
			P_BUFF(71636),
			-- Surge of Power
			P_BUFF(71644),
			-- Devious Minds
			P_BUFF(70840),
			-- Hyperspeed Accelerators
			P_BUFF(54999),
		},

		{
			Name = "T_DEBUFF_ICON",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", T_DEBUFF_ICON_Anchor},

			-- Curse of the Elements
			T_DEBUFF_ALL(47865),
			-- Ebon Plaguebringer
			T_DEBUFF_ALL(51161),
			-- Earth and Moon
			T_DEBUFF_ALL(48511),
			-- Curse of Tongues
			T_DEBUFF_ALL(11719),
			-- Curse of Exhaustion
			T_DEBUFF_ALL(18223),
			-- Curse of Weakness
			T_DEBUFF_ALL(50511),
			-- Shadow Embrace
			T_BUFF(32385),
		},

		{
			Name = "P_PROC_ICON",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", P_PROC_ICON_Anchor},

			-- Essence of Life
			P_BUFF(60062),
			-- Molten Core
			P_BUFF(47383),
			-- Decimation
			P_BUFF(63158),
			-- Backdraft
			P_BUFF(54277),
			-- Backlash
			P_BUFF(34939),
			-- Nether Protection
			P_BUFF(30302),
			-- Greatness
			P_BUFF(60235),
			-- Greatness
			P_BUFF(60234),
			-- Nightfall
			P_BUFF(18095),

		},

		{
			Name = "T_DE/BUFF_BAR",
			Direction = "UP",
			IconSide = "LEFT",
			Mode = "BAR",
			Interval = 3,
			Alpha = 1,
			IconSize = 25,
			BarWidth = 186,
			Position = {"LEFT", T_DE_BUFF_BAR_Anchor},

			-- Corruption
			{ spellID = 172, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
			-- Immolate
			{ spellID = 348, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
			-- Curse of Agony
			{ spellID = 980, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
			-- Curse of Doom
			{ spellID = 47867, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
			-- Unstable Affliction
			{ spellID = 47843, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
			-- Haunt
			{ spellID = 59164, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
			-- Seed of Corruption
			{ spellID = 27243, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
			-- Curse of Weakness
			{ spellID = 702, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
			-- Curse of Tongues
			{ spellID = 1714, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
			-- Curse of Exhaustion
			{ spellID = 18223, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
			-- Fear
			{ spellID = 6215, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
			-- Howl of Terror
			{ spellID = 5484, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
			-- Death Coil
			{ spellID = 6789, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
			-- Banish
			{ spellID = 710, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
			-- Enslave Demon
			{ spellID = 1098, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
			-- Demon Charge
			{ spellID = 54785, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
		},

		{
			Name = "PVE/PVP_CC",
			Direction = "DOWN",
			IconSide = "LEFT",
			Mode = "BAR",
			Interval = 3,
			Alpha = 1,
			IconSize = 25,
			BarWidth = 189,
			Position = {"LEFT", PVE_PVP_CC_Anchor},

			-- Fear
			{ spellID = 5782, size = 25, barWidth = 191, unitID = "focus", caster = "player", filter = "DEBUFF" },
			-- Banish
			{ spellID = 710, size = 25, barWidth = 191, unitID = "focus", caster = "player", filter = "DEBUFF" },
		},

		{
			Name = "COOLDOWN",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.CooldownSize,
			Position = {"TOP", COOLDOWN_Anchor},

			-- Cannibalize
			CD(20577, 30),
			-- Will of the Forsaken
			CD(7744, 30),
			-- Conflagrate
			CD(17962, 30),
			-- Challenging Howl
			CD(59671, 30),
			-- Ritual of Summoning
			CD(698, 30),
			-- Shadow Ward
			CD(47891, 30),
			-- Inferno
			CD(1122, 30),
			-- Demonic Empowerment
			CD(47193, 30),
			-- Demon Charge
			CD(54785, 30),
			-- Ritual of Doom
			CD(18540, 30),
			-- Shadow Cleave
			CD(50581, 30),
			-- Soulshatter
			CD(29858, 30),
			-- Ritual of Souls
			CD(58887, 30),
			-- Demonic Circle: Teleport
			CD(48020, 30),
			-- Howl of Terror
			CD(17928, 30),
			-- Death Coil
			CD(47860, 30),
			-- Haunt
			CD(59164, 30),
			-- Curse of Doom
			CD(47867, 30),
			-- Shadowburn
			CD(47827, 30),
			-- Shadowfury
			CD(47847, 30),
			-- Chaos Bolt
			CD(59172, 30),
			-- Shadowflame
			CD(61290, 30),
			-- Fel Domination
			CD(18708, 30),
			-- Phase Shift (Imp)
			CD(4511, 30),
			-- Sacrifice (Voidwalker)
			CD(47986, 30),
			-- Suffering (Voidwalker)
			CD(47990, 30),
			-- Spell Lock (Felhunter)
			CD(19647, 30),
			-- Devour Magic (Felhunter)
			CD(48011, 30),
			-- Intercept (Felguard)
			CD(47996, 30),
		},
	},
	["ROGUE"] = {
		{
			Name = "P_BUFF_ICON",
			Direction = "LEFT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", P_BUFF_ICON_Anchor},

			-- Slice and Dice
			P_BUFF(5171),
			-- Blade Flurry
			P_BUFF(13877),
			-- Adrenaline Rush
			P_BUFF(13750),
			-- Tricks of the Trade
			P_BUFF(57934),
			-- Cloak of Shadows
			P_BUFF(31224),
			-- Sprint
			P_BUFF(2983),
			-- Evasion
			P_BUFF(5277),
			-- Envenom
			P_BUFF(32645),
			-- Overkill
			P_BUFF(58426),
			-- Turn the Tables
			P_BUFF(51627),
			-- Hunger For Blood
			P_BUFF(51662),
			-- Bloodlust
			P_BUFF_ALL(2825),
			-- Heroism
			P_BUFF_ALL(32182),
			-- Hyperspeed Accelerators
			P_BUFF(54999),
		},

		{
			Name = "T_DEBUFF_ICON",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", T_DEBUFF_ICON_Anchor},

			-- Rupture
			T_DEBUFF(48672),
			-- Garrote
			T_DEBUFF(48676),
			-- Kidney shot
			T_DEBUFF(408),
			-- Gouge
			T_DEBUFF(1776),
			-- Cheap shot
			T_DEBUFF(1833),
			-- Blind
			T_DEBUFF(2094),
			-- Sap
			T_DEBUFF(6770),
			-- Expose Armor
			T_DEBUFF(8647),
			-- Dismantle
			T_DEBUFF(51722),
			-- Deadly Poison
			T_DEBUFF(57973),
			-- Wound Poison
			T_DEBUFF(57978),
			-- Crippling Poison
			T_DEBUFF(3408),
			-- Mind-numbing Poison
			T_DEBUFF(5761),
		},

		{
			Name = "PVE/PVP_CC",
			Direction = "DOWN",
			IconSide = "LEFT",
			Mode = "BAR",
			Interval = 3,
			Alpha = 1,
			IconSize = 25,
			BarWidth = 189,
			Position = {"LEFT", PVE_PVP_CC_Anchor},

			-- Blind
			{ spellID = 2094, size = 25, barWidth = 191, unitID = "focus", caster = "player", filter = "DEBUFF" },
		},

		{
			Name = "COOLDOWN",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.CooldownSize,
			Position = {"TOP", COOLDOWN_Anchor},

			-- Kick
			CD(1766, 30),
			-- Gouge
			CD(1776, 30),
			-- Kidney shot
			CD(8643, 30),
			-- Killing Spree
			CD(51690, 30),
			-- Adrenaline Rush
			CD(13750, 30),
			-- Stealth
			CD(1784, 30),
			-- Vanish
			CD(1856, 30),
			-- Blade Flurry
			CD(13877, 30),
		},
	},
	["DEATHKNIGHT"] = {
		{
			Name = "P_BUFF_ICON",
			Direction = "LEFT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", P_BUFF_ICON_Anchor},

			-- Bloodlust
			P_BUFF_ALL(2825),
			-- Heroism
			P_BUFF_ALL(32182),
			-- Hyperspeed Accelerators
			P_BUFF(54999),
		},

		{
			Name = "T_DE/BUFF_BAR",
			Direction = "UP",
			IconSide = "LEFT",
			Mode = "BAR",
			Interval = 3,
			Alpha = 1,
			IconSize = 25,
			BarWidth = 186,
			Position = {"LEFT", T_DE_BUFF_BAR_Anchor},

			-- Blood Plague
			{ spellID = 59879, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
			-- Frost Fever
			{ spellID = 59921, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
			-- Unholy Blight
			{ spellID = 49194, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
			-- Summon Gargoyle
			{ spellID = 49206, size = 25, barWidth = 187, unitID = "target", caster = "player", filter = "DEBUFF" },
		},

		{
			Name = "P_PROC_ICON",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.BuffsSize,
			Position = {"TOP", P_PROC_ICON_Anchor},

			-- Greatness
			P_BUFF(60229),
			-- Unholy Force
			P_BUFF(67383),
			-- Desolation
			P_BUFF(66817),
			-- Unholy Strength
			P_BUFF(53365),
			-- Pyrite Infusion
			P_BUFF(65014),
			-- Unholy Might
			P_BUFF(67117),
			-- Dancing Rune Weapon
			P_BUFF(49028),
			-- Killing machine
			P_BUFF(51124),
			-- Freezing fog
			P_BUFF(59052),
		},

		{
			Name = "COOLDOWN",
			Direction = "RIGHT",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.CooldownSize,
			Position = {"TOP", COOLDOWN_Anchor},

			-- Summon Gargoyle
			CD(49206, 30),
			-- Gnaw
			CD(47481, 30),
			-- Strangulate
			CD(47476, 30),
			-- Mind Freeze
			CD(47528, 30),
		},
	},
	["ALL"] = {
		{
			Name = "PVE/PVP_DEBUFF",
			Direction = "UP",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.PvPSize,
			Position = {"TOP", PVE_PVP_DEBUFF_Anchor},

			-- Death Knight
			-- Gnaw (Ghoul)
			{ spellID = 47481, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Strangulate
			{ spellID = 47476, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Chains of Ice
			{ spellID = 45524, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Desecration (no duration, lasts as long as you stand in it)
			{ spellID = 55741, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Glyph of Heart Strike
			{ spellID = 58617, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Icy Clutch (Chilblains)
			{ spellID = 50436, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Hungering Cold
			{ spellID = 51209, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },

			-- Druid
			-- Cyclone
			{ spellID = 33786, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Hibernate
			{ spellID = 2637, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Bash
			{ spellID = 5211, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Maim
			{ spellID = 22570, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Pounce
			{ spellID = 9005, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Entangling Roots
			{ spellID = 339, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Feral Charge Effect
			{ spellID = 45334, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Infected Wounds
			{ spellID = 58179, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },

			-- Hunter
			-- Freezing Trap Effect
			{ spellID = 3355, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Freezing Arrow Effect
			{ spellID = 60210, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Scare Beast
			{ spellID = 1513, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Scatter Shot
			{ spellID = 19503, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Chimera Shot - Scorpid
			{ spellID = 53359, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Snatch (Bird of Prey)
			{ spellID = 50541, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Silencing Shot
			{ spellID = 34490, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Intimidation
			{ spellID = 24394, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Sonic Blast (Bat)
			{ spellID = 50519, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Ravage (Ravager)
			{ spellID = 50518, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Concussive Barrage
			{ spellID = 35101, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Concussive Shot
			{ spellID = 5116, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Frost Trap Aura
			{ spellID = 13810, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Glyph of Freezing Trap
			{ spellID = 61394, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Wing Clip
			{ spellID = 2974, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Counterattack
			{ spellID = 19306, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Entrapment
			{ spellID = 19185, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Pin (Crab)
			{ spellID = 50245, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Venom Web Spray (Silithid)
			{ spellID = 54706, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Web (Spider)
			{ spellID = 4167, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Froststorm Breath (Chimera)
			{ spellID = 51209, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Tendon Rip (Hyena)
			{ spellID = 51209, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },

			-- Mage
			-- Dragon's Breath
			{ spellID = 31661, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Polymorph
			{ spellID = 118, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Silenced - Improved Counterspell
			{ spellID = 18469, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Deep Freeze
			{ spellID = 44572, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Freeze (Water Elemental)
			{ spellID = 33395, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Frost Nova
			{ spellID = 122, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Shattered Barrier
			{ spellID = 55080, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Chilled
			{ spellID = 6136, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Cone of Cold
			{ spellID = 120, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Slow
			{ spellID = 31589, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },

			-- Paladin
			-- Repentance
			{ spellID = 20066, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Turn Evil
			{ spellID = 10326, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Shield of the Templar
			{ spellID = 63529, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Hammer of Justice
			{ spellID = 853, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Holy Wrath
			{ spellID = 2812, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Stun (Seal of Justice proc)
			{ spellID = 20170, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Avenger's Shield
			{ spellID = 31935, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },

			-- Priest
			-- Psychic Horror
			{ spellID = 64058, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Mind Control
			{ spellID = 605, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Psychic Horror
			{ spellID = 64044, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Psychic Scream
			{ spellID = 8122, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Silence
			{ spellID = 15487, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Mind Flay
			{ spellID = 15407, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },

			-- Rogue
			-- Dismantle
			{ spellID = 51722, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Blind
			{ spellID = 2094, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Gouge
			{ spellID = 1776, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Sap
			{ spellID = 6770, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Garrote - Silence
			{ spellID = 1330, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Silenced - Improved Kick
			{ spellID = 18425, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Cheap Shot
			{ spellID = 1833, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Kidney Shot
			{ spellID = 408, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Blade Twisting
			{ spellID = 31125, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Crippling Poison
			{ spellID = 3409, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Deadly Throw
			{ spellID = 26679, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },

			-- Shaman
			-- Hex
			{ spellID = 51514, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Earthgrab
			{ spellID = 64695, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Freeze
			{ spellID = 63685, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Stoneclaw Stun
			{ spellID = 39796, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Earthbind
			{ spellID = 3600, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Frost Shock
			{ spellID = 8056, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },

			-- Warlock
			-- Banish
			{ spellID = 710, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Death Coil
			{ spellID = 6789, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Fear
			{ spellID = 5782, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Howl of Terror
			{ spellID = 5484, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Seduction (Succubus)
			{ spellID = 6358, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Spell Lock (Felhunter)
			{ spellID = 24259, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Shadowfury
			{ spellID = 30283, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Intercept (Felguard)
			{ spellID = 30153, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Aftermath
			{ spellID = 18118, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Curse of Exhaustion
			{ spellID = 18223, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },

			-- Warrior
			-- Intimidating Shout
			{ spellID = 20511, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Disarm
			{ spellID = 676, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Silenced (Gag Order)
			{ spellID = 18498, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Charge Stun
			{ spellID = 7922, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Concussion Blow
			{ spellID = 12809, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Intercept
			{ spellID = 20253, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Revenge Stun
			{ spellID = 12798, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Shockwave
			{ spellID = 46968, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Glyph of Hamstring
			{ spellID = 58373, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Improved Hamstring
			{ spellID = 23694, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Hamstring
			{ spellID = 1715, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Piercing Howl
			{ spellID = 12323, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },

			-- Racials
			-- War Stomp
			{ spellID = 20549, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },

			-- Mark of the Fallen Champion
			{ spellID = 72293, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Inoculated (Festergut)
			{ spellID = 72103, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Mutated Infection (Rotface)
			{ spellID = 71224, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Unbound Plague (Professor Putricide)
			{ spellID = 72856, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Gas Variable (Professor Putricide)
			{ spellID = 70353, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Ooze Variable (Professor Putricide)
			{ spellID = 70352, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Pact of the Darkfallen (Bloodqueen Lana'thel)
			{ spellID = 71340, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Swarming Shadows (Bloodqueen Lana'thel)
			{ spellID = 71861, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Essence of the Blood Queen (Bloodqueen Lana'thel)
			{ spellID = 71473, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Frost Bomb (Sindragosa)
			{ spellID = 71053, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Instability (Sindragosa)
			{ spellID = 69766, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Unchained Magic (Sindragosa)
			{ spellID = 69762, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Mystic Buffet (Sindragosa)
			{ spellID = 70128, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
			-- Necrotic Plague (Arthas - The Lich King)
			{ spellID = 73912, size = 51, unitID = "player", caster = "all", filter = "DEBUFF" },
		},
		{
			Name = "T_BUFF",
			Direction = "UP",
			Mode = "ICON",
			Interval = 3,
			Alpha = 1,
			IconSize = C.Filger.PvPSize,
			Position = {"TOP", T_BUFF_Anchor},

			-- Aspect of the Viper
			{ spellID = 34074, size = 51, unitID = "player", caster = "player", filter = "BUFF" },
			-- Aspect of the Pack
			{ spellID = 13159, size = 51, unitID = "player", caster = "player", filter = "BUFF" },
			-- Innervate
			{ spellID = 29166, size = 51, unitID = "target", caster = "all", filter = "BUFF"},
			-- Spell Reflection
			{ spellID = 23920, size = 51, unitID = "target", caster = "all", filter = "BUFF" },
			-- Aura Mastery
			{ spellID = 31821, size = 51, unitID = "target", caster = "all", filter = "BUFF" },
			-- Ice Block
			{ spellID = 45438, size = 51, unitID = "target", caster = "all", filter = "BUFF" },
			-- Cloak of Shadows
			{ spellID = 31224, size = 51, unitID = "target", caster = "all", filter = "BUFF" },
			-- Divine Shield
			{ spellID = 642, size = 51, unitID = "target", caster = "all", filter = "BUFF" },
			-- Deterrence
			{ spellID = 19263, size = 51, unitID = "target", caster = "all", filter = "BUFF" },
			-- Anti-Magic Shell
			{ spellID = 48707, size = 51, unitID = "target", caster = "all", filter = "BUFF" },
			-- Lichborne
			{ spellID = 49039, size = 51, unitID = "target", caster = "all", filter = "BUFF" },
			-- Hand of Freedom
			{ spellID = 1044, size = 51, unitID = "target", caster = "all", filter = "BUFF" },
			-- Hand of Sacrifice
			{ spellID = 6940, size = 51, unitID = "target", caster = "all", filter = "BUFF" },
			-- Grounding Totem Effect
			{ spellID = 8178, size = 51, unitID = "target", caster = "all", filter = "BUFF" },
		},
	},
}