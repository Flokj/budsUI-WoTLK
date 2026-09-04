local K, C, L, _ = select(2, ...):unpack()
if IsAddOnLoaded("Quartz") or IsAddOnLoaded("Stuf") or IsAddOnLoaded("PitBull4") or IsAddOnLoaded("ShadowedUnitFrames") or IsAddOnLoaded("XPerl") then return end

local unpack = unpack
local format = string.format
local max = math.max
local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc
local UIPARENT_MANAGED_FRAME_POSITIONS = UIPARENT_MANAGED_FRAME_POSITIONS

local CastBars = CreateFrame("Frame", nil, UIParent)

-- Anchors
local PlayerCastbarAnchor = CreateFrame("Frame", "PlayerCastbarAnchor", UIParent)
if not InCombatLockdown() then
	local width = CastingBarFrame:GetWidth()
	local height = CastingBarFrame:GetHeight()
	if width == 0 then width = 150 end
	if height == 0 then height = 24 end
	PlayerCastbarAnchor:SetSize(width * C.Unitframe.CastBarScale, height * 2)
	PlayerCastbarAnchor:SetPoint(unpack(C.Position.UnitFrames.PlayerCastBar))
end

local TargetCastbarAnchor = CreateFrame("Frame", "TargetCastbarAnchor", UIParent)
if not InCombatLockdown() then
	local width = TargetFrameSpellBar:GetWidth()
	local height = TargetFrameSpellBar:GetHeight()
	if width == 0 then width = 150 end
	if height == 0 then height = 24 end
	TargetCastbarAnchor:SetSize(width * C.Unitframe.CastBarScale, height * 2)
	TargetCastbarAnchor:SetPoint(unpack(C.Position.UnitFrames.TargetCastBar))
end

CastBars:RegisterEvent("ADDON_LOADED")
CastBars:SetScript("OnEvent", function(self, event, addon)
	if (addon ~= "budsUI") then return end
	if not InCombatLockdown() then

		UIPARENT_MANAGED_FRAME_POSITIONS["CastingBarFrame"] = nil

		-- Move Cast Bar
		CastingBarFrame:ClearAllPoints()
		CastingBarFrame:SetScale(C.Unitframe.CastBarScale)
		CastingBarFrame:SetPoint("CENTER", PlayerCastbarAnchor, "CENTER", 0, -3)

		-- Style CastingBarFrame
		CastingBarFrameBorder:SetTexture("Interface\\CastingBar\\UI-CastingBar-Border-Small")
		CastingBarFrameFlash:SetTexture("Interface\\CastingBar\\UI-CastingBar-Flash-Small")

		CastingBarFrameText:ClearAllPoints()
		CastingBarFrameText:SetPoint("CENTER", 0, 1)

		CastingBarFrameBorder:SetWidth(CastingBarFrameBorder:GetWidth() + 4)
		CastingBarFrameFlash:SetWidth(CastingBarFrameFlash:GetWidth() + 4)
		CastingBarFrameBorderShield:SetWidth(CastingBarFrameBorderShield:GetWidth() + 4)
		CastingBarFrameBorder:SetPoint("TOP", 0, 26)
		CastingBarFrameFlash:SetPoint("TOP", 0, 26)
		CastingBarFrameBorderShield:SetPoint("TOP", 0, 26)

		-- CastingBarFrame Icon
		CastingBarFrameIcon:Show()
		CastingBarFrameIcon:SetSize(20, 20)
		CastingBarFrameIcon:ClearAllPoints()
		CastingBarFrameIcon:SetPoint("LEFT", CastingBarFrame, "RIGHT", 8, 0)

		-- Target Castbar
		TargetFrameSpellBar:ClearAllPoints()
		TargetFrameSpellBar:SetPoint("CENTER", TargetCastbarAnchor, "CENTER", 0, 0)
		TargetFrameSpellBar:SetScale(C.Unitframe.CastBarScale)

		-- Castbar Timer
		CastingBarFrame.timer = CastingBarFrame:CreateFontString(nil)
		if C.Unitframe.Outline then
			CastingBarFrame.timer:SetFont(C.Media.Font, C.Media.Font_Size + 2, C.Media.Font_Style)
			CastingBarFrame.timer:SetShadowOffset(0, 0)
		else
			CastingBarFrame.timer:SetFont(C.Media.Font, C.Media.Font_Size + 2)
			CastingBarFrame.timer:SetShadowOffset(K.Mult, -K.Mult)
		end
		CastingBarFrame.timer:SetPoint("RIGHT", CastingBarFrame, "LEFT", -12, 1)
		CastingBarFrame.updateDelay = 0.1

		TargetFrameSpellBar.timer = TargetFrameSpellBar:CreateFontString(nil)
		if C.Unitframe.Outline then
			TargetFrameSpellBar.timer:SetFont(C.Media.Font, C.Media.Font_Size, C.Media.Font_Style)
			TargetFrameSpellBar.timer:SetShadowOffset(0, 0)
		else
			TargetFrameSpellBar.timer:SetFont(C.Media.Font, C.Media.Font_Size)
			TargetFrameSpellBar.timer:SetShadowOffset(K.Mult, -K.Mult)
		end
		TargetFrameSpellBar.timer:SetPoint("LEFT", TargetFrameSpellBar, "RIGHT", 8, 2)
		TargetFrameSpellBar.updateDelay = 0.1

		-- Lock positions to prevent Blizzard overrides (Safe for 3.3.5)
		-- Store original functions and override with position restore
		CastingBarFrame._ClearAllPoints = CastingBarFrame.ClearAllPoints
		CastingBarFrame._SetPoint = CastingBarFrame.SetPoint
		CastingBarFrame.ClearAllPoints = function(self)
			-- Restore position after Blizzard tries to move it
			self:_ClearAllPoints()
			self:_SetPoint("CENTER", PlayerCastbarAnchor, "CENTER", 0, 0)
		end
		CastingBarFrame.SetPoint = K.Noop
		
		TargetFrameSpellBar._ClearAllPoints = TargetFrameSpellBar.ClearAllPoints
		TargetFrameSpellBar._SetPoint = TargetFrameSpellBar.SetPoint
		TargetFrameSpellBar.ClearAllPoints = function(self)
			self:_ClearAllPoints()
			self:_SetPoint("CENTER", TargetCastbarAnchor, "CENTER", 0, 0)
		end
		TargetFrameSpellBar.SetPoint = K.Noop

		self:UnregisterEvent("ADDON_LOADED")
	end
end)

