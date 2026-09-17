local K, C, L = select(2, ...):unpack()

-- If you're saving frame positions, use "UIParent", not UIParent
C["Position"] = {
	["Achievements"] = {"TOP", "UIParent", "TOP", 0, -22},
	["BGScore"] = {"CENTER", "UIParent", "TOPLEFT", 150, -210},
	["Bag"] = {"RIGHT", "UIParent", "RIGHT", -140, -20},
	["Bank"] = {"LEFT", "UIParent", "LEFT", 23, 150},
	["BnetPopup"] = {"BOTTOMLEFT", "ChatFrame1", "TOPLEFT", 4, 54},
	["BottomBars"] = {"BOTTOM", "UIParent", "BOTTOM", 0, 5},
	["CaptureBar"] = {"CENTER", "UIParent", "CENTER", 0, 250},
	["Chat"] = {"BOTTOMLEFT", "UIParent", "BOTTOMLEFT", 3, 5},
	["GroupLoot"] = {"BOTTOM", "UIParent", "BOTTOM", 420, 650},
	["Loot"] = {"TOPLEFT", "UIParent", "CENTER", 280, 50},
	["Minimap"] = {"TOPRIGHT", "UIParent", "TOPRIGHT", -7, -7},
	["MinimapButtons"] = {"TOPRIGHT", "Minimap", "TOPLEFT", -3, 2},
	["PetHorizontal"] = {"CENTER", "UIParent", "CENTER", 60, 440},
	["PlayerBuffs"] = {"TOPRIGHT", "Minimap", "TOPLEFT", -26, 2},
	["PowerBar"] = {"BOTTOM", "ActionBarAnchor", "TOP", 0, 130},
	["PulseCooldown"] = {"CENTER", "UIParent", "CENTER", 0, 0},
	["Quest"] = {"TOPRIGHT", "UIParent", -80, -345},
	["RightBars"] = {"BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -5, 330},
	["StanceBar"] = {"BOTTOMLEFT", "MultiBarRightButton12", "TOPLEFT", 24, 6},
	["StatsFrame"] = {"CENTER", "StatFrame", "CENTER", 0, 0},
	["Ticket"] = {"TOPLEFT", "UIParent", "TOPLEFT", 0, -1},
	["Tooltip"] = {"BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -3, 40},
	["UIError"] = {"TOP", "UIParent", "TOP", 0, -80},
	["Vehicle"] = {"TOP", "Minimap", "BOTTOM", 0, -30},
	["VehicleBar"] = {"BOTTOMLEFT", "MultiBarRightButton12", "TOPLEFT", 60, 40},
	-- UnitFrame positions
	UnitFrames = {
		["Arena"] = {"BOTTOMRIGHT", "UIParent", "RIGHT", -60, -70},
		["Focus"] = {"BOTTOM", "PlayerFrame", "TOP", 0, 60},
		["Player"] = {"BOTTOMRIGHT", "ActionBarAnchor", "TOPLEFT", -35, 440},
		["PlayerCastBar"] = {"BOTTOM", "ActionBarAnchor", "TOP", 50, 275},
		["Target"] = {"BOTTOMLEFT", "ActionBarAnchor", "TOPRIGHT", -675, 355},
		["TargetCastBar"] = {"BOTTOM", "CastingBarFrame", "TOP", 0, 21},
	},
	-- Filger positions
	Filger = {
		["PvECC"] = {"TOPLEFT", "UIParent", "CENTER", -700, 120},
		["Cooldown"] = {"CENTER", "UIParent", "CENTER", 0, 300},

		["PlayerProcIcon"] = {"BOTTOMLEFT", "UIParent", "CENTER", 187, -73},
		["SpecialProcIcon"] = {"BOTTOMLEFT", "UIParent", "CENTER", 0, 0},
		["TargetBuffIcon"] = {"BOTTOMLEFT", "UIParent", "CENTER", 179, 32},
		
		["TargetBar"] = {"BOTTOMLEFT", "UIParent", "CENTER", -171, -90},
		["TargetDebuffIcon"] = {"BOTTOMLEFT", "UIParent", "CENTER", -171, -50},
		["PlayerBuffIcon"] = {"BOTTOMLEFT", "UIParent", "CENTER", -171, -10},
		["PvEDebuff"] = {"BOTTOMLEFT", "UIParent", "CENTER", -171, 30},
	},
}