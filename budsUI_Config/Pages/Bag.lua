-- budsUI_Config :: Pages/Bag.lua

local _, ns = ...

local function T(option, label, extra)
	local entry = { group = "Bag", option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

ns.RegisterPage({
	key = "Bag",
	name = L_GUI_BAGS or "Bags",
	order = 6,
	schema = {
		{ header = L_GUI_BAGS or "Bags" },
		T("Enable", L_GUI_BAGS_ENABLE or "Enable bags", {
			type = "toggle", reload = true,
		}),
		T("BagColumns", L_GUI_BAGS_BAG or "Bag columns", {
			type = "number", min = 4, max = 20, step = 1,
			desc = "Number of columns in main bag.",
		}),
		T("BankColumns", L_GUI_BAGS_BANK or "Bank columns", {
			type = "number", min = 4, max = 24, step = 1,
			desc = "Number of columns in bank.",
		}),
		T("ButtonSize", L_GUI_BAGS_BUTTON_SIZE or "Button size", {
			type = "number", min = 20, max = 60, step = 1,
		}),
		T("ButtonSpace", L_GUI_BAGS_BUTTON_SPACE or "Button space", {
			type = "number", min = 1, max = 10, step = 1,
		}),
		T("ShowItemLevel", L_GUI_BAGS_ITEM_LEVEL or "Item level", {
			type = "toggle",
			desc = "Show item level on bag items.",
		}),
		T("HideSoulBag", L_GUI_BAGS_HIDE_SOULBAG or "Hide soul bag", {
			type = "toggle",
			desc = "Warlock: hide the Soul Shard bag slots.",
		}),
	},
})
