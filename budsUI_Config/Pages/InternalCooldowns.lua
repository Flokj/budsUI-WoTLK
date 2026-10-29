-- budsUI_Config :: Pages/InternalCooldowns.lua

local _, ns = ...

local function T(option, label, extra)
	local entry = { group = "InternalCooldowns", option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

local function S(sub, key, label, extra)
	local entry = { group = "InternalCooldowns", option = sub, key = key, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

ns.RegisterPage({
	key = "InternalCooldowns",
	name = L_GUI_ICD or "Internal Cooldowns",
	order = 23,
	schema = {
		{ header = L_GUI_ICD or "Internal Cooldowns" },
		T("Enable", L_GUI_ICD_ENABLE or "Enable", {
			type = "toggle", reload = true,
			desc = "Track internal cooldowns of trinket procs, enchants and talents.",
		}),
		T("HideReady", L_GUI_ICD_HIDE_READY or "Only while on cooldown", {
			type = "toggle",
			enabledBy = "InternalCooldowns.Enable",
			desc = "Hide proc icons that are ready.",
		}),
		T("UnknownTrinkets", L_GUI_ICD_UNKNOWN_TRINKETS or "Unknown enemy trinkets", {
			type = "toggle",
			enabledBy = "InternalCooldowns.Enable",
			desc = "Show question mark icons for enemy trinkets until first proc.",
		}),
		T("ActiveColor", L_GUI_ICD_ACTIVE_COLOR or "Active buff color", {
			type = "color",
			enabledBy = "InternalCooldowns.Enable",
			desc = "Border and glow color while proc buff is active.",
		}),

		{ header = L_GUI_ICD_UNITS or "Units" },
		T("Player", L_GUI_ICD_PLAYER or "Player icons", {
			type = "toggle", reload = true,
			enabledBy = "InternalCooldowns.Enable",
		}),
		T("PlayerDetached", L_GUI_ICD_PLAYER_DETACHED or "Player icons separately", {
			type = "toggle", reload = true,
			enabledBy = "InternalCooldowns.Player",
			desc = "Movable separate block above action bars (move via /moveui).",
		}),
		T("PlayerSize", L_GUI_ICD_PLAYER_SIZE or "Player icon size", {
			type = "number", min = 16, max = 64, step = 1,
			enabledBy = "InternalCooldowns.PlayerDetached",
		}),
		T("Target", L_GUI_ICD_TARGET or "Target icons", {
			type = "toggle", reload = true,
			enabledBy = "InternalCooldowns.Enable",
		}),
		T("Focus", L_GUI_ICD_FOCUS or "Focus icons", {
			type = "toggle", reload = true,
			enabledBy = "InternalCooldowns.Enable",
		}),
		T("Size", L_GUI_ICD_SIZE or "Target/Focus icon size", {
			type = "number", min = 12, max = 48, step = 1,
			enabledBy = "InternalCooldowns.Enable",
		}),
		T("Spacing", L_GUI_ICD_SPACING or "Icon spacing", {
			type = "number", min = 0, max = 10, step = 1, advanced = true,
			enabledBy = "InternalCooldowns.Enable",
		}),
		T("TargetOffsetY", L_GUI_ICD_OFFSET_Y or "Target vertical offset", {
			type = "number", min = -50, max = 100, step = 1, advanced = true,
			enabledBy = "InternalCooldowns.Target",
		}),

		{ header = L_GUI_ICD_SOURCES or "Tracked Sources" },
		S("Slots", "trinket", L_GUI_ICD_SLOT_TRINKET or "Trinkets", {
			type = "toggle",
			enabledBy = "InternalCooldowns.Enable",
		}),
		S("Slots", "weapon", L_GUI_ICD_SLOT_WEAPON or "Weapons and relics", {
			type = "toggle",
			enabledBy = "InternalCooldowns.Enable",
		}),
		S("Slots", "ring", L_GUI_ICD_SLOT_RING or "Rings", {
			type = "toggle",
			enabledBy = "InternalCooldowns.Enable",
		}),
		S("Slots", "armor", L_GUI_ICD_SLOT_ARMOR or "Other equipment", {
			type = "toggle",
			enabledBy = "InternalCooldowns.Enable",
		}),
		S("Slots", "enchant", L_GUI_ICD_SLOT_ENCHANT or "Enchants", {
			type = "toggle",
			enabledBy = "InternalCooldowns.Enable",
		}),
		S("Slots", "gem", L_GUI_ICD_SLOT_GEM or "Meta gems", {
			type = "toggle",
			enabledBy = "InternalCooldowns.Enable",
		}),
		S("Slots", "set", L_GUI_ICD_SLOT_SET or "Tier sets", {
			type = "toggle",
			enabledBy = "InternalCooldowns.Enable",
		}),
		S("Slots", "talent", L_GUI_ICD_SLOT_TALENT or "Talents", {
			type = "toggle",
			enabledBy = "InternalCooldowns.Enable",
		}),
	},
})
