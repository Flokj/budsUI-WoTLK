local K, C, L, _ = select(2, ...):unpack()

-- Profession sidebar: an icon per known crafting profession on the RIGHT side of
-- the open profession window. Clicking a tab casts that profession and the
-- client swaps the window; the current one gets a gold border. 3.3.5 spreads the
-- windows over three hosts: TradeSkillFrame for most professions, CraftFrame
-- (Blizzard_CraftUI) for Enchanting and RuneforgeFrame for Death Knight
-- Runeforging, so the strip follows whichever window is shown.

local _G = _G
local CreateFrame, UIParent = CreateFrame, UIParent
local GetSpellInfo, GetSpellName = GetSpellInfo, GetSpellName
local unpack = unpack

local BOOKTYPE_SPELL = BOOKTYPE_SPELL or "spell"
local TAB_SIZE, TAB_GAP, FIRST_Y = 32, 3, -64
local SELECTED_COLOR = { 1, 0.82, 0 }

-- The sheet the stock SpellBookSkillLineTabTemplate draws behind its icon
-- (64x64, offset up and out of the button). It makes the sidebar read as tabs
-- belonging to the window instead of a free-floating icon column.
local SHEET = "Interface\\SpellBook\\SpellBook-SkillLineTab"
local HIGHLIGHT = "Interface\\Buttons\\ButtonHilight-Square"
local CHECKED = "Interface\\Buttons\\CheckButtonHilight"
local SHEET_SIZE, SHEET_X, SHEET_Y = 64, 3, 11
local SHEET_OVERHANG = SHEET_SIZE - TAB_SIZE + SHEET_X

local ENCHANTING_ID, RUNEFORGING_ID = 7411, 53428

-- Every entry opens a profession window; pure gathering skills do not.
-- { name spell id, optional spell that actually opens the window }
local CATALOG = {
	{ 2259 }, -- Alchemy
	{ 2018 }, -- Blacksmithing
	{ 7411 }, -- Enchanting (opens CraftFrame)
	{ 4036 }, -- Engineering
	{ 45357 }, -- Inscription
	{ 25229 }, -- Jewelcrafting
	{ 2108 }, -- Leatherworking
	{ 3908 }, -- Tailoring
	{ 2550 }, -- Cooking
	{ 3273 }, -- First Aid
	{ 2575, 2656 }, -- Mining: its window opens with Smelting
	{ 53428 }, -- Runeforging (Death Knight, opens RuneforgeFrame)
}

-- "line" hosts report the open window's profession through GetTradeSkillLine();
-- "current" hosts own a single profession, so the tab is matched by spell id.
local HOSTS = {
	{ frame = "TradeSkillFrame", addon = "Blizzard_TradeSkillUI", line = true },
	{ frame = "CraftFrame", addon = "Blizzard_CraftUI", current = ENCHANTING_ID },
	{ frame = "RuneforgeFrame", current = RUNEFORGING_ID },
}

local strip = CreateFrame("Frame", "budsUIProfessionTabs", UIParent)
strip:SetSize(TAB_SIZE, TAB_SIZE)
strip:Hide()

local tabs = {}
local activeHost, activeEntry

local function IsEnabled()
	return C.Blizzard ~= nil and C.Blizzard.ProfessionTabs == true
end

-- ---------------------------------------------------------------------------
-- Current profession
-- ---------------------------------------------------------------------------

local function IsCurrent(tab)
	if not activeHost then return false end
	if activeEntry and activeEntry.current then
		return tab.nameId == activeEntry.current
	end
	if IsTradeSkillLinked and IsTradeSkillLinked() then return false end
	local line = GetTradeSkillLine and GetTradeSkillLine()
	if not line or line == "" then return false end
	return line == tab.castName or line == tab.profName
end

local function MarkCurrent(tab, current)
	if current then
		tab.backdrop:SetBackdropBorderColor(unpack(SELECTED_COLOR))
	else
		tab.backdrop:SetBackdropBorderColor(unpack(C.Media.Border_Color))
	end
	if tab.checked then
		if current then
			tab.checked:Show()
		else
			tab.checked:Hide()
		end
	end
end

local function UpdateCurrent()
	for _, tab in ipairs(tabs) do
		if tab:IsShown() then
			MarkCurrent(tab, IsCurrent(tab))
		end
	end
