local Engine = select(2, ...)
local K, C = Engine:unpack()
local Module = Engine.UnitFrames
local Build = Module.Build

local UnitGUID = UnitGUID
local UnitIsPlayer = UnitIsPlayer
local UnitCanAttack = UnitCanAttack
local GameTooltip = GameTooltip
local GetTime = GetTime
local min, huge, random = math.min, math.huge, math.random
local unpack, wipe = unpack, wipe
local pairs = pairs
local string = string

local ICD = K.InternalCooldowns
local CHECK_INTERVAL = 0.5
local TEST_AURA_DURATION = 15
local TEST_MAX_ICONS = 3
local MAX_UNKNOWN = 2
local PLAYER_SLOTS = 4
local UNKNOWN = ICD and ICD.UNKNOWN or "?"
local GLOW_TEXTURE = "Interface\\Buttons\\UI-ActionButton-Border"
local GLOW_SCALE = 1.75

local SLOT_CAPS = {
	trinket = 2,
	ring = 2,
	weapon = 2,
	armor = 1,
	enchant = 2,
	gem = 1,
	set = 1,
	talent = 1,
}

local function getSlotCount(cfg)
	if not cfg or not cfg.Slots then
		return 2
	end
	local total = 0
	for slot, enabled in pairs(cfg.Slots) do
		if enabled then
			total = total + (SLOT_CAPS[slot] or 1)
		end
	end
	return math.max(1, math.min(total, 6))
end

local containers = {}
local testKeys = {}
local playerBlock

local function placeIcon(container, icon, index)
	local step = container.size + container.spacing
	icon:ClearAllPoints()
	if container.growth == "RIGHT" then
		icon:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", (index - 1) * step, 0)
	else
		icon:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -(index - 1) * step, 0)
	end
end

local function slotShown(guid, key)
	local cfg = C.InternalCooldowns
	if not cfg or not cfg.Slots then
		return true
	end
	local category = ICD:GetCategory(guid, key)
	return category == nil or cfg.Slots[category] ~= false
end

local function onIconEnter(icon)
	GameTooltip:SetOwner(icon, "ANCHOR_BOTTOMRIGHT")
	local source = ICD:GetSource(icon.key)
	if not source then
		GameTooltip:SetText(L_UNKNOWN_TRINKET or "Unknown trinket", 1, 1, 1)
		GameTooltip:AddLine(L_UNKNOWN_TRINKET_DESC or "Shown once the trinket procs.", nil, nil, nil, true)
		GameTooltip:Show()
		return
	end
	GameTooltip:SetHyperlink(source.kind == "i" and "item:" .. source.id or "spell:" .. source.spell)
	GameTooltip:AddLine(string.format(L_ICD_FORMAT or "Internal cooldown: %d sec", source.cd), 1, 0.82, 0)
	GameTooltip:Show()
end

local function onIconLeave()
	GameTooltip:Hide()
end

local function createIcon(container, index)
	local icon = CreateFrame("Frame", nil, container)
	icon:SetSize(container.size, container.size)
	K.CreateBorder(icon, 10)
	icon:SetFrameLevel(container:GetFrameLevel() + 2)
	icon:EnableMouse(true)
	icon:SetScript("OnEnter", onIconEnter)
	icon:SetScript("OnLeave", onIconLeave)

	local tex = icon:CreateTexture(nil, "ARTWORK")
	tex:SetAllPoints()
	tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	icon.texture = tex

	local cd = CreateFrame("Cooldown", nil, icon)
	cd:SetAllPoints()
	cd:SetReverse(true)
	if K.StyleCooldownSwipe then
		K.StyleCooldownSwipe(cd)
	end
	icon.cooldown = cd

	local glow = icon:CreateTexture(nil, "OVERLAY")
	glow:SetPoint("CENTER")
	glow:SetTexture(GLOW_TEXTURE)
	glow:SetBlendMode("ADD")
	glow:SetSize(container.size * GLOW_SCALE, container.size * GLOW_SCALE)
	glow:Hide()
	icon.glow = glow

	placeIcon(container, icon, index)
	container[index] = icon
	return icon
end

local function setIcon(container, index, key)
	local icon = container[index] or createIcon(container, index)
	if icon.key ~= key then
		icon.key = key
		icon.texture:SetTexture(ICD:GetTexture(key))
	end
	icon:Show()
	return icon
end

local function setIconActive(icon, active)
	if active == icon.active then
		return
	end
	icon.active = active
	icon.cooldown:SetReverse(active)
	local cfg = C.InternalCooldowns
	if active then
		local r, g, b = unpack((cfg and cfg.ActiveColor) or { 0.2, 1, 0.2 })
		if icon.SetBackdropBorderColor then
			icon:SetBackdropBorderColor(r, g, b)
		end
		if icon.glow then
			icon.glow:SetVertexColor(r, g, b)
			icon.glow:Show()
		end
	else
		if icon.SetBackdropBorderColor then
			icon:SetBackdropBorderColor(unpack(C.Media.Border_Color or { 0.1, 0.1, 0.1, 1 }))
		end
		if icon.glow then
			icon.glow:Hide()
		end
	end
