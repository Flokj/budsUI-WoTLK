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
	},
})
