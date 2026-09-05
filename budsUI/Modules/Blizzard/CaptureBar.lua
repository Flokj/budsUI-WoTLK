local K, C, L, _ = select(2, ...):unpack()
if C.Blizzard.CaptureBar ~= true then return end

local _G = _G
local unpack = unpack
local select = select
local hooksecurefunc = hooksecurefunc
local CreateFrame, UIParent = CreateFrame, UIParent

-- Holder (ElvUI-style): bars anchor to it, it moves via /moveui,
-- position is saved by Core/Movers.lua into C.MoverPositions (+ profile)
local holder = CreateFrame("Frame", "CaptureBarAnchor", UIParent)
holder:SetSize(172, 16)
holder:SetPoint(unpack(C.Position.CaptureBar))

-- Skin (kept from old implementation)
local function SkinBar(bar, barname)
	if bar.skinned then return end

	local left = _G[barname.."LeftBar"]
	local right = _G[barname.."RightBar"]
	local middle = _G[barname.."MiddleBar"]
	if not left or not right or not middle then return end

	local region = select(4, bar:GetRegions())
	if region then region:Hide() end

	for _, name in ipairs({barname.."LeftLine", barname.."RightLine", barname.."LeftIconHighlight", barname.."RightIconHighlight"}) do
		local tex = _G[name]
		if tex then tex:SetAlpha(0) end
	end

	left:SetTexture(C.Media.Texture)
	right:SetTexture(C.Media.Texture)
	middle:SetTexture(C.Media.Texture)

	left:SetVertexColor(0.2, 0.6, 1)
	right:SetVertexColor(0.9, 0.2, 0.2)
	middle:SetVertexColor(0.8, 0.8, 0.8)

	if not bar.shadow then
		bar.shadow = CreateFrame("Frame", nil, bar)
		bar.shadow:SetFrameLevel(0)
		bar.shadow:SetBackdrop(K.ShadowBackdrop)
		bar.shadow:SetPoint("TOPLEFT", left, -2, 2)
		bar.shadow:SetPoint("BOTTOMRIGHT", right, 2, -2)
		bar.shadow:SetBackdropBorderColor(0, 0, 0, 1)
	end

	bar.skinned = true
end

-- Anchor one bar: first to holder (locked against Blizzard moves),
-- the rest stacked below the previous one (ElvUI-style)
local function captureBarUpdate(id)
	local barname = "WorldStateCaptureBar"..id
	local bar = _G[barname]
	if not bar then return end

	SkinBar(bar, barname)

	bar:ClearAllPoints()
	if id == 1 then
		-- Lock first bar on the holder: block Blizzard's SetPoint,
		-- reposition through the saved original so our own updates still work
		if not bar._OrigSetPoint then bar._OrigSetPoint = bar.SetPoint end
		bar._OrigSetPoint(bar, "CENTER", holder, "CENTER", 0, 0)
		bar.SetPoint = K.Noop
	else
		local prev = _G["WorldStateCaptureBar"..(id - 1)]
		if prev then
			bar:SetPoint("TOPLEFT", prev, "TOPLEFT", 0, -45)
		else
			bar:SetPoint("CENTER", holder, "CENTER", 0, 0)
		end
	end
end

local function CaptureUpdateAll()
	if not _G.NUM_EXTENDED_UI_FRAMES then return end
	for id = 1, _G.NUM_EXTENDED_UI_FRAMES do
		captureBarUpdate(id)
	end
end

-- 3.3.5 path: Blizzard repositions capture bars inside this update
hooksecurefunc("WorldStateAlwaysUpFrame_Update", CaptureUpdateAll)

-- Newer clients path (ElvUI-style): hook bar creation directly when available
if _G.ExtendedUI and _G.ExtendedUI["CAPTUREPOINT"] then
	hooksecurefunc(_G.ExtendedUI["CAPTUREPOINT"], "create", captureBarUpdate)
end

-- Initial pass for bars that already exist at load
CaptureUpdateAll()
