-- budsUI_Config :: Pages/Loot.lua

local _, ns = ...

local function T(option, label, extra)
	local entry = { group = "Loot", option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

ns.RegisterPage({
	key = "Loot",
	name = LOOT or "Loot",
	order = 13,
	schema = {
		{ header = LOOT or "Loot" },
		T("Enable", L_GUI_LOOT_ENABLE or "Enable loot frame", {
			type = "toggle", reload = true,
		}),
		T("GroupLoot", L_GUI_LOOT_ROLL_ENABLE or "Group loot frame", {
			type = "toggle",
			desc = "Enable group loot frame.",
			enabledBy = "Loot.Enable",
		}),
		T("Width", L_GUI_LOOT_WIDTH or "Loot frame width", {
			type = "number", min = 150, max = 400, step = 1,
			enabledBy = "Loot.Enable",
		}),
		T("IconSize", L_GUI_LOOT_ICON_SIZE or "Icon size", {
			type = "number", min = 16, max = 60, step = 1,
			enabledBy = "Loot.Enable",
		}),
		T("AutoGreed", L_GUI_LOOT_AUTOGREED or "Auto-greed", {
			type = "toggle",
			desc = "Enable auto-greed & disenchant for green items at max level.",
		}),
		T("ConfirmDisenchant", L_GUI_LOOT_AUTODE or "Auto confirm disenchant", {
			type = "toggle",
		}),
		T("LootFilter", L_GUI_LOOT_BETTER_LOOTFILTER or "Loot filter", {
			type = "toggle", advanced = true,
			desc = "Filter party & raid members loot messages, based on item rarity.",
		}),
	},
})
