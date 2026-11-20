local K, C, L, _ = select(2, ...):unpack()

local function Init()
if C.Automation.ScreenShot ~= true then return end

local CreateFrame = CreateFrame

local function OnEvent(self, event, ...)
	K.Delay(1, function() Screenshot() end)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ACHIEVEMENT_EARNED")
frame:SetScript("OnEvent", OnEvent)
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN")
	Init()
end)
