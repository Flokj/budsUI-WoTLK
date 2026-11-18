local K, C, L, _ = select(2, ...):unpack()
if C.ActionBar.Enable ~= true then return end

local _G = _G
local unpack = unpack
local CreateFrame = CreateFrame
local UIParent = UIParent
local InCombatLockdown = InCombatLockdown
local GetNumShapeshiftForms = GetNumShapeshiftForms
local GetShapeshiftFormInfo = GetShapeshiftFormInfo
local hooksecurefunc = hooksecurefunc

if C.ActionBar.StanceBarHide then ShiftHolder:Hide() return end

-- Setup Shapeshift Bar by Tukz
local bar = CreateFrame("Frame", "UIShapeShift", ShiftHolder, "SecureHandlerStateTemplate")
bar:ClearAllPoints()
bar:SetAllPoints(ShiftHolder)

local States = {
	["DEATHKNIGHT"] = "show",
	["DRUID"] = "show",
	["PALADIN"] = "show",
	["PRIEST"] = "show",
	["ROGUE"] = "show",
	["WARLOCK"] = "show",
	["WARRIOR"] = "show",
}

-- Resize holder + mover to the form count the class actually has
local function updateSize(numForms)
	numForms = tonumber(numForms) or GetNumShapeshiftForms()
	numForms = math.min(math.max(numForms, 1), NUM_SHAPESHIFT_SLOTS)
	local size, space = C.ActionBar.ButtonSize, C.ActionBar.ButtonSpace
	local length = (size * numForms) + (space * (numForms - 1))
	if C.ActionBar.StanceBarHorizontal == true then
		ShiftHolder:SetWidth(length)
		ShiftHolder:SetHeight(size)
	else
		ShiftHolder:SetWidth(size)
		ShiftHolder:SetHeight(length)
	end
	local mover = ShiftHolder.budsUI_Mover
	if mover then mover:SetSize(ShiftHolder:GetWidth(), ShiftHolder:GetHeight()) end
end
K.UpdateMoverSize = updateSize

local function updateForms()
	if InCombatLockdown() then
		bar:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	bar:UnregisterEvent("PLAYER_REGEN_ENABLED")
	updateSize(GetNumShapeshiftForms())
	for i = 1, NUM_SHAPESHIFT_SLOTS do
		local button = _G["ShapeshiftButton"..i]
		local _, name = GetShapeshiftFormInfo(i)
		if name then
			button:Show()
		else
			button:Hide()
		end
	end
	K.ShiftBarUpdate()
end

bar:RegisterEvent("PLAYER_LOGIN")
bar:RegisterEvent("PLAYER_ENTERING_WORLD")
bar:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
bar:RegisterEvent("UPDATE_SHAPESHIFT_USABLE")
bar:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN")
bar:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
bar:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
bar:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_LOGIN" then
		for i = 1, NUM_SHAPESHIFT_SLOTS do
			local button = _G["ShapeshiftButton"..i]
			button:ClearAllPoints()
			button:SetParent(self)
			if i == 1 then
				if C.ActionBar.StanceBarHorizontal == true then
					button:SetPoint("BOTTOMLEFT", ShiftHolder, "BOTTOMLEFT", 0, 0)
				else
					button:SetPoint("TOPLEFT", ShiftHolder, "TOPLEFT", 0, 0)
				end
			else
				local previous = _G["ShapeshiftButton"..i-1]
				if C.ActionBar.StanceBarHorizontal == true then
					button:SetPoint("LEFT", previous, "RIGHT", C.ActionBar.ButtonSpace, 0)
				else
					button:SetPoint("TOP", previous, "BOTTOM", 0, -C.ActionBar.ButtonSpace)
				end
			end
		end
		RegisterStateDriver(self, "visibility", States[K.Class] or "hide")
		local function movestance()
			if not InCombatLockdown() then
				if C.ActionBar.StanceBarHorizontal == true then
					ShapeshiftButton1:SetPoint("BOTTOMLEFT", ShiftHolder, "BOTTOMLEFT", 0, 0)
				else
					ShapeshiftButton1:SetPoint("TOPLEFT", ShiftHolder, "TOPLEFT", 0, 0)
				end
			end
		end
		hooksecurefunc("ShapeshiftBar_Update", movestance)
	elseif event == "UPDATE_SHAPESHIFT_FORMS" or event == "PLAYER_ENTERING_WORLD" then
		updateForms()
		if event == "PLAYER_ENTERING_WORLD" then
			K.StyleShift()
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		updateForms()
	else
		K.ShiftBarUpdate()
	end
end)