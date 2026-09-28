-- budsUI_Config :: Pages/ThreatMeter.lua

local _, ns = ...

local function T(option, label, extra)
	local entry = { group = "ThreatMeter", option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

ns.RegisterPage({
	key = "ThreatMeter",
	name = L_GUI_THREATMETER or "Threat Meter",
	order = 20,
	schema = {
		{ header = L_GUI_THREATMETER or "Threat Meter" },
		T("Enable", L_GUI_THREATMETER_ENABLE or "Enable", {
			type = "toggle", reload = true,
			desc = "Enable threat meter on your target.",
		}),
		T("Width", L_GUI_THREATMETER_WIDTH or "Bar width", {
			type = "number", min = 100, max = 400, step = 1,
			enabledBy = "ThreatMeter.Enable",
		}),
		T("Height", L_GUI_THREATMETER_HEIGHT or "Bar height", {
			type = "number", min = 8, max = 40, step = 1,
			enabledBy = "ThreatMeter.Enable",
		}),
		T("MaxBars", L_GUI_THREATMETER_MAXBARS or "Max bars", {
			type = "number", min = 1, max = 10, step = 1,
			enabledBy = "ThreatMeter.Enable",
			desc = "Max bars shown.",
		}),
		T("Spacing", L_GUI_THREATMETER_SPACING or "Spacing", {
			type = "number", min = 0, max = 20, step = 1,
			enabledBy = "ThreatMeter.Enable",
			desc = "Spacing between bars.",
		}),
		T("FontSize", L_GUI_THREATMETER_FONTSIZE or "Font size", {
			type = "number", min = 8, max = 24, step = 1,
			enabledBy = "ThreatMeter.Enable",
		}),
	},
})
