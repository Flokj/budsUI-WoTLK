local K, C, L, _ = select(2, ...):unpack()
if C.ActionBar.Enable ~= true then return end

local tremove = table.remove
local CreateFrame = CreateFrame

local PREALLOCATED = 20
local pool = {}

local function onFinished(animGroup)
	pool[#pool + 1] = animGroup:GetParent():GetParent()
end

local function createAnimationFrame()
	local frame = CreateFrame("Frame")
	frame:SetFrameStrata("MEDIUM")

	local texture = frame:CreateTexture(nil, "OVERLAY")
	texture:SetTexture("Interface\\Cooldown\\star4")
	texture:SetAllPoints()
	texture:SetAlpha(0)
	texture:SetBlendMode("ADD")

	local animGroup = texture:CreateAnimationGroup()
	animGroup:SetScript("OnFinished", onFinished)

	local alpha = animGroup:CreateAnimation("Alpha")
	alpha:SetChange(1)
	alpha:SetDuration(0)
	alpha:SetOrder(1)

	local grow = animGroup:CreateAnimation("Scale")
	grow:SetScale(1.5, 1.5)
	grow:SetDuration(0)
	grow:SetOrder(1)

	local shrink = animGroup:CreateAnimation("Scale")
	shrink:SetScale(0, 0)
	shrink:SetDuration(0.2)
	shrink:SetOrder(2)

	local rotate = animGroup:CreateAnimation("Rotation")
	rotate:SetDegrees(90)
	rotate:SetDuration(0.2)
	rotate:SetOrder(2)

	frame.animGroup = animGroup
	return frame
end

for i = 1, PREALLOCATED do
	pool[i] = createAnimationFrame()
end

local function PlayClickAnimation(button)
	if C.ActionBar.ClickAnimation == false then
		return
	end

	local frame = tremove(pool) or createAnimationFrame()
	frame:SetParent(button)
	frame:SetAllPoints(button)
	frame.animGroup:Play()
end
K.PlayClickAnimation = PlayClickAnimation

local hooked = {}
local function HookButton(button)
	if not button or hooked[button] then return end
	hooked[button] = true
	button:HookScript("OnClick", PlayClickAnimation)
end

local function HookAllActionButtons()
	for i = 1, 12 do
		HookButton(_G["ActionButton" .. i])
		HookButton(_G["BonusActionButton" .. i])
		HookButton(_G["MultiBarBottomLeftButton" .. i])
		HookButton(_G["MultiBarBottomRightButton" .. i])
		HookButton(_G["MultiBarRightButton" .. i])
		HookButton(_G["MultiBarLeftButton" .. i])
	end
	for i = 1, 10 do
		HookButton(_G["PetActionButton" .. i])
		HookButton(_G["ShapeshiftButton" .. i])
	end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN")
	HookAllActionButtons()
end)
