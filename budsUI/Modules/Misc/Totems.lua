local K, C, L, _ = select(2, ...):unpack()
if K.Class ~= "SHAMAN" then return end

-- Skinned shaman totems, KkthnxUI-style (border + cooldown swipe).
-- WotLK note: no totemPool here (Cata+ API), we reuse Blizzard
-- TotemFrameTotem1-4 buttons.
-- Runs on PLAYER_LOGIN so Core (Movers/Border) is fully loaded.

local _G = _G
local unpack = unpack
local CreateFrame = CreateFrame
local GetTotemInfo = GetTotemInfo

local totemSize = 32
local totemSpacing = 8
local totemWidth = (totemSize * 4) + (totemSpacing * 3)

local function Totem_UpdateCooldown(i)
	local button = _G["TotemFrameTotem"..i]
	if not button or not button.cd then return end
	local haveTotem, _, start, duration = GetTotemInfo(i)
	if haveTotem and start and start > 0 and duration and duration > 0 then
		button.cd:SetCooldown(start, duration)
		button.cd:Show()
	else
		button.cd:Hide()
	end
end

local function Totem_UpdateAll()
	for i = 1, 4 do Totem_UpdateCooldown(i) end
end

local function Totem_Init()
	TotemFrame:SetParent(UIParent)
	TotemFrame:SetWidth(totemWidth)
	TotemFrame:SetHeight(totemSize)
	TotemFrame:SetClampedToScreen(true)

	K.CreateMover(TotemFrame, "TotemBar", "Totems", {"BOTTOM", UIParent, "TOP", -370, -436}, totemWidth, totemSize)

	for i = 1, 4 do
		local button = _G["TotemFrameTotem"..i]
		if button then
			select(2, button:GetChildren()):Hide()
			select(2, button:GetChildren()).Show = function() end
			_G["TotemFrameTotem"..i.."IconTexture"]:SetTexCoord(unpack(K.TexCoords))
			_G["TotemFrameTotem"..i.."Background"]:Hide()
			_G["TotemFrameTotem"..i.."Background"].Show = function() end
			button:SetWidth(totemSize)
			button:SetHeight(totemSize)
			_G["TotemFrameTotem"..i.."Icon"]:SetWidth(totemSize)
			_G["TotemFrameTotem"..i.."Icon"]:SetHeight(totemSize)
			-- Cooldown numbers come from our Cooldown module swipe text
			_G["TotemFrameTotem"..i.."Duration"]:SetAlpha(0)
			button:ClearAllPoints()
			if i == 1 then
				button:SetPoint("LEFT", TotemFrame, "LEFT", 0, 0)
			else
				button:SetPoint("LEFT", _G["TotemFrameTotem"..(i-1)], "RIGHT", totemSpacing, 0)
			end

			if not button.border then
				K.CreateBorder(button, 10, 1)
				button.border = true
			end
		end
	end

	local updater = CreateFrame("Frame")
	updater:RegisterEvent("PLAYER_TOTEM_UPDATE")
	updater:RegisterEvent("PLAYER_ENTERING_WORLD")
	updater:SetScript("OnEvent", Totem_UpdateAll)
	Totem_UpdateAll()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN")
	Totem_Init()
end)
