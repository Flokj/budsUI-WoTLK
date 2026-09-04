local K, C, _ = select(2, ...):unpack()
if C.Unitframe.SmoothBars ~= true then return end

local CreateFrame = CreateFrame
local _G = _G
local abs = math.abs
local max = math.max
local pairs, ipairs = pairs, ipairs

local SmoothFrame = CreateFrame("Frame")
local Smoothing = {}

local BarsToSmooth = { -- SMOOTH ANIM ON PLAYER, TARGET, XP, REP, SKILL STATUSBARS
	-- ALSO NAMEPLATES
	PlayerFrameHealthBar, PlayerFrameManaBar,
	TargetFrameHealthBar, TargetFrameManaBar,
	MainMenuExpBar, ReputationWatchStatusBar,
	PartyMemberFrame1HealthBar, PartyMemberFrame1ManaBar,
	PartyMemberFrame2HealthBar, PartyMemberFrame2ManaBar,
	PartyMemberFrame3HealthBar, PartyMemberFrame3ManaBar,
	PartyMemberFrame4HealthBar, PartyMemberFrame4ManaBar,
	ReputationBar1, ReputationBar2, ReputationBar3, ReputationBar4, ReputationBar5,
	ReputationBar6, ReputationBar7, ReputationBar8, ReputationBar9, ReputationBar10,
	ReputationBar11, ReputationBar12, ReputationBar13, ReputationBar14, ReputationBar15,
	SkillRankFrame1, SkillRankFrame2, SkillRankFrame3, SkillRankFrame4,
	SkillRankFrame5, SkillRankFrame6, SkillRankFrame7, SkillRankFrame8,
	SkillRankFrame9, SkillRankFrame10, SkillRankFrame11, SkillRankFrame12,
}

local isPlate = function(frame)
	local overlayRegion = frame:GetRegions()
	if not overlayRegion or overlayRegion:GetObjectType() ~= "Texture"
	or overlayRegion:GetTexture() ~= [[Interface\Tooltips\Nameplate-Border]] then
		return false
	end
	return true
end

local function AnimationTick()
	for bar, value in pairs(Smoothing) do
		local cur = bar:GetValue()
		local new = cur + ((value - cur) / 3)
		if new ~= new then new = value end
		if cur == value or abs(new - value) < 2 then
			bar:SetValue_(value)
			Smoothing[bar] = nil
		else
			bar:SetValue_(new)
		end
	end
end

local function SmoothSetValue(self, value)
	local _, max = self:GetMinMaxValues()
	if value == self:GetValue() or self._max and self._max ~= max then
		Smoothing[self] = nil
		self:SetValue_(value)
	else
		Smoothing[self] = value
	end
	self._max = max
end



local function SmoothBar(bar)
	if not bar.SetValue_ then
		bar.SetValue_ = bar.SetValue
		bar.SetValue = SmoothSetValue
	end
end

local function ResetBar(bar)
	if bar.SetValue_ then
		bar.SetValue = bar.SetValue_
		bar.SetValue_ = nil
	end
end

local plateScanTimer = 0
local lastChildren = 0
local hasActiveAnimations = false

local function CheckActiveAnimations()
	return next(Smoothing) ~= nil
end

SmoothFrame:SetScript("OnUpdate", function(self, elapsed)
	-- Only run if we have active animations
	if not hasActiveAnimations and not CheckActiveAnimations() then
		return
	end
	
	plateScanTimer = plateScanTimer + elapsed
	if plateScanTimer > 0.5 then
		plateScanTimer = 0
		local numChildren = WorldFrame:GetNumChildren()
		if numChildren ~= lastChildren then
			for i = lastChildren + 1, numChildren do
				local plate = select(i, WorldFrame:GetChildren())
				if plate and isPlate(plate) then
					local v = plate:GetChildren()
					if v and v:GetObjectType() == "StatusBar" then
						SmoothBar(v)
					end
				end
			end
			lastChildren = numChildren
		end

		-- Clean up Smoothing table to prevent leaks or dead references
		for bar in pairs(Smoothing) do
			if not bar:IsVisible() or not bar:GetParent() then
				Smoothing[bar] = nil
			end
		end
	end
	
	AnimationTick()
	hasActiveAnimations = CheckActiveAnimations()
end)


for _, v in pairs (BarsToSmooth) do if v then SmoothBar(v) end end