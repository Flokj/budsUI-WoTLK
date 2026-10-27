-- budsUI_Config :: Pages/ActionBar.lua

local _, ns = ...

local function T(option, label, extra)
	local entry = { group = "ActionBar", option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

ns.RegisterPage({
	key = "ActionBar",
	name = "ActionBar",
	order = 3,
	schema = {
		{ header = "ActionBar" },
		T("Enable", L_GUI_ACTIONBAR_ENABLE or "Enable action bars", {
			type = "toggle", reload = true,
		}),
		{ header = "Bars" },
		T("BottomBars", L_GUI_ACTIONBAR_BOTTOMBARS or "Bottom bars", {
			type = "number", min = 1, max = 3, step = 1,
			desc = "Number of action bars on the bottom (1, 2 or 3).",
		}),
		T("RightBars", L_GUI_ACTIONBAR_RIGHTBARS or "Right bars", {
			type = "number", min = 0, max = 3, step = 1,
			desc = "Number of action bars on the right (0, 1, 2 or 3).",
		}),
		T("SplitBars", L_GUI_ACTIONBAR_SPLIT_BARS or "Split fifth bar", {
			type = "toggle",
			desc = "Split the fifth bar on two bars of 6 buttons.",
		}),
		T("ButtonSize", L_GUI_ACTIONBAR_BUTTON_SIZE or "Button size", {
			type = "number", min = 20, max = 60, step = 1,
		}),
		T("ButtonSpace", L_GUI_ACTIONBAR_BUTTON_SPACE or "Button space", {
			type = "number", min = 1, max = 10, step = 1,
		}),
		T("ShowGrid", L_GUI_ACTIONBAR_GRID or "Show empty buttons", {
			type = "toggle",
			desc = "Show empty action bar buttons.",
		}),
		{ header = "Text" },
		T("Hotkey", L_GUI_ACTIONBAR_HOTKEY or "Hotkeys", {
			type = "toggle",
			desc = "Show hotkey on buttons.",
		}),
		T("Macro", L_GUI_ACTIONBAR_MACRO or "Macro names", {
			type = "toggle",
			desc = "Show macro name on buttons.",
		}),
		{ header = "Pet & Stance" },
		T("PetBarHide", L_GUI_ACTIONBAR_PETBAR_HIDE or "Hide pet bar", {
			type = "toggle",
		}),
		T("PetBarHorizontal", L_GUI_ACTIONBAR_PETBAR_HORIZONTAL or "Horizontal pet bar", {
			type = "toggle", enabledBy = "ActionBar.PetBarHide",
		}),
		T("PetBarScale", L_GUI_ACTIONBAR_PETBAR_SCALE or "Pet bar scale", {
			type = "number", min = 0.5, max = 1.5, step = 0.05, percent = true,
			reload = true,
			desc = "Scale of the pet action bar. The mover frame matches it.",
			disabled = function() return ns.Get({ group = "ActionBar", option = "PetBarHide" }) end,
		}),
		T("StanceBarHide", L_GUI_ACTIONBAR_STANCEBAR_HIDE or "Hide stance bar", {
			type = "toggle",
		}),
		T("StanceBarHorizontal", L_GUI_ACTIONBAR_STANCEBAR_HORIZONTAL or "Horizontal stance bar", {
			type = "toggle",
		}),
		{ header = "Totem bar" },
		T("TotemButtonSize", L_GUI_ACTIONBAR_TOTEM_SIZE or "Totem button size", {
			type = "number", min = 20, max = 50, step = 1, reload = true,
			desc = "Size of the main totem bar buttons.",
		}),
		T("TotemButtonSpace", L_GUI_ACTIONBAR_TOTEM_SPACE or "Totem button space", {
			type = "number", min = 1, max = 10, step = 1, reload = true,
			desc = "Space between totem bar buttons.",
		}),
		T("TotemColumns", L_GUI_ACTIONBAR_TOTEM_COLUMNS or "Totem bar columns", {
			type = "number", min = 1, max = 6, step = 1, reload = true,
			desc = "Number of buttons per row (6 = horizontal, 1 = vertical).",
		}),
		T("TotemFlyoutSize", L_GUI_ACTIONBAR_TOTEM_FLYOUT_SIZE or "Flyout button size", {
			type = "number", min = 16, max = 40, step = 1,
			desc = "Button size in the popup menu that opens above each totem slot.",
		}),
		T("TotemFlyoutRows", L_GUI_ACTIONBAR_TOTEM_FLYOUT_ROWS or "Flyout buttons per column", {
			type = "number", min = 1, max = 12, step = 1,
			desc = "Maximum buttons per column in the totem menu (10 = single column).",
		}),
		T("TotemFlyoutSpace", L_GUI_ACTIONBAR_TOTEM_FLYOUT_SPACE or "Flyout spacing", {
			type = "number", min = 0, max = 10, step = 1,
			desc = "Space between buttons in the totem popup menu.",
		}),
		{ header = "Combat feedback", advanced = true },
		T("EquipBorder", L_GUI_ACTIONBAR_EQUIP_BORDER or "Equipped border", {
			type = "toggle",
			desc = "Display green border on equipped items.",
		}),
		T("Selfcast", L_GUI_ACTIONBAR_SELFCAST or "Self-cast on right-click", {
			type = "toggle",
			desc = "Always self-cast on right-click (regardless of current target).",
		}),
		T("OutOfMana", L_GUI_ACTIONBAR_OUT_OF_MANA or "Out of mana color", {
			type = "color",
		}),
		T("OutOfRange", L_GUI_ACTIONBAR_OUT_OF_RANGE or "Out of range color", {
			type = "color",
		}),
	},
})
