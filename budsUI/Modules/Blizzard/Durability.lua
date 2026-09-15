local K, C, L, _ = select(2, ...):unpack()
if C.Blizzard.Durability ~= true then return end

-- Worst-slot durability meter (replaces per-slot % on CharacterFrame).
-- A small standalone frame with a budsUI mover; hover shows all slots.
-- Runs on PLAYER_LOGIN so Core (Movers/Border) is fully loaded.

local CreateFrame, UIParent = CreateFrame, UIParent
local pairs = pairs
local format = string.format
local GetInventorySlotInfo = GetInventorySlotInfo
local GetInventoryItemLink = GetInventoryItemLink
local GetInventoryItemDurability = GetInventoryItemDurability
local GetInventoryItemTexture = GetInventoryItemTexture

local SLOTS = { "Head", "Shoulder", "Chest", "Waist", "Legs", "Feet", "Wrist", "Hands", "MainHand", "SecondaryHand", "Ranged" }

local function RYGColorGradient(perc)
	local relperc = perc * 2 % 1
	if perc <= 0 then
		return 1, 0, 0
	elseif perc < 0.5 then
		return 1, relperc, 0
	elseif perc == 0.5 then
		return 1, 1, 0
	elseif perc < 1.0 then
		return 1 - relperc, 1, 0
	else
		return 0, 1, 0
	end
end

local function Durability_Init()
	local holder = CreateFrame("Frame", "budsUIDurability", UIParent)
	holder:SetSize(110, 18)
	holder:SetBackdrop(K.Backdrop)
	K.CreateBorder(holder)
	-- Colors AFTER CreateBorder: it re-applies the backdrop, resetting white
	holder:SetBackdropColor(unpack(C.Media.Backdrop_Color))
	holder:SetBackdropBorderColor(unpack(C.Media.Border_Color))
	holder:EnableMouse(true)

	local text = holder:CreateFontString(nil, "OVERLAY")
	text:SetFont(C.Media.Font, C.Media.Font_Size, C.Media.Font_Style)
	text:SetPoint("CENTER")
	text:SetShadowColor(0, 0, 0)
	text:SetShadowOffset(1, -1)
	holder.Text = text

	K.CreateMover(holder, "Durability", DURABILITY, { "BOTTOMLEFT", UIParent, "BOTTOMLEFT", 450, 6 }, 110, 18)

	local function Update()
		local min, count = 1, 0
		for _, slot in pairs(SLOTS) do
			local id = GetInventorySlotInfo(slot .. "Slot")
			if id and GetInventoryItemLink("player", id) then
				local v1, v2 = GetInventoryItemDurability(id)
				if v1 and v2 and v2 ~= 0 then
					min = math.min(v1 / v2, min)
					count = count + 1
				end
			end
		end
		if count > 0 then
			local r, g, b = RYGColorGradient(min)
			text:SetFormattedText("|cff9d9d9d%s:|r |cff%02x%02x%02x%d%%|r",
				DURABILITY, r * 255, g * 255, b * 255, min * 100)
		else
			text:SetFormattedText("|cff9d9d9d%s: --|r", DURABILITY)
		end
	end

	holder:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 4)
		GameTooltip:AddLine(DURABILITY, 0.4, 0.6, 1)
		GameTooltip:AddLine(" ")
		for _, slot in pairs(SLOTS) do
			local id = GetInventorySlotInfo(slot .. "Slot")
			if id and GetInventoryItemLink("player", id) then
				local v1, v2 = GetInventoryItemDurability(id)
				if v1 and v2 and v2 ~= 0 then
					local perc = v1 / v2
					local r, g, b = RYGColorGradient(perc)
					local icon = GetInventoryItemTexture("player", id)
					local label = icon and format("|T%s:14:14:0:0:64:64:4:60:4:60|t %s", icon, _G[slot:upper()] or slot) or slot
					GameTooltip:AddDoubleLine(label, format("%d%%", perc * 100), 1, 1, 1, r, g, b)
				end
			end
		end
		GameTooltip:Show()
	end)
	holder:SetScript("OnLeave", function() GameTooltip:Hide() end)

	local updater = CreateFrame("Frame")
	updater:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
	updater:RegisterEvent("PLAYER_ENTERING_WORLD")
	updater:RegisterEvent("UNIT_INVENTORY_CHANGED")
	updater:SetScript("OnEvent", function(_, _, unit)
		if unit and unit ~= "player" then return end
		Update()
	end)
	Update()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN")
	Durability_Init()
end)
