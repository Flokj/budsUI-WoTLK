local K, C, L, _ = select(2, ...):unpack()

local _G = _G
local unpack = unpack
local pairs = pairs
local select = select
local IsAddOnLoaded = IsAddOnLoaded
local CreateFrame = CreateFrame
local UIParent = UIParent
local InCombatLockdown = InCombatLockdown
local hooksecurefunc = hooksecurefunc
local UnitIsPlayer = UnitIsPlayer
local UnitPlayerControlled = UnitPlayerControlled
local UnitClass, GetUnitName = UnitClass, GetUnitName
local CUSTOM_CLASS_COLORS = CUSTOM_CLASS_COLORS
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local UnitIsEnemy = UnitIsEnemy
local UnitIsTappedByPlayer = UnitIsTappedByPlayer
local UnitIsTapped = UnitIsTapped
local UnitReaction = UnitReaction
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsConnected = UnitIsConnected

-- Layout Constants
local PLAYER_TARGET_X = 51
local PLAYER_TARGET_Y = 3
local FOCUS_TOT_X = 34
local FOCUS_TOT_Y = 35
local RUNE_OFFSET_X = -1
local RUNE_OFFSET_Y = -5

local Unitframes = CreateFrame("Frame", "Unitframes", UIParent)

if not (IsAddOnLoaded("Stuf") or IsAddOnLoaded("PitBull4") or IsAddOnLoaded("ShadowedUnitFrames") or IsAddOnLoaded("XPerl")) then

	local PlayerAnchor = CreateFrame("Frame", "PlayerFrameAnchor", UIParent)
	if not InCombatLockdown() then
		PlayerAnchor:SetSize(146, 28)
		PlayerAnchor:SetPoint(unpack(C.Position.UnitFrames.Player))
	end

	local TargetAnchor = CreateFrame("Frame", "TargetFrameAnchor", UIParent)
	if not InCombatLockdown() then
		TargetAnchor:SetSize(146, 28)
		TargetAnchor:SetPoint(unpack(C.Position.UnitFrames.Target))
	end

	Unitframes:RegisterEvent("ADDON_LOADED")
	Unitframes:SetScript("OnEvent", function(self, event, addon)
		if (addon ~= "budsUI") then return end
		-- TAINT FIX: All frame manipulation must be outside combat
		if InCombatLockdown() then
			-- Defer to after combat
			local combatFrame = CreateFrame("Frame")
			combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
			combatFrame:SetScript("OnEvent", function(cf)
				cf:UnregisterAllEvents()
				-- Retry the initialization
				Unitframes:GetScript("OnEvent")(Unitframes, "ADDON_LOADED", "budsUI")
			end)
			return
		end
		
		-- UnitFrame_Update hook removed - caused PetFrame taint issues
		
		-- Font Helper
		local function SetUnitFont(fontString, sizeAdj)
			local size = C.Media.Font_Size + (sizeAdj or 0)
			if C.Unitframe.Outline then
				fontString:SetFont(C.Media.Font, size, C.Media.Font_Style)
				fontString:SetShadowOffset(0, -0)
			else
				fontString:SetFont(C.Media.Font, size)
				fontString:SetShadowOffset(K.Mult, -K.Mult)
			end
		end

		-- Font Strings Configuration
		local unitFramesFontStrings = {
			-- Generic Unit Font
			[1] = {
				PlayerName, TargetFrameTextureFrameName, FocusFrameTextureFrameName,
				PlayerFrameHealthBarText, PlayerFrameManaBarText,
				TargetFrameTextureFrameHealthBarText, TargetFrameTextureFrameManaBarText,
				FocusFrameTextureFrameHealthBarText, FocusFrameTextureFrameManaBarText,
				PetFrameHealthBarText, PetFrameManaBarText
			},
			-- Party Font (Size adjusted)
			[-3] = {
				PartyMemberFrame1HealthBarText, PartyMemberFrame1ManaBarText,
				PartyMemberFrame2HealthBarText, PartyMemberFrame2ManaBarText,
				PartyMemberFrame3HealthBarText, PartyMemberFrame3ManaBarText,
				PartyMemberFrame4HealthBarText, PartyMemberFrame4ManaBarText,
			},
			-- Level Font (Size adjusted)
			[1] = {
				PlayerLevelText, TargetFrameTextureFrameLevelText, FocusFrameTextureFrameLevelText
			}
		}

		for adj, frames in pairs(unitFramesFontStrings) do
			for _, fontString in ipairs(frames) do
				SetUnitFont(fontString, adj)
			end
		end


		-- Tweak Party Frame
		for i = 1, MAX_PARTY_MEMBERS do
			_G["PartyMemberFrame"..i]:SetScale(C.Unitframe.Scale)
		end
		PartyMemberBuffTooltip:Kill() -- I personally hate this shit.

		-- TAINT FIX: Tweak Player Frame (protected frame)
		PlayerFrame:SetMovable(true)
		PlayerFrame:ClearAllPoints()
		PlayerFrame:SetPoint("CENTER", PlayerFrameAnchor, "CENTER", -PLAYER_TARGET_X, PLAYER_TARGET_Y)
		PlayerFrame:SetMovable(false)

		-- Hide Pet Name.
		PetName:Hide()

		-- TAINT FIX: Tweak Target Frame (protected frame)
		TargetFrame:SetMovable(true)
		TargetFrame:ClearAllPoints()
		TargetFrame:SetPoint("CENTER", TargetFrameAnchor, "CENTER", PLAYER_TARGET_X, PLAYER_TARGET_Y)
		TargetFrame:SetMovable(false)
		-- Tweak Name Background
		TargetFrameNameBackground:SetTexture(0, 0, 0, 0.01)

		-- Tweak Focus Frame
		FocusFrame:ClearAllPoints()
		FocusFrame:SetPoint(unpack(C.Position.UnitFrames.Focus))
		-- Tweak Name Background
		FocusFrameNameBackground:SetTexture(0, 0, 0, 0.01)

		-- TAINT FIX: Scale frames (protected frames)
		for _, FrameScale in pairs({
			PlayerFrame,
			TargetFrame,
			FocusFrame,
		}) do
			FrameScale:SetScale(C.Unitframe.Scale)
		end

		-- Arena Frames Scaling
		local function SetArenaFrames()
			for i = 1, MAX_ARENA_ENEMIES do
				_G["ArenaEnemyFrame"..i]:SetScale(C.Unitframe.Scale)
				ArenaEnemyFrames:SetPoint(unpack(C.Position.UnitFrames.Arena))
			end
		end

		if IsAddOnLoaded("Blizzard_ArenaUI") then
			SetArenaFrames()
		else
			local f = CreateFrame("Frame")
			f:RegisterEvent("ADDON_LOADED")
			f:SetScript("OnEvent", function(self, event, addon)
				if (addon == "Blizzard_ArenaUI") then
					self:UnregisterEvent(event)
					SetArenaFrames()
				end
			end)
		end

		-- RuneFrame
		if K.Class == "DEATHKNIGHT" then
			RuneFrame:ClearAllPoints()
			RuneFrame:SetPoint("TOPLEFT", PlayerFrameManaBar, "BOTTOMLEFT", RUNE_OFFSET_X, RUNE_OFFSET_Y)
			for i = 1, 6 do
				_G["RuneButtonIndividual"..i]:SetScale(C.Unitframe.Scale)
			end
		end

		-- ComboFrame
		if K.Class == "ROGUE" or K.Class == "DRUID" then
			for i = 1, 5 do
				_G["ComboPoint"..i]:SetScale(C.Unitframe.Scale)
			end

			if C.Unitframe.ComboFrame == true then
				ComboFrame:Kill()
			end
		end

		self:UnregisterEvent("ADDON_LOADED")
	end)
