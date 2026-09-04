local K, C, L, _ = select(2, ...):unpack()
if C.Aura.Enable ~= true then return end

-- Localize standard libraries
local _G = _G
local setmetatable, getmetatable = setmetatable, getmetatable
local floor, ceil, max, abs = math.floor, math.ceil, math.max, math.abs
local unpack, select, pairs, ipairs = unpack, select, pairs, ipairs

-- Localize WoW API
local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local UnitAura = UnitAura
local CancelUnitBuff = CancelUnitBuff
local GetWeaponEnchantInfo = GetWeaponEnchantInfo
local GetInventoryItemTexture = GetInventoryItemTexture
local CancelItemTempEnchantment = CancelItemTempEnchantment
local GetTime = GetTime
local UnitHasVehicleUI = UnitHasVehicleUI
local UnitExists = UnitExists
local hooksecurefunc = hooksecurefunc

-- Constants from Config & Screen Resolution
local SIZE = C.Aura.BuffSize or 36
local SPACING_X = 4
local SPACING_Y = 12
local IN_ROW = 14

-- BuffsAnchor Frame setup
local BuffsAnchor = CreateFrame("Frame", "BuffsAnchor", UIParent)
BuffsAnchor:SetPoint(unpack(C.Position.PlayerBuffs))
BuffsAnchor:SetSize((IN_ROW * SIZE) + ((IN_ROW - 1) * SPACING_X), (SIZE * 2) + SPACING_Y)

-- Debuff colors table
local debuffColors = {}
for debuffType, tbl in pairs(DebuffTypeColor) do
	debuffColors[debuffType] = { tbl.r, tbl.g, tbl.b }
end

-- Aura Prototype
local auraPrototype = setmetatable({}, getmetatable(PlayerFrame or UIParent))
local auraMT = { __index = auraPrototype }

function auraPrototype:OnUpdate()
	if self.isTempEnchant then
		GameTooltip:SetInventoryItem("player", self.slot)
	else
		local unit = self:GetParent():GetUnit()
		if unit then
			GameTooltip:SetUnitAura(unit, self.id, self.filter)
		end
	end
end

function auraPrototype:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
	self:SetScript("OnUpdate", self.OnUpdate)
end

function auraPrototype:OnLeave()
	self:SetScript("OnUpdate", nil)
	GameTooltip:Hide()
end

function auraPrototype:OnClick()
	if self.isTempEnchant then
		CancelItemTempEnchantment(self.slotID)
	else
		local unit = self:GetParent():GetUnit()
		if unit then
			CancelUnitBuff(unit, self.id, self.filter)
		end
	end
end

-- Group Prototype
local groupPrototype = setmetatable({}, getmetatable(UIParent))
local groupMT = { __index = groupPrototype }

function groupPrototype:CreateAura()
	local button = CreateFrame("Button", nil, self)
	setmetatable(button, auraMT)
	button:SetFrameLevel(self:GetFrameLevel() + 2)
	button:SetSize(SIZE, SIZE)
	button:RegisterForClicks("RightButtonDown")
	button:SetScript("OnClick", button.OnClick)
	button:SetScript("OnEnter", button.OnEnter)
	button:SetScript("OnLeave", button.OnLeave)

	-- Panel & Backdrop setup
	local panel = CreateFrame("Frame", nil, button)
	if panel.CreatePanel then
		panel:CreatePanel("CreateBackdrop", SIZE, SIZE, "CENTER", button, "CENTER", 0, 0)
	else
		panel:SetTemplate("Default")
		panel:SetAllPoints(button)
	end
	panel:SetFrameLevel(button:GetFrameLevel() - 1)
	panel:SetFrameStrata(button:GetFrameStrata())

	if C.Aura.ClassColorBorder == true and panel.backdrop then
		panel.backdrop:SetBackdropBorderColor(K.Color.r, K.Color.g, K.Color.b)
	end

	if not panel.shadow and panel.CreateBlizzShadow then
		panel:CreateBlizzShadow(5)
	end

	-- Icon
	local icon = button:CreateTexture(nil, "BACKGROUND")
	icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	icon:SetPoint("TOPLEFT", button, 2, -2)
	icon:SetPoint("BOTTOMRIGHT", button, -2, 2)

	-- Cooldown Frame
	local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cooldown:SetAllPoints(icon)
	cooldown:SetReverse(true)
	cooldown:SetDrawEdge(true)
	cooldown:SetFrameLevel(button:GetFrameLevel() + 1)

	-- Stack Count
	local count = button:CreateFontString(nil, "OVERLAY")
	count:SetParent(cooldown)
	count:SetPoint("BOTTOMRIGHT", button, 0, 1)
	count:SetFont(C.Media.Font, C.Media.Font_Size + 4, C.Media.Font_Style)
	count:SetShadowOffset(0, 0)

	button.panel = panel
	button.cooldown = cooldown
	button.icon = icon
	button.count = count
	return button
