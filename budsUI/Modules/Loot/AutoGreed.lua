local K, C, L, _ = select(2, ...):unpack()
if C.Loot.AutoGreed ~= true or K.Level ~= MAX_PLAYER_LEVEL then return end

local pairs = pairs
local CreateFrame = CreateFrame
local GetItemInfo = GetItemInfo
local GetLootRollItemLink = GetLootRollItemLink

--	Auto greed & disenchant on green items(by Tekkub) and NeedTheOrb(by Myrilandell of Lothar)
local frame = CreateFrame("Frame")
frame:RegisterEvent("START_LOOT_ROLL")
frame:SetScript("OnEvent", function(self, event, id)
	-- WoW 3.3.5: GetLootRollItemInfo() doesn't exist, use GetLootRollItemLink() + GetItemInfo()
	local itemLink = GetLootRollItemLink(id)
	if not itemLink then return end
	
	local name, _, quality, _, _, _, _, _, _, texture = GetItemInfo(itemLink)
	if not name then return end
	
	-- Check if item is BoP by trying to parse tooltip (not perfect but works)
	local BoP = itemLink:find("item:(%d+):") and select(14, GetItemInfo(itemLink)) == 1
	
	if id and quality == 2 and not BoP then
		for i in pairs(K.NeedLoot) do
			local itemName = GetItemInfo(K.NeedLoot[i])
			if name == itemName and RollOnLoot(id, 1) then
				RollOnLoot(id, 1)
				return
			end
		end
		if RollOnLoot(id, 3) then
			RollOnLoot(id, 3)
		else
			RollOnLoot(id, 2)
		end
	end
end)