-- TAINT FIX: Standalone cast timer frame replaces hooksecurefunc on CastingBarFrame_OnUpdate.
-- The hook injected addon code into Blizzard's protected cast bar OnUpdate chain every frame
-- during combat casts. This standalone frame reads CastingBarFrame values independently and
-- only runs its OnUpdate during active casts (zero overhead when not casting).
local castTimerFrame = CreateFrame("Frame")
castTimerFrame:Hide()

-- Update both CastingBarFrame and TargetFrameSpellBar timers
local function UpdateCastTimers(self, elapsed)
	-- Player cast bar timer
	local cbf = CastingBarFrame
	if cbf and cbf.timer then
		if not cbf._timerDelay then cbf._timerDelay = 0 end
		cbf._timerDelay = cbf._timerDelay - elapsed
		if cbf._timerDelay <= 0 then
			if cbf.casting and cbf.maxValue and cbf.value then
				cbf.timer:SetText(format("%2.1f / %1.1f", max(cbf.maxValue - cbf.value, 0), cbf.maxValue))
			elseif cbf.channeling and cbf.value then
				cbf.timer:SetText(format("%.1f", max(cbf.value, 0)))
			else
				cbf.timer:SetText("")
			end
			cbf._timerDelay = 0.1
		end
	end

	-- Target cast bar timer
	local tsb = TargetFrameSpellBar
	if tsb and tsb.timer then
		if not tsb._timerDelay then tsb._timerDelay = 0 end
		tsb._timerDelay = tsb._timerDelay - elapsed
		if tsb._timerDelay <= 0 then
			if tsb.casting and tsb.maxValue and tsb.value then
				tsb.timer:SetText(format("%2.1f / %1.1f", max(tsb.maxValue - tsb.value, 0), tsb.maxValue))
			elseif tsb.channeling and tsb.value then
				tsb.timer:SetText(format("%.1f", max(tsb.value, 0)))
			else
				tsb.timer:SetText("")
			end
			tsb._timerDelay = 0.1
		end
	end

	-- If neither bar is actively casting/channeling, deactivate
	local playerActive = cbf and (cbf.casting or cbf.channeling)
	local targetActive = tsb and (tsb.casting or tsb.channeling)
	if not playerActive and not targetActive then
		-- Clear timer text
		if cbf and cbf.timer then cbf.timer:SetText("") end
		if tsb and tsb.timer then tsb.timer:SetText("") end
		self:Hide()
	end
end

castTimerFrame:SetScript("OnUpdate", UpdateCastTimers)

-- Event-driven activation: only enable OnUpdate during active casts
castTimerFrame:RegisterEvent("UNIT_SPELLCAST_START")
castTimerFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
castTimerFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
castTimerFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
castTimerFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
castTimerFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
castTimerFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
castTimerFrame:SetScript("OnEvent", function(self, event, unit)
	if event == "PLAYER_TARGET_CHANGED" then
		-- Check if new target is casting
		local tsb = TargetFrameSpellBar
		if tsb and (tsb.casting or tsb.channeling) then
			self:Show()
		end
		return
	end
	if unit ~= "player" and unit ~= "target" then return end
	if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
		self:Show()
	elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED"
		or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
		-- Let OnUpdate handle cleanup on next tick (in case other bar is still active)
	end
end)