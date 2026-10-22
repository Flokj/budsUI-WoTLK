-- budsUI :: Modules/UnitFrames/AuraFilter.lua

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
