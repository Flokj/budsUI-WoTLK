--[[-----------------------------------------------------------------------------
Addon: budsUI
File: Modules/UnitFrames/Tags.lua
Purpose:
	Custom oUF text tags. Bar values are not here on purpose: those are driven
	straight into SetFormattedText from the bar's PostUpdate (see
	Elements/Texts.lua).

	Ported from KkthnxUI retail: all Midnight secret-value handling is gone
	(3.3.5 has no secret values), UnitInPartyIsAI does not exist, and name
	trimming uses budsUI's UTF-8 safe K.ShortenString.
-----------------------------------------------------------------------------]]

local Engine = select(2, ...)
local K, C = Engine:unpack()
local oUF = Engine.oUF or _G.budsUF

if not oUF then return end

local UnitName = UnitName
local UnitLevel = UnitLevel
local UnitClass = UnitClass
local UnitClassification = UnitClassification
local UnitIsAFK = UnitIsAFK
local UnitIsConnected = UnitIsConnected
local UnitIsDND = UnitIsDND
local UnitIsPlayer = UnitIsPlayer
local UnitReaction = UnitReaction
local GetQuestGreenRange = GetQuestGreenRange

-- Difficulty colour that also works on friendlies. oUF's own [difficulty]
-- only colours attackable units, which left your own pet's level white.
-- (GetCreatureDifficultyColor does not exist on this client, so the
-- thresholds are computed from the player's level directly.)
oUF.Tags.Methods["buds:diff"] = function(unit)
	local level = UnitLevel(unit)
	if not level or level <= 0 then
		return "|cffff0000"
	end
	local plvl = UnitLevel("player") or level
	local diff = level - plvl
	local greenRange = (GetQuestGreenRange and GetQuestGreenRange()) or 5
	local r, g, b
	if diff >= 5 then
		r, g, b = 1, 0.1, 0.1
	elseif diff >= 3 then
		r, g, b = 1, 0.5, 0
	elseif diff >= -2 then
		r, g, b = 1, 0.9, 0
	elseif -diff <= greenRange then
		r, g, b = 0.25, 0.75, 0.25
	else
		r, g, b = 0.5, 0.5, 0.5
	end
	return K.RGBToHex(r, g, b)
end
oUF.Tags.Events["buds:diff"] = "UNIT_LEVEL PLAYER_LEVEL_UP"

-- ---------------------------------------------------------------------------
-- Name
-- ---------------------------------------------------------------------------

-- Colour prefix for a name. oUF ships [raidcolor], but that only knows about
-- players, so every NPC comes out white. This covers reactions as well, and
-- greys out anyone who has dropped connection.
oUF.Tags.Methods["buds:namecolor"] = function(unit)
	if not C.Unitframe.NameColor then
		return ""
	end

	-- When the health bar already carries the class/reaction colour, keep the
	-- name white so the two do not double up.
	if C.Unitframe.ClassHealth then
		return ""
	end

	if not UnitIsConnected(unit) then
		return "|cff909090"
	end

	local color
	if UnitIsPlayer(unit) then
		local _, class = UnitClass(unit)
		if class then
			color = oUF.colors.class[class]
		end
	else
		local reaction = UnitReaction(unit, "player")
		if reaction then
			color = oUF.colors.reaction[reaction]
		end
	end

	return color and color:GenerateHexColorMarkup() or ""
end
oUF.Tags.Events["buds:namecolor"] = "UNIT_NAME_UPDATE UNIT_FACTION UNIT_CONNECTION"

-- Trim long names to a character count (UTF-8 safe). Every name font string is
-- also width bounded, so the client already ellipsizes on its own; this is the
-- extra cap for players who want short names on wide frames.
oUF.Tags.Methods["buds:name"] = function(unit)
	local name = UnitName(unit)
	if not name then
		return ""
	end

	local limit = C.Unitframe.NameLength or 0
	if limit > 0 then
		return K.ShortenString(name, limit, "...")
	end
	return name
end
oUF.Tags.Events["buds:name"] = "UNIT_NAME_UPDATE"

-- Short name for the narrow raid frames: the first few characters, no ellipsis,
-- so a whole group reads cleanly at a glance.
oUF.Tags.Methods["buds:nameshort"] = function(unit)
	local name = UnitName(unit)
	if not name then
		return ""
	end
	return K.ShortenString(name, 5)
end
oUF.Tags.Events["buds:nameshort"] = "UNIT_NAME_UPDATE"

-- ---------------------------------------------------------------------------
-- Status
-- ---------------------------------------------------------------------------
oUF.Tags.Methods["buds:afkdnd"] = function(unit)
	if UnitIsAFK(unit) then
		return " |cff999999" .. (CHAT_FLAG_AFK or "<AFK>") .. "|r"
	elseif UnitIsDND(unit) then
		return " |cff999999" .. (CHAT_FLAG_DND or "<DND>") .. "|r"
	end
	return ""
end
oUF.Tags.Events["buds:afkdnd"] = "PLAYER_FLAGS_CHANGED"

-- Level plus the classification shorthand, so "82+" reads as an elite.
oUF.Tags.Methods["buds:level"] = function(unit)
	local level = UnitLevel(unit)
	if not level or level <= 0 then
		return "??"
	end

	local class = UnitClassification(unit)
	if class == "worldboss" then
		return level .. "B"
	elseif class == "rareelite" then
		return level .. "R+"
	elseif class == "elite" then
		return level .. "+"
	elseif class == "rare" then
		return level .. "R"
	end
	return level
end
oUF.Tags.Events["buds:level"] = "UNIT_LEVEL PLAYER_LEVEL_UP UNIT_CLASSIFICATION_CHANGED"
