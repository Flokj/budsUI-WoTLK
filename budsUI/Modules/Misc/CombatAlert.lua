local K, C, L, _ = select(2, ...):unpack()

-- Combat alert (from FrostAtomUI): centered message on entering/leaving combat with
-- hold + fade; colors from C.Misc.CombatAlert*, movable mover, toggle read live at event time.

local CreateFrame = CreateFrame

local HOLD_TIME = 3
local FADE_TIME = 1.5

local combatAlert = CreateFrame("Frame", "budsUICombatAlert", UIParent)
combatAlert:SetSize(200, 30)
combatAlert:SetFrameStrata("HIGH")
combatAlert:Hide()

local text = combatAlert:CreateFontString(nil, "OVERLAY")
text:SetPoint("CENTER")
text:SetFont(C.Media.Font, 22, "OUTLINE")

combatAlert:SetScript("OnUpdate", function(self, elapsed)
	if self.hold and self.hold > 0 then
		self.hold = self.hold - elapsed
		return
	end
	self.hold = nil
	local alpha = self:GetAlpha() - elapsed / FADE_TIME
	if alpha > 0 then
		self:SetAlpha(alpha)
	else
		self:Hide()
	end
end)

local function colors(color)
	if type(color) == "table" then
		local r, g, b = color[1] or 1, color[2] or 1, color[3] or 1
		return r, g, b
	end
	return 1, 1, 1
end

local function showAlert(message, color)
	if C.Misc.CombatAlert ~= true then
		return
	end
	if message == nil or message == "" then
		return
	end
	local r, g, b = colors(color)
	text:SetText(message)
	text:SetTextColor(r, g, b)
	combatAlert.hold = HOLD_TIME
	combatAlert:SetAlpha(1)
	combatAlert:Show()
end

local function showEnterAlert()
	showAlert(C.Misc.CombatAlertEnterText, C.Misc.CombatAlertEnterColor)
end

local function showLeaveAlert()
	showAlert(C.Misc.CombatAlertLeaveText, C.Misc.CombatAlertLeaveColor)
end

-- Exposed for the config "Test" button.
budsUICombatAlertTest = showEnterAlert

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_REGEN_DISABLED" then
		showEnterAlert()
	else
		showLeaveAlert()
	end
end)

-- Movable anchor (deferred: Core/Movers.lua loads after Modules).
local moverWait = CreateFrame("Frame")
moverWait:SetScript("OnUpdate", function(self)
	if K.CreateMover then
		self:SetScript("OnUpdate", nil)
		K.CreateMover(combatAlert, "CombatAlert", "Combat alert", { "CENTER", UIParent, "CENTER", 0, 200 }, 200, 30)
	end
end)
