--[[-----------------------------------------------------------------------------
Addon: budsUI
File: Modules/UnitFrames/Init.lua
Purpose:
	Spawn pass. Runs last (see Load_UnitFrames.xml), after every style and
	builder has registered itself on Engine.UnitFrames.
-----------------------------------------------------------------------------]]

local Engine = select(2, ...)
local Module = Engine.UnitFrames
if Module and Module.Init then
	Module:Init()
end

-- Preview mode toggle: /bunit forces the real frames on with your data.
SLASH_BUDSUNITFRAMES1 = "/bunit"
SlashCmdList.BUDSUNITFRAMES = function()
	if Module and Module.ToggleTest then
		Module:ToggleTest()
	end
end
