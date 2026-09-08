--[[-----------------------------------------------------------------------------
Addon: budsUI
File: Modules/UnitFrames/Units/Target.lua
Purpose:
	Target and focus. Both are the player frame mirrored: portrait on the
	right, name above health, debuffs above the name, buffs below, and a
	detached castbar.

	Focus is the same shape at a smaller size, so the two share one builder.
-----------------------------------------------------------------------------]]

local Engine = select(2, ...)
local K, C = Engine:unpack()
local Module = Engine.UnitFrames
local Build = Module.Build

local function BuildMirrored(self, cfg, nameSize, style)
	Module.EnableInteraction(self, style)

	Build.Health(self, cfg.Height)
	Build.Power(self, Module.PowerHeight(cfg))
	Build.HealthText(self, nameSize + 3)
	Build.PowerText(self, 13)

	Build.Portrait(self, "right")
	Build.PortraitLevel(self)

	Build.Indicators(self)
	Build.Range(self)

	-- Name first so it sits directly above health, then the aura panels on top.
	Build.Name(self, nameSize + 3)
	Build.Auras(self, cfg)
end

Module.Styles.Target = function(self)
	local cfg = C.Unitframe.Target
	local castbar = C.Unitframe.Castbar

	BuildMirrored(self, cfg, 12, "target")

	-- Centred between the player and target frames, at their health-bar height.
	Build.DetachedCastbar(self, "TargetCastbar", "Target Castbar", castbar.TargetWidth, castbar.TargetHeight, { "BOTTOM", UIParent, "BOTTOM", 105, 420 }, "left")
end

Module.Styles.Focus = function(self)
	local cfg = C.Unitframe.Focus
	local castbar = C.Unitframe.Castbar

	BuildMirrored(self, cfg, 11, "focus")

	Build.DetachedCastbar(self, "FocusCastbar", "Focus Castbar", castbar.FocusWidth, castbar.FocusHeight, { "BOTTOM", UIParent, "TOPLEFT", 450, -30 }, "left")
end
