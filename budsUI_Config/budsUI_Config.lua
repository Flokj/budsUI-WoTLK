-- budsUI_Config :: budsUI_Config.lua (compat shim) — legacy global kept for macros/keybinds.
-- Monolith split into Controls.lua, Core.lua and Pages/*.lua; this file loads last (see .toc).

local _, ns = ...

-- Core.lua already defines this; keep a fallback for direct calls.
if not CreateUIConfig and ns and ns.Toggle then
	function CreateUIConfig()
		ns.Toggle()
	end
end
