-- budsUI_Config :: Pages/Aura.lua

local _, ns = ...

local function T(option, label, extra)
	local entry = { group = "Aura", option = option, label = label }
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	return entry
end

ns.RegisterPage({
	key = "Aura",
	name = L_GUI_AURA or "Buffs & Debuffs",
	order = 8,
	schema = {
		{ header = L_GUI_AURA or "Buffs & Debuffs" },
		T("Enable", L_GUI_AURA_ENABLE or "Enable", {
			type = "toggle", reload = true,
			desc = "Enable Player Buffs/Debuffs.",
		}),
		T("BuffSize", L_GUI_AURA_PLAYER_BUFF_SIZE or "Player buff size", {
			type = "number", min = 16, max = 60, step = 1,
			enabledBy = "Aura.Enable",
		}),
		T("CastBy", L_GUI_AURA_CAST_BY or "Show caster", {
			type = "toggle",
			desc = "Show who cast a buff/debuff in its tooltip.",
			enabledBy = "Aura.Enable",
		}),
		T("ClassColorBorder", L_GUI_AURA_CLASSCOLOR_BORDER or "Classcolor border", {
			type = "toggle",
			desc = "Enable classcolor border for player buffs.",
			enabledBy = "Aura.Enable",
		}),
	},
})
