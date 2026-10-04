-- budsUI_Config :: Pages/Unitframe.lua
-- Nested per-unit tables (C.Unitframe.Player, .Target, ...) are addressed
-- with group = "Unitframe", option = <sub-table>, key = <field>.
-- Writes go through ns.Set which merges one level deep, exactly like the
-- legacy monolith and MergeProfileIntoC on load.

local _, ns = ...

local function T(option, label, extra)
	local entry = { group = "Unitframe", option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

local function S(sub, key, label, extra)
	local entry = { group = "Unitframe", option = sub, key = key, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

local function Dims(sub, advanced)
	local adv = advanced and true or nil
	return {
		S(sub, "Width", L_GUI_UNITFRAME_WIDTH or "Width", {
			type = "number", min = 40, max = 400, step = 1, advanced = adv,
		}),
		S(sub, "Height", L_GUI_UNITFRAME_HEIGHT or "Height", {
			type = "number", min = 8, max = 100, step = 1, advanced = adv,
		}),
		S(sub, "PowerHeight", L_GUI_UNITFRAME_POWER_HEIGHT or "Power height", {
			type = "number", min = 0, max = 40, step = 1, advanced = true,
		}),
		S(sub, "ShowPower", L_GUI_UNITFRAME_SHOW_POWER or "Show power bar", {
			type = "toggle",
		}),
	}
end

local PORTRAIT_STYLE = {
	{ "3D", "3D" },
	{ "2D", "2D" },
	{ "Class", "Class" },
}

local TEXT_FORMAT = {
	{ "None", "None" },
	{ "Current", "Current" },
	{ "Percent", "Percent" },
	{ "Both", "Both" },
}

local schema = {
	{ header = L_GUI_UNITFRAME_GENERAL or "General" },
	T("Enable", L_GUI_UNITFRAME_ENABLE or "Enable unitframes", {
		type = "toggle", reload = true,
		desc = "Use budsUI Player, Target & Focus layout.",
	}),
	T("Texture", L_GUI_UNITFRAME_TEXTURE or "Statusbar texture", {
		type = "string", width = 180, maxLetters = 64,
		desc = "SharedMedia statusbar name.",
	}),
	T("ClassHealth", L_GUI_UNITFRAME_CLASS_HEALTH or "Class-colored health", {
		type = "toggle",
		desc = "Use class colors for your health bars instead of green.",
	}),
	T("ClassColorBorder", L_GUI_UNITFRAME_CLASS_COLOR_BORDER or "Class-colored border", {
		type = "toggle",
	}),
	T("ThreatHealthColor", L_GUI_UNITFRAME_THREAT_HEALTH_COLOR or "Threat health color", {
		type = "toggle",
		desc = "Color enemy health by threat.",
	}),
	T("BarBackdrop", L_GUI_UNITFRAME_BAR_BACKDROP or "Bar backdrop", {
		type = "toggle",
		desc = "Tint the empty part of bars.",
	}),
	T("Portrait", L_GUI_UNITFRAME_PORTRAIT or "Portraits", {
		type = "toggle",
		desc = "Show portraits.",
	}),
	T("PortraitStyle", L_GUI_UNITFRAME_PORTRAIT_STYLE or "Portrait style", {
		type = "select", width = 120, values = PORTRAIT_STYLE,
		enabledBy = "Unitframe.Portrait",
		desc = "3D, 2D or Class.",
	}),
	T("HealthPrediction", L_GUI_UNITFRAME_HEALTH_PREDICTION or "Incoming heals", {
		type = "toggle",
		desc = "Show incoming heals on health bars.",
	}),
	T("AbsorbShields", L_GUI_UNITFRAME_ABSORB_SHIELDS or "Absorb shields", {
		type = "toggle",
		desc = "Show absorb shields on health bars.",
	}),
	T("HealthPredictionSplit", L_GUI_UNITFRAME_HEALTH_PREDICTION_SPLIT or "Split own heals", {
		type = "toggle",
		desc = "Show your own incoming heals as a separate segment.",
		enabledBy = "Unitframe.HealthPrediction",
	}),
	T("HealthPredictionColor", L_GUI_UNITFRAME_HEALTH_PREDICTION_COLOR or "Incoming heals color", {
		type = "color",
		desc = "Color of incoming heals from others.",
		enabledBy = "Unitframe.HealthPrediction",
	}),
	T("HealthPredictionOwnColor", L_GUI_UNITFRAME_HEALTH_PREDICTION_OWN_COLOR or "Own heals color", {
		type = "color",
		desc = "Color of your own incoming heals.",
		enabledBy = { "Unitframe.HealthPrediction", "Unitframe.HealthPredictionSplit" },
	}),
	T("AbsorbColor", L_GUI_UNITFRAME_ABSORB_COLOR or "Absorb shields color", {
		type = "color",
		desc = "Color of absorb shields.",
		enabledBy = "Unitframe.AbsorbShields",
	}),
	T("RangeFade", L_GUI_UNITFRAME_RANGE_FADE or "Range fade", {
		type = "toggle",
		desc = "Fade frames of out-of-range units.",
	}),
	T("RangeAlpha", L_GUI_UNITFRAME_RANGE_ALPHA or "Out-of-range opacity", {
		type = "number", min = 0, max = 1, step = 0.05,
		enabledBy = "Unitframe.RangeFade",
	}),
	T("HealthFormat", L_GUI_UNITFRAME_HEALTH_FORMAT or "Health text", {
		type = "select", width = 130, values = TEXT_FORMAT,
	}),
	T("PowerFormat", L_GUI_UNITFRAME_POWER_FORMAT or "Power text", {
		type = "select", width = 130, values = TEXT_FORMAT,
	}),
	T("NameColor", L_GUI_UNITFRAME_NAME_COLOR or "Class-colored names", {
		type = "toggle",
		desc = "Color names by class/reaction.",
	}),
	T("NameLength", L_GUI_UNITFRAME_NAME_length or "Max name length", {
		type = "number", min = 0, max = 30, step = 1,
		desc = "0 = unlimited.",
	}),
	T("NameBackground", L_GUI_UNITFRAME_NAME_BACKGROUND or "Name background", {
		type = "toggle",
		desc = "Dark strip behind name and level texts.",
	}),
	T("FontOutline", L_GUI_UNITFRAME_FONT_OUTLINE or "Font outline", {
		type = "toggle",
		desc = "OUTLINE on unitframe texts instead of shadow.",
	}),
	T("PercentHealth", L_GUI_UNITFRAME_PERCENT_HEALTH or "Health color by percent", {
		type = "toggle", advanced = true,
		desc = "Health bars change color with health percent. Turn class colors off first.",
	}),
	T("BetterPowerColors", L_GUI_UNITFRAME_BETTER_POWER_COLOR or "Better power colors", {
		type = "toggle", advanced = true,
		desc = "Override the global power color table with budsUI colors.",
	}),
	T("GroupDispelOnly", L_GUI_UNITFRAME_GROUP_DISPEL_ONLY or "Only dispellable group debuffs", {
		type = "toggle",
		desc = "Party/raid frames show only debuffs you can dispel.",
	}),
	T("AuraWatch", L_GUI_UNITFRAME_AURA_WATCH or "Corner aura watch", {
		type = "toggle",
		desc = "Corner dots on party/raid frames for tracked heals.",
	}),

	{ header = L_GUI_UNITFRAME_OPT_PLAYER or "Player" },
	S("Player", "Enable", L_GUI_UNITFRAME_OPT_ENABLE or "Enable", { type = "toggle" }),
}
for _, e in ipairs(Dims("Player")) do
	schema[#schema + 1] = e
end
for _, e in ipairs({
	S("Player", "Buffs", L_GUI_UNITFRAME_OPT_BUFFS or "Buffs", { type = "toggle" }),
	S("Player", "Debuffs", L_GUI_UNITFRAME_OPT_DEBUFFS or "Debuffs", { type = "toggle" }),
	S("Player", "ClassPower", L_GUI_UNITFRAME_OPT_CLASS_POWER or "Class power", {
		type = "toggle", desc = "Combo points / runes.",
	}),
	S("Player", "AdditionalPower", L_GUI_UNITFRAME_OPT_ADDITIONAL_POWER or "Druid mana", {
		type = "toggle", desc = "Druid mana strip.",
	}),
	S("Player", "ShowName", L_GUI_UNITFRAME_OPT_SHOW_NAME or "Show name", { type = "toggle" }),
}) do
	schema[#schema + 1] = e
end

schema[#schema + 1] = { header = L_GUI_UNITFRAME_OPT_TARGET or "Target" }
schema[#schema + 1] = S("Target", "Enable", L_GUI_UNITFRAME_OPT_ENABLE or "Enable", { type = "toggle" })
for _, e in ipairs(Dims("Target")) do
	schema[#schema + 1] = e
end
schema[#schema + 1] = S("Target", "Buffs", L_GUI_UNITFRAME_OPT_BUFFS or "Buffs", { type = "toggle" })
schema[#schema + 1] = S("Target", "Debuffs", L_GUI_UNITFRAME_OPT_DEBUFFS or "Debuffs", { type = "toggle" })

schema[#schema + 1] = { header = L_GUI_UNITFRAME_OPT_FOCUS or "Focus" }
schema[#schema + 1] = S("Focus", "Enable", L_GUI_UNITFRAME_OPT_ENABLE or "Enable", { type = "toggle" })
for _, e in ipairs(Dims("Focus")) do
	schema[#schema + 1] = e
end
schema[#schema + 1] = S("Focus", "Debuffs", L_GUI_UNITFRAME_OPT_DEBUFFS or "Debuffs", { type = "toggle" })

schema[#schema + 1] = { header = L_GUI_UNITFRAME_OPT_TARGETTOT or "Target of target" }
schema[#schema + 1] = S("TargetOfTarget", "Enable", "Target of target", { type = "toggle" })
for _, e in ipairs(Dims("TargetOfTarget")) do
	schema[#schema + 1] = e
end
schema[#schema + 1] = S("TargetOfTarget", "Debuffs", L_GUI_UNITFRAME_OPT_DEBUFFS or "Debuffs", { type = "toggle" })
schema[#schema + 1] = { header = L_GUI_UNITFRAME_OPT_PET or "Pet" }
schema[#schema + 1] = S("Pet", "Enable", "Pet", { type = "toggle" })
for _, e in ipairs(Dims("Pet")) do
	schema[#schema + 1] = e
end
schema[#schema + 1] = S("Pet", "Debuffs", L_GUI_UNITFRAME_OPT_DEBUFFS or "Debuffs", { type = "toggle" })
schema[#schema + 1] = { header = L_GUI_UNITFRAME_OPT_FOCUSTARGET or "Focus target" }
schema[#schema + 1] = S("FocusTarget", "Enable", "Focus target", { type = "toggle" })
for _, e in ipairs(Dims("FocusTarget")) do
	schema[#schema + 1] = e
end
schema[#schema + 1] = S("FocusTarget", "Debuffs", L_GUI_UNITFRAME_OPT_DEBUFFS or "Debuffs", { type = "toggle" })

schema[#schema + 1] = { header = L_GUI_UNITFRAME_OPT_PARTY or "Party" }
for _, e in ipairs({
	S("Party", "Enable", L_GUI_UNITFRAME_OPT_ENABLE or "Enable", { type = "toggle" }),
	S("Party", "Width", L_GUI_UNITFRAME_WIDTH or "Width", { type = "number", min = 40, max = 400, step = 1 }),
	S("Party", "Height", L_GUI_UNITFRAME_HEIGHT or "Height", { type = "number", min = 8, max = 100, step = 1 }),
	S("Party", "PowerHeight", L_GUI_UNITFRAME_POWER_HEIGHT or "Power height", {
		type = "number", min = 0, max = 40, step = 1, advanced = true,
	}),
	S("Party", "ShowPower", L_GUI_UNITFRAME_SHOW_POWER or "Show power bar", { type = "toggle" }),
	S("Party", "ShowPlayer", L_GUI_UNITFRAME_OPT_SHOW_PLAYER or "Show player", { type = "toggle" }),
	S("Party", "ShowSolo", L_GUI_UNITFRAME_OPT_SHOW_SOLO or "Show while solo", { type = "toggle" }),
	S("Party", "RaidStyle", L_GUI_UNITFRAME_OPT_RAID_STYLE or "Raid style in party", { type = "toggle" }),
	S("Party", "Portrait", L_GUI_UNITFRAME_OPT_PORTRAIT or "Portraits", { type = "toggle" }),
	S("Party", "Debuffs", L_GUI_UNITFRAME_OPT_DEBUFFS or "Debuffs", { type = "toggle" }),
	S("Party", "DispelHighlight", L_GUI_UNITFRAME_OPT_DISPEL or "Dispel highlight", { type = "toggle" }),
	S("Party", "Castbar", L_GUI_UNITFRAME_OPT_CASTBAR or "Castbar", { type = "toggle" }),
}) do
	schema[#schema + 1] = e
end

schema[#schema + 1] = { header = L_GUI_UNITFRAME_OPT_RAID or "Raid" }
for _, e in ipairs({
	S("Raid", "Enable", L_GUI_UNITFRAME_OPT_ENABLE or "Enable", { type = "toggle" }),
	S("Raid", "Width", L_GUI_UNITFRAME_WIDTH or "Width", { type = "number", min = 40, max = 200, step = 1 }),
	S("Raid", "Height", L_GUI_UNITFRAME_HEIGHT or "Height", { type = "number", min = 8, max = 100, step = 1 }),
	S("Raid", "PowerHeight", L_GUI_UNITFRAME_POWER_HEIGHT or "Power height", {
		type = "number", min = 0, max = 20, step = 1, advanced = true,
	}),
	S("Raid", "PowerGap", L_GUI_UNITFRAME_POWER_GAP or "Power gap", {
		type = "number", min = 0, max = 20, step = 1, advanced = true,
	}),
	S("Raid", "PowerMode", L_GUI_UNITFRAME_OPT_POWER_MODE or "Power mode", {
		type = "select", width = 120,
		values = { { "All", "All" }, { "Mana", "Mana" }, { "None", "None" } },
	}),
	S("Raid", "GroupsPerRow", L_GUI_UNITFRAME_OPT_GROUPS_PER_ROW or "Groups per row", {
		type = "number", min = 1, max = 8, step = 1,
	}),
	S("Raid", "GroupBy", L_GUI_UNITFRAME_OPT_GROUP_BY or "Group by", {
		type = "select", width = 120,
		values = { { "GROUP", "GROUP" }, { "CLASS", "CLASS" } },
	}),
	S("Raid", "RaidWide", L_GUI_UNITFRAME_OPT_RAID_WIDE or "Fill across groups", { type = "toggle" }),
	S("Raid", "SortDirection", L_GUI_UNITFRAME_OPT_SORT_DIR or "Sort direction", {
		type = "select", width = 120,
		values = { { "ASC", "ASC" }, { "DESC", "DESC" } },
	}),
	S("Raid", "Orientation", L_GUI_UNITFRAME_OPT_ORIENTATION or "Growth", {
		type = "select", width = 150,
		values = {
			{ "DOWN_RIGHT", "DOWN_RIGHT" }, { "DOWN_LEFT", "DOWN_LEFT" },
			{ "UP_RIGHT", "UP_RIGHT" }, { "UP_LEFT", "UP_LEFT" },
		},
	}),
	S("Raid", "DispelHighlight", L_GUI_UNITFRAME_OPT_DISPEL or "Dispel highlight", { type = "toggle" }),
	S("Raid", "ShowGroupNumber", L_GUI_UNITFRAME_OPT_GROUP_NUMBERS or "Group numbers", { type = "toggle" }),
}) do
	schema[#schema + 1] = e
end

schema[#schema + 1] = { header = L_GUI_UNITFRAME_OPT_BOSS or "Boss" }
schema[#schema + 1] = S("Boss", "Enable", L_GUI_UNITFRAME_OPT_ENABLE or "Enable", { type = "toggle" })
for _, e in ipairs(Dims("Boss")) do
	schema[#schema + 1] = e
end
for _, e in ipairs({
	S("Boss", "Spacing", L_GUI_UNITFRAME_SPACING or "Spacing", {
		type = "number", min = 0, max = 80, step = 1,
	}),
	S("Boss", "Portrait", L_GUI_UNITFRAME_OPT_PORTRAIT or "Portraits", { type = "toggle" }),
	S("Boss", "Debuffs", L_GUI_UNITFRAME_OPT_DEBUFFS or "Debuffs", { type = "toggle" }),
	S("Boss", "Castbar", L_GUI_UNITFRAME_OPT_CASTBAR or "Castbar", { type = "toggle" }),
}) do
	schema[#schema + 1] = e
end

schema[#schema + 1] = { header = L_GUI_UNITFRAME_OPT_AURAS or "Auras" }
for _, e in ipairs({
	S("Auras", "PerRow", L_GUI_UNITFRAME_OPT_PER_ROW or "Auras per row", {
		type = "number", min = 1, max = 12, step = 1,
	}),
	S("Auras", "NumBuffs", L_GUI_UNITFRAME_OPT_NUM_BUFFS or "Max buffs", {
		type = "number", min = 0, max = 30, step = 1,
	}),
	S("Auras", "NumDebuffs", L_GUI_UNITFRAME_OPT_NUM_DEBUFFS or "Max debuffs", {
		type = "number", min = 0, max = 30, step = 1,
	}),
	S("Auras", "Spacing", L_GUI_UNITFRAME_SPACING or "Spacing", {
		type = "number", min = 0, max = 20, step = 1,
	}),
	S("Auras", "OnlyPlayerDebuffs", L_GUI_UNITFRAME_OPT_ONLY_MINE or "Only your debuffs", {
		type = "toggle",
	}),
}) do
	schema[#schema + 1] = e
end

schema[#schema + 1] = { header = L_GUI_UNITFRAME_OPT_CLASSPOWER or "Class power", advanced = true }
schema[#schema + 1] = S("ClassPower", "Height", L_GUI_UNITFRAME_HEIGHT or "Height", {
	type = "number", min = 4, max = 30, step = 1, advanced = true,
})
schema[#schema + 1] = S("ClassPower", "Spacing", L_GUI_UNITFRAME_SPACING or "Spacing", {
	type = "number", min = 0, max = 20, step = 1, advanced = true,
})

schema[#schema + 1] = { header = L_GUI_UNITFRAME_OPT_CASTBAR or "Castbar" }
for _, e in ipairs({
	S("Castbar", "Enable", L_GUI_UNITFRAME_OPT_ENABLE or "Enable", { type = "toggle" }),
	S("Castbar", "ShowIcon", L_GUI_UNITFRAME_OPT_SHOW_ICON or "Icon", { type = "toggle" }),
	S("Castbar", "ShowTimer", L_GUI_UNITFRAME_OPT_SHOW_TIMER or "Timer", { type = "toggle" }),
	S("Castbar", "ShowSpark", L_GUI_UNITFRAME_OPT_SHOW_SPARK or "Spark", { type = "toggle" }),
	S("Castbar", "ShowLatency", L_GUI_UNITFRAME_OPT_SHOW_LATENCY or "Latency zone", { type = "toggle" }),
	S("Castbar", "ShowTicks", L_GUI_UNITFRAME_OPT_SHOW_TICKS or "Channel ticks", { type = "toggle" }),
	S("Castbar", "TimeToHold", L_GUI_UNITFRAME_OPT_HOLD_TIME or "Hold time", {
		type = "number", min = 0, max = 2, step = 0.1, unit = "s", advanced = true,
	}),
	S("Castbar", "PlayerWidth", L_GUI_UNITFRAME_OPT_PLAYER_WIDTH or "Player width", {
		type = "number", min = 100, max = 400, step = 1,
	}),
	S("Castbar", "PlayerHeight", L_GUI_UNITFRAME_OPT_PLAYER_HEIGHT or "Player height", {
		type = "number", min = 10, max = 60, step = 1,
	}),
	S("Castbar", "TargetWidth", L_GUI_UNITFRAME_OPT_TARGET_WIDTH or "Target width", {
		type = "number", min = 100, max = 400, step = 1,
	}),
	S("Castbar", "TargetHeight", L_GUI_UNITFRAME_OPT_TARGET_HEIGHT or "Target height", {
		type = "number", min = 10, max = 60, step = 1,
	}),
	S("Castbar", "FocusWidth", L_GUI_UNITFRAME_OPT_FOCUS_WIDTH or "Focus width", {
		type = "number", min = 100, max = 400, step = 1,
	}),
	S("Castbar", "FocusHeight", L_GUI_UNITFRAME_OPT_FOCUS_HEIGHT or "Focus height", {
		type = "number", min = 10, max = 60, step = 1,
	}),
}) do
	schema[#schema + 1] = e
end

schema[#schema + 1] = { header = L_GUI_UNITFRAME_OPT_POWERS or "Power colors", advanced = true }
for _, token in ipairs({ "MANA", "RAGE", "FOCUS", "ENERGY", "RUNIC_POWER" }) do
	local label = token:lower():gsub("^%l", string.upper):gsub("_(%l)", function(c)
		return " " .. string.upper(c)
	end)
	schema[#schema + 1] = S("PowerColors", token, label, { type = "color", advanced = true })
end

schema[#schema + 1] = { header = L_GUI_UNITFRAME_OPT_REACTION or "Reaction colors", advanced = true }
for i = 1, 8 do
	schema[#schema + 1] = S("ReactionColors", i,
		_G["FACTION_STANDING_LABEL" .. i] or ("Reaction " .. i),
		{ type = "color", advanced = true })
end

ns.RegisterPage({
	key = "Unitframe",
	name = L_GUI_UNITFRAME or "Unitframes",
	order = 22,
	schema = schema,
})
