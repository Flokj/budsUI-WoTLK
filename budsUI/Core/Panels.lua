local K, C, L, _ = select(2, ...):unpack()

local unpack = unpack
local _G = _G
local CreateFrame = CreateFrame
local UIParent = UIParent

--	Bottom bars anchor (height follows BottomBars/SplitBars, applied after profile merge)
local bottombaranchor = CreateFrame("Frame", "ActionBarAnchor", UIParent)
bottombaranchor:CreatePanel("Invisible", 1, 1, unpack(C.Position.BottomBars))
bottombaranchor:SetWidth((C.ActionBar.ButtonSize * 12) + (C.ActionBar.ButtonSpace * 11))
bottombaranchor:SetFrameStrata("LOW")

-- Right bars anchor: created only when something uses it (3rd bar, vertical pet/stance bar); else Bar4 floats alone.
local rightbaranchor
local needRightAnchor = (C.ActionBar.RightBars or 0) >= 3
	or (C.ActionBar.PetBarHorizontal ~= true and (C.ActionBar.RightBars or 0) > 0)
	or C.ActionBar.StanceBarHorizontal ~= true
if needRightAnchor then
	rightbaranchor = CreateFrame("Frame", "RightActionBarAnchor", UIParent)
	rightbaranchor:CreatePanel("Invisible", 1, 1, unpack(C.Position.RightBars))
	rightbaranchor:SetHeight((C.ActionBar.ButtonSize * 12) + (C.ActionBar.ButtonSpace * 11))
	if C.ActionBar.RightBars == 1 then
		rightbaranchor:SetWidth(C.ActionBar.ButtonSize)
	elseif C.ActionBar.RightBars == 2 then
		rightbaranchor:SetWidth((C.ActionBar.ButtonSize * 2) + C.ActionBar.ButtonSpace)
	elseif C.ActionBar.RightBars == 3 then
		rightbaranchor:SetWidth((C.ActionBar.ButtonSize * 3) + (C.ActionBar.ButtonSpace * 2))
	else
		rightbaranchor:Hide()
	end
	rightbaranchor:SetFrameStrata("LOW")
end

--	Split bar anchor
local SplitBarLeft = CreateFrame("Frame", "SplitBarLeft", UIParent)
SplitBarLeft:CreatePanel("Invisible", (C.ActionBar.ButtonSize * 3) + (C.ActionBar.ButtonSpace * 2), (C.ActionBar.ButtonSize * 2) + C.ActionBar.ButtonSpace, "BOTTOMRIGHT", ActionBarAnchor, "BOTTOMLEFT", -C.ActionBar.ButtonSpace, 0)
SplitBarLeft:SetFrameStrata("LOW")

local SplitBarRight = CreateFrame("Frame", "SplitBarRight", UIParent)
SplitBarRight:CreatePanel("Invisible", (C.ActionBar.ButtonSize * 3) + (C.ActionBar.ButtonSpace * 2), (C.ActionBar.ButtonSize * 2) + C.ActionBar.ButtonSpace, "BOTTOMLEFT", ActionBarAnchor, "BOTTOMRIGHT", C.ActionBar.ButtonSpace, 0)
SplitBarRight:SetFrameStrata("LOW")

-- Split anchors exist always; the toggle only switches visibility and the bottom
-- anchor height. 3.3.5 loads profiles after the files, so re-apply on PLAYER_LOGIN.
local function ApplyBottomLayout()
	if C.ActionBar.BottomBars == 2 then
		bottombaranchor:SetHeight((C.ActionBar.ButtonSize * 2) + C.ActionBar.ButtonSpace)
	elseif C.ActionBar.BottomBars == 3 then
		if C.ActionBar.SplitBars == true then
			bottombaranchor:SetHeight((C.ActionBar.ButtonSize * 2) + C.ActionBar.ButtonSpace)
		else
			bottombaranchor:SetHeight((C.ActionBar.ButtonSize * 3) + (C.ActionBar.ButtonSpace * 2))
		end
	else
		bottombaranchor:SetHeight(C.ActionBar.ButtonSize)
	end

	if C.ActionBar.SplitBars == true then
		SplitBarLeft:Show()
		SplitBarRight:Show()
	else
		SplitBarLeft:Hide()
		SplitBarRight:Hide()
	end
end
ApplyBottomLayout()
local layoutLoader = CreateFrame("Frame")
layoutLoader:RegisterEvent("PLAYER_LOGIN")
layoutLoader:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN")
	ApplyBottomLayout()
end)

--	Pet bar anchor (sized to the on-screen footprint: pet buttons render
--	with C.ActionBar.PetBarScale, so the anchor and its mover must match it)
local petbaranchor = CreateFrame("Frame", "PetActionBarAnchor", UIParent)
local PetBarScale = C.ActionBar.PetBarScale or 0.7
if C.ActionBar.PetBarHorizontal == true then
	petbaranchor:CreatePanel("Invisible", ((C.ActionBar.ButtonSize * 10) + (C.ActionBar.ButtonSpace * 9)) * PetBarScale, (C.ActionBar.ButtonSize + C.ActionBar.ButtonSpace) * PetBarScale, unpack(C.Position.PetHorizontal))
elseif rightbaranchor then
	petbaranchor:CreatePanel("Invisible", (C.ActionBar.ButtonSize + 3) * PetBarScale, ((C.ActionBar.ButtonSize * 10) + (C.ActionBar.ButtonSpace * 9)) * PetBarScale, "RIGHT", rightbaranchor, "LEFT", 0, 0)
else
	petbaranchor:CreatePanel("Invisible", (C.ActionBar.ButtonSize + C.ActionBar.ButtonSpace) * PetBarScale, ((C.ActionBar.ButtonSize * 10) + (C.ActionBar.ButtonSpace * 9)) * PetBarScale, unpack(C.Position.RightBars))
end
petbaranchor:SetFrameStrata("LOW")
RegisterStateDriver(petbaranchor, "visibility", "[pet,novehicleui,nobonusbar:5] show; hide")

--	Stance bar anchor (ShapeshiftBar.lua sizes it to the class form count)
local ShiftHolder = CreateFrame("Frame", "ShiftHolder", UIParent)
if C.ActionBar.StanceBarHorizontal == true then
	ShiftHolder:SetPoint(unpack(C.Position.StanceBar))
else
	if (PetActionBarFrame:IsShown() or PetHolder) and C.ActionBar.PetBarHorizontal ~= true then
		ShiftHolder:SetPoint("RIGHT", "PetHolder", "LEFT", -C.ActionBar.ButtonSpace, (C.ActionBar.ButtonSize / 2) + 1)
	else
		ShiftHolder:SetPoint("RIGHT", "RightActionBarAnchor", "LEFT", -C.ActionBar.ButtonSpace, (C.ActionBar.ButtonSize / 2) + 1)
	end
end