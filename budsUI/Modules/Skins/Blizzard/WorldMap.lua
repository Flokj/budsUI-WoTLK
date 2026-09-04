local K, C, L, _ = select(2, ...):unpack()
if C.Skins.WorldMap ~= true or IsAddOnLoaded("Mapster") == true or IsAddOnLoaded("Aurora") then return end

local floor = math.floor
local select = select
local CreateFrame = CreateFrame
local GetPlayerMapPosition = GetPlayerMapPosition

-- Hilfsfunktion zum Ermitteln des korrekten Skalierungs-Keys (Big vs Mini)
local function GetMapScaleKey()
	local windowedSize = WORLDMAP_WINDOWED_SIZE or 1
	if WORLDMAP_SETTINGS and WORLDMAP_SETTINGS.size == windowedSize then
		return "WorldMapScaleMini"
	else
		return "WorldMapScale"
	end
end

-- Hilfsfunktion zum Speichern von Position und Größe
local function SaveWorldMapSettings()
	if not budsUIData or not budsUIData.Profiles then return end
	
	local activeProfile = K.GetActiveProfile()
	if not activeProfile or not budsUIData.Profiles[activeProfile] then return end
	local profile = budsUIData.Profiles[activeProfile]

	-- Position
	local ap, _, rp, x, y = WorldMapFrame:GetPoint()
	if not profile.MoverPositions then profile.MoverPositions = {} end
	profile.MoverPositions["WorldMapFrame"] = {ap, "UIParent", rp, x, y}
	C.MoverPositions["WorldMapFrame"] = {ap, "UIParent", rp, x, y}

	-- Scale
	local scaleKey = GetMapScaleKey()
	local scale = WorldMapFrame:GetScale()
	if not profile.Skins then profile.Skins = {} end
	profile.Skins[scaleKey] = scale
	if not C.Skins then C.Skins = {} end
	C.Skins[scaleKey] = scale
end

