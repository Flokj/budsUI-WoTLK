-- budsUI :: Modules/UnitFrames/Units/Small.lua

local Engine = select(2, ...)
local K, C = Engine:unpack()
local Module = Engine.UnitFrames
local Build = Module.Build

local BY_UNIT = {
	pet = "Pet",
	targettarget = "TargetOfTarget",
	focustarget = "FocusTarget",
}

Module.Styles.Small = function(self, unit)
	local cfg = C.Unitframe[BY_UNIT[unit] or "Pet"]

	Module.EnableInteraction(self, unit)

	Build.Health(self, cfg.Height)
	Build.Power(self, Module.PowerHeight(cfg))
	Build.Portrait(self, unit == "pet" and "left" or "right")
	if unit == "pet" then
		-- Level after the name, like Kkthnx (its default has no portrait).
		Build.Name(self, 12, true)
		Build.HealthText(self, 11)
	elseif unit == "targettarget" then
		-- Name is pre-cut to a fixed character count (buds:nameclip, no
		-- ellipsis) so the tiny bar never gets the client's width-clip "...".
		Build.NameCenter(self, 13, 0, "[buds:namecolor][buds:nameclip]")
	else
		Build.NameCenter(self, 13)
	end
	Build.Indicators(self, 12)
	Build.Range(self)

	-- Pet keeps the compact side row, clear of its left portrait.
	-- ToT/focustarget/pet get 3 debuffs below the frame, right to left,
	-- stretched to the full frame width (no gap on the left).
	if cfg.Debuffs then
		Build.BottomDebuffs(self, 3, (cfg.Width - Module.GAP * 2) / 3)
	end
end
