-- budsUI_Config :: Pages/Filger.lua

local _, ns = ...

local function T(option, label, extra)
	local entry = { group = "Filger", option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

ns.RegisterPage({
	key = "Filger",
	name = L_GUI_FILGER or "Filger",
	order = 12,
	schema = {
		{ header = L_GUI_FILGER or "Filger" },
		T("Enable", L_GUI_FILGER_ENABLE or "Enable Filger", {
			type = "toggle", reload = true,
		}),
		T("BuffsSize", L_GUI_FILGER_BUFFS_SIZE or "Buffs size", {
			type = "number", min = 16, max = 60, step = 1,
			enabledBy = "Filger.Enable",
		}),
		T("CooldownSize", L_GUI_FILGER_COOLDOWN_SIZE or "Cooldowns size", {
			type = "number", min = 16, max = 60, step = 1,
			enabledBy = "Filger.Enable",
		}),
		T("PvPSize", L_GUI_FILGER_PVP_SIZE or "PvP debuffs size", {
			type = "number", min = 16, max = 80, step = 1,
			enabledBy = "Filger.Enable",
		}),
		T("ShowTooltip", L_GUI_FILGER_SHOW_TOOLTIP or "Show tooltip", {
			type = "toggle",
			enabledBy = "Filger.Enable",
		}),
		T("TestMode", L_GUI_FILGER_TEST_MODE or "Test icon mode", {
			type = "toggle",
			enabledBy = "Filger.Enable",
		}),
		T("MaxTestIcon", L_GUI_FILGER_MAX_TEST_ICON or "Test icons", {
			type = "number", min = 1, max = 20, step = 1,
			enabledBy = "Filger.TestMode",
			desc = "The number of icons in test mode.",
		}),
	},
})
