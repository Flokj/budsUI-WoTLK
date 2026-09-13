--[[-----------------------------------------------------------------------------
Addon: budsUI
File: Modules/UnitFrames/Units/Player.lua
Purpose:
	The player frame. Portrait on the left, health and power stacked, class
	resource above, debuffs above that, and a free floating castbar down by
	the action bars the way the original KkthnxUI had it.

	No name text here on purpose. You know who you are.
-----------------------------------------------------------------------------]]

local Engine = select(2, ...)
local K, C = Engine:unpack()
local Module = Engine.UnitFrames
local Build = Module.Build

Module.Styles.Player = function(self)
	local cfg = C.Unitframe.Player
	local castbar = C.Unitframe.Castbar

	Module.EnableInteraction(self, "player")

	Build.Health(self, cfg.Height)
	Build.Power(self, Module.PowerHeight(cfg))
	Build.HealthText(self, 14)
	Build.PowerText(self, 12)

	Build.Portrait(self, "left")
	Build.PortraitLevel(self)

	if cfg.ShowName then
		Build.Name(self, 14)
	end

	if cfg.AdditionalPower then
		Build.AdditionalPower(self)
	end

	Build.Indicators(self)
	Build.PlayerIndicators(self)

	-- Class resource lives in its own detached holder with a mover now, so it
	-- no longer takes part in the upward stack. Only one of the resource
	-- builders does anything for a given class.
	if cfg.ClassPower then
		Build.Runes(self, cfg.Width)
		Build.ClassPower(self, cfg.Width)
	end
	Build.Auras(self, cfg)

	-- Sit evenly between the action bars below and the unit frames above.
	Build.DetachedCastbar(self, "PlayerCastbar", "Player Castbar", castbar.PlayerWidth, castbar.PlayerHeight, { "BOTTOM", UIParent, "BOTTOM", 25, 385 }, "left")
end
