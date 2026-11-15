local K, C, L, _ = select(2, ...):unpack()
if C.Loot.AutoGreed ~= true then return end

-- Add/remove items by their ID from the wowhead.com item URL.
K.NeedLoot = {
	33865,	-- Amani Hex Stick
	68729,	-- Elementium Lockbox
}