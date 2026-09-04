local K, C, L, _ = select(2, ...):unpack()
if C.Skins.WeakAuras ~= true then return end

local pairs = pairs
local select = select
local CreateFrame = CreateFrame

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
	if not WeakAuras or not WeakAuras.regionTypes then return end

	local function Skin_WeakAuras(frame, ftype)
		if not frame then return end

		if not frame.border then
			K.CreateBorder(frame, 10, 1)
		end

		if frame.icon then
			frame.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
			frame.icon.SetTexCoord = K.Noop
		end

		if frame.bar then
			if frame.bar.fg then frame.bar.fg:SetTexture(C.Media.Texture) end
			if frame.bar.bg then frame.bar.bg:SetTexture(C.Media.Texture) end
		end

		if frame.stacks then
			K.SkinFont(frame.stacks)
			frame.stacks:SetFont(C.Media.Font, select(2, frame.stacks:GetFont()), C.Media.Font_Style)
		end

		if frame.timer then
			K.SkinFont(frame.timer)
			frame.timer:SetFont(C.Media.Font, select(2, frame.timer:GetFont()), C.Media.Font_Style)
		end

		if frame.text then
			K.SkinFont(frame.text)
			frame.text:SetFont(C.Media.Font, select(2, frame.text:GetFont()), C.Media.Font_Style)
		end
	end

	if WeakAuras.regionTypes.icon then
		local Create_Icon = WeakAuras.regionTypes.icon.create
		local Modify_Icon = WeakAuras.regionTypes.icon.modify

		WeakAuras.regionTypes.icon.create = function(parent, data)
			local region = Create_Icon(parent, data)
			Skin_WeakAuras(region, "icon")
			return region
		end

		WeakAuras.regionTypes.icon.modify = function(parent, region, data)
			Modify_Icon(parent, region, data)
			Skin_WeakAuras(region, "icon")
		end
	end

	if WeakAuras.regionTypes.aurabar then
		local Create_AuraBar = WeakAuras.regionTypes.aurabar.create
		local Modify_AuraBar = WeakAuras.regionTypes.aurabar.modify

		WeakAuras.regionTypes.aurabar.create = function(parent)
			local region = Create_AuraBar(parent)
			Skin_WeakAuras(region, "aurabar")
			return region
		end

		WeakAuras.regionTypes.aurabar.modify = function(parent, region, data)
			Modify_AuraBar(parent, region, data)
			Skin_WeakAuras(region, "aurabar")
		end
	end

	if WeakAuras.regions then
		for weakAura, data in pairs(WeakAuras.regions) do
			if data.regionType == "icon" or data.regionType == "aurabar" then
				Skin_WeakAuras(data.region, data.regionType)
			end
		end
	end
end)