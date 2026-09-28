-- budsUI_Config :: Pages/Announcements.lua

local _, ns = ...

local function T(option, label, extra)
	local entry = { group = "Announcements", option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

ns.RegisterPage({
	key = "Announcements",
	name = L_GUI_ANNOUNCEMENTS or "Announcements",
	order = 4,
	schema = {
		{ header = L_GUI_ANNOUNCEMENTS or "Announcements" },
		{
			description = "Chat announcements for interrupts, pulls, portals and more.",
		},
		T("Interrupt", L_GUI_ANNOUNCEMENTS_INTERRUPT or "Announce interrupts", {
			type = "toggle",
			desc = "Announce in party / raid when you interrupt others.",
		}),
		T("Spells", L_GUI_ANNOUNCEMENTS_SPELLS or "Announce spells", {
			type = "toggle",
			desc = "Announce in party/raid when you cast some spells.",
		}),
		T("SpellsFromAll", L_GUI_ANNOUNCEMENTS_SPELLS_FROM_ALL or "Spells from all", {
			type = "toggle",
			desc = "Check spells cast from all members.",
			enabledBy = "Announcements.Spells",
		}),
		T("PullCountdown", L_GUI_ANNOUNCEMENTS_PULL_COUNTDOWN or "Pull countdown", {
			type = "toggle",
			desc = "Simple script to aid in creating a pull countdown announce. /pc",
		}),
		T("Feasts", L_GUI_ANNOUNCEMENTS_FEASTS or "Feasts", {
			type = "toggle",
			desc = "Announce Feasts/Souls/Repair Bots cast.",
		}),
		T("Portals", L_GUI_ANNOUNCEMENTS_PORTALS or "Portals", {
			type = "toggle",
			desc = "Announce Portals/Ritual of Summoning cast.",
		}),
		T("Toys", L_GUI_ANNOUNCEMENTS_TOY_TRAIN or "Toys", {
			type = "toggle",
			desc = "Announce some annoying toys.",
		}),
		T("Bad_Gear", L_GUI_ANNOUNCEMENTS_BAD_GEAR or "Bad gear check", {
			type = "toggle",
			desc = "Check for bad gear in instances.",
		}),
		T("SaySapped", L_GUI_ANNOUNCEMENTS_SAY_SAPPED or "Say sapped", {
			type = "toggle",
			desc = "Instantly says Sapped to alert those around you whenever Rogues sap you.",
		}),
	},
})
