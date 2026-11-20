local K, C, L, _ = select(2, ...):unpack()

local function Init()
if C.Minimap.Enable ~= true then return end

local match = string.match
local ToggleDropDownMenu = ToggleDropDownMenu

Minimap:SetScript("OnMouseUp", function(self, button)
	local position = self:GetPoint()
	if button == "RightButton" then
		local xoff = -1
		if position and position:match("RIGHT") then
			xoff = -16
		end
		ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, self, xoff, -3)
	elseif button == "MiddleButton" then
		return
	else
		Minimap_OnClick(self)
	end
end)
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN")
	Init()
end)
