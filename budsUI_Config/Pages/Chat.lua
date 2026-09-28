-- budsUI_Config :: Pages/Chat.lua

local _, ns = ...

local function T(option, label, extra)
	local entry = { group = "Chat", option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

local TIMESTAMP_VALUES = {
	{ 1, "Disable" },
	{ 2, "03:27 PM" },
	{ 3, "03:27:32 PM" },
	{ 4, "15:27" },
	{ 5, "15:27:32" },
}

ns.RegisterPage({
	key = "Chat",
	name = "Chat",
	order = 9,
	schema = {
		{ header = "Chat" },
		T("Enable", L_GUI_CHAT_ENABLE or "Enable chat", {
			type = "toggle", reload = true,
		}),
		T("Width", L_GUI_CHAT_WIDTH or "Chat width", {
			type = "number", min = 200, max = 800, step = 10,
		}),
		T("Height", L_GUI_CHAT_HEIGHT or "Chat height", {
			type = "number", min = 100, max = 600, step = 10,
		}),
		T("BigWidth", "Copy chat width", {
			type = "number", min = 200, max = 800, step = 10, advanced = true,
		}),
		T("BigHeight", "Copy chat height", {
			type = "number", min = 100, max = 800, step = 10, advanced = true,
		}),
		T("TimestampFormat", L_GUI_CHAT_TIMESTAMP or "Timestamp format", {
			type = "select", width = 140, values = TIMESTAMP_VALUES,
		}),
		T("Sticky", L_GUI_CHAT_STICKY or "Sticky channels", {
			type = "toggle",
			desc = "Remember last channel.",
		}),
		T("Fading", L_GUI_CHAT_FADING or "Fading", {
			type = "toggle",
			desc = "Chat message fading (disable to keep messages always visible).",
		}),
		T("FadeTime", L_GUI_CHAT_FADE_TIME or "Fade time", {
			type = "number", min = 5, max = 120, step = 1, unit = "s",
			enabledBy = "Chat.Fading",
			desc = "How long chat lines stay visible before they start to fade.",
		}),
		{ header = "Tabs & Look" },
		T("HideTextures", L_GUI_CHAT_HIDE_TEXTURES or "Hide background", {
			type = "toggle",
			desc = "Hide chat background.",
		}),
		T("TabsMouseover", L_GUI_CHAT_TABS_MOUSEOVER or "Tabs on mouseover", {
			type = "toggle",
			desc = "Chat tabs on mouseover.",
		}),
		T("Outline", L_GUI_CHAT_OUTLINE or "Font outline", {
			type = "toggle",
			desc = "Apply an outline to the chat font.",
		}),
		T("TabsOutline", L_GUI_CHAT_TABS_OUTLINE or "Tabs outline", {
			type = "toggle",
			desc = "Apply an outline to the chat tabs font.",
		}),
		T("CombatLog", L_GUI_CHAT_CL_TAB or "Combat Log tab", {
			type = "toggle",
			desc = "Show Combat Log tab.",
		}),
		T("WhispSound", L_GUI_CHAT_WHISP or "Whisper sound", {
			type = "toggle",
			desc = "Sound when whisper.",
		}),
		{ header = "Spam filter", advanced = true },
		T("Filter", L_GUI_CHAT_SPAM or "Systems spam filter", {
			type = "toggle",
			desc = "Removing some systems spam ('Player1' won duel 'Player2').",
		}),
		T("Spam", L_GUI_CHAT_GOLD or "Gold spam filter", {
			type = "toggle",
			desc = "Removing some players spam.",
		}),
		T("DamageMeterSpam", L_GUI_CHAT_DAMAGE_METER_SPAM or "Merge meter spam", {
			type = "toggle",
			desc = "Merge damage meter spam in one line-link.",
		}),
	},
})
