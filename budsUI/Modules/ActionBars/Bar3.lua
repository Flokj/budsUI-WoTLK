local K, C, L, _ = select(2, ...):unpack()
if C.ActionBar.Enable ~= true then return end

local _G = _G
local CreateFrame = CreateFrame

local TOTALSIZE = C.ActionBar.ButtonSize + C.ActionBar.ButtonSpace
local function square(i)
    local row = floor((i-1)/4)
    return TOTALSIZE/2+(-2+i%4)*TOTALSIZE,row*TOTALSIZE
end

--	Setup MultiBarLeft as bar #3 by Tukz
for i = 1, 12 do
	local b = _G["MultiBarLeftButton"..i]
	b:ClearAllPoints()
    local x,y = square(i)
    b:SetPoint("BOTTOMLEFT",ActionButton12,110+x,y)
end

-- Hide bar
if C.ActionBar.RightBars < 2 then
	bar:Hide()
end