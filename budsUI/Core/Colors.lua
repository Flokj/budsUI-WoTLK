local K, C, _ = select(2, ...):unpack()

local _G = _G
local PowerBarColor = PowerBarColor

-- Custom Faction Colors (localized to budsUI namespace)
local BETTER_FACTION_BAR_COLORS = {
	[1] = {r = 217/255, g = 69/255, b = 69/255},
	[2] = {r = 217/255, g = 69/255, b = 69/255},
	[3] = {r = 217/255, g = 69/255, b = 69/255},
	[4] = {r = 217/255, g = 196/255, b = 92/255},
	[5] = {r = 84/255, g = 150/255, b = 84/255},
	[6] = {r = 84/255, g = 150/255, b = 84/255},
	[7] = {r = 84/255, g = 150/255, b = 84/255},
	[8] = {r = 84/255, g = 150/255, b = 84/255},
}
K.BetterFactionBarColors = BETTER_FACTION_BAR_COLORS

-- Custom Power Colors
if C.Unitframe.BetterPowerColors == true then
	_G.PowerBarColor["RAGE"] = {r = 199/255, g = 64/255, b = 64/255}
	_G.PowerBarColor["FOCUS"] = {r = 181/255, g = 110/255, b = 69/255}
	_G.PowerBarColor["MANA"] = {r = 79/255, g = 115/255, b = 161/255}
	_G.PowerBarColor["ENERGY"] = {r = 166/255, g = 161/255, b = 89/255}
	_G.PowerBarColor["RUNES"] = {r = 128/255, g = 128/255, b = 128/255}
	_G.PowerBarColor["RUNIC_POWER"] = {r = 0/255, g = 209/255, b = 255/255}
end