local K, C, L, _ = select(2, ...):unpack()
if IsAddOnLoaded("Stuf") or IsAddOnLoaded("PitBull4") or IsAddOnLoaded("ShadowedUnitFrames") or IsAddOnLoaded("XPerl") then return end

local _G = _G
local CreateFrame = CreateFrame
local UnitExists = UnitExists
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitName = UnitName
local UnitClass = UnitClass
local UnitIsPlayer = UnitIsPlayer
local UnitSelectionColor = UnitSelectionColor
local InCombatLockdown = InCombatLockdown
local SetPortraitTexture = SetPortraitTexture
local UnitPowerType = UnitPowerType
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local PowerBarColor = PowerBarColor
local CUSTOM_CLASS_COLORS = CUSTOM_CLASS_COLORS
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local ToT = CreateFrame("Frame")

-- Disable Blizzard ToT frames natively to avoid taint.
-- Setting SetAlpha(0) on secure frames causes taint when Blizzard's secure combat 
-- updates attempt to show/hide them. We use the CVar to cleanly bypass the logic.
local function DisableBlizzardToT()
	SetCVar("showTargetOfTarget", "0")
end

local targetToT
local focusToT

local function UpdateColors(frame, unit)
	if UnitIsPlayer(unit) then
		local _, class = UnitClass(unit)
		local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
		if color then
			frame.health:SetStatusBarColor(color.r, color.g, color.b)
		end
	else
		local r, g, b = UnitSelectionColor(unit)
		frame.health:SetStatusBarColor(r, g, b)
	end
end

local function UpdateMana(frame, unit)
	local pType = UnitPowerType(unit)
	local color = PowerBarColor[pType] or PowerBarColor["MANA"]
	frame.mana:SetStatusBarColor(color.r, color.g, color.b)
	
	local power, powerMax = UnitPower(unit), UnitPowerMax(unit)
	frame.mana:SetMinMaxValues(0, powerMax)
	frame.mana:SetValue(power)
end

local function UpdateToT(frame, parentUnit, totUnit)
	if UnitExists(totUnit) then
		frame:Show()
		local hp, hpMax = UnitHealth(totUnit), UnitHealthMax(totUnit)
		frame.health:SetMinMaxValues(0, hpMax)
		frame.health:SetValue(hp)
		
		local name = UnitName(totUnit) or ""
		frame.name:SetText(name)
		
		SetPortraitTexture(frame.portrait, totUnit)
		
		UpdateColors(frame, totUnit)
		UpdateMana(frame, totUnit)
	else
		frame:Hide()
	end
end

local function CreateCustomToT(name, anchorFrame, relativePoint)
	local frame = CreateFrame("Frame", name, UIParent)
	frame:SetSize(93, 45)
	frame:SetScale((C.Unitframe.Scale or 1.2) * 1.2)
	-- Aligning perfectly relative to TargetFrame/FocusFrame
	frame:SetPoint("BOTTOMRIGHT", anchorFrame, relativePoint, -10, -10)
	frame:SetFrameLevel(4)
	frame:Hide()

	-- Portrait
	frame.portrait = frame:CreateTexture(name.."Portrait", "BACKGROUND")
	frame.portrait:SetSize(37, 37)
	frame.portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5)

	-- Health Bar
	frame.health = CreateFrame("StatusBar", name.."HealthBar", frame)
	frame.health:SetSize(48, 7)
	frame.health:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -18)
	frame.health:SetStatusBarTexture(C.Media.Texture)
	frame.health:SetFrameLevel(frame:GetFrameLevel() + 1)

	-- Mana Bar
	frame.mana = CreateFrame("StatusBar", name.."ManaBar", frame)
	frame.mana:SetSize(48, 7)
	frame.mana:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -24)
	frame.mana:SetStatusBarTexture(C.Media.Texture)
	frame.mana:SetFrameLevel(frame:GetFrameLevel() + 1)

	-- Texture Frame (Must be on top of Health/Mana to overlay borders correctly)
	frame.textureFrame = CreateFrame("Frame", nil, frame)
	frame.textureFrame:SetAllPoints()
	frame.textureFrame:SetFrameLevel(frame:GetFrameLevel() + 2)

	-- Frame Texture (Classic Blizzard WoW Border)
	frame.texture = frame.textureFrame:CreateTexture(name.."Texture", "ARTWORK")
	frame.texture:SetTexture([[Interface\TargetingFrame\UI-TargetofTargetFrame]])
	if C.Blizzard and C.Blizzard.DarkTextures == true and C.Blizzard.DarkTexturesColor then
		frame.texture:SetVertexColor(unpack(C.Blizzard.DarkTexturesColor))
	end
	frame.texture:SetSize(128, 64)
	frame.texture:SetPoint("TOPLEFT", frame.textureFrame, "TOPLEFT", 0, -2) -- Blizzard uses 0, -2

	-- Name FontString
	frame.name = frame.textureFrame:CreateFontString(name.."Name", "OVERLAY")
	frame.name:SetFont(C.Media.Font, C.Media.Font_Size - 2, C.Media.Font_Style)
	frame.name:SetPoint("BOTTOMLEFT", frame.textureFrame, "BOTTOMLEFT", 42, 2)
	frame.name:SetWidth(50)
	frame.name:SetHeight(10)
	frame.name:SetWordWrap(false)
	frame.name:SetJustifyH("LEFT")

	return frame
end

function ToT:PLAYER_ENTERING_WORLD()
	DisableBlizzardToT()
	
	if not targetToT then
		targetToT = CreateCustomToT("budsUI_TargetToT", TargetFrame, "BOTTOMRIGHT")
	end
	if not focusToT then
		focusToT = CreateCustomToT("budsUI_FocusToT", FocusFrame, "BOTTOMRIGHT")
	end
	
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function ToT:PLAYER_TARGET_CHANGED()
	if targetToT then UpdateToT(targetToT, "target", "targettarget") end
end

function ToT:PLAYER_FOCUS_CHANGED()
	if focusToT then UpdateToT(focusToT, "focus", "focustarget") end
end

function ToT:UNIT_TARGET(unit)
	if unit == "target" and targetToT then
		UpdateToT(targetToT, "target", "targettarget")
	elseif unit == "focus" and focusToT then
		UpdateToT(focusToT, "focus", "focustarget")
	end
end

function ToT:UNIT_HEALTH(unit)
	if unit == "targettarget" and targetToT and targetToT:IsVisible() then
		targetToT.health:SetValue(UnitHealth(unit))
	elseif unit == "focustarget" and focusToT and focusToT:IsVisible() then
		focusToT.health:SetValue(UnitHealth(unit))
	end
end

local timer = 0
ToT:SetScript("OnUpdate", function(self, elapsed)
	timer = timer + elapsed
	if timer > 0.3 then
		-- Polling to ensure PvE mobs and manabars are heavily updated
		if targetToT and TargetFrame and TargetFrame:IsVisible() then
			UpdateToT(targetToT, "target", "targettarget")
		end
		if focusToT and FocusFrame and FocusFrame:IsVisible() then
			UpdateToT(focusToT, "focus", "focustarget")
		end
		timer = 0
	end
end)

ToT:RegisterEvent("PLAYER_ENTERING_WORLD")
ToT:RegisterEvent("PLAYER_TARGET_CHANGED")
ToT:RegisterEvent("PLAYER_FOCUS_CHANGED")
ToT:RegisterEvent("UNIT_TARGET")
ToT:RegisterEvent("UNIT_HEALTH")
ToT:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		self[event](self, ...)
	end
end)