end

function groupPrototype:UpdateAuras()
	local unit = self:GetUnit()
	if not unit or not UnitExists(unit) then
		for j = 1, #self do
			self[j]:Hide()
		end
		return
	end

	local filter = self.filter
	local isDebuff = (filter == "HARMFUL")
	local button
	local totalIndex = 0

	-- Temporary Weapon Enchants (Helpful, player only)
	if filter == "HELPFUL" and unit == "player" then
		local hasMH, mhExp, mhCount, _, hasOH, ohExp, ohCount = GetWeaponEnchantInfo()
		local tempEnchants = {}

		if hasMH then
			table.insert(tempEnchants, { slot = 16, slotID = 1, exp = mhExp, count = mhCount })
		end
		if hasOH then
			table.insert(tempEnchants, { slot = 17, slotID = 2, exp = ohExp, count = ohCount })
		end

		for _, enchant in ipairs(tempEnchants) do
			totalIndex = totalIndex + 1
			button = self[totalIndex]
			if not button then
				button = self:CreateAura()
				self[totalIndex] = button
			end

			button:SetPoint("TOPRIGHT", self, "TOPRIGHT", -((totalIndex - 1) % IN_ROW) * (SIZE + SPACING_X), -floor((totalIndex - 1) / IN_ROW) * (SIZE + SPACING_Y))
			button.isTempEnchant = true
			button.slot = enchant.slot
			button.slotID = enchant.slotID
			button.filter = filter

			local texture = GetInventoryItemTexture("player", enchant.slot) or "Interface\\Icons\\Inv_misc_questionmark"
			button.icon:SetTexture(texture)

			if C.Aura.ClassColorBorder == true and button.panel then
				local bFrame = button.panel.backdrop or button.panel
				if bFrame and bFrame.SetBackdropBorderColor then
					bFrame:SetBackdropBorderColor(K.Color.r, K.Color.g, K.Color.b)
				end
			end

			if enchant.exp and enchant.exp > 0 then
				local timeLeft = enchant.exp / 1000
				local now = GetTime()
				if not button.expTime or abs(button.expTime - (now + timeLeft)) > 1 then
					button.expTime = now + timeLeft
					button.cooldown:SetCooldown(now, timeLeft)
				end
				button.cooldown:Show()

				if button.cooldown.timer and button.cooldown.timer.text then
					local text = button.cooldown.timer.text
					text:ClearAllPoints()
					text:SetPoint("TOP", button.cooldown, "BOTTOM", 1, 6)
				end
			else
				button.expTime = nil
				button.cooldown:Hide()
			end

			if enchant.count and enchant.count > 1 then
				button.count:SetText(enchant.count)
				button.count:Show()
			else
				button.count:Hide()
			end

			button:Show()
		end
	end

	-- Regular Unit Auras
	local i = 0
	while true do
		i = i + 1
		local name, _, texture, count, debuffType, duration, endTime = UnitAura(unit, i, filter)
		if not name then break end

		totalIndex = totalIndex + 1
		button = self[totalIndex]
		if not button then
			button = self:CreateAura()
			self[totalIndex] = button
		end

		button:SetPoint("TOPRIGHT", self, "TOPRIGHT", -((totalIndex - 1) % IN_ROW) * (SIZE + SPACING_X), -floor((totalIndex - 1) / IN_ROW) * (SIZE + SPACING_Y))
		button.isTempEnchant = nil
		button.filter = filter
		button.id = i

		button.icon:SetTexture(texture)

		-- Border color logic
		if isDebuff then
			local color = debuffColors[debuffType or "none"] or debuffColors["none"] or { 0.8, 0, 0 }
			local bFrame = (button.panel and button.panel.backdrop) or button.panel
			if bFrame and bFrame.SetBackdropBorderColor then
				bFrame:SetBackdropBorderColor(unpack(color))
			end
		else
			if C.Aura.ClassColorBorder == true and button.panel then
				local bFrame = button.panel.backdrop or button.panel
				if bFrame and bFrame.SetBackdropBorderColor then
					bFrame:SetBackdropBorderColor(K.Color.r, K.Color.g, K.Color.b)
				end
			end
		end

		if (duration and duration > 0 and endTime) then
			button.cooldown:SetCooldown(endTime - duration, duration)
			button.cooldown:Show()

			if button.cooldown.timer and button.cooldown.timer.text then
				local text = button.cooldown.timer.text
				text:ClearAllPoints()
				text:SetPoint("TOP", button.cooldown, "BOTTOM", 1, 6)
			end
		else
			button.cooldown:Hide()
		end

		if count and count > 1 then
			button.count:SetText(count)
			button.count:Show()
		else
			button.count:Hide()
		end

		button:Show()
	end

	-- Update parent container height
	local rows = ceil(totalIndex / IN_ROW)
	if totalIndex > 0 then
		self:SetHeight(rows * SIZE + (rows - 1) * SPACING_Y)
	else
		self:SetHeight(1)
	end

	-- Hide remaining unused aura buttons
	for j = totalIndex + 1, #self do
		button = self[j]
		if button:IsShown() then
			button:Hide()
		end
	end
