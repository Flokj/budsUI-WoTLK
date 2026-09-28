-- budsUI_Config :: Pages/PulseCD.lua

local _, ns = ...

local function T(option, label, extra)
	local entry = { group = "PulseCD", option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

ns.RegisterPage({
	key = "PulseCD",
	name = L_GUI_PULSECD or "Pulse Cooldowns",
	order = 18,
	schema = {
		{ header = L_GUI_PULSECD or "Pulse Cooldowns" },
		T("Enable", L_GUI_PULSECD_ENABLE or "Enable", {
			type = "toggle", reload = true,
			desc = "Show cooldowns pulse.",
		}),
		T("Size", L_GUI_PULSECD_SIZE or "Icon size", {
			type = "number", min = 30, max = 150, step = 1,
			enabledBy = "PulseCD.Enable",
			desc = "Cooldowns pulse icon size.",
		}),
		T("Threshold", L_GUI_PULSECD_THRESHOLD or "Threshold", {
			type = "number", min = 0, max = 30, step = 1, unit = "s",
			enabledBy = "PulseCD.Enable",
			desc = "Minimal threshold time.",
		}),
		T("HoldTime", L_GUI_PULSECD_HOLD_TIME or "Hold time", {
			type = "number", min = 0, max = 5, step = 0.1, unit = "s", advanced = true,
			enabledBy = "PulseCD.Enable",
			desc = "Max opacity hold time.",
		}),
		T("AnimationScale", L_GUI_PULSECD_ANIM_SCALE or "Animation scale", {
			type = "number", min = 0.5, max = 3, step = 0.1, advanced = true,
			enabledBy = "PulseCD.Enable",
		}),
		T("Sound", L_GUI_PULSECD_SOUND or "Sound", {
			type = "toggle",
			desc = "Warning sound notification.",
			enabledBy = "PulseCD.Enable",
		}),
	},
})