end

-- Class Icons
if not InCombatLockdown() then
	if C.Unitframe.ClassIcon == true then
		-- TAINT FIX: Use UNIT_PORTRAIT_UPDATE events instead of Show hooks
		-- UnitFrame styling logic
		-- Secure frames like TargetFrame are hooked safely to avoid taint.
		-- TargetFrameToT is neutralized separately in TargetOfTarget.lua.
		
		local function UpdateClassIcon(self)
			if not self or not self.unit or not self.portrait then return end
			
			if UnitIsPlayer(self.unit) then
				local t = CLASS_ICON_TCOORDS[select(2, UnitClass(self.unit))]
				if t then
					self.portrait:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
					self.portrait:SetTexCoord(unpack(t))
				end
			else
				self.portrait:SetTexCoord(0, 1, 0, 1)
			end
		end
		
		-- Use UNIT_PORTRAIT_UPDATE and target change events instead of Show hooks
		local portraitWatcher = CreateFrame("Frame")
		portraitWatcher:RegisterEvent("UNIT_PORTRAIT_UPDATE")
		portraitWatcher:RegisterEvent("PLAYER_TARGET_CHANGED")
		portraitWatcher:RegisterEvent("PLAYER_FOCUS_CHANGED")
		portraitWatcher:SetScript("OnEvent", function(self, event, unit)
			if event == "UNIT_PORTRAIT_UPDATE" then
				if unit == "player" and PlayerFrame then
					UpdateClassIcon(PlayerFrame)
				elseif unit == "target" and TargetFrame then
					UpdateClassIcon(TargetFrame)
				elseif unit == "focus" and FocusFrame then
					UpdateClassIcon(FocusFrame)
				end
			elseif event == "PLAYER_TARGET_CHANGED" and TargetFrame then
				UpdateClassIcon(TargetFrame)
			elseif event == "PLAYER_FOCUS_CHANGED" and FocusFrame then
				UpdateClassIcon(FocusFrame)
			end
		end)
	end

	-- Class Color Bars
	-- Strategy: Hook AFTER Blizzard's UnitFrameHealthBar_Update to override
	-- the default UnitSelectionColor (green) with class colors in the SAME frame.
	-- The previous OnUpdate-queue approach caused 1-frame flicker because Blizzard
	-- set green synchronously and our fix ran 1 frame later.
	-- hooksecurefunc on a global function name (string) is taint-safe.
	-- SetStatusBarColor is NOT a protected operation.
	-- Class Color Bars
	if C.Unitframe.ClassHealth == true then
		local function colorHealthBar(statusbar, unit)
			if not statusbar or not unit then return end
			
			if UnitIsPlayer(unit) and UnitIsConnected(unit) then
				local _, class = UnitClass(unit)
				if class then
					local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
					if color then
						local cr, cg, cb = statusbar:GetStatusBarColor()
						-- Only set if current color differs by more than 1% to prevent feedback loops
						if math.abs(cr - color.r) > 0.01 or math.abs(cg - color.g) > 0.01 or math.abs(cb - color.b) > 0.01 then
							statusbar:SetStatusBarColor(color.r, color.g, color.b)
						end
					end
				end
			end
		end

		-- Map health bars to their unit IDs for fast lookup
		local barToUnit = {}
		barToUnit[PlayerFrameHealthBar] = "player"
		barToUnit[TargetFrameHealthBar] = "target"
		barToUnit[FocusFrameHealthBar]  = "focus"
		for i = 1, 4 do -- MAX_PARTY_MEMBERS
			local partyHealthBar = _G["PartyMemberFrame"..i.."HealthBar"]
			if partyHealthBar then barToUnit[partyHealthBar] = "party"..i end
		end

		-- Hook Blizzard's global health bar update function.
		-- Restricted to frames we explicitly care about to avoid noise.
		hooksecurefunc("UnitFrameHealthBar_Update", function(statusbar, unit)
			local u = barToUnit[statusbar]
			if u then
				colorHealthBar(statusbar, u)
			end
		end)
	end
end
-- Remove Portrait Damage Spam
if C.Unitframe.CombatFeedback == true then
	PlayerHitIndicator:Hide()
	PlayerHitIndicator:SetAlpha(0)
end

-- Remove Group Number Frame
if C.Unitframe.GroupNumber == true then
	PlayerFrameGroupIndicator:Hide()
	PlayerFrameGroupIndicator:SetAlpha(0)
end

-- Remove PvPIcons
if C.Unitframe.PvPIcon == true then
	PlayerPVPIcon:Kill()
	TargetFrameTextureFramePVPIcon:Kill()
	FocusFrameTextureFramePVPIcon:Kill()
	for i = 1, MAX_PARTY_MEMBERS do
		_G["PartyMemberFrame"..i.."PVPIcon"]:Kill()
	end
end