-- budsUI_Config :: Pages/Misc.lua

local _, ns = ...

local function T(option, label, extra)
	local entry = { group = "Misc", option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

local function TM(option, label, extra)
	local entry = { group = "ThreatMeter", option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

ns.RegisterPage({
	key = "Misc",
	name = L_GUI_MISC or "Miscellaneous",
	order = 15,
	schema = {
		{ header = L_GUI_MISC or "Miscellaneous" },
		T("ItemLevel", L_GUI_MISC_ITEM_LEVEL or "Item level on slots", {
			type = "toggle",
			desc = "Item level on character slot buttons.",
		}),
		T("AlreadyKnown", L_GUI_MISC_ALREADY_KNOWN or "Already known", {
			type = "toggle",
			desc = "Colorizes recipes, mounts & pets that are already known.",
		}),
		T("EnhancedMail", L_GUI_MISC_ENCHANCED_MAIL or "Enhanced mail", {
			type = "toggle",
			desc = "Adds a take all button to your mail frame.",
		}),
		T("HatTrick", L_GUI_MISC_HATTRICK or "Helm & cloak toggles", {
			type = "toggle",
			desc = "Adds checkboxes to toggle the helm & cloak settings.",
		}),
		T("DurabilityWarning", L_GUI_MISC_DURABILITY_WARNINIG or "Durability warning", {
			type = "toggle",
			desc = "Helps remind you to repair your gear when it is close to being broken.",
		}),
		T("BGSpam", L_GUI_MISC_HIDE_BG_SPAM or "Hide BG spam", {
			type = "toggle",
			desc = "Remove Boss Emote spam during BG.",
		}),
		T("AFKCamera", L_GUI_MISC_SPIN_CAMERA or "AFK spin camera", {
			type = "toggle",
			desc = "Spin camera while afk.",
		}),
		T("PvPTimer", L_GUI_MISC_PVP_TIMER or "PvP timer", {
			type = "toggle",
			desc = "Retail-style PvP start timer (BG/arena countdown with big numbers).",
		}),
		T("Armory", L_GUI_MISC_ARMORY_LINK or "Armory link", {
			type = "toggle", advanced = true,
			desc = "Add Armory link in UnitPopupMenus (it can break UnitPopupMenus).",
		}),
		T("InviteKeyword", L_GUI_MISC_INVKEYWORD or "Invite keyword", {
			type = "string", width = 120, maxLetters = 16,
			desc = "Short keyword for invite (/ainv).",
		}),
		T("SpeedyLoad", L_GUI_MISC_SPEEDYLOAD or "Speedy load", {
			type = "toggle", advanced = true, reload = true,
			desc = "Disable certain events during loading screens to drastically improve loading times.",
		}),
		{ header = L_GUI_MISC_COMBAT_ALERT or "Combat alert" },
		T("CombatAlert", L_GUI_MISC_COMBAT_ALERT or "Combat alert", {
			type = "toggle",
			desc = "Flash a message when entering or leaving combat.",
		}),
		T("CombatAlertEnterText", L_GUI_MISC_COMBAT_ALERT_ENTER_TEXT or "Enter combat text", {
			type = "string", width = 120, maxLetters = 40, enabledBy = "Misc.CombatAlert",
		}),
		T("CombatAlertLeaveText", L_GUI_MISC_COMBAT_ALERT_LEAVE_TEXT or "Leave combat text", {
			type = "string", width = 120, maxLetters = 40, enabledBy = "Misc.CombatAlert",
		}),
		T("CombatAlertEnterColor", L_GUI_MISC_COMBAT_ALERT_ENTER_COLOR or "Enter combat color", {
			type = "color", enabledBy = "Misc.CombatAlert",
		}),
		T("CombatAlertLeaveColor", L_GUI_MISC_COMBAT_ALERT_LEAVE_COLOR or "Leave combat color", {
			type = "color", enabledBy = "Misc.CombatAlert",
		}),
		T("CombatAlertTest", L_GUI_MISC_COMBAT_ALERT_TEST or "Test combat alert", {
			type = "execute", text = "Show", noReset = true, enabledBy = "Misc.CombatAlert",
			desc = "Show the enter combat message once.",
			func = function()
				if _G["budsUICombatAlertTest"] then
					_G["budsUICombatAlertTest"]()
				end
			end,
		}),
		{ header = L_GUI_MISC_FADE or "Fading" },
		T("MicroMenuFade", L_GUI_MISC_MICRO_FADE or "Micro menu / bag fade", {
			type = "toggle",
			desc = "Fade the micro menu and bag button out on mouseover (FrostAtomUI-style).",
		}),
		{ header = L_GUI_THREATMETER or "Threat Meter" },
		TM("Enable", L_GUI_THREATMETER_ENABLE or "Enable", {
			type = "toggle", reload = true,
			desc = "Enable threat meter on your target.",
		}),
		TM("Width", L_GUI_THREATMETER_WIDTH or "Bar width", {
			type = "number", min = 100, max = 400, step = 1,
			enabledBy = "ThreatMeter.Enable",
		}),
		TM("Height", L_GUI_THREATMETER_HEIGHT or "Bar height", {
			type = "number", min = 8, max = 40, step = 1,
			enabledBy = "ThreatMeter.Enable",
		}),
		TM("MaxBars", L_GUI_THREATMETER_MAXBARS or "Max bars", {
			type = "number", min = 1, max = 10, step = 1,
			enabledBy = "ThreatMeter.Enable",
			desc = "Max bars shown.",
		}),
		TM("Spacing", L_GUI_THREATMETER_SPACING or "Spacing", {
			type = "number", min = 0, max = 20, step = 1,
			enabledBy = "ThreatMeter.Enable",
			desc = "Spacing between bars.",
		}),
		TM("FontSize", L_GUI_THREATMETER_FONTSIZE or "Font size", {
			type = "number", min = 8, max = 24, step = 1,
			enabledBy = "ThreatMeter.Enable",
		}),
	},
})
