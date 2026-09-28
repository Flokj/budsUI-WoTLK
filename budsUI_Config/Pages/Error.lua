-- budsUI_Config :: Pages/Error.lua

local _, ns = ...

local function T(option, label, extra)
	local entry = { group = "Error", option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

ns.RegisterPage({
	key = "Error",
	name = L_GUI_ERROR or "Errors",
	order = 11,
	schema = {
		{ header = L_GUI_ERROR or "Errors" },
		{
			description = "Which UI error messages (red text) are shown or hidden.",
		},
		T("Black", L_GUI_ERROR_BLACK or "Hide blacklisted errors", {
			type = "toggle",
			desc = "Hide errors from black list.",
		}),
		T("White", L_GUI_ERROR_WHITE or "Show whitelisted errors", {
			type = "toggle",
			desc = "Show errors from white list.",
		}),
		T("Combat", L_GUI_ERROR_HIDE_COMBAT or "Hide errors in combat", {
			type = "toggle",
			desc = "Hide all errors in combat.",
		}),
	},
})
