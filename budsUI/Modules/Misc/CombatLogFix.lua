local K, C, L, _ = select(2, ...):unpack()

-- 3.3.5 (seen on WoW Circle / Warmane cross-realm BG): the combat log can stall after a cast
-- until CombatLogClearEntries() unfreezes the client-side log buffer.
local CombatLogClearEntries = CombatLogClearEntries
local IsInInstance = IsInInstance

local SILENCE_TIMEOUT = 0.8
local watchdog = CreateFrame("Frame")
watchdog:Hide()
watchdog.remain = 0

watchdog:SetScript("OnShow", function(self)
	self.remain = SILENCE_TIMEOUT
end)

watchdog:SetScript("OnUpdate", function(self, elapsed)
	self.remain = self.remain - elapsed
	if self.remain < 0 then
		CombatLogClearEntries()
		self:Hide()
	end
end)

local listener = CreateFrame("Frame")
listener:RegisterEvent("PLAYER_ENTERING_WORLD")

listener:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_ENTERING_WORLD" then
		local enabled = C.Misc and C.Misc.CombatLogFix ~= false
		local inInstance = select(1, IsInInstance())
		if enabled and inInstance then
			self:RegisterEvent("UNIT_SPELLCAST_SENT")
			self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		else
			self:UnregisterEvent("UNIT_SPELLCAST_SENT")
			self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			watchdog:Hide()
		end
	elseif event == "UNIT_SPELLCAST_SENT" then
		watchdog:Show()
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		watchdog:Hide()
	end
end)