-- Hilfsfunktion für die Karten-Konfiguration (Vermeidung von Redundanz)
local function SetupWorldMapLayout()
	if BlackoutWorld:IsShown() then
		BlackoutWorld:Hide()
	end
	
	-- Load saved scale and position if available
	local scaleKey = GetMapScaleKey()
	local scale = C.Skins[scaleKey] or (scaleKey == "WorldMapScaleMini" and 1.0 or 0.80)
	WorldMapFrame:SetScale(scale)

	-- Stylization
	if not WorldMapFrame.backdrop then
		WorldMapFrame:StripTextures()
		WorldMapFrame:CreateBackdrop("Transparent")
		WorldMapFrame.backdrop:SetPoint("TOPLEFT", WorldMapDetailFrame, "TOPLEFT", -2, 2)
		WorldMapFrame.backdrop:SetPoint("BOTTOMRIGHT", WorldMapDetailFrame, "BOTTOMRIGHT", 2, -2)
	end
	
	WorldMapFrame:SetMovable(true)
	WorldMapFrame:EnableMouse(true)
	WorldMapFrame:RegisterForDrag("LeftButton")
	WorldMapFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
	WorldMapFrame:SetScript("OnDragStop", function(self) 
		self:StopMovingOrSizing()
		self:SetUserPlaced(true)
		SaveWorldMapSettings()
	end)

	-- Resize Handle
	if not WorldMapFrame.Resizer then
		local resizer = CreateFrame("Button", nil, WorldMapFrame)
		resizer:SetSize(16, 16)
		resizer:SetPoint("BOTTOMRIGHT", WorldMapFrame.backdrop, "BOTTOMRIGHT", 0, 0)
		resizer:SetNormalTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Up]])
		resizer:SetPushedTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Down]])
		resizer:SetHighlightTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Highlight]])
		
		resizer:SetScript("OnMouseDown", function()
			resizer.isResizing = true
		end)
		resizer:SetScript("OnMouseUp", function()
			resizer.isResizing = nil
			SaveWorldMapSettings()
		end)
		
		-- Custom Resizing logic
		resizer:SetScript("OnDragStart", function()
			resizer.isResizing = true
		end)
		resizer:SetScript("OnDragStop", function()
			resizer.isResizing = nil
			SaveWorldMapSettings()
		end)
		
		resizer:HookScript("OnUpdate", function(self)
			if self.isResizing then
				local x, y = GetCursorPosition()
				local frameScale = WorldMapFrame:GetEffectiveScale()
				
				-- Calculation: Coordinate of the cursor relative to the frame's anchor
				-- Width is determined by the distance from the left edge
				local left, top = WorldMapFrame:GetLeft(), WorldMapFrame:GetTop()
				local newWidth = (x / frameScale) - left
				
				-- Scale calculation: NewWidth / OriginalWidth_unscaled
				local newScale = newWidth / (WorldMapFrame:GetWidth() / WorldMapFrame:GetScale())
				newScale = math.max(0.4, math.min(1.5, newScale))
				
				WorldMapFrame:SetScale(newScale)
				
				-- Invert scale for tooltips so they don't look distorted
				WorldMapTooltip:SetScale(1 / newScale)
			end
		end)
		resizer:RegisterForDrag("LeftButton")
		
	end
	
	-- MouseWheel Zoom
	WorldMapFrame:EnableMouseWheel(true)
	WorldMapFrame:SetScript("OnMouseWheel", function(self, delta)
		local currentScale = self:GetScale()
		local newScale = currentScale + (delta * 0.05)
		newScale = math.max(0.4, math.min(1.5, newScale))

		self:SetScale(newScale)
		WorldMapTooltip:SetScale(1 / newScale)
		SaveWorldMapSettings()
	end)

	WorldMapFrame:EnableKeyboard(false)
	WorldMapFrame:SetAttribute("UIPanelLayout-area", "center")
	WorldMapFrame:SetAttribute("UIPanelLayout-allowOtherPanels", true)
	UIPanelWindows["WorldMapFrame"] = {area = "center", pushable = 0} -- Restored to prevent "attempt to index field WorldMapFrame (a nil value)" in Blizzard code
end

