-- budsUI_Config :: Pages/PowerBar.lua

local _, ns = ...

local function T(option, label, extra)
	local entry = { group = "PowerBar", option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

ns.RegisterPage({
	key = "PowerBar",
	name = L_GUI_POWERBAR or "Powerbar",
	order = 17,
	schema = {
		{ header = L_GUI_POWERBAR or "Powerbar" },
		T("Enable", L_GUI_POWERBAR_ENABLE or "Enable", {
			type = "toggle", reload = true,
			desc = "Enable standalone Powerbar.",
		}),
		T("Width", L_GUI_POWERBAR_WIDTH or "Width", {
			type = "number", min = 100, max = 400, step = 1,
			enabledBy = "PowerBar.Enable",
		}),
		T("Height", L_GUI_POWERBAR_HEIGHT or "Height", {
			type = "number", min = 2, max = 30, step = 1,
			enabledBy = "PowerBar.Enable",
		}),
		T("FontOutline", L_GUI_POWERBAR_FONT_OUTLINE or "Font outline", {
			type = "toggle",
			desc = "Apply an outline to the Powerbar text.",
			enabledBy = "PowerBar.Enable",
		}),
		T("ValueAbbreviate", L_GUI_POWERBAR_VALUE_SHORT or "Short values", {
			type = "toggle",
			desc = "Shorten the text value on the Powerbar.",
			enabledBy = "PowerBar.Enable",
		}),
		{ header = "Resources" },
		T("Mana", L_GUI_POWERBAR_SHOW_MANA or "Mana", {
			type = "toggle", enabledBy = "PowerBar.Enable",
		}),
		T("Rage", L_GUI_POWERBAR_SHOW_RAGE or "Rage", {
			type = "toggle", enabledBy = "PowerBar.Enable",
		}),
		T("Combo", L_GUI_POWERBAR_SHOW_COMBO or "Combo points", {
			type = "toggle", enabledBy = "PowerBar.Enable",
		}),
		T("Rune", L_GUI_POWERBAR_SHOW_RUNE or "Runes", {
			type = "toggle", enabledBy = "PowerBar.Enable",
		}),
		T("RuneCooldown", L_GUI_POWERBAR_SHOW_RUNE_CD or "Rune cooldowns", {
			type = "toggle", enabledBy = "PowerBar.Rune",
		}),
		T("DKRuneBar", L_GUI_POWERBAR_HIDE_BLIZZ_RUNEBAR or "Hide Blizzard runebar", {
			type = "toggle", advanced = true,
			desc = "Hide Blizzard DK Runebar (useful with other addons).",
		}),
		{ header = "Maelstrom" },
		T("Maelstrom", L_GUI_POWERBAR_SHOW_MAELSTROM or "Maelstrom tracker", {
			type = "toggle", enabledBy = "PowerBar.Enable",
		}),
		T("MaelstromSize", L_GUI_POWERBAR_MAELSTROM_SIZE or "Maelstrom size", {
			type = "number", min = 64, max = 512, step = 8,
			enabledBy = { "PowerBar.Enable", "PowerBar.Maelstrom" },
			desc = "Default 256.",
		}),
		T("MaelstromPulse", L_GUI_POWERBAR_MAELSTROM_PULSE or "Pulse animation", {
			type = "toggle", enabledBy = { "PowerBar.Enable", "PowerBar.Maelstrom" },
			desc = "Pulse animation at stack threshold.",
		}),
		T("MaelstromPulseAt", L_GUI_POWERBAR_MAELSTROM_PULSE_AT or "Pulse at stacks", {
			type = "number", min = 1, max = 5, step = 1,
			enabledBy = { "PowerBar.Enable", "PowerBar.Maelstrom", "PowerBar.MaelstromPulse" },
		}),
		T("MaelstromSpellID", "Maelstrom spell ID", {
			type = "number", min = 1, max = 9999999, step = 1, advanced = true,
			enabledBy = { "PowerBar.Enable", "PowerBar.Maelstrom" },
			desc = "Spell ID tracked by the Maelstrom stack counter.",
		}),
	},
})
