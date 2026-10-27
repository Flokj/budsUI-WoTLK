local K, C, L, _ = select(2, ...):unpack()
if K.Class ~= "SHAMAN" then return end

-- Custom shaman totems with cooldown swipe and CLEU pulse bars (FrostAtomUI-style).
-- Uses independent buttons, right-click DestroyTotem, and proper 3.3.5 slot order.
-- Runs on PLAYER_LOGIN so Core (Movers/Border) is fully loaded.

local unpack = unpack
local pairs = pairs
local ipairs = ipairs
local abs = math.abs
local max = math.max
local CreateFrame = CreateFrame
local GetTotemInfo = GetTotemInfo
local DestroyTotem = DestroyTotem
local GetTime = GetTime
local UnitGUID = UnitGUID

local totemSize = 32
local totemSpacing = 6
local totemWidth = (totemSize * 4) + (totemSpacing * 3)

local MAX_TOTEMS = 4
local SLOT_ORDER = { 2, 1, 3, 4 } -- Earth (2), Fire (1), Water (3), Air (4)
local SUMMON_TOLERANCE = 1

local TOTEMS = {
	{ 1, 300, 8227, 5950, 8249, 6012, 10526, 7423, 16387, 10557, 25557, 15485, 58649, 31132, 58652, 31158, 58656, 31133 }, -- Flametongue Totem I-VIII
	{ 1, 300, 8181, 5926, 10478, 7412, 10479, 7413, 25560, 15486, 58741, 31171, 58745, 31172 }, -- Frost Resistance Totem I-VI
	{ 1, 21, 8190, 5929, 10585, 7464, 10586, 7465, 10587, 7466, 25552, 15484, 58731, 31166, 58734, 31167 }, -- Magma Totem I-VII
	{ 1, 30, 3599, 2523 }, -- Searing Totem
	{ 1, 35, 6363, 3902 }, -- Searing Totem II
	{ 1, 40, 6364, 3903 }, -- Searing Totem III
	{ 1, 45, 6365, 3904 }, -- Searing Totem IV
	{ 1, 50, 10437, 7400 }, -- Searing Totem V
	{ 1, 55, 10438, 7402 }, -- Searing Totem VI
	{ 1, 60, 25533, 15480, 58699, 31162, 58703, 31164, 58704, 31165 }, -- Searing Totem VII-X
	{ 1, 300, 30706, 17539, 57720, 30652, 57721, 30653, 57722, 30654 }, -- Totem of Wrath I-IV
	{ 1, 120, 2894, 15439 }, -- Fire Elemental Totem
	{ 2, 120, 2062, 15430 }, -- Earth Elemental Totem
	{ 2, 45, 2484, 2630 }, -- Earthbind Totem
	{ 2, 15, 5730, 3579, 6390, 3911, 6391, 3912, 6392, 3913, 10427, 7398, 10428, 7399, 25525, 15478, 58580, 31120, 58581, 31121, 58582, 31122 }, -- Stoneclaw Totem I-X
	{ 2, 300, 8071, 5873, 8154, 5919, 8155, 5920, 10406, 7366, 10407, 7367, 10408, 7368, 25508, 15470, 25509, 15474, 58751, 31175, 58753, 31176 }, -- Stoneskin Totem I-X
	{ 2, 300, 8075, 5874, 8160, 5921, 8161, 5922, 10442, 7403, 25361, 15464, 25528, 15479, 57622, 30647, 58643, 31129 }, -- Strength of Earth Totem I-VIII
	{ 2, 300, 8143, 5913 }, -- Tremor Totem
	{ 3, 300, 8170, 5924 }, -- Cleansing Totem
	{ 3, 300, 8184, 5927, 10537, 7424, 10538, 7425, 25563, 15487, 58737, 31169, 58739, 31170 }, -- Fire Resistance Totem I-VI
	{ 3, 300, 5394, 3527, 6375, 3906, 6377, 3907, 10462, 3908, 10463, 3909, 25567, 15488, 58755, 31181, 58756, 31182, 58757, 31185 }, -- Healing Stream Totem I-IX
	{ 3, 300, 5675, 3573, 10495, 7414, 10496, 7415, 10497, 7416, 25570, 15489, 58771, 31186, 58773, 31189, 58774, 31190 }, -- Mana Spring Totem I-VIII
	{ 3, 13, 16190, 10467 }, -- Mana Tide Totem
	{ 4, 45, 8177, 5925 }, -- Grounding Totem
	{ 4, 300, 10595, 7467, 10600, 7468, 10601, 7469, 25574, 15490, 58746, 31173, 58749, 31174 }, -- Nature Resistance Totem I-VI
	{ 4, 300, 6495, 3968 }, -- Sentry Totem
	{ 4, 300, 8512, 6112 }, -- Windfury Totem
	{ 4, 300, 3738, 15447 }, -- Wrath of Air Totem
}

