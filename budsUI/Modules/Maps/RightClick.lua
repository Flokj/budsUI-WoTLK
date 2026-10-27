local K, C, L, _ = select(2, ...):unpack()
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