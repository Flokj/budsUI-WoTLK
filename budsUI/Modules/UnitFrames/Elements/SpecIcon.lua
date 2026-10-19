--[[-----------------------------------------------------------------------------
Addon: budsUI
File: Modules/UnitFrames/Elements/SpecIcon.lua
Purpose:
	Spec icon in the top-right corner of the health bar (player, target and
	focus). Own spec is read from the talent tabs locally; other players come
	through the inspect pipeline (K.Inspect, shared with the tooltip spec
	line), GUID-keyed. Icons are the talent-tree textures per class/spec
	(SPEC_ICONS, ported from FrostAtomUI's UIKit).
-----------------------------------------------------------------------------]]

local Engine = select(2, ...)
local K, C = Engine:unpack()
local Module = Engine.UnitFrames

local GetTalentTabInfo = GetTalentTabInfo
local GetActiveTalentGroup = GetActiveTalentGroup
local UnitGUID = UnitGUID
local UnitClass = UnitClass
local UnitIsPlayer = UnitIsPlayer
local UnitIsUnit = UnitIsUnit
local CreateFrame = CreateFrame

local SPEC_ICONS = {
	DEATHKNIGHT = {
		"Interface\\Icons\\Spell_Deathknight_BloodPresence",
		"Interface\\Icons\\Spell_Deathknight_FrostPresence",
		"Interface\\Icons\\Spell_Deathknight_UnholyPresence",
	},
	DRUID = {
		"Interface\\Icons\\Spell_Nature_StarFall",
		"Interface\\Icons\\Ability_Racial_BearForm",
		"Interface\\Icons\\Spell_Nature_HealingTouch",
	},
	HUNTER = {
		"Interface\\Icons\\Ability_Hunter_BeastTaming",
		"Interface\\Icons\\Ability_Marksmanship",
		"Interface\\Icons\\Ability_Hunter_SwiftStrike",
	},
	MAGE = {
		"Interface\\Icons\\Spell_Holy_MagicalSentry",
		"Interface\\Icons\\Spell_Fire_FlameBolt",
		"Interface\\Icons\\Spell_Frost_FrostBolt02",
	},
	PALADIN = {
		"Interface\\Icons\\Spell_Holy_HolyBolt",
		"Interface\\Icons\\Spell_Holy_DevotionAura",
		"Interface\\Icons\\Spell_Holy_AuraOfLight",
	},
	PRIEST = {
		"Interface\\Icons\\Spell_Holy_WordFortitude",
		"Interface\\Icons\\Spell_Holy_GuardianSpirit",
		"Interface\\Icons\\Spell_Shadow_ShadowWordPain",
	},
	ROGUE = {
		"Interface\\Icons\\Ability_Rogue_Eviscerate",
		"Interface\\Icons\\Ability_BackStab",
		"Interface\\Icons\\Ability_Stealth",
	},
	SHAMAN = {
		"Interface\\Icons\\Spell_Nature_Lightning",
		"Interface\\Icons\\Spell_Nature_LightningShield",
		"Interface\\Icons\\Spell_Nature_MagicImmunity",
	},
	WARLOCK = {
		"Interface\\Icons\\Spell_Shadow_DeathCoil",
		"Interface\\Icons\\Spell_Shadow_Metamorphosis",
		"Interface\\Icons\\Spell_Shadow_RainOfFire",
	},
	WARRIOR = {
		"Interface\\Icons\\Ability_Warrior_SavageBlow",
		"Interface\\Icons\\Ability_Warrior_InnerRage",
		"Interface\\Icons\\Ability_Warrior_DefensiveStance",
	},
}

local TRIM = 0.08

-- guid -> dominant talent tree (spec index), filled by inspect replies
local specs = {}
-- frames carrying the element
local frames = {}

-- Dominant tree by talent points. inspect=true reads the last inspected
-- unit (valid only inside the talent callback window).
local function dominantTree(inspect)
	local group = GetActiveTalentGroup(inspect)
	local best, bestPoints = 1, -1
	for tab = 1, 3 do
		local _, _, points = GetTalentTabInfo(tab, inspect, nil, group)
		if not points then return end
		if points > bestPoints then
			best, bestPoints = tab, points
		end
	end
	if bestPoints <= 0 then return end
	return best
end

-- ---------------------------------------------------------------------------
-- Aura-guesser (ported from FrostAtomUI's Talents module): infers specs of
-- hostile players from their visible buffs. The inspect queue only sends
-- out of combat, so in PvP this is the only in-combat source. Scans just
-- target/focus/arena1-5, every unique hint is processed once per GUID.
-- ---------------------------------------------------------------------------

local NUM_TREES = 3
local POINTS_PER_TIER = 5
local MAX_TALENT_POINTS = 71
local DEPTH_ODDS = { 1.2, 1.5, 2, 3, 5, 10, 40, 200, 1000 }
local SPEC_MIN_DEPTH = 31
local SPEC_MIN_SHARE = 0.8
local MAX_AURAS = 40

local max, min, floor = math.max, math.min, math.floor
local wipe = wipe
local UnitCanAttack = UnitCanAttack
local UnitBuff = UnitBuff
local GetPlayerInfoByGUID = GetPlayerInfoByGUID

local specHints = K.SpecHints
local guessed = {}
local guidClass = {}

local HOSTILE_SCAN_UNITS = {
	arena1 = true, arena2 = true, arena3 = true, arena4 = true, arena5 = true,
	target = true, focus = true,
}

local function classOf(guid)
	local class = guidClass[guid]
	if class == nil then
		local _, playerClass = GetPlayerInfoByGUID(guid)
		class = playerClass or false
		guidClass[guid] = class
	end
	return class
end

local function newGuess()
	return {
		main = { 1 / NUM_TREES, 1 / NUM_TREES, 1 / NUM_TREES },
		proven = { 0, 0, 0 },
		cap = { MAX_TALENT_POINTS, MAX_TALENT_POINTS, MAX_TALENT_POINTS },
		seen = {},
	}
end

local function weigh(guess)
	local proven, cap, main = guess.proven, guess.cap, guess.main
	local total = proven[1] + proven[2] + proven[3]
	for tree = 1, NUM_TREES do
		cap[tree] = max(MAX_TALENT_POINTS - (total - proven[tree]), proven[tree])
	end
	local sum = 0
	for tree = 1, NUM_TREES do
		local depth = proven[tree]
		if proven[tree % 3 + 1] > cap[tree] or proven[(tree + 1) % 3 + 1] > cap[tree] then
			main[tree] = 0
		elseif depth > 0 then
			main[tree] = DEPTH_ODDS[min(floor((depth - 1) / POINTS_PER_TIER) + 1, #DEPTH_ODDS)]
		else
			main[tree] = 1
		end
		sum = sum + main[tree]
	end
	for tree = 1, NUM_TREES do
		main[tree] = sum > 0 and main[tree] / sum or 1 / NUM_TREES
	end
end

-- Confident guess only: dominant tree proven >= 31 points deep, or an
-- overwhelming share. Hybrid/leveled enemies stay blank rather than wrong.
local function guessSpec(guid)
	local guess = guessed[guid]
	if not guess then return end
	local main = guess.main
	local bestTree = 1
	for tree = 2, NUM_TREES do
		if main[tree] > main[bestTree] then bestTree = tree end
	end
	if guess.proven[bestTree] >= SPEC_MIN_DEPTH or main[bestTree] >= SPEC_MIN_SHARE then
		return bestTree
	end
end

-- Repaints whichever frame shows the given GUID; forward-declared here
-- because observe() runs before updateFrame is defined, assigned below.
local repaintGuid

local function observe(guid, hint)
	if classOf(guid) ~= hint.class then return end
	local guess = guessed[guid]
	if not guess then
		guess = newGuess()
		guessed[guid] = guess
	end
	if guess.seen[hint] then return end
	guess.seen[hint] = true
	local tree = hint.tree
	guess.proven[tree] = max(guess.proven[tree], hint.points + 1)
	weigh(guess)
	repaintGuid(guid)
end

local function scanAuras(unit)
	if not UnitGUID(unit) or not UnitIsPlayer(unit) or not UnitCanAttack("player", unit) then
		return
	end
	for i = 1, MAX_AURAS do
		local name, _, _, _, _, _, _, caster, _, _, spellId = UnitBuff(unit, i)
		if not name then return end
		local hint = specHints and specHints[spellId]
		if hint and caster and UnitIsPlayer(caster) then
			local guid = UnitGUID(caster)
			if guid then
				observe(guid, hint)
			end
		end
	end
end

local function updateFrame(frame)
	local icon = frame.SpecIcon
	if not icon then return end
	if C.Unitframe.SpecIcon ~= true then
		icon:Hide()
		return
	end

	local unit = frame.unit
	if not unit or not UnitIsPlayer(unit) then
		icon:Hide()
		return
	end

	local spec
	if UnitIsUnit(unit, "player") then
		spec = dominantTree(false)
	else
		local guid = UnitGUID(unit)
		if not guid then
			icon:Hide()
			return
		end
		-- Exact spec from the inspect queue first, confident aura guess
		-- second (the only source while in combat: the inspect queue only
		-- sends out of combat).
		spec = specs[guid] or guessSpec(guid)
		if not spec then
			-- Not cached yet: queue an inspect. The reply fills specs[] and
			-- refreshes this frame; the manager throttles sends (1.5s
			-- interval, urgent lane) and only fires out of combat / in range.
			if K.Inspect and K.Inspect.Request then
				K.Inspect:Request(unit, nil, true)
			end
			icon:Hide()
			return
		end
	end

	local _, class = UnitClass(unit)
	local path = spec and class and SPEC_ICONS[class] and SPEC_ICONS[class][spec]
	if not path then
		icon:Hide()
		return
	end
	icon:SetTexture(path)
	icon:Show()
end

local function updateAll()
	for i = 1, #frames do
		updateFrame(frames[i])
	end
end

repaintGuid = function(guid)
	for i = 1, #frames do
		local frame = frames[i]
		if frame.unit and UnitGUID(frame.unit) == guid then
			updateFrame(frame)
		end
	end
end

-- Inspect replies: read the inspected tabs while the data window is open,
-- store the spec by GUID (cross-realm BGs reuse names, GUIDs do not), then
-- repaint whichever frame shows that unit.
if K.Inspect and K.Inspect.RegisterTalentCallback then
	K.Inspect:RegisterTalentCallback(function(guid)
		local spec = dominantTree(true)
		if not spec or not guid then return end
		specs[guid] = spec
		repaintGuid(guid)
	end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("PLAYER_FOCUS_CHANGED")
events:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
events:RegisterEvent("CHARACTER_POINTS_CHANGED")
events:RegisterEvent("UNIT_AURA")
events:RegisterEvent("ARENA_OPPONENT_UPDATE")
events:SetScript("OnEvent", function(_, event, unit)
	if event == "UNIT_AURA" then
		-- Only the watched hostile units: target/focus/arena1-5.
		if HOSTILE_SCAN_UNITS[unit] then
			scanAuras(unit)
		end
	elseif event == "ARENA_OPPONENT_UPDATE" then
		scanAuras(unit)
	elseif event == "PLAYER_TARGET_CHANGED" then
		scanAuras("target")
		updateAll()
	elseif event == "PLAYER_FOCUS_CHANGED" then
		scanAuras("focus")
		updateAll()
	elseif event == "PLAYER_ENTERING_WORLD" then
		-- Zone change invalidates aura guesses (donor wipes on PEW).
		wipe(guessed)
		updateAll()
	else
		updateAll()
	end
end)

function Module.Build.SpecIcon(self)
	if C.Unitframe.SpecIcon ~= true then
		return
	end

	local size = C.Unitframe.SpecIconSize or 18
	local icon = self.Health:CreateTexture(nil, "OVERLAY")
	icon:SetDrawLayer("OVERLAY", 7)
	icon:SetSize(size, size)
	icon:SetPoint("TOPRIGHT", self.Health, "TOPRIGHT", -3, -3)
	icon:SetTexCoord(TRIM, 1 - TRIM, TRIM, 1 - TRIM)
	icon:Hide()

	self.SpecIcon = icon
	frames[#frames + 1] = self

	-- Style runs at spawn; the event driver repaints once units exist.
	updateFrame(self)
	return icon
end
