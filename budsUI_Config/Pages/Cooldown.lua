-- budsUI_Config :: Pages/Cooldown.lua

local _, ns = ...

local function T(option, label, extra)
	local entry = { group = "Cooldown", option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

ns.RegisterPage({
	key = "Cooldown",
	name = L_GUI_COOLDOWN or "Cooldown",
	order = 10,
	schema = {
		{ header = L_GUI_COOLDOWN or "Cooldown" },
		T("Enable", L_GUI_COOLDOWN_ENABLE or "Enable", {
			type = "toggle", reload = true,
			desc = "Enable UI cooldown module.",
		}),
		T("FontSize", L_GUI_COOLDOWN_FONT_SIZE or "Font size", {
			type = "number", min = 8, max = 40, step = 1,
			enabledBy = "Cooldown.Enable",
		}),
		T("Threshold", L_GUI_COOLDOWN_THRESHOLD or "Threshold", {
			type = "number", min = 0, max = 30, step = 1, unit = "s",
			enabledBy = "Cooldown.Enable",
			desc = "Cooldown threshold number.",
		}),
		T("IgnoreWeakAuras", L_GUI_COOLDOWN_IGNORE_WEAKAURAS or "Ignore WeakAuras", {
			type = "toggle", advanced = true,
			desc = "Ignore WeakAuras cooldowns.",
			enabledBy = "Cooldown.Enable",
		}),
	},
})
