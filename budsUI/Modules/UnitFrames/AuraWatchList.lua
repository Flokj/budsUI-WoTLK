-- budsUI :: Modules/UnitFrames/AuraWatchList.lua

local Engine = select(2, ...)
local K = Engine:unpack()

local GREEN = { 0.4, 0.85, 0.4 }
local BLUE = { 0.4, 0.7, 1 }
local GOLD = { 0.95, 0.75, 0.35 }
local PINK = { 0.95, 0.5, 0.75 }
local TEAL = { 0.35, 0.85, 0.8 }

K.AuraWatchList = {
	DRUID = {
		[774] = { corner = "TOPLEFT", color = GREEN, mine = true }, -- Rejuvenation
		[8936] = { corner = "TOPRIGHT", color = GOLD, mine = true }, -- Regrowth
		[33763] = { corner = "BOTTOMLEFT", color = TEAL, mine = true }, -- Lifebloom
		[48438] = { corner = "BOTTOMRIGHT", color = BLUE, mine = true }, -- Wild Growth
	},
	PRIEST = {
		[139] = { corner = "TOPLEFT", color = GREEN, mine = true }, -- Renew
		[17] = { corner = "TOPRIGHT", color = GOLD, mine = true }, -- Power Word: Shield
		[33076] = { corner = "BOTTOMLEFT", color = BLUE, mine = true }, -- Prayer of Mending
		[33206] = { corner = "BOTTOMRIGHT", color = PINK, mine = true }, -- Pain Suppression
	},
	SHAMAN = {
		[61295] = { corner = "TOPLEFT", color = BLUE, mine = true }, -- Riptide
		[974] = { corner = "TOPRIGHT", color = GOLD, mine = true }, -- Earth Shield
	},
	PALADIN = {
		[53563] = { corner = "TOPLEFT", color = GOLD, mine = true }, -- Beacon of Light
		[1022] = { corner = "TOPRIGHT", color = BLUE, mine = true }, -- Hand of Protection
	},
}

K.AuraWatch = K.AuraWatchList[K.Class] or {}
