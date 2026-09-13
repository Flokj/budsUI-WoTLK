--[[-----------------------------------------------------------------------------
Addon: budsUI
File: Modules/UnitFrames/Units/Small.lua
Purpose:
	The companion frames: pet, target of target, focus target.
	Only the pet reads like the target frame, with the name above the bar.
	Target of target and focus target stay compact with the name on the bar.
	The pet reads left-to-right like the player it belongs to, so its
	portrait sits on the left, the others sit on the right.
-----------------------------------------------------------------------------]]

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
	else
		Build.NameCenter(self, 13)
	end
	Build.Indicators(self, 12)
	Build.Range(self)

	-- Pet keeps the compact side row, clear of its left portrait.
	if cfg.Debuffs then
		Build.GroupDebuffs(self, 3, cfg.Height, unit == "pet" and "right" or nil)
	end
end
