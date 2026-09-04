local K, C, L, _ = select(2, ...):unpack()
if C.Skins.MinimapButtons ~= true or C.Minimap.Enable ~= true then return end

local match = string.match
local select = select
local find = string.find
local unpack = unpack

-- Skin addons icons on minimap
local buttons = {
	"Archy",
	"GatherMatePin",
	"GatherNote",
	"HandyNotesPin",
	"HelpOpenTicketButton",
	"MiniMapBattlefieldFrame",
	"MiniMapMailFrame",
	"MiniMapTrackingButton",
	"Minimap",
	"QuestMapPOI",
	"Spy_MapNoteList_mini",
	"TimeManagerClockButton",
	"WorldMapPOIFrame",
	"ZGVMarker",
	"poiWorldMapPOIFrame",
}

local function SkinButton(f)
	if not f or f:GetObjectType() ~= "Button" or f.isSkinned then return end

	local name = f:GetName()
	if name then
		for _, blacklist in pairs(buttons) do
			if name:match(blacklist) then return end
		end
	end

	f:SetPushedTexture(nil)
	f:SetHighlightTexture(nil)
	f:SetDisabledTexture(nil)
	f:SetSize(19, 19)

	for i = 1, f:GetNumRegions() do
		local region = select(i, f:GetRegions())
		if region and region:GetObjectType() == "Texture" and (region:IsVisible() or region:IsShown()) then
			local tex = tostring(region:GetTexture())

			if tex and (tex:find("Border") or tex:find("Background") or tex:find("AlphaMask")) then
				region:SetTexture(nil)
			else
				region:ClearAllPoints()
				region:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
				region:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
				region:SetTexCoord(0.1, 0.9, 0.1, 0.9)
				region:SetDrawLayer("ARTWORK")
				if name == "PS_MinimapButton" then
					region.SetPoint = K.Noop
				end
			end
		end
	end

	K.CreateBorder(f, 10)
	f:SetBackdrop(K.BorderBackdrop)
	f:SetBackdropColor(unpack(C.Media.Backdrop_Color))
	
	f.isSkinned = true
end

local function SkinLibDBIcon()
	local LibDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
	if LibDBIcon then
		if LibDBIcon.objects then
			for _, button in pairs(LibDBIcon.objects) do
				SkinButton(button)
			end
		end

		if not LibDBIcon.__skinHooked then
			hooksecurefunc(LibDBIcon, "Register", function(self, name)
				local button = (self.GetMinimapButton and self:GetMinimapButton(name)) or (self.objects and self.objects[name])
				if button then
					SkinButton(button)
				end
			end)
			LibDBIcon.__skinHooked = true
		end
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
	for i = 1, Minimap:GetNumChildren() do
		SkinButton(select(i, Minimap:GetChildren()))
	end

	SkinLibDBIcon()

	if WIM3MinimapButton and WIM3MinimapButton:GetNumRegions() < 9 then
		SkinButton(WIM3MinimapButton)
	end

	self:UnregisterAllEvents()
end)