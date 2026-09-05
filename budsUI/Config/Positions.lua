local K, C, L = select(2, ...):unpack()

-- If you're saving frame positions, use "UIParent", not UIParent
C["Position"] = {
	["Achievements"] = {"TOP", "UIParent", "TOP", 0, -22},
	["BGScore"] = {"CENTER", "UIParent", "TOPLEFT", 150, -210},
	["Bag"] = {"RIGHT", "UIParent", "RIGHT", -140, -20},
	["Bank"] = {"LEFT", "UIParent", "LEFT", 23, 150},
	["BnetPopup"] = {"BOTTOMLEFT", "ChatFrame1", "TOPLEFT", 4, 54},
	["BottomBars"] = {"BOTTOM", "UIParent", "BOTTOM", 0, 5},
	["CaptureBar"] = {"TOP", "UIParent", "TOP", 0, -80},
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
	["Tooltip"] = {"BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -3, 3},
	["UIError"] = {"TOP", "UIParent", "TOP", 0, -80},
	["Vehicle"] = {"TOP", "Minimap", "BOTTOM", 0, -30},
	["VehicleBar"] = {"TOPLEFT", "MultiBarLeftButton11", "TOPRIGHT", 3, 0},
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

		["PlayerProcIcon"] = {"BOTTOMLEFT", "UIParent", "CENTER", 200, -70},
		["SpecialProcIcon"] = {"BOTTOMLEFT", "UIParent", "CENTER", 0, 0},
		["TargetBuffIcon"] = {"BOTTOMLEFT", "UIParent", "CENTER", 190, 36},
		
		["TargetBar"] = {"BOTTOMLEFT", "UIParent", "CENTER", -176, -98},
		["TargetDebuffIcon"] = {"BOTTOMLEFT", "UIParent", "CENTER", -176, -54},
		["PlayerBuffIcon"] = {"BOTTOMLEFT", "UIParent", "CENTER", -176, -10},
		["PvEDebuff"] = {"BOTTOMLEFT", "UIParent", "CENTER", -176, 36},
	},
}