local PULSES = {
	[8190] = { 2, 8187, 10579, 10580, 10581, 25550, 58732, 58735 }, -- Magma Totem
	[2484] = { 3, 3600 }, -- Earthbind
	[5730] = { 2, 5729, 6393, 6394, 6395, 10423, 10424, 25512 }, -- Stoneclaw Totem
	[8143] = { 3, 8146 }, -- Tremor Totem
	[8170] = { 3, 8171 }, -- Cleansing Totem
	[5394] = { 2, 52041, 52046, 52047, 52048, 52049, 52050, 58759, 58760, 58761, 52042 }, -- Healing Stream, Healing Stream Totem
	[16190] = { 3, 39610, 39609 }, -- Mana Tide Totem
}

local TICK_EVENTS = {
	SPELL_CAST_SUCCESS = true,
	SPELL_DAMAGE = true,
	SPELL_MISSED = true,
	SPELL_HEAL = true,
	SPELL_ENERGIZE = true,
	SPELL_AURA_APPLIED = true,
	SPELL_AURA_REFRESH = true,
	SPELL_DISPEL = true,
}

local spells = {}
local tickSpells = {}

for i = 1, #TOTEMS do
	local row = TOTEMS[i]
	local pulseRow = PULSES[row[3]]
	local pulse
	if pulseRow then
		pulse = { period = pulseRow[1], ticks = {} }
		for j = 2, #pulseRow do
			pulse.ticks[pulseRow[j]] = true
			tickSpells[pulseRow[j]] = true
		end
	end
	for j = 3, #row, 2 do
		local spellId = row[j]
		spells[spellId] = { slot = row[1], duration = row[2], pulse = pulse }
	end
end

local buttons = {}
local pulses = {}
local playerGUID

local ticker = CreateFrame("Frame")
ticker:Hide()

ticker:SetScript("OnUpdate", function(self)
	local now = GetTime()
	local any = false
	for slot, record in pairs(pulses) do
		local button = buttons[slot]
		local bar = button and button.pulse
		if bar and bar:IsShown() and record.pulse then
			local period = record.pulse.period
			if period and period > 0 then
				local elapsed = max(0, now - record.lastTick)
				bar.bar:SetValue((elapsed % period) / period)
				any = true
			end
		end
	end
	if not any then
		self:Hide()
	end
end)

local function updatePulse(button, active, startTime)
	local record = pulses[button:GetID()]
	local show = active and record and (abs(startTime - record.start) < SUMMON_TOLERANCE)
	if show then
		button.pulse:Show()
		ticker:Show()
	else
		button.pulse:Hide()
	end
end

local function updateButton(button)
	local slot = button:GetID()
	local haveTotem, _, startTime, duration, icon = GetTotemInfo(slot)
	local active = haveTotem and duration and duration > 0
	if active then
		button.icon:SetTexture(icon)
		button.cd:SetCooldown(startTime, duration)
		button.cd:Show()
		button:SetAlpha(1)
		button:EnableMouse(true)
	else
		button.cd:SetCooldown(0, 0)
		button.cd:Hide()
		button:SetAlpha(0)
		button:EnableMouse(false)
		pulses[slot] = nil
	end
	updatePulse(button, active, startTime)
end

local function Totem_UpdateAll()
	for i = 1, MAX_TOTEMS do
		local button = buttons[i]
		if button then
			updateButton(button)
		end
	end
end

local function onSummon(dstGUID, spellId)
	local data = spells[spellId]
	if not data then return end
	local slot = data.slot
	if data.pulse then
		local now = GetTime()
		pulses[slot] = { guid = dstGUID, pulse = data.pulse, start = now, lastTick = now }
	else
		pulses[slot] = nil
	end
	local button = buttons[slot]
	if button then
		updateButton(button)
	end
end

local function onTick(srcGUID, spellId)
	for _, record in pairs(pulses) do
		if (srcGUID == record.guid or srcGUID == playerGUID) and record.pulse.ticks[spellId] then
			record.lastTick = GetTime()
		end
	end
end

local function onDestroyed(dstGUID)
	for slot, record in pairs(pulses) do
		if record.guid == dstGUID then
			pulses[slot] = nil
			local button = buttons[slot]
			if button and button.pulse then
				button.pulse:Hide()
			end
		end
	end
end

