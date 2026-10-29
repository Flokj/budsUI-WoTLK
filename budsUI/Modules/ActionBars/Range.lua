local K, C, L, _ = select(2, ...):unpack()
if C.ActionBar.Enable ~= true then return end

-- Out-of-range / out-of-mana icon tint for the stock action buttons.
-- FrostAtom-style: one throttled ticker over cached per-button flags, writes
-- color only on change, repaints instantly on target change. The stock button
-- OnUpdate is left alive, so Blizzard's own flash still works.

local _G = _G
local CreateFrame = CreateFrame
local GetTime = GetTime
local UnitExists = UnitExists
local hooksecurefunc = hooksecurefunc

local UPDATE_DELAY = 0.1

local ActionButton_GetPagedID = ActionButton_GetPagedID
local GetActionInfo = GetActionInfo
local ActionHasRange = ActionHasRange
local IsActionInRange = IsActionInRange
local IsUsableAction = IsUsableAction
local HasAction = HasAction

local COLORS = {
	OOR      = C.ActionBar.OutOfRange,
	OOM      = C.ActionBar.OutOfMana,
	NORMAL   = { 1, 1, 1 },
	UNUSABLE = { 0.2, 0.2, 0.2 },
}

local buttons = {}
local hasTarget = false

local function CollectButtons()
	for i = 1, 12 do
		buttons[#buttons + 1] = _G["ActionButton" .. i]
		buttons[#buttons + 1] = _G["BonusActionButton" .. i]
		buttons[#buttons + 1] = _G["MultiBarBottomLeftButton" .. i]
		buttons[#buttons + 1] = _G["MultiBarBottomRightButton" .. i]
		buttons[#buttons + 1] = _G["MultiBarLeftButton" .. i]
		buttons[#buttons + 1] = _G["MultiBarRightButton" .. i]
	end
end

-- Cache whether the button holds a ranged action, its icon and macro state.
-- Runs on ActionButton_Update / OnShow / OnHide only, never in the tick loop.
local function UpdateButtonStatus(button)
	local action = ActionButton_GetPagedID(button)
	if action and HasAction(action) and ActionHasRange(action) then
		button.rangeStatus = true
		button.rangeIcon = button.rangeIcon or _G[button:GetName() .. "Icon"]
		button.isMacro = (GetActionInfo(action) == "macro")
	else
		button.rangeStatus = nil
		button.rangeIcon = nil
		button.isMacro = nil
		button.colorKind = nil
	end
end

local function SetButtonColor(button, kind)
	if button.colorKind == kind then
		return
	end
	button.colorKind = kind
	if kind ~= "UNUSABLE" then
		local icon = button.rangeIcon
		if icon then
			local color = COLORS[kind]
			icon:SetVertexColor(color[1], color[2], color[3])
		end
	end
end

local function UpdateButton(button)
	local action = ActionButton_GetPagedID(button)
	if not action or not button.rangeStatus or not button:IsVisible() then
		return
	end

	local isUsable, notEnoughMana = IsUsableAction(action)

	if isUsable then
		if (not hasTarget and not button.isMacro) or IsActionInRange(action) ~= 0 then
			SetButtonColor(button, "NORMAL")
		else
			SetButtonColor(button, "OOR")
		end
	elseif notEnoughMana then
		SetButtonColor(button, "OOM")
	else
		SetButtonColor(button, "UNUSABLE")
	end
end

local function UpdateButtons()
	for i = 1, #buttons do
		UpdateButton(buttons[i])
	end
end

local ticker = CreateFrame("Frame")
ticker:Hide()
local nextUpdate = 0
ticker:SetScript("OnUpdate", function()
	local now = GetTime()
	if now < nextUpdate then
		return
	end
	nextUpdate = now + UPDATE_DELAY
	UpdateButtons()
end)

local function RepaintNow()
	nextUpdate = 0
	UpdateButtons()
end

local listener = CreateFrame("Frame")
listener:RegisterEvent("PLAYER_LOGIN")
listener:RegisterEvent("PLAYER_TARGET_CHANGED")
listener:RegisterEvent("PLAYER_ENTERING_WORLD")

listener:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		CollectButtons()
		for i = 1, #buttons do
			local button = buttons[i]
			button:HookScript("OnShow", function() UpdateButtonStatus(button) end)
			button:HookScript("OnHide", function() UpdateButtonStatus(button) end)
			UpdateButtonStatus(button)
		end
		hooksecurefunc("ActionButton_Update", function(button)
			if button and button:IsVisible() then
				UpdateButtonStatus(button)
			end
		end)
		ticker:Show()
	end
	hasTarget = UnitExists("target")
	RepaintNow()
end)