end

local function setIconCooldown(icon, start, duration, active)
	active = active or false
	if start ~= icon.start or duration ~= icon.duration or active ~= icon.active then
		icon.start, icon.duration = start, duration
		setIconActive(icon, active)
		icon.cooldown:SetCooldown(start or 0, start and duration or 0)
	end
end

local function hideFrom(container, shown)
	for i = shown + 1, #container do
		container[i]:Hide()
	end
	container.shown = shown
end

local refresh

local function onContainerUpdate(container, elapsed)
	container.untilCheck = container.untilCheck - elapsed
	if container.untilCheck > 0 then
		return
	end
	container.untilCheck = CHECK_INTERVAL
	if container.nextExpiry <= GetTime() then
		refresh(container)
	end
end

local function isHostile(container, unit)
	return container.kind == "arena" or UnitCanAttack("player", unit)
end

function refresh(container)
	if not container or not container.enabled then
		if container then
			hideFrom(container, 0)
		end
		return
	end
	local unit = container.unit
	local guid = UnitGUID(unit)
	container.guid = guid

	local shown = 0
	local nextExpiry = huge
	local cfg = C.InternalCooldowns
	if cfg and cfg.Enable and guid and (container.kind == "arena" or UnitIsPlayer(unit)) then
		local hideReady = cfg.HideReady
		local unknown = cfg.UnknownTrinkets and (not cfg.Slots or cfg.Slots.trinket ~= false) and not hideReady and isHostile(container, unit)
		local keys = ICD:Collect(guid, container.keys, unknown)
		for i = 1, #keys do
			local key = keys[i]
			local start, duration, auraStart, auraDuration
			if key ~= UNKNOWN then
				start, duration = ICD:GetCooldown(guid, key)
				auraStart, auraDuration = ICD:GetAura(guid, key)
			end
			if (start or not hideReady) and slotShown(guid, key) then
				shown = shown + 1
				local icon = setIcon(container, shown, key)
				if auraStart then
					if auraDuration then
						setIconCooldown(icon, auraStart, auraDuration, true)
						nextExpiry = min(nextExpiry, auraStart + auraDuration)
					else
						setIconCooldown(icon, start, duration, true)
					end
				else
					setIconCooldown(icon, start, duration)
				end
				if start then
					nextExpiry = min(nextExpiry, start + duration)
				end
			end
		end
	end
	hideFrom(container, shown)

	container.nextExpiry = nextExpiry
	container.untilCheck = 0
	container:SetScript("OnUpdate", nextExpiry < huge and onContainerUpdate or nil)
end

