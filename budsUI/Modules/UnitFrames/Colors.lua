--[[-----------------------------------------------------------------------------
Addon: budsUI
File: Modules/UnitFrames/Colors.lua
Purpose:
	Power and reaction palette, applied over the oUF colour tables so every
	health bar coloured by reaction and every power bar uses them. Values live
	in the config so they can be tuned. Module.ApplyUnitColors re-reads them.

	Ported from KkthnxUI retail: Midnight-only power tokens (Lunar, Maelstrom,
	Insanity, Fury, Pain) and Enum.PowerType lookups are gone; 3.3.5 power is
	keyed by token string, which is all classic oUF needs.
-----------------------------------------------------------------------------]]

local Engine = select(2, ...)
local K, C = Engine:unpack()
local oUF = Engine.oUF or _G.budsUF

local Module = Engine.UnitFrames
if not Module then return end

local colors = oUF and oUF.colors
if not colors then
	return
end

local pairs = pairs

-- Class colours, harmonised for the dark theme (mage locked to the accent).
local CLASS = {
	DEATHKNIGHT = { 0.77, 0.12, 0.23 },
	DRUID = { 1.00, 0.49, 0.04 },
	HUNTER = { 0.67, 0.83, 0.45 },
	MAGE = { 0.36, 0.55, 0.81 },
	PALADIN = { 0.96, 0.55, 0.73 },
	PRIEST = { 0.90, 0.92, 0.96 },
	ROGUE = { 0.96, 0.85, 0.41 },
	SHAMAN = { 0.00, 0.44, 0.87 },
	WARLOCK = { 0.53, 0.47, 0.84 },
	WARRIOR = { 0.78, 0.61, 0.43 },
}
K.ClassColors = CLASS

local function MakeColor(c)
	-- Numeric indices: the oUF core reads colours as t[1..3]. Named fields
	-- plus methods: our own border/tag code uses :GetRGB() and
	-- :GenerateHexColorMarkup().
	return {
		c[1], c[2], c[3],
		r = c[1], g = c[2], b = c[3],
		GetRGB = function(self) return self[1], self[2], self[3] end,
		GenerateHexColorMarkup = function(self)
			return string.format("|cff%02x%02x%02x", self[1] * 255, self[2] * 255, self[3] * 255)
		end,
	}
end
Module.MakeColor = MakeColor

function Module.ApplyUnitColors()
	local db = C.Unitframe
	if not db then
		return
	end

	if db.PowerColors then
		for token, c in pairs(db.PowerColors) do
			colors.power[token] = MakeColor(c)
		end
	end

	if db.ReactionColors then
		for i, c in pairs(db.ReactionColors) do
			colors.reaction[i] = MakeColor(c)
		end
	end

	for token, c in pairs(CLASS) do
		colors.class[token] = MakeColor(c)
	end

	local mine = CLASS[K.Class]
	if mine then
		K.ClassColor = { r = mine[1], g = mine[2], b = mine[3] }
	end
end
