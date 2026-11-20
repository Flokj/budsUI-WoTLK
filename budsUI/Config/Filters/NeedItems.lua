local K, C, L, _ = select(2, ...):unpack()

local function Init()
if C.Loot.AutoGreed ~= true then return end

-- Add/remove items by their ID from the wowhead.com item URL.
K.NeedLoot = {
	33865,	-- Amani Hex Stick
	68729,	-- Elementium Lockbox
}
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN")
	Init()
end)
