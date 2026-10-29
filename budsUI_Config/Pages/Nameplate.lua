-- budsUI_Config :: Pages/Nameplate.lua

local _, ns = ...

local function T(option, label, extra)
	local entry = { group = "Nameplate", option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

local generalSchema = {
	{ header = UNIT_NAMEPLATES or "Nameplates" },
	T("Enable", L_GUI_NAMEPLATE_ENABLE or "Enable nameplates", {
		type = "toggle", reload = true,
	}),
	T("Width", L_GUI_NAMEPLATE_WIDTH or "Width", {
		type = "number", min = 50, max = 300, step = 1,
		enabledBy = "Nameplate.Enable",
	}),
	T("Height", L_GUI_NAMEPLATE_HEIGHT or "Height", {
		type = "number", min = 5, max = 50, step = 1,
		enabledBy = "Nameplate.Enable",
	}),
	T("AdditionalWidth", L_GUI_NAMEPLATE_AD_WIDTH or "Selected width bonus", {
		type = "number", min = 0, max = 100, step = 1,
		enabledBy = "Nameplate.Enable",
		desc = "Additional width for selected nameplate.",
	}),
	T("AdditionalHeight", L_GUI_NAMEPLATE_AD_HEIGHT or "Selected height bonus", {
		type = "number", min = 0, max = 50, step = 1,
		enabledBy = "Nameplate.Enable",
		desc = "Additional height for selected nameplate.",
	}),
	T("HealthValue", L_GUI_NAMEPLATE_HEALTH or "Health value", {
		type = "toggle",
		desc = "Numeral health value.",
		enabledBy = "Nameplate.Enable",
	}),
	T("NameAbbreviate", L_GUI_NAMEPLATE_NAME_ABBREV or "Abbreviated names", {
		type = "toggle",
		desc = "Display abbreviated unit names.",
		enabledBy = "Nameplate.Enable",
	}),
	T("Combat", L_GUI_NAMEPLATE_COMBAT or "Show in combat", {
		type = "toggle",
		desc = "Automatically show nameplates in combat.",
		enabledBy = "Nameplate.Enable",
	}),
	T("ClassIcons", L_GUI_NAMEPLATE_CLASS_ICON or "Class icons in PvP", {
		type = "toggle",
		desc = "Icons by class in PvP.",
		enabledBy = "Nameplate.Enable",
	}),
	{ header = "Auras" },
	T("Auras", L_GUI_NAMEPLATE_SHOW_DEBUFFS or "Show debuffs", {
		type = "toggle",
		desc = "Show debuffs (from the list).",
		enabledBy = "Nameplate.Enable",
	}),
	T("AuraSize", L_GUI_NAMEPLATE_DEBUFFS_SIZE or "Debuffs size", {
		type = "number", min = 10, max = 50, step = 1,
		enabledBy = { "Nameplate.Enable", "Nameplate.Auras" },
	}),
	T("AuraSizeHighlight", L_GUI_NAMEPLATE_DEBUFFS_SIZE_HIGHLIGHT or "Highlight size", {
		type = "number", min = 10, max = 50, step = 1,
		enabledBy = { "Nameplate.Enable", "Nameplate.Auras" },
	}),
	T("AuraOffsetY", L_GUI_NAMEPLATE_AURA_OFFSET_Y or "Aura offset", { type = "number", min = 0, max = 60, step = 1, enabledBy = { "Nameplate.Enable", "Nameplate.Auras" } }),
	T("CastBarName", L_GUI_NAMEPLATE_CASTBAR_NAME or "Castbar name", {
		type = "toggle",
		desc = "Show castbar name.",
		enabledBy = "Nameplate.Enable",
	}),
	{ header = "Threat" },
	T("EnhanceThreat", L_GUI_NAMEPLATE_THREAT or "Threat feature", {
		type = "toggle",
		desc = "Enable threat feature, automatically changes by your role.",
		enabledBy = "Nameplate.Enable",
	}),
	T("GoodColor", L_GUI_NAMEPLATE_GOOD_COLOR or "Good threat color", {
		type = "color",
		desc = "Good threat color, varies depending if you are a tank or dps/heal.",
		enabledBy = { "Nameplate.Enable", "Nameplate.EnhanceThreat" },
	}),
	T("NearColor", L_GUI_NAMEPLATE_NEAR_COLOR or "Near threat color", {
		type = "color",
		desc = "Losing/Gaining threat color.",
		enabledBy = { "Nameplate.Enable", "Nameplate.EnhanceThreat" },
	}),
	T("BadColor", L_GUI_NAMEPLATE_BAD_COLOR or "Bad threat color", {
		type = "color",
		desc = "Bad threat color, varies depending if you are a tank or dps/heal.",
		enabledBy = { "Nameplate.Enable", "Nameplate.EnhanceThreat" },
	}),
}

local function getBlacklist()
	local _, C = ns.Engine()
	if not C or not C.Nameplate then return {} end
	if not C.Nameplate.Blacklist then
		C.Nameplate.Blacklist = {}
	end
	return C.Nameplate.Blacklist
end

local function saveBlacklist(list)
	local K, C = ns.Engine()
	if C and C.Nameplate then
		C.Nameplate.Blacklist = CopyTable(list)
	end
	local active = K and K.GetActiveProfile and K.GetActiveProfile()
	if active and budsUIData and budsUIData.Profiles and budsUIData.Profiles[active] then
		local P = budsUIData.Profiles[active]
		if not P.Nameplate then P.Nameplate = {} end
		P.Nameplate.Blacklist = CopyTable(list)
	end
end

local function setBlacklistEnable(enabled)
	local K, C = ns.Engine()
	if C and C.Nameplate then
		C.Nameplate.BlacklistEnable = enabled
	end
	local active = K and K.GetActiveProfile and K.GetActiveProfile()
	if active and budsUIData and budsUIData.Profiles and budsUIData.Profiles[active] then
		local P = budsUIData.Profiles[active]
		if not P.Nameplate then P.Nameplate = {} end
		P.Nameplate.BlacklistEnable = enabled
	end
	if K and K.UpdatePlateBlacklist then
		K.UpdatePlateBlacklist()
	end
end

local function addName(name)
	name = name and strtrim(name)
	if not name or name == "" then return end
	local lower = string.lower(name)
	local list = getBlacklist()
	for _, existing in ipairs(list) do
		if string.lower(existing) == lower then
			return
		end
	end
	list[#list + 1] = name
	saveBlacklist(list)
	local K = ns.Engine()
	if K and K.UpdatePlateBlacklist then
		K.UpdatePlateBlacklist()
	end
	ns.RefreshPage(true)
end

local function buildBlacklistSchema()
	local _, C = ns.Engine()
	local schema = {
		{ header = L_GUI_NAMEPLATE_BLACKLIST or "Blacklist" },
		{
			group = "Nameplate",
			option = "BlacklistEnable",
			label = L_GUI_NAMEPLATE_BLACKLIST_ENABLE or "Enable blacklist",
			type = "toggle",
			desc = L_GUI_NAMEPLATE_BLACKLIST_DESC or "Nameplates of the units in the list are not shown and do not react to clicks or mouseover.",
			get = function()
				return C and C.Nameplate and C.Nameplate.BlacklistEnable ~= false
			end,
			set = function(val)
				setBlacklistEnable(val)
				ns.RefreshPage(true)
			end,
		},
		{ header = L_GUI_NAMEPLATE_BLACKLIST_NAMES or "Blacklisted Units" },
	}

	local list = getBlacklist()
	for index, name in ipairs(list) do
		local idx = index
		schema[#schema + 1] = {
			type = "custom",
			label = name,
			userContent = true,
			noReset = true,
			indent = false,
			enabledBy = "Nameplate.BlacklistEnable",
			build = function(row)
				local remove = ns.CreateButton(row, L_GUI_REMOVE or "Remove", 64, true, 20)
				remove:SetPoint("RIGHT", row, "RIGHT", -6, 0)
				remove:SetScript("OnClick", function()
					local current = getBlacklist()
					table.remove(current, idx)
					saveBlacklist(current)
					local K = ns.Engine()
					if K and K.UpdatePlateBlacklist then
						K.UpdatePlateBlacklist()
					end
					ns.RefreshPage(true)
				end)
				row.removeButton = remove
			end,
			setEnabled = function(row, enabled)
				if row.label then
					ns.SetTextEnabled(row.label, enabled)
				end
				if row.removeButton then
					ns.SetControlEnabled(row.removeButton, enabled)
				end
			end,
		}
	end

	schema[#schema + 1] = {
		type = "input",
		label = L_GUI_NAMEPLATE_ADD_NAME or "Add name",
		text = L_GUI_ADD or "Add",
		width = 160,
		maxLetters = 48,
		indent = false,
		enabledBy = "Nameplate.BlacklistEnable",
		func = addName,
	}

	schema[#schema + 1] = {
		type = "execute",
		label = L_GUI_NAMEPLATE_ADD_TARGET or "Add from target",
		text = L_GUI_NAMEPLATE_ADD_TARGET or "Add from target",
		width = 160,
		indent = false,
		enabledBy = "Nameplate.BlacklistEnable",
		func = function()
			if UnitExists("target") then
				addName(UnitName("target"))
			end
		end,
	}

	return schema
end

ns.RegisterPage({
	key = "Nameplate",
	name = UNIT_NAMEPLATES or "Nameplates",
	order = 16,
	tabs = {
		{ key = "General", name = "General", schema = generalSchema },
		{ key = "Blacklist", name = L_GUI_NAMEPLATE_BLACKLIST or "Blacklist", schema = buildBlacklistSchema },
	},
})