local function OnCombatLog(...)
	local _, subEvent, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 = ...
	local srcGUID, dstGUID, spellId
	if type(arg3) == "boolean" then
		srcGUID = arg4
		dstGUID = arg7
		spellId = arg10
	else
		srcGUID = arg3
		dstGUID = arg6
		spellId = arg9
	end

	if not subEvent then return end

	if subEvent == "SPELL_SUMMON" then
		if srcGUID == playerGUID and spellId then
			onSummon(dstGUID, spellId)
		end
	elseif TICK_EVENTS[subEvent] then
		if spellId and tickSpells[spellId] then
			onTick(srcGUID, spellId)
		end
	elseif subEvent == "UNIT_DIED" or subEvent == "UNIT_DESTROYED" then
		if dstGUID then
			onDestroyed(dstGUID)
		end
	end
end

local function CreateTotemButton(slot, parent)
	local button = CreateFrame("Button", "budsUI_Totem"..slot, parent)
	button:SetID(slot)
	button:SetSize(totemSize, totemSize)
	button:SetAlpha(0)
	button:EnableMouse(false)
	button:RegisterForClicks("RightButtonUp")
	button:SetScript("OnClick", function(self)
		DestroyTotem(self:GetID())
	end)
	button:SetScript("OnEnter", function(self)
		local id = self:GetID()
		local haveTotem, name = GetTotemInfo(id)
		if haveTotem and name and name ~= "" then
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
			GameTooltip:SetTotem(id)
			GameTooltip:Show()
		end
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	local icon = button:CreateTexture(nil, "BACKGROUND")
	icon:SetAllPoints()
	icon:SetTexCoord(unpack(K.TexCoords))
	button.icon = icon

	K.CreateBorder(button, 10, 1)

	local cd = CreateFrame("Cooldown", "$parentCooldown", button, "CooldownFrameTemplate")
	cd:SetAllPoints()
	cd:SetReverse(true)
	if K.StyleCooldownSwipe then
		K.StyleCooldownSwipe(cd)
	elseif cd.SetDrawEdge then
		pcall(cd.SetDrawEdge, cd, false)
	end
	button.cd = cd

	-- Pulse bar
	local pulse = CreateFrame("Frame", nil, button)
	pulse:SetHeight(6)
	pulse:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 0, 3)
	pulse:SetPoint("BOTTOMRIGHT", button, "TOPRIGHT", 0, 3)
	pulse:SetBackdrop({
		bgFile = C.Media.Blank,
		edgeFile = C.Media.Blank,
		edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	pulse:SetBackdropColor(0.1, 0.1, 0.1, 0.85)
	pulse:SetBackdropBorderColor(0, 0, 0, 1)
	pulse:Hide()

	local bar = CreateFrame("StatusBar", nil, pulse)
	bar:SetPoint("TOPLEFT", pulse, "TOPLEFT", 1, -1)
	bar:SetPoint("BOTTOMRIGHT", pulse, "BOTTOMRIGHT", -1, 1)
	bar:SetStatusBarTexture(C.Media.Blank)
	bar:SetStatusBarColor(0.3, 0.75, 1)
	bar:SetMinMaxValues(0, 1)
	local tex = bar:GetStatusBarTexture()
	if tex then
		tex:SetHorizTile(false)
	end
	pulse.bar = bar
	button.pulse = pulse

	buttons[slot] = button
	return button
end

local function Totem_Init()
	if TotemFrame then
		if TotemFrame.UnregisterAllEvents then
			TotemFrame:UnregisterAllEvents()
		end
		TotemFrame:Hide()
		TotemFrame.Show = K.Noop or function() end
	end

	playerGUID = UnitGUID("player")

	local holder = CreateFrame("Frame", "budsUI_TotemTimers", UIParent)
	holder:SetWidth(totemWidth)
	holder:SetHeight(totemSize)
	holder:SetClampedToScreen(true)

	K.CreateMover(holder, "TotemTimers", "Totem Timers", {"BOTTOM", UIParent, "TOP", -370, -436}, totemWidth, totemSize)

	for index, slot in ipairs(SLOT_ORDER) do
		local button = CreateTotemButton(slot, holder)
		button:ClearAllPoints()
		button:SetPoint("LEFT", holder, "LEFT", (index - 1) * (totemSize + totemSpacing), 0)
	end

	local events = CreateFrame("Frame")
	events:RegisterEvent("PLAYER_TOTEM_UPDATE")
	events:RegisterEvent("PLAYER_ENTERING_WORLD")
	events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	events:SetScript("OnEvent", function(_, event, ...)
		if event == "PLAYER_TOTEM_UPDATE" then
			local slot = ...
			if slot and buttons[slot] then
				updateButton(buttons[slot])
			end
		elseif event == "PLAYER_ENTERING_WORLD" then
			playerGUID = UnitGUID("player")
			Totem_UpdateAll()
		elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
			OnCombatLog(...)
		end
	end)

	Totem_UpdateAll()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN")
	Totem_Init()
end)
