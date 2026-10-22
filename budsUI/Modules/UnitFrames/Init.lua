-- budsUI :: Modules/UnitFrames/Init.lua

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
