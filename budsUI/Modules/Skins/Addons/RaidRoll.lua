local K, C, L, _ = select(2, ...):unpack()
if C.Skins.RaidRoll ~= true then return end

local _G = _G
local pairs = pairs
local select = select
local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc

-- RaidRoll skin for budsUI (ported from ElvUI_AddOnSkins raidRoll.lua)
-- Covers RaidRoll roll frame + RaidRoll_LootTracker loot frame

local function SkinFrame(frame)
	if not frame or frame.styled then return end
	frame:StripTextures()
	frame:CreateBackdrop(2)
	frame:SetBackdropColor(unpack(C.Media.Backdrop_Color))
	frame.styled = true
end

local function SkinButton(button)
	if not button or button.styled then return end
	button:StripTextures()
	button:CreateBackdrop(2)
	if button.SetNormalTexture then button:SetNormalTexture("") end
	if button.SetHighlightTexture then button:SetHighlightTexture("") end
	if button.SetPushedTexture then button:SetPushedTexture("") end
	if button.SetDisabledTexture then button:SetDisabledTexture("") end
	local normal = button:GetFontString()
	if normal then K.SkinFont(normal) end
	for i = 1, button:GetNumRegions() do
		local region = select(i, button:GetRegions())
		if region and region:GetObjectType() == "FontString" then
			K.SkinFont(region)
		end
	end
	button:HookScript("OnEnter", function(self)
		if self.backdrop then self.backdrop:SetBackdropBorderColor(K.Color.r, K.Color.g, K.Color.b) end
	end)
	button:HookScript("OnLeave", function(self)
		if self.backdrop then self.backdrop:SetBackdropBorderColor(unpack(C.Media.Border_Color)) end
	end)
	button.styled = true
end

local function SkinCloseButton(button, parent)
	if not button or button.styled then return end
	if button.SetNormalTexture then button:SetNormalTexture("") end
	if button.SetHighlightTexture then button:SetHighlightTexture("") end
	if button.SetPushedTexture then button:SetPushedTexture("") end
	if not button.text then
		button:FontString("text", C.Media.Font, C.Media.Font_Size)
		button.text:SetPoint("CENTER")
		button.text:SetText("X")
	end
	button:HookScript("OnEnter", function(self) self.text:SetTextColor(K.Color.r, K.Color.g, K.Color.b) end)
	button:HookScript("OnLeave", function(self) self.text:SetTextColor(1, 1, 1) end)
	if parent then button:SetFrameLevel(parent:GetFrameLevel() + 2) end
	button.styled = true
end

local function SkinCheckBox(box)
	if not box or box.styled then return end
	box:StripTextures()
	box:CreateBackdrop(2)
	box:SetSize(16, 16)
	local label = _G[box:GetName() .. "Text"]
	if label then K.SkinFont(label) end
	box.styled = true
end

local function SkinSlider(slider)
	if not slider or slider.styled then return end
	slider:StripTextures()
	slider:CreateBackdrop(2)
	local thumb = slider:GetThumbTexture()
	if thumb then
		thumb:SetTexture(C.Media.Texture)
		thumb:SetVertexColor(K.Color.r, K.Color.g, K.Color.b)
	end
	slider:SetHitRectInsets(0, 0, 0, 0)
	slider.styled = true
end

local function SkinFonts(...)
	for i = 1, select("#", ...) do
		local fs = select(i, ...)
		if fs and fs:GetObjectType() == "FontString" then
			K.SkinFont(fs)
		end
	end
end