end

-- ---------------------------------------------------------------------------
-- Tabs
-- ---------------------------------------------------------------------------

local function ShowTooltip(tab)
	GameTooltip:SetOwner(tab, "ANCHOR_RIGHT", -4, -4)
	GameTooltip:SetText(tab.profName or "", 1, 1, 1)
	if IsCurrent(tab) then
		GameTooltip:AddLine(L_PROFESSIONS_CURRENT, 0.6, 0.6, 0.6)
	elseif InCombatLockdown() then
		GameTooltip:AddLine(L_PROFESSIONS_COMBAT, 1, 0.15, 0.15)
	else
		GameTooltip:AddLine(L_PROFESSIONS_SWITCH, 0.6, 0.6, 0.6)
	end
	GameTooltip:Show()
end

local function SwitchTo(tab)
	if IsCurrent(tab) then return end
	if InCombatLockdown() then
		UIErrorsFrame:AddMessage(L_PROFESSIONS_COMBAT, 1, 0.1, 0.1, 1)
		return
	end
	if tab.castName then
		CastSpellByName(tab.castName)
	end
end

local function PlaceSheet(tab, leftSide)
	local sheet = tab.sheet
	if not sheet then return end
	sheet:ClearAllPoints()
	if leftSide then
		sheet:SetPoint("TOPRIGHT", tab, "TOPRIGHT", SHEET_X, SHEET_Y)
	else
		sheet:SetPoint("TOPLEFT", tab, "TOPLEFT", -SHEET_X, SHEET_Y)
	end
end

local function CreateTab(index)
	local tab = CreateFrame("Button", "budsUIProfessionTab" .. index, strip)
	tab:SetSize(TAB_SIZE, TAB_SIZE)
	tab:SetPoint("TOPLEFT", strip, "TOPLEFT", -30, -(index - 1) * (TAB_SIZE + TAB_GAP))

	-- Its own frame one level below the backdrop, so the border and its dark
	-- fill cover the sheet's middle and only the tab art poking out stays visible.
	local sheet = CreateFrame("Frame", nil, tab)
	sheet:SetSize(SHEET_SIZE, SHEET_SIZE)
	local level = tab:GetFrameLevel()
	sheet:SetFrameLevel(level > 2 and level - 2 or 0)
	sheet.texture = sheet:CreateTexture(nil, "BACKGROUND")
	sheet.texture:SetAllPoints()
	sheet.texture:SetTexture(SHEET)
	tab.sheet = sheet
	PlaceSheet(tab, false)

	tab:CreateBackdrop()
	tab:SetHighlightTexture(HIGHLIGHT)
	tab:GetHighlightTexture():SetBlendMode("ADD")

	tab.checked = tab:CreateTexture(nil, "OVERLAY")
	tab.checked:SetAllPoints()
	tab.checked:SetTexture(CHECKED)
	tab.checked:SetBlendMode("ADD")
	tab.checked:Hide()

	tab.icon = tab:CreateTexture(nil, "ARTWORK")
	tab.icon:SetPoint("TOPLEFT", 2, -2)
	tab.icon:SetPoint("BOTTOMRIGHT", -2, 2)
	tab.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	tab:SetScript("OnClick", SwitchTo)
	tab:SetScript("OnEnter", function(self)
		self.backdrop:SetBackdropBorderColor(1, 1, 1)
		ShowTooltip(self)
	end)
	tab:SetScript("OnLeave", function(self)
		self.backdrop:SetBackdropBorderColor(unpack(C.Media.Border_Color))
		UpdateCurrent()
		if GameTooltip:IsOwned(self) then
			GameTooltip:Hide()
		end
	end)
	return tab
end

local function KnownProfessionNames()
	local names = {}
	local i = 1
	while true do
		local name = GetSpellName(i, BOOKTYPE_SPELL)
		if not name then break end
		names[name] = true
		i = i + 1
	end
	return names
end

