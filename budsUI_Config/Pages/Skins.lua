-- budsUI_Config :: Pages/Skins.lua

local _, ns = ...

local function T(option, label, extra)
	local entry = { group = "Skins", option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

ns.RegisterPage({
	key = "Skins",
	name = L_GUI_SKINS or "Stylization",
	order = 19,
	schema = {
		{ header = L_GUI_SKINS or "Stylization" },
		{
			description = "Apply the budsUI style to Blizzard frames and addons. " ..
				"Changing these needs a UI reload.",
		},
		T("DBM", L_GUI_SKINS_DBM or "DeadlyBossMods", {
			type = "toggle", reload = true,
			desc = "Enable styling DeadlyBossMods.",
		}),
		T("Skada", L_GUI_SKINS_SKADA or "Skada", {
			type = "toggle", reload = true,
			desc = "Enable styling Skada.",
		}),
		T("Recount", L_GUI_SKINS_RECOUNT or "Recount", {
			type = "toggle", reload = true,
			desc = "Enable styling Recount.",
		}),
		T("WeakAuras", L_GUI_SKINS_WEAKAURAS or "WeakAuras", {
			type = "toggle", reload = true,
			desc = "Enable styling WeakAuras.",
		}),
		T("Spy", L_GUI_SKINS_SPY or "Spy", {
			type = "toggle", reload = true,
			desc = "Enable styling Spy.",
		}),
		T("RaidRoll", L_GUI_SKINS_RAIDROLL or "RaidRoll", {
			type = "toggle", reload = true,
			desc = "Enable styling RaidRoll.",
		}),
		T("CLCRet", L_GUI_SKINS_CLCR or "CLCRet", {
			type = "toggle", reload = true,
			desc = "Enable styling CLCRet.",
		}),
		T("CharacterStats", L_GUI_SKINS_CHARACTER_STATS or "Character stats", {
			type = "toggle", reload = true,
			desc = "Enable extended character stats panel.",
		}),
		T("ChatBubble", L_GUI_SKINS_CHAT_BUBBLE or "Chat bubbles", {
			type = "toggle", reload = true,
			desc = "Enable styling chat bubbles.",
		}),
		T("MinimapButtons", L_GUI_SKINS_MINIMAP_BUTTONS or "Minimap buttons", {
			type = "toggle", reload = true,
			desc = "Enable styling addon icons on minimap.",
		}),
		T("WorldMap", L_GUI_SKINS_WORLDMAP or "Worldmap", {
			type = "toggle", reload = true,
			desc = "Enable styling Worldmap.",
		}),
		T("WorldMapScale", "World map scale", {
			type = "number", min = 0.4, max = 1.5, step = 0.05, advanced = true,
			enabledBy = "Skins.WorldMap",
		}),
		T("WorldMapScaleMini", "Mini world map scale", {
			type = "number", min = 0.4, max = 2, step = 0.05, advanced = true,
			enabledBy = "Skins.WorldMap",
		}),
	},
})
