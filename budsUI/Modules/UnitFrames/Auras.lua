local K, C, L, _ = select(2, ...):unpack()
if IsAddOnLoaded("Stuf") or IsAddOnLoaded("PitBull4") or IsAddOnLoaded("ShadowedUnitFrames") or IsAddOnLoaded("XPerl") then return end

local _G = _G
local GetName = GetName
local UnitIsFriend = UnitIsFriend
local hooksecurefunc = hooksecurefunc

-- Aura Constants
local AURA_BORDER_SIZE = 8
local AURA_CD_OFFSET = 1.5
local AURA_ROW_WIDTH = 100

local AURA_START_X = 3
local AURA_START_Y = 32
local AURA_OFFSET_Y_DEFAULT = 3
local BEAUTY_NUDGE = 3
local BEAUTY_SPACING = 1

-- AURAS
local function TargetAuraColour(self)
	-- CRITICAL: Only process TargetFrame and FocusFrame, reject everything else immediately
	if self ~= TargetFrame and self ~= FocusFrame then
		return
	end
	
	if not self or not self.unit then return end
	
	-- buffs
	for i = 1, MAX_TARGET_BUFFS do
		local bframe = _G[self:GetName().."Buff"..i]
		local bframecd = _G[self:GetName().."Buff"..i.."Cooldown"]
		local bframecount = _G[self:GetName().."Buff"..i.."Count"]
		if bframe then
			bframe:SetScale(1)
			K.CreateBorder(bframe, AURA_BORDER_SIZE)

			bframecd:ClearAllPoints()
			bframecd:SetPoint("TOPLEFT", bframe, AURA_CD_OFFSET, -AURA_CD_OFFSET)
			bframecd:SetPoint("BOTTOMRIGHT", bframe, -AURA_CD_OFFSET, AURA_CD_OFFSET)

			bframecount:ClearAllPoints()
			bframecount:SetPoint("CENTER", bframe, "BOTTOM", 0, 0)
			bframecount:SetJustifyH("CENTER")
			bframecount:SetFont(C.Media.Font, C.Media.Font_Size - 1, C.Media.Font_Style)
			bframecount:SetDrawLayer("OVERLAY", 7)
		end
	end
	-- debuffs
	for i = 1, MAX_TARGET_DEBUFFS do
		local dframe = _G[self:GetName().."Debuff"..i]
		local dframecd = _G[self:GetName().."Debuff"..i.."Cooldown"]
		local dframecount = _G[self:GetName().."Debuff"..i.."Count"]
		if dframe then
			K.CreateBorder(dframe, AURA_BORDER_SIZE)

			-- border colour
			local dname, _, _, _, dtype = UnitDebuff(self.unit, i)
			if dname then
				local colour = DebuffTypeColor[dtype] or DebuffTypeColor.none
				local auborder = _G[self:GetName().."Debuff"..i.."Border"]
				if auborder then
					auborder:Hide()
					auborder:SetAlpha(0)
				end
				dframe:SetBackdropBorderColor(colour.r, colour.g, colour.b)
			else
				dframe:SetBackdropBorderColor(unpack(C.Media.Border_Color))
			end

			if dframecd then -- pet doesn"t show cd?
				dframecd:ClearAllPoints()
				dframecd:SetPoint("TOPLEFT", dframe, AURA_CD_OFFSET, -AURA_CD_OFFSET)
				dframecd:SetPoint("BOTTOMRIGHT", dframe, -AURA_CD_OFFSET, AURA_CD_OFFSET)
			end

			if dframecount then -- debuffs show stacks if applicable
				dframecount:ClearAllPoints()
				dframecount:SetPoint("CENTER", dframe, "BOTTOM")
				dframecount:SetJustifyH("CENTER")
				dframecount:SetFont(C.Media.Font, C.Media.Font_Size - 1, C.Media.Font_Style)
			end
		end
	end
end

local beauty = _G["!BeautyCase"] or _G["BeautyCase"]


do
	-- Frame-specific hooks to prevent general unit frame taint.
	-- Blizzard's TargetFrameToT is handled separately in TargetOfTarget.lua to completely avoid taint.
	-- DO NOT hook Show on secure frames like TargetFrame/FocusFrame as it still taints other secure chains.
	
	-- Create event frame to monitor aura updates
	local auraWatcher = CreateFrame("Frame")
	auraWatcher:RegisterEvent("UNIT_AURA")
	auraWatcher:RegisterEvent("PLAYER_TARGET_CHANGED")
	auraWatcher:RegisterEvent("PLAYER_FOCUS_CHANGED")
	auraWatcher:SetScript("OnEvent", function(self, event, unit)
		-- CRITICAL: Only handle target and focus, never raid/party/pet units
		if event == "UNIT_AURA" then
			if unit ~= "target" and unit ~= "focus" then
				return
			end
		end
		
		if not InCombatLockdown() then
			if (event == "UNIT_AURA" and unit == "target") or event == "PLAYER_TARGET_CHANGED" then
				if TargetFrame and TargetFrame:IsVisible() then
					TargetAuraColour(TargetFrame)
				end
			elseif (event == "UNIT_AURA" and unit == "focus") or event == "PLAYER_FOCUS_CHANGED" then
				if FocusFrame and FocusFrame:IsVisible() then
					TargetAuraColour(FocusFrame)
				end
			end
		end
	end)
	
	-- Note: TargetFrameToT and FocusFrameToT are now handled via custom non-secure frames in TargetOfTarget.lua
end