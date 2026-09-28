-- budsUI_Config :: Pages/Automation.lua

local _, ns = ...

local function T(option, label, extra)
	local entry = { group = "Automation", option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

ns.RegisterPage({
	key = "Automation",
	name = L_GUI_AUTOMATION or "Automation",
	order = 5,
	schema = {
		{ header = L_GUI_AUTOMATION or "Automation" },
		T("SellGreyRepair", L_GUI_AUTOMATION_SELLGREY_N_REPAIR or "Sell grey & repair", {
			type = "toggle",
			desc = "Automatically sell all your gray items & repair your equipment.",
		}),
		T("AutoInvite", L_GUI_AUTOMATION_ACCEPTINVITE or "Auto accept invites", {
			type = "toggle",
			desc = "Auto accept invites (Friends / Guild) only.",
		}),
		T("DeclineDuel", L_GUI_AUTOMATION_DECLINEDUEL or "Decline duels", {
			type = "toggle",
			desc = "Auto decline all duels.",
		}),
		T("Resurrection", L_GUI_AUTOMATION_RESURRECTION or "Auto resurrection", {
			type = "toggle",
			desc = "Auto resurrection in battlegrounds.",
		}),
		T("ScreenShot", L_GUI_AUTOMATION_SCREENSHOT or "Screenshot on achievement", {
			type = "toggle",
			desc = "Take screenshot when player gets an achievement.",
		}),
		T("LoggingCombat", L_GUI_AUTOMATION_LOGGING_COMBAT or "Combat logging", {
			type = "toggle",
			desc = "Auto enables combat log text file in raid instances.",
		}),
		T("TabBinder", L_GUI_AUTOMATION_TAB_BINDER or "Tab binder", {
			type = "toggle",
			desc = "Auto change Tab key to only target enemy players.",
		}),
		T("AutoCollapse", L_GUI_AUTOMATION_AUTOCOLLAPSE or "Auto collapse tracker", {
			type = "toggle", advanced = true,
			desc = "Auto collapse WatchFrame in instances, PvP & when resting.",
		}),
	},
})
