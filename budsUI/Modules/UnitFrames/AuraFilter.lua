--[[-----------------------------------------------------------------------------
Addon: budsUI
File: Modules/UnitFrames/AuraFilter.lua
Purpose:
	Which debuff schools the player's class can remove. Used by the group
	dispel highlight and the dispel-only aura filter.

	Ported from KkthnxUI retail: WotLK dispel table (no monks, evokers, or
	Cataclysm-era dispel changes; shaman cleanse is Curse-only here).
-----------------------------------------------------------------------------]]

local Engine = select(2, ...)
local K = Engine:unpack()

local CLASS_DISPEL = {
	PRIEST = { Magic = true, Disease = true },
	PALADIN = { Magic = true, Poison = true, Disease = true },
	SHAMAN = { Curse = true },
	DRUID = { Curse = true, Poison = true },
	MAGE = { Curse = true },
	WARLOCK = { Magic = true },
}
K.CanDispel = CLASS_DISPEL[K.Class] or {}
