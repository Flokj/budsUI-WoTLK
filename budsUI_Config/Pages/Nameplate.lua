-- budsUI_Config :: Pages/Nameplate.lua

local _, ns = ...

local function T(option, label, extra)
	local entry = { group = "Nameplate", option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

ns.RegisterPage({
	key = "Nameplate",
	name = UNIT_NAMEPLATES or "Nameplates",
	order = 16,
	schema = {
		{ header = UNIT_NAMEPLATES or "Nameplates" },
		T("Enable", L_GUI_NAMEPLATE_ENABLE or "Enable nameplates", {
			type = "toggle", reload = true,
		}),
		T("Width", L_GUI_NAMEPLATE_WIDTH or "Width", {
			type = "number", min = 50, max = 300, step = 1,
			enabledBy = "Nameplate.Enable",
		}),
		T("Height", L_GUI_NAMEPLATE_HEIGHT or "Height", {
			type = "number", min = 5, max = 50, step = 1,
			enabledBy = "Nameplate.Enable",
		}),
		T("AdditionalWidth", L_GUI_NAMEPLATE_AD_WIDTH or "Selected width bonus", {
			type = "number", min = 0, max = 100, step = 1,
			enabledBy = "Nameplate.Enable",
			desc = "Additional width for selected nameplate.",
		}),
		T("AdditionalHeight", L_GUI_NAMEPLATE_AD_HEIGHT or "Selected height bonus", {
			type = "number", min = 0, max = 50, step = 1,
			enabledBy = "Nameplate.Enable",
			desc = "Additional height for selected nameplate.",
		}),
		T("HealthValue", L_GUI_NAMEPLATE_HEALTH or "Health value", {
			type = "toggle",
			desc = "Numeral health value.",
			enabledBy = "Nameplate.Enable",
		}),
		T("NameAbbreviate", L_GUI_NAMEPLATE_NAME_ABBREV or "Abbreviated names", {
			type = "toggle",
			desc = "Display abbreviated names (show debuffs must be turned off).",
			enabledBy = "Nameplate.Enable",
		}),
		T("Combat", L_GUI_NAMEPLATE_COMBAT or "Show in combat", {
			type = "toggle",
			desc = "Automatically show nameplates in combat.",
			enabledBy = "Nameplate.Enable",
		}),
		T("ClassIcons", L_GUI_NAMEPLATE_CLASS_ICON or "Class icons in PvP", {
			type = "toggle",
			desc = "Icons by class in PvP.",
			enabledBy = "Nameplate.Enable",
		}),
		{ header = "Auras" },
		T("Auras", L_GUI_NAMEPLATE_SHOW_DEBUFFS or "Show debuffs", {
			type = "toggle",
			desc = "Show debuffs (from the list).",
			enabledBy = "Nameplate.Enable",
		}),
		T("AuraSize", L_GUI_NAMEPLATE_DEBUFFS_SIZE or "Debuffs size", {
			type = "number", min = 10, max = 50, step = 1,
			enabledBy = { "Nameplate.Enable", "Nameplate.Auras" },
		}),
		T("CastBarName", L_GUI_NAMEPLATE_CASTBAR_NAME or "Castbar name", {
			type = "toggle",
			desc = "Show castbar name.",
			enabledBy = "Nameplate.Enable",
		}),
		{ header = "Threat" },
		T("EnhanceThreat", L_GUI_NAMEPLATE_THREAT or "Threat feature", {
			type = "toggle",
			desc = "Enable threat feature, automatically changes by your role.",
			enabledBy = "Nameplate.Enable",
		}),
		T("GoodColor", L_GUI_NAMEPLATE_GOOD_COLOR or "Good threat color", {
			type = "color",
			desc = "Good threat color, varies depending if you are a tank or dps/heal.",
			enabledBy = { "Nameplate.Enable", "Nameplate.EnhanceThreat" },
		}),
		T("NearColor", L_GUI_NAMEPLATE_NEAR_COLOR or "Near threat color", {
			type = "color",
			desc = "Losing/Gaining threat color.",
			enabledBy = { "Nameplate.Enable", "Nameplate.EnhanceThreat" },
		}),
		T("BadColor", L_GUI_NAMEPLATE_BAD_COLOR or "Bad threat color", {
			type = "color",
			desc = "Bad threat color, varies depending if you are a tank or dps/heal.",
			enabledBy = { "Nameplate.Enable", "Nameplate.EnhanceThreat" },
		}),
	},
})
