-- budsUI_Config :: Pages/General.lua

local _, ns = ...

local function T(group, option, label, extra)
	local entry = { group = group, option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

ns.RegisterPage({
	key = "General",
	name = L_GUI_GENERAL_AUTOSCALE and "General" or "General",
	order = 1,
	schema = {
		{ header = "General" },
		{
			description = "UI scale, fonts and client tweaks. " ..
				"Scale changes need a UI reload (APPLY button below).",
		},
		T("General", "AutoScale", L_GUI_GENERAL_AUTOSCALE or "Auto UI Scale", {
			type = "toggle",
			desc = "Automatic UI scale based on screen resolution.",
		}),
		T("General", "UIScale", L_GUI_GENERAL_UISCALE or "UI Scale", {
			type = "number", min = 0.4, max = 1.2, step = 0.01,
			enabledBy = nil,
			desc = "Manual UI scale (used when auto-scale is off).",
			reload = true,
		}),
		T("General", "MultisampleCheck", L_GUI_GENERAL_MULTISAMPLE_CHECK or "Crisp borders", {
			type = "toggle", advanced = true,
			desc = "Reduce antialiasing so borders stay crisp.",
		}),
		T("General", "ReplaceBlizzardFonts", L_GUI_GENERAL_REPLACE_BLIZZARD_FONTS or "Replace Blizzard fonts", {
			type = "toggle",
			desc = "Replace all default fonts with budsUI fonts.",
			reload = true,
		}),
		T("General", "BubbleFontSize", L_GUI_GENERAL_CHATBUBBLE_FONTSIZE or "Chat bubble font size", {
			type = "number", min = 8, max = 32, step = 1,
		}),
		T("General", "BubbleBackdrop", L_GUI_GENERAL_CHATBUBBLE_NOBACKDROP or "Chat bubble backdrop", {
			type = "toggle",
			desc = "Remove the chat bubble backdrop.",
		}),
		T("General", "WelcomeMessage", L_GUI_GENERAL_WELCOME_MESSAGE or "Welcome message", {
			type = "toggle",
			desc = "Welcome message in chat after login.",
		}),
		T("General", "DeveloperMode", L_GUI_GENERAL_DEVELOPER_MODE or "Developer mode", {
			type = "toggle", advanced = true,
			desc = "Extra debug output. For developers only.",
		}),
	},
})