local function SkinRaidRoll()
	if _G.RR_RollFrameSkinned then return end
	if not _G.RR_RollFrame then return end

	SkinFrame(_G.RR_RollFrame)
	if _G.RR_NAME_FRAME then SkinFrame(_G.RR_NAME_FRAME) end
	if _G.RR_Frame then
		SkinFrame(_G.RR_Frame)
		_G.RR_Frame:Width(185)
		_G.RR_Frame:Point("TOP", _G.RR_RollFrame, "BOTTOM", 0, 1)
	end

	if _G.RR_Close_Button then SkinCloseButton(_G.RR_Close_Button, _G.RR_RollFrame) end

	if _G.RaidRoll_Slider_ID then SkinSlider(_G.RaidRoll_Slider_ID) end

	SkinButton(_G.RaidRoll_AnnounceWinnerButton)
	SkinButton(_G.RR_Roll_5SecAndAnnounce)
	SkinButton(_G.RR_Roll_RollButton)
	SkinButton(_G.RR_Last)
	SkinButton(_G.RR_Clear)
	SkinButton(_G.RR_Next)
	SkinButton(_G.RaidRoll_OptionButton)
	SkinButton(_G.Raid_Roll_ClearSymbols)
	SkinButton(_G.Raid_Roll_ClearRolls)
	SkinButton(_G.RaidRoll_ExtraOptionButton)

	-- Same layout fixes as ElvUI skin
	if _G.RR_Roll_5SecAndAnnounce then
		_G.RR_Roll_5SecAndAnnounce:ClearAllPoints()
		_G.RR_Roll_5SecAndAnnounce:Point("BOTTOM", 0, 31)
	end
	if _G.RR_Clear then _G.RR_Clear:Point("BOTTOM", 0, 8) end
	if _G.RR_Last then _G.RR_Last:Point("BOTTOM", -45, 8) end
	if _G.RR_Roll_RollButton then _G.RR_Roll_RollButton:Point("BOTTOMRIGHT", _G.RR_RollFrame, "BOTTOM", -65, 8) end
	if _G.RR_Next then _G.RR_Next:Point("BOTTOM", 45, 8) end
	if _G.RaidRoll_OptionButton then
		_G.RaidRoll_OptionButton:Size(20)
		_G.RaidRoll_OptionButton:Point("BOTTOM", 75, 8)
	end

	-- Checkboxes above the options frame level so they stay clickable
	if _G.RR_Frame then
		local level = _G.RR_Frame:GetFrameLevel()
		if _G.RaidRoll_Catch_All then _G.RaidRoll_Catch_All:SetFrameLevel(level + 2) end
		if _G.RaidRoll_Allow_All then _G.RaidRoll_Allow_All:SetFrameLevel(level + 2) end
		if _G.RaidRollCheckBox_ExtraRolls then _G.RaidRollCheckBox_ExtraRolls:SetFrameLevel(level + 2) end
	end
	SkinCheckBox(_G.RaidRoll_Catch_All)
	SkinCheckBox(_G.RaidRoll_Allow_All)
	SkinCheckBox(_G.RaidRollCheckBox_ExtraRolls)

	-- Symbol buttons next to roller names
	for i = 1, 5 do
		local f = _G["Raid_Roll_SetSymbol" .. i]
		if f then
			f:ClearAllPoints()
			f:Point("TOPLEFT", _G["RR_RollerPos" .. i], "TOPRIGHT", -15, -1)
			f:Point("BOTTOMRIGHT", _G["RR_Rolled" .. i], "BOTTOMLEFT", 45, -1)
			local highlight = f:GetHighlightTexture()
			if highlight then
				highlight:SetTexture(C.Media.Texture)
				highlight:SetVertexColor(0.9, 0.9, 0.9, 0.35)
			end
			SkinFonts(f:GetFontString())
		end
	end

	-- Fonts
	if C.General.ReplaceBlizzardFonts and GetLocale() ~= "zhCN" then
		for i = 1, 5 do
			local roller = _G["RR_Roller" .. i]
			if roller then
				K.SkinFont(roller)
				roller.SetFont = K.Noop
			end
		end
	end

	_G.RR_RollFrameSkinned = true
end

local function SkinLootTracker()
	if _G.RR_LootFrameSkinned then return end
	if not _G.RR_LOOT_FRAME then return end

	SkinFrame(_G.RR_LOOT_FRAME)

	if _G.RaidRoll_Loot_Slider_ID then SkinSlider(_G.RaidRoll_Loot_Slider_ID) end

	SkinButton(_G.RR_Loot_LinkLootButton)
	SkinButton(_G.RR_Loot_ButtonClear)
	SkinButton(_G.RR_Loot_ButtonFirst)
	SkinButton(_G.RR_Loot_ButtonPrev)
	SkinButton(_G.RR_Loot_ButtonNext)
	SkinButton(_G.RR_Loot_ButtonLast)

	for i = 1, 4 do
		SkinButton(_G["RR_Loot_Announce_1_Button_" .. i])
		SkinButton(_G["RR_Loot_Announce_2_Button_" .. i])
		SkinButton(_G["RR_Loot_Announce_3_Button_" .. i])
		SkinButton(_G["RR_Loot_RaidRollButton_" .. i])
		for _, name in pairs({
			"RR_Loot_Announce_1_Button_" .. i,
			"RR_Loot_Announce_2_Button_" .. i,
			"RR_Loot_Announce_3_Button_" .. i,
			"RR_Loot_RaidRollButton_" .. i,
		}) do
			local b = _G[name]
			if b then b:Show() end
		end
	end

	for i = 1, _G.RR_LOOT_FRAME:GetNumChildren() do
		local child = select(i, _G.RR_LOOT_FRAME:GetChildren())
		if child and child:IsObjectType("Button") and child:GetName() == "Close_Button" then
			SkinCloseButton(child, _G.RR_LOOT_FRAME)
			break
		end
	end

	_G.RR_LootFrameSkinned = true
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, addon)
	if event == "PLAYER_LOGIN" then
		if IsAddOnLoaded("RaidRoll") then SkinRaidRoll() end
		if IsAddOnLoaded("RaidRoll_LootTracker") then SkinLootTracker() end
	elseif event == "ADDON_LOADED" then
		if addon == "RaidRoll" then
			SkinRaidRoll()
		elseif addon == "RaidRoll_LootTracker" then
			SkinLootTracker()
		end
		if _G.RR_RollFrameSkinned and (not IsAddOnLoaded("RaidRoll_LootTracker") or _G.RR_LootFrameSkinned) then
			self:UnregisterEvent("ADDON_LOADED")
		end
	end
end)