end

function groupPrototype:GetUnit()
	local unit = self.unit
	if type(unit) == "function" then
		return unit()
	else
		return unit
	end
end

function groupPrototype:OnEvent(event, ...)
	local arg1 = ...
	if event == "UNIT_AURA" or event == "UNIT_INVENTORY_CHANGED" then
		if arg1 == self:GetUnit() or arg1 == "player" then
			self:UpdateAuras()
		end
	else
		self:UpdateAuras()
	end
end

-- Main Controller
local main = CreateFrame("Frame", nil, UIParent)

function main:CreateGroup(unit, filter)
	local frame = CreateFrame("Frame", nil, UIParent)
	setmetatable(frame, groupMT)
	frame:SetWidth((IN_ROW * SIZE) + ((IN_ROW - 1) * SPACING_Y))
	frame:SetHeight(1)
	frame:RegisterEvent("UNIT_AURA")
	frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("VEHICLE_UPDATE")
	frame:RegisterEvent("UNIT_ENTERED_VEHICLE")
	frame:RegisterEvent("UNIT_EXITED_VEHICLE")
	frame:SetScript("OnEvent", frame.OnEvent)
	frame.unit = unit
	frame.filter = filter

	return frame
end

function main:OnInitialize()
	-- Disable default Blizzard aura frames
	if BuffFrame then
		BuffFrame:UnregisterAllEvents()
		BuffFrame:SetScript("OnUpdate", nil)
		BuffFrame:Hide()
	end

	if TemporaryEnchantFrame then
		TemporaryEnchantFrame:UnregisterAllEvents()
		TemporaryEnchantFrame:Hide()
	end

	if ConsolidatedBuffs then
		ConsolidatedBuffs:UnregisterAllEvents()
		ConsolidatedBuffs:Hide()
	end

	local getPlayerUnitID = function()
		return (UnitHasVehicleUI and UnitHasVehicleUI("player") and "vehicle") or "player"
	end

	local buffs = self:CreateGroup(getPlayerUnitID, "HELPFUL")
	local debuffs = self:CreateGroup(getPlayerUnitID, "HARMFUL")

	buffs:SetPoint("TOPRIGHT", BuffsAnchor, "TOPRIGHT", 0, 0)
	debuffs:SetPoint("TOPRIGHT", buffs, "BOTTOMRIGHT", 0, -60)
end

main:OnInitialize()