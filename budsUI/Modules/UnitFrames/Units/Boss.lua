--[[-----------------------------------------------------------------------------
Addon: budsUI
File: Modules/UnitFrames/Units/Boss.lua
Purpose:
	Boss style frames. Narrow bars stacked down the right side of the screen
	with the name on the bar, debuffs fanning out to the left, and an
	attached castbar so you can tell which of several casters is the problem.

	Ported from KkthnxUI retail: no encounter alternate-power bar on 3.3.5
	(Build.AlternativePower is a no-op here).
-----------------------------------------------------------------------------]]

local Engine = select(2, ...)
local K, C = Engine:unpack()
local Module = Engine.UnitFrames
local Build = Module.Build

Module.Styles.Boss = function(self)
	local cfg = C.Unitframe.Boss

	Module.EnableInteraction(self, "boss")

	Build.Health(self, cfg.Height)
	Build.Power(self, Module.PowerHeight(cfg))

	-- Portrait hangs off the right, clear of the debuffs that fan out to the
	-- left.
	if cfg.Portrait then
		Build.Portrait(self, "right", Module.TotalHeight(cfg))
		Build.PortraitLevel(self)
	end

	-- Name on the gradient strip above health, health value on the health
	-- bar, and numbers on the power bar.
	Build.Name(self, 13, true)
	Build.HealthText(self, 13)
	Build.PowerText(self, 11)

	Build.AlternativePower(self)
	Build.Indicators(self, 14)
	Build.Range(self)

	if cfg.Debuffs then
		Build.GroupDebuffs(self, 4, cfg.Height - 2)
	end

	-- The same top castbar the party uses, with its icon slot on the portrait
	-- side.
	if cfg.Castbar then
		Build.TopCastbar(self, 14, "right")
	end
end
