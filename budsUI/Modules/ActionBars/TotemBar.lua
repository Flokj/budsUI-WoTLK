local K, C, L, _ = select(2, ...):unpack()
if C.ActionBar.Enable ~= true or K.Class ~= "SHAMAN" then return end

-- We just use default totem bar for shaman
-- We parent it to our shapeshift bar.

if K.Class == "SHAMAN" then
	if MultiCastActionBarFrame then
		MultiCastActionBarFrame:SetScript("OnUpdate", nil)
		MultiCastActionBarFrame:SetScript("OnShow", nil)
		MultiCastActionBarFrame:SetScript("OnHide", nil)
		MultiCastActionBarFrame:SetScale(1.1)
		MultiCastActionBarFrame:SetParent(ShiftHolder)
		MultiCastActionBarFrame:ClearAllPoints()
		MultiCastActionBarFrame:SetPoint("CENTER", ShiftHolder, 0, 0)
 
		hooksecurefunc("MultiCastActionButton_Update",function(actionbutton) if not InCombatLockdown() then actionbutton:SetAllPoints(actionbutton.slotButton) end end)
 
		MultiCastActionBarFrame.SetParent = K.Noop
		MultiCastActionBarFrame.SetPoint = K.Noop
		MultiCastRecallSpellButton.SetPoint = K.Noop
	end
end