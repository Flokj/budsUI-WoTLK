local K, C, L, _ = select(2, ...):unpack()

-- Alt gold: hovering the money in the bags lists every character's gold.
-- Records live in budsUIData (account-wide), never inside a profile.

local _G = _G
local CreateFrame, UIParent = CreateFrame, UIParent
local GameTooltip = GameTooltip
local format, floor = string.format, math.floor
local sort, pairs, type, tonumber = table.sort, pairs, type, tonumber

local NUM_CONTAINER_FRAMES = NUM_CONTAINER_FRAMES or 13
local GOLD_SYMBOL = GOLD_AMOUNT_SYMBOL or "g"
local SILVER_SYMBOL = SILVER_AMOUNT_SYMBOL or "s"
local COPPER_SYMBOL = COPPER_AMOUNT_SYMBOL or "c"

local function IsEnabled()
	return C.Bag ~= nil and C.Bag.AltMoney == true
end

-- ---------------------------------------------------------------------------
-- Storage: budsUIData.CharacterMoney[realm][name] = { copper, class }
-- ---------------------------------------------------------------------------

local function GetStore(create)
	if type(budsUIData) ~= "table" then
		if not create then return nil end
		budsUIData = {}
	end
	local store = budsUIData.CharacterMoney
	if type(store) ~= "table" then
		if not create then return nil end
		store = {}
		budsUIData.CharacterMoney = store
	end
	return store
end

-- A zero from PEW/LOGOUT is not trustworthy: on 3.3.5 cores the purse can still
-- be empty until the server sends it. Only a trusted call (PLAYER_MONEY, or the
-- bags tooltip where the amount is on screen) may lower a recorded amount.
local function SaveMoney(trusted)
	local store = GetStore(true)
	if not store then return end
	local realm = store[K.Realm]
	if type(realm) ~= "table" then
		realm = {}
		store[K.Realm] = realm
	end
	local copper = GetMoney() or 0
	local old = realm[K.Name]
	if copper == 0 and not trusted and type(old) == "table" then
		local known = tonumber(old.copper) or 0
		if known > 0 then
			copper = known
		end
	end
	realm[K.Name] = { copper = copper, class = K.Class }
end

local function ForgetMoney(realm, name)
	local store = GetStore(false)
	local characters = store and store[realm]
	if type(characters) == "table" then
		characters[name] = nil
	end
end

-- ---------------------------------------------------------------------------
-- Formatting
-- ---------------------------------------------------------------------------

local function MoneyText(copper)
	-- GetCoinTextureString exists on 3.3.5 but is missing on some private cores.
	if type(GetCoinTextureString) == "function" then
		return GetCoinTextureString(copper)
	end
	return format("|cffffd700%d%s|r |cffc7c7cf%d%s|r |cffeda55f%d%s|r",
		floor(copper / 10000), GOLD_SYMBOL,
		floor(copper % 10000 / 100), SILVER_SYMBOL,
		copper % 100, COPPER_SYMBOL)
end

local function ClassColor(class)
	local colors = CUSTOM_CLASS_COLORS or _G.RAID_CLASS_COLORS
	local color = class and colors and colors[class]
	if color then
		return color.r, color.g, color.b
	end
	return 1, 1, 1
end

-- ---------------------------------------------------------------------------
-- Tooltip
-- ---------------------------------------------------------------------------

local entries = {}

local function CollectEntries()
	for i = #entries, 1, -1 do
		entries[i] = nil
	end

	local store = GetStore(false)
	if not store then return entries end

	for realm, characters in pairs(store) do
		if type(characters) == "table" then
			for name, data in pairs(characters) do
				if type(name) == "string" and type(data) == "table" then
					entries[#entries + 1] = {
						name = name,
						realm = realm,
						copper = tonumber(data.copper) or 0,
						class = data.class,
						current = (realm == K.Realm and name == K.Name),
					}
				end
			end
		end
	end

	sort(entries, function(a, b)
		if a.current ~= b.current then return a.current end
		if a.copper ~= b.copper then return a.copper > b.copper end
		return a.name < b.name
	end)
	return entries
end

