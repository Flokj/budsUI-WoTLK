local K, C, L, _ = select(2, ...):unpack()
if C.ActionBar.Enable ~= true then return end

local UnitGUID = UnitGUID
local GetTime = GetTime
local GetActionInfo = GetActionInfo
local GetMacroSpell = GetMacroSpell
local band = bit.band
local CreateFrame = CreateFrame

local lockedSchool = 0
local lockoutEnd = 0
local playerGUID

local INTERRUPT_DURATIONS = {
	[2139] = 8,  -- Counterspell
	[72] = 6,    -- Shield Bash
	[1766] = 5,  -- Kick
	[6552] = 4,  -- Pummel
	[47528] = 4, -- Mind Freeze
	[19647] = 3, -- Spell Lock
	[57994] = 2, -- Wind Shear
}

local function GetButtonSpellSchool(button)
	if not button or not button.action then return 0 end
	local actionType, id = GetActionInfo(button.action)
	if actionType == "spell" and id then
		local data = K.LockoutData and K.LockoutData.SPELLS and K.LockoutData.SPELLS[id]
		return data and data[1] or 0
	elseif actionType == "macro" and id then
		local spellId = GetMacroSpell(id)
		if spellId then
			local data = K.LockoutData and K.LockoutData.SPELLS and K.LockoutData.SPELLS[spellId]
			return data and data[1] or 0
		end
	end
	return 0
end

local function UpdateButtonLockout(button, now)
	if not button then return end
	local school = GetButtonSpellSchool(button)
	local isLocked = (lockedSchool > 0) and (now < lockoutEnd) and (school > 0) and (band(school, lockedSchool) ~= 0)

	if isLocked then
		if not button.lockoutOverlay then
			local overlay = button:CreateTexture(nil, "OVERLAY", nil, 6)
			overlay:SetAllPoints()
			overlay:SetTexture(0.85, 0.15, 0.15, 0.45)
			button.lockoutOverlay = overlay
		end
		button.lockoutOverlay:Show()
	elseif button.lockoutOverlay then
		button.lockoutOverlay:Hide()
	end
end

local buttons = {}
local function CollectButtons()
	for i = 1, 12 do
		buttons[#buttons + 1] = _G["ActionButton" .. i]
		buttons[#buttons + 1] = _G["BonusActionButton" .. i]
		buttons[#buttons + 1] = _G["MultiBarBottomLeftButton" .. i]
		buttons[#buttons + 1] = _G["MultiBarBottomRightButton" .. i]
		buttons[#buttons + 1] = _G["MultiBarRightButton" .. i]
		buttons[#buttons + 1] = _G["MultiBarLeftButton" .. i]
	end
end

local function UpdateAllLockouts()
	local now = GetTime()
	if now >= lockoutEnd then
		lockedSchool = 0
	end
	for i = 1, #buttons do
		UpdateButtonLockout(buttons[i], now)
	end
end

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()
timerFrame:SetScript("OnUpdate", function(self, elapsed)
	if GetTime() >= lockoutEnd then
		self:Hide()
		UpdateAllLockouts()
	end
end)

local listener = CreateFrame("Frame")
listener:RegisterEvent("PLAYER_LOGIN")

listener:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_LOGIN" then
		playerGUID = UnitGUID("player")
		CollectButtons()
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local _, subEvent, _, sourceGUID, sourceName, _, destGUID, destName, _, spellID, spellName, spellSchool, extraSpellID, extraSpellName, extraSchool = ...
		if subEvent == "SPELL_INTERRUPT" and destGUID == playerGUID then
			local duration = INTERRUPT_DURATIONS[spellID] or 4
			local school = extraSchool or (K.LockoutData and K.LockoutData.SPELLS and extraSpellID and K.LockoutData.SPELLS[extraSpellID] and K.LockoutData.SPELLS[extraSpellID][1]) or 0
			if school > 0 then
				lockedSchool = school
				lockoutEnd = GetTime() + duration
				timerFrame:Show()
				UpdateAllLockouts()
			end
		end
	elseif event == "ACTIONBAR_UPDATE_COOLDOWN" then
		if lockedSchool > 0 then
			UpdateAllLockouts()
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		lockedSchool = 0
		lockoutEnd = 0
		timerFrame:Hide()
		UpdateAllLockouts()
	end
end)
