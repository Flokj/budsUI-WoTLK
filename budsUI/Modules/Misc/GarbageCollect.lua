local K, C, L, _ = select(2, ...):unpack()

local collectgarbage = collectgarbage
local UnitIsAFK = UnitIsAFK
local CreateFrame = CreateFrame
local Garbage = CreateFrame("Frame")

function Garbage:OnEvent(event, unit)
	if event == "PLAYER_ENTERING_WORLD" then
		collectgarbage("collect")
		self:UnregisterEvent(event)
	elseif event == "PLAYER_FLAGS_CHANGED" and unit == "player" then
		if UnitIsAFK(unit) then
			collectgarbage("collect")
		end
	end
end

Garbage:SetScript("OnEvent", Garbage.OnEvent)

Garbage:RegisterEvent("PLAYER_FLAGS_CHANGED")
Garbage:RegisterEvent("PLAYER_ENTERING_WORLD")