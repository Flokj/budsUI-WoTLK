-- budsUI_Config :: Pages/Minimap.lua

local _, ns = ...

local function T(option, label, extra)
	local entry = { group = "Minimap", option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

ns.RegisterPage({
	key = "Minimap",
	name = L_GUI_MINIMAP or "Minimap",
	order = 14,
	schema = {
		{ header = L_GUI_MINIMAP or "Minimap" },
		T("Enable", L_GUI_MINIMAP_ENABLEMINIMAP or "Enable minimap", {
			type = "toggle", reload = true,
			desc = "Enable minimap & make it square.",
		}),
		T("Size", L_GUI_MINIMAP_MINIMAPSIZE or "Minimap size", {
			type = "number", min = 100, max = 300, step = 1,
			enabledBy = "Minimap.Enable",
			desc = "Default is 150.",
		}),
		T("CollectButtons", L_GUI_MINIMAP_COLLECTBUTTONS or "Collect buttons", {
			type = "toggle",
			desc = "Collect most minimap buttons in one line.",
			enabledBy = "Minimap.Enable",
		}),
		T("CollectDelay", "Collect delay", {
			type = "number", min = 0, max = 30, step = 1, unit = "s", advanced = true,
			enabledBy = "Minimap.CollectButtons",
			desc = "Delay before minimap buttons are collected.",
		}),
		T("CDR", L_GUI_MINIMAP_CDR or "Raid cooldown", {
			type = "toggle",
			desc = "Display Raid Cooldown (move the mouse over the clock).",
			enabledBy = "Minimap.Enable",
		}),
		T("Ping", L_GUI_MINIMAP_PING or "Ping message", {
			type = "toggle",
			desc = "Displays a message when someone pings the minimap.",
			enabledBy = "Minimap.Enable",
		}),
	},
})