local function InitializeMap()
	-- Konflikt-Warnung
	if IsAddOnLoaded("Mapster") or IsAddOnLoaded("Aurora") then
		K.Print("|cffff0000budsUI:|r WorldMap-Skin deaktiviert, da Mapster oder Aurora erkannt wurde.")
		return
	end

	-- Initiales Layout setzen
	SetupWorldMapLayout()

	-- Sicherstellen, dass der schwarze Hintergrund versteckt bleibt und das Layout zentriert ist
	hooksecurefunc(BlackoutWorld, "Show", SetupWorldMapLayout)

	-- Karte skalieren und Transparenz setzen
	hooksecurefunc(WorldMapFrame, "Show", function(self)
		-- TAINT FIX: Skip secure operations during combat
		if InCombatLockdown() then return end
		
		-- Restore scale from config
		local scaleKey = GetMapScaleKey()
		local scale = C.Skins[scaleKey] or (scaleKey == "WorldMapScaleMini" and 1.0 or 0.80)
		self:SetScale(scale)
		self:SetAlpha(0.90)
		WorldMapTooltip:SetScale(1 / scale)
	end)

	-- Update scale when toggling modes (3.3.5 function names)
	if WorldMap_ToggleSizeUp then
		hooksecurefunc("WorldMap_ToggleSizeUp", function()
			-- TAINT FIX: Skip during combat
			if InCombatLockdown() then return end
			
			local scaleKey = GetMapScaleKey()
			local scale = C.Skins[scaleKey] or (scaleKey == "WorldMapScaleMini" and 1.0 or 0.80)
			WorldMapFrame:SetScale(scale)
			WorldMapTooltip:SetScale(1 / scale)
		end)
	end
	if WorldMap_ToggleSizeDown then
		hooksecurefunc("WorldMap_ToggleSizeDown", function()
			-- TAINT FIX: Skip during combat
			if InCombatLockdown() then return end
			
			local scaleKey = GetMapScaleKey()
			local scale = C.Skins[scaleKey] or (scaleKey == "WorldMapScaleMini" and 1.0 or 0.80)
			WorldMapFrame:SetScale(scale)
			WorldMapTooltip:SetScale(1 / scale)
		end)
	end

	-- Koordinaten-Frame initialisieren
	local WorldMap_Coords = CreateFrame("Frame", "budsUI_CoordsFrame", WorldMapFrame)
	local Font_Height = select(2, WorldMapQuestShowObjectivesText:GetFont()) * 1.1
	WorldMap_Coords:SetFrameLevel(WorldMapDetailFrame:GetFrameLevel() + 2)
	WorldMap_Coords:FontString("PlayerText", C.Media.Font, Font_Height, C.Media.Font_Style)
	WorldMap_Coords:FontString("MouseText", C.Media.Font, Font_Height, C.Media.Font_Style)
	
	local textColor = WorldMapQuestShowObjectivesText:GetTextColor()
	WorldMap_Coords.PlayerText:SetTextColor(textColor)
	WorldMap_Coords.MouseText:SetTextColor(textColor)
	
	WorldMap_Coords.PlayerText:SetPoint("BOTTOMLEFT", WorldMapDetailFrame, "BOTTOMLEFT", 5, 5)
	WorldMap_Coords.MouseText:SetPoint("BOTTOMLEFT", WorldMap_Coords.PlayerText, "TOPLEFT", 0, 5)

	local timeElapsed = 0
	WorldMapFrame:HookScript("OnUpdate", function(self, elapsed)
		if not self:IsShown() then return end
		timeElapsed = timeElapsed + elapsed

		if timeElapsed >= 0.1 then
			-- PLAYER Coordinates calculation
			local x, y = GetPlayerMapPosition("player")
			if x and y and x > 0 and y > 0 then
				WorldMap_Coords.PlayerText:SetFormattedText("%s: %d, %d", PLAYER, floor(100 * x), floor(100 * y))
			else
				WorldMap_Coords.PlayerText:SetText("")
			end

			-- MOUSE Coordinates calculation
			-- We need to account for the scale of the detail frame independently of UIParent scale
			local scale = WorldMapDetailFrame:GetEffectiveScale()
			local width = WorldMapDetailFrame:GetWidth()
			local height = WorldMapDetailFrame:GetHeight()
			local centerX, centerY = WorldMapDetailFrame:GetCenter()
			local cursorX, cursorY = GetCursorPosition()
			
			if centerX and centerY and cursorX and cursorY then
				-- Normalized coordinates within the Map border
				local adjustedX = (cursorX / scale - (centerX - (width / 2))) / width
				local adjustedY = (centerY + (height / 2) - cursorY / scale) / height

				if (adjustedX >= 0 and adjustedY >= 0 and adjustedX <= 1 and adjustedY <= 1) then
					WorldMap_Coords.MouseText:SetFormattedText("%s: %d, %d", MOUSE_LABEL, floor(100 * adjustedX), floor(100 * adjustedY))
				else
					WorldMap_Coords.MouseText:SetText("")
				end
			else
				WorldMap_Coords.MouseText:SetText("")
			end

			timeElapsed = 0
		end
	end)

	-- Dropdown-Fixes
	WorldMapContinentDropDownButton:HookScript("OnClick", function() DropDownList1:SetScale(C.General.UIScale) end)
	WorldMapZoneDropDownButton:HookScript("OnClick", function(self)
		DropDownList1:SetScale(C.General.UIScale)
		DropDownList1:ClearAllPoints()
		DropDownList1:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 2, -4)
	end)
end

-- Sicherer Start außerhalb des Kampfes
if InCombatLockdown() then
	local initFrame = CreateFrame("Frame")
	initFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	initFrame:SetScript("OnEvent", function(self)
		InitializeMap()
		self:UnregisterAllEvents()
	end)
else
	InitializeMap()
end