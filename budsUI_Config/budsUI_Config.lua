-- budsUI_Config :: budsUI_Config.lua (compat shim)
-- The old 1763-line monolith was split into modular FrostAtomUI_Config-style
-- architecture: Controls.lua (row creators), Core.lua (window, nav, search)
-- and Pages/*.lua (one schema file per option group).
-- This file only keeps backward compatibility for macros / keybinds that
-- call the legacy global. It loads last (see budsUI_Config.toc).

local _, ns = ...

-- Core.lua already defines this; keep a fallback for direct calls.
if not CreateUIConfig and ns and ns.Toggle then
	function CreateUIConfig()
		ns.Toggle()
	end
end