local function shownTestKeys()
	wipe(testKeys)
	local keys = ICD:GetTestKeys()
	for i = 1, #keys do
		if slotShown(nil, keys[i]) then
			testKeys[#testKeys + 1] = keys[i]
		end
	end
	return testKeys
end

local function fillTest(container)
	container:SetScript("OnUpdate", nil)
	container.guid = nil
	local shown = 0
	if container.enabled then
		local cfg = C.InternalCooldowns
		local keys = shownTestKeys()
		local now = GetTime()
		local maxSlots = container.growth == "RIGHT" and getSlotCount(cfg) or TEST_MAX_ICONS
		local count = min(random(container.growth == "RIGHT" and 1 or 0, maxSlots), #keys)
		for _ = 1, count do
			shown = shown + 1
			local icon = setIcon(container, shown, keys[random(#keys)])
			local roll = random(3)
			if roll == 1 then
				setIconCooldown(icon, now - random(0, TEST_AURA_DURATION - 5), TEST_AURA_DURATION, true)
			elseif roll == 2 then
				local src = ICD:GetSource(icon.key)
				local duration = src and src.cd or 45
				setIconCooldown(icon, now - random(0, duration - 5), duration)
			else
				setIconCooldown(icon, nil)
			end
		end
		if (container.kind == "arena" or container.kind == "target") and cfg and cfg.UnknownTrinkets then
			for _ = count + 1, MAX_UNKNOWN do
				shown = shown + 1
				setIconCooldown(setIcon(container, shown, UNKNOWN), nil)
			end
		end
	end
	hideFrom(container, shown)
end

local function updatePlayerBlock()
	if not playerBlock then
		return
	end
	local cfg = C.InternalCooldowns
	playerBlock.enabled = cfg and cfg.Enable and cfg.Player and cfg.PlayerDetached
	local size = (cfg and cfg.PlayerSize) or 26
	local spacing = (cfg and cfg.Spacing) or 2
	local slots = getSlotCount(cfg)
	local width = size * slots + spacing * (slots - 1)
	playerBlock.size = size
	playerBlock.spacing = spacing
	playerBlock:SetSize(width, size)
	if playerBlock.mover then
		playerBlock.mover:SetSize(width, size)
	end
	for i = 1, #playerBlock do
		playerBlock[i]:SetSize(size, size)
	end
	if playerBlock.mover and playerBlock.mover:IsShown() then
		fillTest(playerBlock)
	else
		refresh(playerBlock)
	end
end

local function createPlayerBlock()
	local cfg = C.InternalCooldowns
	if not (cfg and cfg.Enable and cfg.Player and cfg.PlayerDetached) then
		return
	end

	local size = (cfg and cfg.PlayerSize) or 26
	local spacing = (cfg and cfg.Spacing) or 2
	local slots = getSlotCount(cfg)
	local width = size * slots + spacing * (slots - 1)

	local container = CreateFrame("Frame", "budsUI_PlayerProcICD", UIParent)
	container.unit = "player"
	container.kind = "player"
	container.growth = "RIGHT"
	container.keys = {}
	container.untilCheck = 0
	container.nextExpiry = huge
	container.size = size
	container.spacing = spacing
	container.enabled = cfg and cfg.Enable and cfg.Player and cfg.PlayerDetached
	container:SetSize(width, size)

	local defPoint = (C.Position and C.Position.PlayerProcICD) or { "BOTTOM", UIParent, "BOTTOM", 0, 192 }
	container:SetPoint(unpack(defPoint))
	local mover = K.CreateMover(container, "PlayerProcICD", "Player Procs", defPoint, width, size)
	container.mover = mover

	if mover then
		mover:HookScript("OnShow", function()
			updatePlayerBlock()
			fillTest(container)
		end)
		mover:HookScript("OnHide", function()
			updatePlayerBlock()
			refresh(container)
		end)
	end

	containers[#containers + 1] = container
	playerBlock = container
	updatePlayerBlock()
	return container
end

function Module.Build.Procs(self, unit)
	local cfg = C.InternalCooldowns
	if not cfg or cfg.Enable ~= true then
		return
	end
	if unit == "player" and cfg.PlayerDetached then
		return
	end
	local key = unit:gsub("^%l", string.upper)
	if cfg[key] ~= true and cfg[unit] ~= true then
		return
	end

	local size = cfg.Size or 22
	local spacing = cfg.Spacing or 2
	local container = CreateFrame("Frame", nil, self)
	container:SetFrameLevel(self:GetFrameLevel() + 4)
	container.unit = unit
	container.kind = unit
	container.keys = {}
	container.untilCheck = 0
	container.nextExpiry = huge
	container.size = size
	container.spacing = spacing
	container.enabled = true
	container:SetSize(size * 4 + spacing * 3, size)

	local anchorTo = self.__stackUp or self
	if unit == "target" then
		container:SetPoint("BOTTOMRIGHT", anchorTo, "TOPRIGHT", cfg.TargetOffsetX or 0, cfg.TargetOffsetY or 4)
	elseif unit == "focus" then
		container:SetPoint("BOTTOMRIGHT", anchorTo, "TOPRIGHT", 0, 4)
	elseif unit == "player" then
		container.growth = "RIGHT"
		container:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 8)
	else
		container:SetPoint("BOTTOMLEFT", anchorTo, "TOPLEFT", 0, 4)
	end

	containers[#containers + 1] = container
	self.Procs = container

	refresh(container)
	return container
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("PLAYER_TARGET_CHANGED")
driver:RegisterEvent("PLAYER_FOCUS_CHANGED")
driver:RegisterEvent("ARENA_OPPONENT_UPDATE")

driver:SetScript("OnEvent", function(self, event, unit)
	if event == "PLAYER_LOGIN" then
		createPlayerBlock()
		if ICD and ICD.RegisterCallback then
			ICD:RegisterCallback(function(guid)
				if playerBlock and (guid == nil or guid == UnitGUID("player")) then
					updatePlayerBlock()
				end
				for i = 1, #containers do
					local c = containers[i]
					if c ~= playerBlock and (guid == nil or guid == c.guid or (c.unit and guid == UnitGUID(c.unit))) then
						refresh(c)
					end
				end
			end)
		end
	elseif event == "PLAYER_TARGET_CHANGED" then
		for i = 1, #containers do
			if containers[i].unit == "target" then
				refresh(containers[i])
			end
		end
	elseif event == "PLAYER_FOCUS_CHANGED" then
		for i = 1, #containers do
			if containers[i].unit == "focus" then
				refresh(containers[i])
			end
		end
	elseif event == "ARENA_OPPONENT_UPDATE" then
		for i = 1, #containers do
			if containers[i].unit == unit then
				refresh(containers[i])
			end
		end
	end
end)
