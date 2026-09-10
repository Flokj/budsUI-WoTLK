local K, C, L, _ = select(2, ...):unpack()
if C.ActionBar.Enable ~= true then return end

local _G = _G
local floor = floor
local CreateFrame = CreateFrame

local TOTALSIZE = C.ActionBar.ButtonSize + C.ActionBar.ButtonSpace
local function square(i)
	local row = floor((i-1)/4)
	return TOTALSIZE/2+(-2+i%4)*TOTALSIZE, row*TOTALSIZE
end

--	Setup MultiBarLeft as right bar #3 (4x3 block, classic Tukz layout)
local bar = CreateFrame("Frame", "Bar3Holder", UIParent)
bar:SetSize((C.ActionBar.ButtonSize * 4) + (C.ActionBar.ButtonSpace * 3), (C.ActionBar.ButtonSize * 3) + (C.ActionBar.ButtonSpace * 2))
bar:SetPoint("BOTTOMLEFT", ActionButton12, "BOTTOMLEFT", 110 - (TOTALSIZE * 1.5), 0)
MultiBarLeft:SetParent(bar)

for i = 1, 12 do
	local b = _G["MultiBarLeftButton"..i]
	-- NOTE: do not reparent the buttons themselves (3.3.5 resolves their
	-- action slots via the direct parent, they mirror the main bar);
	-- moving/hiding propagates through MultiBarLeft -> holder anyway.
	b:ClearAllPoints()
	local x, y = square(i)
	b:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", x + (TOTALSIZE * 1.5), y)
end

-- Hide bar
if C.ActionBar.RightBars < 1 then
	bar:Hide()
end
