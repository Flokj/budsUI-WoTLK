local K, C, L, _ = select(2, ...):unpack()
if C.Aura.Enable ~= true then return end

-- Localize standard libraries
local _G = _G
local unpack, select, pairs = unpack, select, pairs
local floor, math_floor, math_min = floor, math.floor, math.min
local mod = mod

-- Localize WoW API
local CreateFrame = CreateFrame
local GetWeaponEnchantInfo = GetWeaponEnchantInfo
local UnitHasVehicleUI = UnitHasVehicleUI
local hooksecurefunc = hooksecurefunc

-- Constants
local CONSOLIDATED_SCALING = 0.79 -- Magic number from interview notes, explained as scaling factor for consolidated buff icons

local mainhand, _, _, offhand = GetWeaponEnchantInfo()
local rowbuffs
if K.ScreenWidth <= 1440 then
	rowbuffs = 12
else
	rowbuffs = 16
end

-- BuffsAnchor is used by Core/Movers.lua for dragging.
local BuffsAnchor = CreateFrame("Frame", "BuffsAnchor", UIParent)
BuffsAnchor:SetPoint(unpack(C.Position.PlayerBuffs))
BuffsAnchor:SetSize((15 * C.Aura.BuffSize) + 42, (C.Aura.BuffSize * 2) + 3)

ConsolidatedBuffs:ClearAllPoints()
ConsolidatedBuffs:SetPoint("TOPRIGHT", BuffsAnchor, "TOPRIGHT", 0, 0)
ConsolidatedBuffs:SetSize(C.Aura.BuffSize, C.Aura.BuffSize)
-- ConsolidatedBuffs.SetPoint = K.Noop

ConsolidatedBuffsIcon:SetTexture("Interface\\Icons\\Spell_ChargePositive")
ConsolidatedBuffsIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
ConsolidatedBuffsIcon:SetSize(C.Aura.BuffSize - 4, C.Aura.BuffSize - 4)

local h = CreateFrame("Frame")
h:SetParent(ConsolidatedBuffs)
h:SetAllPoints(ConsolidatedBuffs)
h:SetFrameLevel(30)

ConsolidatedBuffsCount:SetParent(h)
ConsolidatedBuffsCount:SetPoint("BOTTOMRIGHT", 0, 1)
ConsolidatedBuffsCount:SetFont(C.Media.Font, C.Media.Font_Size, C.Media.Font_Style)
ConsolidatedBuffsCount:SetShadowOffset(0, 0)

local CBbg = CreateFrame("Frame", nil, ConsolidatedBuffs)
CBbg:SetTemplate("Default")
if C.Aura.ClassColorBorder == true then
	CBbg:SetBackdropBorderColor(K.Color.r, K.Color.g, K.Color.b)
end
CBbg:SetOutside()
CBbg:SetFrameStrata("BACKGROUND")

for i = 1, 2 do
	local tempEnchant = _G["TempEnchant"..i]
	local f = CreateFrame("Frame", nil, tempEnchant)
	f:CreatePanel("CreateBackdrop", C.Aura.BuffSize, C.Aura.BuffSize, "CENTER", tempEnchant, "CENTER", 0, 0)
	if C.Aura.ClassColorBorder == true then
		f.backdrop:SetBackdropBorderColor(K.Color.r, K.Color.g, K.Color.b)
	end

	if not f.shadow then
		f:CreateBlizzShadow(5)
	end

	local border = _G["TempEnchant"..i.."Border"]
	border:ClearAllPoints()
	border:SetPoint("TOPRIGHT", tempEnchant, 1, 1)
	border:SetPoint("BOTTOMLEFT", tempEnchant, -1, -1)
	border:SetTexCoord(0, 1, 0, 1)
	border:SetVertexColor(1, 1, 1)

	local tempEnchant2 = _G["TempEnchant2"]
	tempEnchant2:ClearAllPoints()
	tempEnchant2:SetPoint("RIGHT", _G["TempEnchant1"], "LEFT", -3, 0)

	local icon = _G["TempEnchant"..i.."Icon"]
	icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	icon:SetPoint("TOPLEFT", tempEnchant, 2, -2)
	icon:SetPoint("BOTTOMRIGHT", tempEnchant, -2, 2)

	tempEnchant:SetSize(C.Aura.BuffSize, C.Aura.BuffSize)

	local duration = _G["TempEnchant"..i.."Duration"]
	duration:ClearAllPoints()
	duration:SetPoint("CENTER", 2, 1)
	duration:SetFont(C.Media.Font, C.Media.Font_Size, C.Media.Font_Style)
	duration:SetShadowOffset(0, 0)
end

