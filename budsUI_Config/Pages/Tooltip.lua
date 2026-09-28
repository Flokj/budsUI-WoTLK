-- budsUI_Config :: Pages/Tooltip.lua

local _, ns = ...

local function T(option, label, extra)
	local entry = { group = "Tooltip", option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

ns.RegisterPage({
	key = "Tooltip",
	name = L_GUI_TOOLTIP or "Tooltip",
	order = 21,
	schema = {
		{ header = L_GUI_TOOLTIP or "Tooltip" },
		T("Enable", L_GUI_TOOLTIP_ENABLE or "Enable tooltip", {
			type = "toggle", reload = true,
		}),
		T("Scale", L_GUI_TOOLTIP_SCALE or "Scale", {
			type = "number", min = 0.5, max = 1.5, step = 0.05,
			enabledBy = "Tooltip.Enable",
			desc = "Scale the tooltip.",
		}),
		T("Cursor", L_GUI_TOOLTIP_CURSOR or "Above cursor", {
			type = "toggle",
			desc = "Tooltip above cursor.",
			enabledBy = "Tooltip.Enable",
		}),
		T("HideCombat", L_GUI_TOOLTIP_HIDE_COMBAT or "Hide in combat", {
			type = "toggle",
			enabledBy = "Tooltip.Enable",
		}),
		T("HideButtons", L_GUI_TOOLTIP_HIDE or "Hide for action bars", {
			type = "toggle",
			desc = "Hide tooltips for action bars.",
			enabledBy = "Tooltip.Enable",
		}),
		{ header = "Unit info" },
		T("Target", L_GUI_TOOLTIP_TARGET or "Target", {
			type = "toggle",
			desc = "Target player in tooltip.",
			enabledBy = "Tooltip.Enable",
		}),
		T("Title", L_GUI_TOOLTIP_TITLE or "Title", {
			type = "toggle",
			desc = "Player title in tooltip.",
			enabledBy = "Tooltip.Enable",
		}),
		T("Rank", L_GUI_TOOLTIP_RANK or "Guild rank", {
			type = "toggle",
			desc = "Player guild-rank in tooltip.",
			enabledBy = "Tooltip.Enable",
		}),
		T("Talents", L_GUI_TOOLTIP_TALENTS or "Talents", {
			type = "toggle",
			desc = "Show tooltip talents.",
			enabledBy = "Tooltip.Enable",
		}),
		T("WhoTargetting", L_GUI_TOOLTIP_WHO_TARGETTING or "Who targets", {
			type = "toggle",
			desc = "Display who is targetting the unit that is in your party/raid.",
			enabledBy = "Tooltip.Enable",
		}),
		T("HealthValue", L_GUI_TOOLTIP_HEALTH or "Health value", {
			type = "toggle",
			desc = "Numeral health value.",
			enabledBy = "Tooltip.Enable",
		}),
		T("RaidIcon", L_GUI_TOOLTIP_RAID_ICON or "Raid icon", {
			type = "toggle",
			enabledBy = "Tooltip.Enable",
		}),
		T("ArenaExperience", L_GUI_TOOLTIP_ARENA_EXPERIENCE or "Arena experience", {
			type = "toggle",
			desc = "Player PvP experience in arena.",
			enabledBy = "Tooltip.Enable",
		}),
		T("Achievements", L_GUI_TOOLTIP_ACHIEVEMENTS or "Achievements", {
			type = "toggle",
			desc = "Comparing achievements in tooltip.",
			enabledBy = "Tooltip.Enable",
		}),
		{ header = "Item info", advanced = true },
		T("ItemIcon", L_GUI_TOOLTIP_ICON or "Item icon", {
			type = "toggle", enabledBy = "Tooltip.Enable",
		}),
		T("ItemCount", L_GUI_TOOLTIP_ITEM_COUNT or "Item count", {
			type = "toggle", enabledBy = "Tooltip.Enable",
		}),
		T("SpellID", L_GUI_TOOLTIP_SPELL_ID or "Spell ID", {
			type = "toggle", enabledBy = "Tooltip.Enable",
		}),
		T("QualityBorder", L_GUI_TOOLTIP_QUALITY_BORDER or "Quality border", {
			type = "toggle",
			desc = "Item border color quality.",
			enabledBy = "Tooltip.Enable",
		}),
		T("InstanceLock", L_GUI_TOOLTIP_INSTANCE_LOCK or "Instance lock", {
			type = "toggle",
			desc = "Your instance lock status in tooltip.",
			enabledBy = "Tooltip.Enable",
		}),
	},
})