local function ShowTooltip(owner)
	-- The amount is on screen here, so this save wins over a spurious zero.
	SaveMoney(true)
	CollectEntries()

	GameTooltip:SetOwner(owner, "ANCHOR_TOPRIGHT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine(L_BAG_ALT_MONEY, 1, 0.82, 0)

	local total = 0
	for i = 1, #entries do
		local entry = entries[i]
		local label = entry.name
		if entry.realm ~= K.Realm then
			label = label .. " - " .. entry.realm
		end
		if entry.current then
			label = label .. " |cff808080" .. L_BAG_ALT_MONEY_CURRENT .. "|r"
		end
		-- A call in mid-argument-list is truncated to one value in Lua 5.1.
		local r, g, b = ClassColor(entry.class)
		GameTooltip:AddDoubleLine(label, MoneyText(entry.copper), r, g, b, 1, 1, 1)
		total = total + entry.copper
	end

	if #entries <= 1 then
		GameTooltip:AddLine(L_BAG_ALT_MONEY_NONE, 0.6, 0.6, 0.6)
	else
		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine(L_BAG_ALT_MONEY_TOTAL, MoneyText(total), 1, 0.82, 0, 1, 1, 1)
	end

	GameTooltip:Show()
end

-- ---------------------------------------------------------------------------
-- Hover regions
-- ---------------------------------------------------------------------------

local function OnEnter(self)
	if not IsEnabled() then return end
	ShowTooltip(self)
end

local function OnLeave(self)
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
end

local hookedButtons = {}

-- HookScript keeps Blizzard's own coin handlers (MoneyFrame coin pickup) intact.
local function HookButton(button)
	if not button or hookedButtons[button] then return end
	hookedButtons[button] = true
	button:HookScript("OnEnter", OnEnter)
	button:HookScript("OnLeave", OnLeave)
end

local function HookBlizzardMoneyFrames()
	for i = 1, NUM_CONTAINER_FRAMES do
		local prefix = "ContainerFrame" .. i .. "MoneyFrame"
		HookButton(_G[prefix .. "GoldButton"])
		HookButton(_G[prefix .. "SilverButton"])
		HookButton(_G[prefix .. "CopperButton"])
	end
end

-- FontStrings take no mouse input, so the Stuffing money text gets an overlay frame.
local function HookStuffingGold()
	local stuff = _G.Stuffing
	local frame = stuff and stuff.frame
	if not frame or not frame.gold or frame.altMoneyHover then return end
	frame.altMoneyHover = true

	local gold = frame.gold
	local hover = CreateFrame("Frame", "budsUIAltMoneyHover", frame)
	hover:EnableMouse(true)
	hover:SetAllPoints(gold)
	hover:SetFrameLevel(frame:GetFrameLevel() + 5)
	hover:SetScript("OnEnter", OnEnter)
	hover:SetScript("OnLeave", OnLeave)

	-- The search box hides the money text; mirror its state on the hover region.
	frame:HookScript("OnUpdate", function(self)
		local shown = gold:IsShown()
		if shown ~= self.altMoneyShown then
			self.altMoneyShown = shown
			if shown then
				hover:Show()
			else
				hover:Hide()
			end
		end
	end)
end

-- ---------------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------------

K.SaveAltMoney = SaveMoney
K.ForgetAltMoney = ForgetMoney
K.GetAltMoneyEntries = CollectEntries
K.ShowAltMoneyTooltip = ShowTooltip

local driver = CreateFrame("Frame", nil, UIParent)
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("PLAYER_MONEY")
driver:RegisterEvent("PLAYER_LOGOUT")

-- The purse can arrive after PLAYER_ENTERING_WORLD on 3.3.5 cores, so a login
-- saves again once the client has had time to receive it.
local settle
local function ArmSettle()
	settle = 0
	driver:SetScript("OnUpdate", function(self, elapsed)
		settle = settle + elapsed
		if settle < 2 then return end
		self:SetScript("OnUpdate", nil)
		SaveMoney(true)
	end)
end

driver:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_ENTERING_WORLD" then
		HookStuffingGold()
		HookBlizzardMoneyFrames()
		SaveMoney(false)
		ArmSettle()
		return
	end
	-- PLAYER_MONEY is authoritative; LOGOUT may run with an empty purse.
	SaveMoney(event == "PLAYER_MONEY")
end)