local function StyleBuffs(buttonName, index, debuff)
	local buff = _G[buttonName..index]
	if not buff then return end

	local icon = _G[buttonName..index.."Icon"]
	local border = _G[buttonName..index.."Border"]
	local duration = _G[buttonName..index.."Duration"]
	local count = _G[buttonName..index.."Count"]

	if icon and not _G[buttonName..index.."Panel"] then
		icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		icon:SetPoint("TOPLEFT", buff, 2, -2)
		icon:SetPoint("BOTTOMRIGHT", buff, -2, 2)

		buff:SetSize(C.Aura.BuffSize, C.Aura.BuffSize)

		duration:ClearAllPoints()
		duration:SetPoint("CENTER", 2, 1)
		duration:SetFont(C.Media.Font, C.Media.Font_Size, C.Media.Font_Style)
		duration:SetShadowOffset(0, 0)

		count:ClearAllPoints()
		count:SetPoint("BOTTOMRIGHT", 0, 1)
		count:SetFont(C.Media.Font, C.Media.Font_Size, C.Media.Font_Style)
		count:SetShadowOffset(0, 0)

		local panel = CreateFrame("Frame", buttonName..index.."Panel", buff)
		panel:CreatePanel("CreateBackdrop", C.Aura.BuffSize, C.Aura.BuffSize, "CENTER", buff, "CENTER", 0, 0)
		if C.Aura.ClassColorBorder == true then
			panel.backdrop:SetBackdropBorderColor(K.Color.r, K.Color.g, K.Color.b)
		end
		panel:SetFrameLevel(buff:GetFrameLevel() - 1)
		panel:SetFrameStrata(buff:GetFrameStrata())

		if not panel.shadow then
			panel:CreateBlizzShadow(5)
		end
	end
	if border then border:Hide() end
end

local function UpdateFlash(self, elapsed)
	self:SetAlpha(1)
end

local UpdateDuration = function(auraButton, timeLeft)
	local duration = auraButton.duration
	if SHOW_BUFF_DURATIONS == "1" and timeLeft then
		local timeLeftInt = math_floor(timeLeft + 0.5)
		if duration.lastTime ~= timeLeftInt then
			if timeLeftInt >= 86400 then
				duration:SetText(format("%dd", math_floor(timeLeftInt/86400 + 0.5)))
			elseif timeLeftInt >= 3600 then
				duration:SetText(format("%dh", math_floor(timeLeftInt/3600 + 0.5)))
			elseif timeLeftInt >= 60 then
				duration:SetText(format("%dm", math_floor(timeLeftInt/60 + 0.5)))
			else
				duration:SetText(timeLeftInt)
			end
			duration.lastTime = timeLeftInt
		end
		duration:Show()
	else
		duration:Hide()
	end
end

local function UpdateBuffAnchors()
	local buttonName = "BuffButton"
	local previousBuff, aboveBuff
	local numBuffs = 0
	local slack = BuffFrame.numEnchants
	local mainhand, _, _, offhand = GetWeaponEnchantInfo()

	if BuffFrame.numConsolidated > 0 then
		slack = slack + 1
	end

	for index = 1, BUFF_ACTUAL_DISPLAY do
		StyleBuffs(buttonName, index, false)
		local buff = _G[buttonName..index]

		if buff and not buff.consolidated then
			numBuffs = numBuffs + 1
			index = numBuffs + slack
			buff:ClearAllPoints()
			if (index > 1) and (mod(index, rowbuffs) == 1) then
				if index == rowbuffs + 1 then
					buff:SetPoint("TOP", ConsolidatedBuffs, "BOTTOM", 0, -3)
				else
					buff:SetPoint("TOP", aboveBuff, "BOTTOM", 0, -3)
				end
				aboveBuff = buff
			elseif index == 1 then
				buff:SetPoint("TOPRIGHT", BuffsAnchor, "TOPRIGHT", 0, 0)
			else
				if numBuffs == 1 then
					if mainhand and offhand and not UnitHasVehicleUI("player") then
						buff:SetPoint("RIGHT", TempEnchant2, "LEFT", -3, 0)
					elseif ((mainhand and not offhand) or (offhand and not mainhand)) and not UnitHasVehicleUI("player") then
						buff:SetPoint("RIGHT", TempEnchant1, "LEFT", -3, 0)
					else
						buff:SetPoint("RIGHT", ConsolidatedBuffs, "LEFT", -3, 0)
					end
				else
					buff:SetPoint("RIGHT", previousBuff, "LEFT", -3, 0)
				end
			end
			previousBuff = buff
		end
	end
end

local function UpdateDebuffAnchors(buttonName, index)
	local debuff = _G[buttonName..index]
	if not debuff then return end

	StyleBuffs(buttonName, index, true)
	local dtype = select(5, UnitDebuff("player", index))
	local color = DebuffTypeColor[dtype or "none"]

	local panel = _G[buttonName..index.."Panel"]
	if panel and panel.backdrop then
		panel.backdrop:SetBackdropBorderColor(color.r, color.g, color.b)
	end

	debuff:ClearAllPoints()
	if index == 1 then
		debuff:SetPoint("TOPRIGHT", BuffsAnchor, -1, -126)
	else
		debuff:SetPoint("RIGHT", _G[buttonName..(index-1)], "LEFT", -4, 0)
	end
end

local function UpdateConsolidatedBuffsAnchors()
	local numConsolidated = BuffFrame.numConsolidated
	local cellSize = C.Aura.BuffSize * CONSOLIDATED_SCALING
	ConsolidatedBuffsTooltip:SetWidth(math_min(numConsolidated * cellSize + 18, 4 * cellSize + 18))
	ConsolidatedBuffsTooltip:SetHeight(floor((numConsolidated + 3) / 4 ) * cellSize + CONSOLIDATED_BUFF_ROW_HEIGHT * CONSOLIDATED_SCALING)
end

hooksecurefunc("BuffFrame_UpdateAllBuffAnchors", UpdateBuffAnchors)
hooksecurefunc("DebuffButton_UpdateAnchors", UpdateDebuffAnchors)
hooksecurefunc("AuraButton_UpdateDuration", UpdateDuration)
hooksecurefunc("AuraButton_OnUpdate", UpdateFlash)
hooksecurefunc("ConsolidatedBuffs_UpdateAllAnchors", UpdateConsolidatedBuffsAnchors)