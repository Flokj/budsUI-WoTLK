-- budsUI_Config :: Pages/Blizzard.lua

local _, ns = ...

local function T(option, label, extra)
	local entry = { group = "Blizzard", option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

ns.RegisterPage({
	key = "Blizzard",
	name = L_GUI_BLIZZARD or "Blizzard",
	order = 7,
	schema = {
		{ header = L_GUI_BLIZZARD or "Blizzard" },
		{
			description = "Styling and improvements for default Blizzard frames.",
		},
		T("CaptureBar", L_GUI_BLIZZARD_CAPTUREBAR or "Capture bar", {
			type = "toggle",
			desc = "Style & move World state Capture bar.",
		}),
		T("ClassColor", L_GUI_BLIZZARD_CLASS_COLOR or "Class colors", {
			type = "toggle",
			desc = "Colorize player names by their class in friend list, who list, guild list, etc.",
		}),
		T("Durability", L_GUI_BLIZZARD_DURABILITY or "Durability meter", {
			type = "toggle",
			desc = "Show standalone durability meter.",
		}),
		T("EnhanceProfessions", L_GUI_BLIZZARD_ENHANCE_PROFESSIONS or "Enhanced professions", {
			type = "toggle",
			desc = "Enhanced profession window (double-wide, more recipes).",
		}),
		T("EnhanceTrainers", L_GUI_BLIZZARD_ENHANCE_TRAINERS or "Enhanced trainers", {
			type = "toggle",
			desc = "Enhanced trainer window (double-wide, more skills).",
		}),
		T("TrainAllButton", L_GUI_BLIZZARD_TRAIN_ALL or "Train All button", {
			type = "toggle",
			desc = "Show Train All button in the trainer window.",
			enabledBy = "Blizzard.EnhanceTrainers",
		}),
		T("MoveAchievements", L_GUI_BLIZZARD_ACHIEVEMENTS or "Achievements", {
			type = "toggle",
			desc = "Style & move Achievement frame.",
		}),
		T("Reputations", L_GUI_BLIZZARD_REPUTATIONS or "Reputations", {
			type = "toggle",
			desc = "Display reputation rewards for quests.",
		}),
	},
})