local function Rebuild()
	local known = KnownProfessionNames()
	local shown = 0
	for _, entry in ipairs(CATALOG) do
		local profName = GetSpellInfo(entry[1])
		local castName = GetSpellInfo(entry[2] or entry[1])
		if profName and castName and known[profName] then
			shown = shown + 1
			local tab = tabs[shown]
			if not tab then
				tab = CreateTab(shown)
				tabs[shown] = tab
			end
			tab.nameId = entry[1]
			tab.profName, tab.castName = profName, castName
			tab.icon:SetTexture(select(3, GetSpellInfo(entry[1])))
			tab:Show()
		end
	end

	for i = shown + 1, #tabs do
		tabs[i]:Hide()
	end

	if shown > 0 then
		strip:SetSize(TAB_SIZE, shown * (TAB_SIZE + TAB_GAP) - TAB_GAP)
	end
	UpdateCurrent()
	return shown
end

-- ---------------------------------------------------------------------------
-- Host windows
-- ---------------------------------------------------------------------------

local function FitsRight(host)
	if not host.GetRight or not UIParent.GetWidth then return true end
	local right, width = host:GetRight(), UIParent:GetWidth()
	if not right or not width then return true end
	-- Reserve the overhang of the tab sheet, not just the button.
	return right + TAB_SIZE + SHEET_OVERHANG <= width
end

local function ApplySide(leftSide)
	for _, tab in ipairs(tabs) do
		PlaceSheet(tab, leftSide)
	end
end

local function ShowFor(entry)
	local host = entry and _G[entry.frame]
	if not host then return end
	activeEntry, activeHost = entry, host
	-- With a single profession there is nothing to switch between.
	if not IsEnabled() or Rebuild() < 2 then
		strip:Hide()
		return
	end
	local leftSide = not FitsRight(host)
	strip:ClearAllPoints()
	if leftSide then
		-- Narrow screen: fall back to the left so the tabs stay on screen.
		strip:SetPoint("TOPRIGHT", host, "TOPLEFT", 4, FIRST_Y)
	else
		-- Right side of the window (preferred).
		strip:SetPoint("TOPLEFT", host, "TOPRIGHT", -4, FIRST_Y)
	end
	ApplySide(leftSide)
	strip:SetFrameStrata(host:GetFrameStrata())
	strip:SetFrameLevel((host:GetFrameLevel() or 1) + 5)
	strip:Show()
end

local function HostHidden(entry)
	if activeEntry ~= entry then return end
	for _, other in ipairs(HOSTS) do
		local frame = _G[other.frame]
		if frame and frame ~= _G[entry.frame] and frame:IsShown() then
			ShowFor(other)
			return
		end
	end
	activeHost, activeEntry = nil, nil
	strip:Hide()
end

local function AttachHost(entry)
	local host = _G[entry.frame]
	if not host or host.budsUITabsHooked then return false end
	host.budsUITabsHooked = true
	host:HookScript("OnShow", function() ShowFor(entry) end)
	host:HookScript("OnHide", function() HostHidden(entry) end)
	return true
end

local function AttachAll()
	for _, entry in ipairs(HOSTS) do
		AttachHost(entry)
	end
end

local function ApplyVisibility()
	AttachAll()
	if not IsEnabled() then
		strip:Hide()
		return
	end
	for _, entry in ipairs(HOSTS) do
		local host = _G[entry.frame]
		if host and host:IsShown() then
			ShowFor(entry)
			return
		end
	end
	if Rebuild() < 2 then
		strip:Hide()
	end
end

K.RebuildProfessionTabs = Rebuild
K.ApplyProfessionTabs = ApplyVisibility

-- ---------------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------------

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("ADDON_LOADED")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:RegisterEvent("TRADE_SKILL_UPDATE")
watcher:RegisterEvent("SKILL_LINES_CHANGED")
watcher:RegisterEvent("SPELLS_CHANGED")
watcher:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" then
		-- Hosts can be created late (CraftFrame comes from Blizzard_CraftUI,
		-- RuneforgeFrame from a custom core), so re-scan on every load.
		AttachAll()
		for _, entry in ipairs(HOSTS) do
			if arg1 == entry.addon then
				local host = _G[entry.frame]
				if host and host:IsShown() and IsEnabled() then
					ShowFor(entry)
				end
				return
			end
		end
		return
	end
	if event == "PLAYER_ENTERING_WORLD" then
		ApplyVisibility()
		return
	end
	if event == "TRADE_SKILL_UPDATE" then
		UpdateCurrent()
		return
	end
	if IsEnabled() then
		Rebuild()
	end
end)
