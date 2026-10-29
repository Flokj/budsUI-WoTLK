-- budsUI_Config :: Core.lua
-- Main config window: left navigation, right page content,
-- Close / Reload / Defaults footer. Pages register via ns.RegisterPage().
-- Lua 5.1 / WoW 3.3.5a safe.

local ADDON_NAME, ns = ...

local max = math.max
local tinsert = tinsert

-- Lua 5.1 lower() handles ASCII only; fold Russian search text by codepoint.
local cyrillicLower = {}
for byte = 0x90, 0xAF do
	local upper = string.char(0xD0, byte)
	cyrillicLower[upper] = byte < 0xA0 and string.char(0xD0, byte + 0x20) or string.char(0xD1, byte - 0x20)
end
cyrillicLower[string.char(0xD0, 0x81)] = string.char(0xD1, 0x91)
local function searchLower(text)
	-- Do not lower UTF-8 bytes through the system ANSI locale.
	local lower = text:gsub("[A-Z]", string.lower)
	return (lower:gsub(string.char(0xD0) .. "[" .. string.char(0x81) .. string.char(0x90) .. "-" .. string.char(0xAF) .. "]", cyrillicLower))
end

local FRAME_NAME = "budsUIConfigFrame"
local WIDTH, HEIGHT = 800, 560
local NAV_WIDTH = 175

local frame
local currentPage
local lastSelectedPage
local makeButton

ns.pages = ns.pages or {}

local CATEGORY_ICONS = {
	General = "INV_Misc_Gear_01",
	Profiles = "INV_Scroll_02",
	ActionBar = "INV_Misc_EngGizmos_30",
	Announcements = "Spell_Holy_Silence",
	Automation = "Trade_Engineering",
	Bag = "INV_Misc_Bag_08",
	Blizzard = "INV_Misc_Book_09",
	Aura = "Spell_Holy_PowerWordShield",
	Chat = "INV_Letter_15",
	Cooldown = "Spell_Nature_TimeStop",
	Error = "Ability_Creature_Cursed_01",
	Filger = "Spell_Arcane_StudentOfMagic",
	Loot = "INV_Box_01",
	Minimap = "INV_Misc_Map_01",
	Misc = "INV_Misc_Gear_02",
	Nameplate = "Ability_Hunter_MarkedForDeath",
	PowerBar = "Spell_Lightning_LightningBolt01",
	PulseCD = "Spell_Nature_WispSplode",
	Skins = "Trade_Engraving",
	Tooltip = "INV_Misc_Note_01",
	Unitframe = "Achievement_Character_Human_Male",
	InternalCooldowns = "INV_Misc_PocketWatch_01",
	Movers = "Ability_Hunter_Pathfinding",
}

-- ---------------------------------------------------------------------------
-- Page loading: Pages/*.lua register via ns.RegisterPage().
-- In-game the files are loaded via budsUI_Config.toc BEFORE this file
-- (WoW 3.3.5a has no directory enumeration, so .toc is the loader), so
-- ns.pages is already filled when the config opens. The manifest below
-- mirrors the .toc order and ns.LoadPages() is a require/loadstring-style
-- fallback for dev/test harnesses outside WoW: it loads every listed page
-- file and each file calls ns.RegisterPage().
-- ---------------------------------------------------------------------------

ns.PageFiles = ns.PageFiles or {
	"General",
	"Profiles",
	"ActionBar",
	"Announcements",
	"Automation",
	"Bag",
	"Blizzard",
	"Aura",
	"Chat",
	"Cooldown",
	"Error",
	"Filger",
	"Loot",
	"Minimap",
	"Misc",
	"Nameplate",
	"PowerBar",
	"PulseCD",
	"Skins",
	"Tooltip",
	"Unitframe",
	"InternalCooldowns",
	"Movers",
}

-- Compile + run one page chunk (loadstring-style). Every page file must
-- call ns.RegisterPage(); returns true on success.
function ns.LoadPageChunk(name, source)
	local compile = loadstring or load
	if type(source) ~= "string" or not compile then
		return false
	end
	local chunk, err = compile(source, "budsUI_Config/Pages/" .. name .. ".lua")
	if not chunk then
		if ns.Print then
			ns.Print("LoadPages: " .. name .. " compile failed: " .. tostring(err))
		end
		return false
	end
	local ok, runErr = pcall(chunk, ADDON_NAME, ns)
	if not ok and ns.Print then
		ns.Print("LoadPages: " .. name .. " failed: " .. tostring(runErr))
	end
	return ok
end

function ns.LoadPages()
	-- In-game: .toc already loaded every page, nothing to do.
	if #ns.pages > 0 then
		return #ns.pages
	end
	-- Dev/test fallback (plain Lua): require/loadstring-style via loadfile.
	-- Each page chunk is expected to call ns.RegisterPage().
	for _, name in ipairs(ns.PageFiles) do
		local ok, chunkOrErr = pcall(function()
			-- Try WoW-style relative path first, then plain require.
			if loadfile then
				local forPath = "Pages/" .. name .. ".lua"
				local chunk = loadfile(forPath)
				if chunk then
					return chunk
				end
			end
			return nil
		end)
		if ok and chunkOrErr then
			local okCall, err = pcall(chunkOrErr, ADDON_NAME, ns)
			if not okCall and ns.Print then
				ns.Print("LoadPages: " .. name .. " failed: " .. tostring(err))
			end
		end
	end
	return #ns.pages
end

-- ---------------------------------------------------------------------------
-- Reload indicator (flagged by ns.Set when a reload entry changes)
-- ---------------------------------------------------------------------------

function ns.FlagReload()
	if frame and frame.reloadButton then
		frame.reloadButton:Show()
	end
end

-- ---------------------------------------------------------------------------
-- Enabled state
-- ---------------------------------------------------------------------------

local function listPaths(paths, list)
	list = list or {}
	if type(paths) == "table" then
		for i = 1, #paths do
			listPaths(paths[i], list)
		end
	elseif paths then
		list[#list + 1] = paths
	end
	return list
end

local function configByPath(path)
	local K, C = ns.Engine()
	if not C then
		return nil
	end
	local node = C
	for key in tostring(path):gmatch("[^.]+") do
		if type(node) ~= "table" then
			return nil
		end
		node = node[tonumber(key) or key]
	end
	return node
end

local function isEntryEnabled(entry)
	if entry.disabled and entry.disabled() then
		return false
	end
	if entry.enabledBy then
		for _, path in ipairs(listPaths(entry.enabledBy)) do
			if not configByPath(path) then
				return false
			end
		end
	end
	if entry.enabledByAny then
		local any = false
		for _, path in ipairs(listPaths(entry.enabledByAny)) do
			if configByPath(path) then
				any = true
				break
			end
		end
		if not any then
			return false
		end
	end
	return true
end

-- ---------------------------------------------------------------------------
-- Page building
-- ---------------------------------------------------------------------------

local function buildPageContent(container, schema, rows)
	for _, row in ipairs(rows) do
		row:Hide()
		row:ClearAllPoints()
	end
	for i = #rows, 1, -1 do
		rows[i] = nil
	end

	local width = container:GetWidth()
	if width < 50 then
		width = 500
	end
	-- NOTE: header entries ({ header = "..." }) carry no .type, so they must
	-- resolve to creators.header explicitly. Falling back to "description"
	-- renders entry.description (nil -> empty) and headers stay invisible.
	local offset = 4
	for _, entry in ipairs(schema) do
		if not entry.hidden then
			local creator
			if entry.header then
				creator = ns.creators.header
			else
				creator = ns.creators[entry.type or "description"]
			end
			local row = creator(container, entry)
			row:SetPoint("TOPLEFT", 0, -offset)
			row:SetPoint("TOPRIGHT", 0, -offset)
			row:Show()
			rows[#rows + 1] = row
			offset = offset + row:GetHeight() + 2
		end
	end
	local contentHeight = offset + 20
	container:SetHeight(max(contentHeight, 100))
end

-- Forward declaration: ns.RefreshPage(true) rebuilds the current view,
-- so it needs showPage defined below.
local showPage

-- ns.RefreshPage(full): light refresh (row Refresh/SetEnabled/Update) by
-- default; with full == true rebuilds the current page via
-- buildPageContent, i.e. fully redraws the current page.
function ns.RefreshPage(full)
	if not frame or not frame:IsShown() then
		return
	end
	if full then
		if currentPage then
			showPage(currentPage)
		elseif #ns.pages > 0 then
			showPage(ns.pages[1])
		end
		return
	end
	for _, row in ipairs(frame.rows) do
		if row.Refresh then
			row.Refresh()
		end
		if row.SetEnabled and row.entry then
			local enabled = isEntryEnabled(row.entry)
			row:SetEnabled(enabled)
			if row.label then
				ns.SetTextEnabled(row.label, enabled)
			end
		end
		if row.Update then
			row:Update()
		end
	end
	if frame.scroll then
		frame.scroll:UpdateScrollChildRect()
	end
end

local function isPageModified(page)
	if not page or page.noReset then return false end
	local function checkSchema(schema)
		if not schema then return false end
		local list = (type(schema) == "function" and schema()) or schema
		for _, entry in ipairs(list) do
			if not entry.header and not entry.description and not entry.noReset
					and (entry.group or entry.path) and ns.IsModified(entry) then
				return true
			end
		end
		return false
	end
	if page.schema and checkSchema(page.schema) then
		return true
	end
	if page.tabs then
		for _, tab in ipairs(page.tabs) do
			if checkSchema(tab.schema) then
				return true
			end
		end
	end
	return false
end
ns.IsPageModified = isPageModified

local function refreshNav()
	if not frame or not frame.navButtons then return end
	for _, info in ipairs(frame.navButtons) do
		if info.page == currentPage then
			info.button:LockHighlight()
		else
			info.button:UnlockHighlight()
		end
		if info.dirtyDot then
			if isPageModified(info.page) then
				info.dirtyDot:Show()
			else
				info.dirtyDot:Hide()
			end
		end
	end
end

showPage = function(page, tabKey)
	currentPage = page
	if page.key ~= "__SEARCH__" then
		lastSelectedPage = page
	end
	if frame.titleText then
		frame.titleText:SetText("")
		frame.titleText:Hide()
	end

	local schema
	if page.tabs and #page.tabs > 0 then
		if frame.tabBar then
			frame.tabBar:Show()
		end
		frame.scroll:SetPoint("TOPLEFT", 6, -34)

		page.activeTabKey = tabKey or page.activeTabKey or page.tabs[1].key
		local activeTab = page.tabs[1]
		for _, tab in ipairs(page.tabs) do
			if tab.key == page.activeTabKey then
				activeTab = tab
				break
			end
		end

		if frame.tabBar and frame.tabBar.buttons then
			for _, btn in ipairs(frame.tabBar.buttons) do
				btn:Hide()
			end
			local x = 0
			for i, tab in ipairs(page.tabs) do
				local btn = frame.tabBar.buttons[i]
				if not btn then
					btn = makeButton(frame.tabBar, tab.name or tab.key, 90)
					btn:SetHeight(20)
					frame.tabBar.buttons[i] = btn
				end
				btn:ClearAllPoints()
				btn:SetPoint("LEFT", x, 0)
				btn:SetText(ns.Text(tab.name or tab.key))
				btn:SetWidth(max(75, btn:GetFontString():GetStringWidth() + 16))
				btn:Show()
				if tab.key == page.activeTabKey then
					btn:LockHighlight()
				else
					btn:UnlockHighlight()
				end
				local tKey = tab.key
				btn:SetScript("OnClick", function()
					PlaySound("igMainMenuOptionCheckBoxOn")
					page.activeTabKey = tKey
					showPage(page, tKey)
				end)
				x = x + btn:GetWidth() + 4
			end
		end
		schema = (type(activeTab.schema) == "function" and activeTab.schema()) or activeTab.schema or {}
	else
		if frame.tabBar then
			frame.tabBar:Hide()
		end
		frame.scroll:SetPoint("TOPLEFT", 6, -8)
		schema = (type(page.schema) == "function" and page.schema()) or page.schema or {}
	end

	buildPageContent(frame.content, schema, frame.rows)
	frame.scroll:SetVerticalScroll(0)
	ns.RefreshPage()
	refreshNav()
end

local function selectPage(page, tabKey)
	showPage(page, tabKey)
	refreshNav()
end

function ns.PerformSearch(query)
	if not query or query == "" then
		if lastSelectedPage then
			selectPage(lastSelectedPage)
		end
		return
	end
	local q = searchLower(query)
	local results = {}
	local seen = {}

	local function scanSchema(schema, catName)
		if not schema then return end
		local list = (type(schema) == "function" and schema()) or schema
		for _, entry in ipairs(list) do
			if not entry.header and not entry.description and not entry.noReset
					and (entry.group or entry.path or entry.label) then
				local labelText = entry.userContent and entry.label or ns.Text(entry.label)
				local descText = entry.userContent and entry.desc or ns.Text(entry.desc)
				local label = searchLower(labelText or "")
				local desc = searchLower(descText or "")
				local group = entry.group and string.lower(entry.group) or ""
				local opt = entry.option and string.lower(entry.option) or ""
				if label:find(q, 1, true) or desc:find(q, 1, true)
						or group:find(q, 1, true) or opt:find(q, 1, true) then
					local uid = tostring(entry.group) .. "." .. tostring(entry.option) .. "." .. tostring(entry.key or entry.path or entry.label)
					if not seen[uid] then
						seen[uid] = true
						local copy = {}
						for k, v in pairs(entry) do
							copy[k] = v
						end
						copy.label = "|cff808080[" .. catName .. "]|r " .. (labelText or "")
						results[#results + 1] = copy
					end
				end
			end
		end
	end

	for _, page in ipairs(ns.pages) do
		local catName = ns.Text(page.name or page.key or "Page")
		if page.tabs and #page.tabs > 0 then
			for _, tab in ipairs(page.tabs) do
				scanSchema(tab.schema, catName .. " > " .. ns.Text(tab.name or tab.key))
			end
		elseif page.schema then
			scanSchema(page.schema, catName)
		end
	end

	local searchSchema = {
		{ header = format(ns.Text("Search Results (%d)"), #results) },
	}
	if #results == 0 then
		searchSchema[#searchSchema + 1] = {
			description = format(ns.Text('No settings found matching "%s".'), query),
		}
	else
		for _, item in ipairs(results) do
			searchSchema[#searchSchema + 1] = item
		end
	end

	local searchPage = {
		key = "__SEARCH__",
		name = "Search Results",
		schema = searchSchema,
		noReset = true,
	}
	showPage(searchPage)
	refreshNav()
end

-- ---------------------------------------------------------------------------
-- Reset
-- ---------------------------------------------------------------------------

StaticPopupDialogs["BUDSUI_CONFIG_RESET_PAGE"] = {
	text = ns.Text("Reset all %s settings to defaults?"),
	button1 = YES,
	button2 = CANCEL,
	OnAccept = function(self, page)
		if page then
			local schema = {}
			if page.tabs and #page.tabs > 0 then
				local activeKey = page.activeTabKey or page.tabs[1].key
				for _, tab in ipairs(page.tabs) do
					if tab.key == activeKey then
						schema = (type(tab.schema) == "function" and tab.schema()) or tab.schema or {}
						break
					end
				end
			else
				schema = (type(page.schema) == "function" and page.schema()) or page.schema or {}
			end
			for _, entry in ipairs(schema) do
				if not entry.header and not entry.description and not entry.noReset
						and (entry.group or entry.path) then
					ns.ResetEntry(entry)
				end
			end
			ns.RefreshPage()
		end
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	preferredIndex = 3,
}

StaticPopupDialogs["BUDSUI_CONFIG_RESET_ALL"] = {
	text = ns.Text("Reset ALL budsUI settings of the active profile to defaults? The UI will be reloaded."),
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		local _, C = ns.Engine()
		local K = ns.Engine()
		if not K or not C then
			return
		end
		local active = K.GetActiveProfile and K.GetActiveProfile()
		if active and _G["budsUIData"] and _G["budsUIData"].Profiles
				and _G["budsUIData"].Profiles[active] then
			_G["budsUIData"].Profiles[active] = {}
		end
		ReloadUI()
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	preferredIndex = 3,
}

-- ---------------------------------------------------------------------------
-- Frame construction
-- ---------------------------------------------------------------------------

local function backdropOf(panel)
	local K, C = ns.Engine()
	if K and K.Backdrop then
		panel:SetBackdrop(K.Backdrop)
		if C and C.Media and C.Media.Backdrop_Color then
			panel:SetBackdropColor(unpack(C.Media.Backdrop_Color))
		else
			panel:SetBackdropColor(0, 0, 0, 0.9)
		end
		if C and C.Media and C.Media.Border_Color then
			panel:SetBackdropBorderColor(unpack(C.Media.Border_Color))
		else
			panel:SetBackdropBorderColor(0.5, 0.5, 0.5)
		end
	else
		panel:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		panel:SetBackdropColor(0, 0, 0, 0.9)
	end
end

makeButton = function(parent, text, width)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width or 100, 23)
	button:SetText(ns.Text(text))
	return button
end

local function createFrame()
	frame = CreateFrame("Frame", FRAME_NAME, UIParent)
	-- Start hidden: CreateFrame shows by default, which would leave the
	-- frame visible (and Toggle would immediately hide it again, so the
	-- first click appears to do nothing). Toggle() shows it explicitly.
	frame:Hide()
	frame:SetSize(WIDTH, HEIGHT)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetFrameLevel(20)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetClampedToScreen(true)
	frame:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)
	frame:SetScript("OnShow", function()
		PlaySound("igMainMenuOption")
		if currentPage then
			showPage(currentPage)
		elseif #ns.pages > 0 then
			showPage(ns.pages[1])
		end
		refreshNav()
	end)
	frame:SetScript("OnHide", function()
		PlaySound("gsTitleOptionExit")
	end)
	tinsert(UISpecialFrames, FRAME_NAME)
	backdropOf(frame)

	-- Title bar ----
	local titleBox = CreateFrame("Frame", nil, frame)
	titleBox:SetPoint("TOPLEFT", 12, -10)
	titleBox:SetPoint("TOPRIGHT", -12, -10)
	titleBox:SetHeight(24)

	local ver = titleBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	ver:SetPoint("CENTER", 0, 0)
	ver:SetJustifyH("CENTER")
	do
		local K = ns.Engine()
		local version = (K and K.Version) or "?"
		ver:SetText("|cff388bdbbudsUI|r " .. tostring(version))
	end

	-- Category title (ex titleText) removed: no per-page header text.
	-- Hint text ("Right-click ... APPLY reloads UI") removed.
	frame.titleText = nil

	-- Left: nav (search + scrollable category list) ----
	local navPanel = CreateFrame("Frame", nil, frame)
	navPanel:SetPoint("TOPLEFT", 12, -40)
	navPanel:SetSize(NAV_WIDTH, HEIGHT - 40 - 44)
	backdropOf(navPanel)

	-- Search box at top of navPanel
	local searchBox = CreateFrame("EditBox", FRAME_NAME .. "SearchBox", navPanel)
	searchBox:SetPoint("TOPLEFT", 6, -6)
	searchBox:SetPoint("TOPRIGHT", -26, -6)
	searchBox:SetHeight(20)
	searchBox:SetAutoFocus(false)
	searchBox:SetFontObject("GameFontHighlightSmall")
	searchBox:SetTextInsets(4, 4, 0, 0)
	backdropOf(searchBox)

	local searchHint = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	searchHint:SetPoint("LEFT", 6, 0)
	searchHint:SetText(ns.Text("Search..."))
	frame.searchHint = searchHint

	local clearBtn = CreateFrame("Button", nil, navPanel)
	clearBtn:SetPoint("LEFT", searchBox, "RIGHT", 4, 0)
	clearBtn:SetSize(18, 18)
	local clearText = clearBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	clearText:SetPoint("CENTER")
	clearText:SetText("x")
	clearBtn:SetFontString(clearText)
	clearBtn:SetScript("OnClick", function()
		searchBox:SetText("")
		searchBox:ClearFocus()
		if lastSelectedPage then
			selectPage(lastSelectedPage)
		end
	end)

	searchBox:SetScript("OnEscapePressed", function(self)
		self:SetText("")
		self:ClearFocus()
		if lastSelectedPage then
			selectPage(lastSelectedPage)
		end
	end)

	searchBox:SetScript("OnEditFocusGained", function()
		searchHint:Hide()
	end)
	searchBox:SetScript("OnEditFocusLost", function(self)
		if self:GetText() == "" then
			searchHint:Show()
		end
	end)

	searchBox:SetScript("OnTextChanged", function(self)
		local text = self:GetText()
		if text and text ~= "" then
			searchHint:Hide()
			if #text >= 2 then
				ns.PerformSearch(text)
			end
		else
			if not self:HasFocus() then
				searchHint:Show()
			end
			if currentPage and currentPage.key == "__SEARCH__" and lastSelectedPage then
				selectPage(lastSelectedPage)
			end
		end
	end)
	frame.searchBox = searchBox

	local navScroll = CreateFrame("ScrollFrame", FRAME_NAME .. "NavScroll", navPanel)
	navScroll:SetPoint("TOPLEFT", 4, -30)
	navScroll:SetPoint("BOTTOMRIGHT", -4, 4)
	navScroll:EnableMouseWheel(true)

	local navChild = CreateFrame("Frame", nil, navScroll)
	navChild:SetPoint("TOPLEFT")
	navChild:SetWidth(NAV_WIDTH - 8)
	navChild:SetHeight(100)
	navScroll:SetScrollChild(navChild)
	frame.navScroll = navScroll

	navScroll:SetScript("OnMouseWheel", function(self, delta)
		local current = self:GetVerticalScroll()
		local maxScroll = max(0, navChild:GetHeight() - navScroll:GetHeight())
		local newScroll = min(maxScroll, max(0, current - delta * 25))
		self:SetVerticalScroll(newScroll)
	end)

	frame.navButtons = {}
	local y = -2
	for _, page in ipairs(ns.pages) do
		local button = CreateFrame("Button", nil, navChild)
		button:SetPoint("TOPLEFT", 2, y)
		button:SetSize(NAV_WIDTH - 12, 18)

		local icon = button:CreateTexture(nil, "ARTWORK")
		icon:SetSize(14, 14)
		icon:SetPoint("LEFT", 2, 0)
		local iconName = CATEGORY_ICONS[page.key] or "INV_Misc_QuestionMark"
		icon:SetTexture("Interface\\Icons\\" .. iconName)
		icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		button.icon = icon

		local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		label:SetPoint("LEFT", icon, "RIGHT", 4, 0)
		label:SetPoint("RIGHT", button, "RIGHT", -14, 0)
		label:SetJustifyH("LEFT")
		label:SetText(ns.Text(page.name or page.key or "?"))
		button:SetFontString(label)
		button.label = label

		local dot = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		dot:SetPoint("RIGHT", button, "RIGHT", -2, 0)
		dot:SetText("|cff59bfff*|r")
		dot:Hide()
		button.dirtyDot = dot

		button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
		local p = page
		button:SetScript("OnClick", function()
			PlaySound("igMainMenuOptionCheckBoxOn")
			searchBox:SetText("")
			searchBox:ClearFocus()
			selectPage(p)
		end)
		button:SetScript("OnEnter", function(self)
			if ns.IsPageModified and ns.IsPageModified(p) then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(ns.Text(p.name or p.key))
				GameTooltip:AddLine(ns.Text("Has modified settings"), 0.35, 0.75, 1.0)
				GameTooltip:Show()
			end
		end)
		button:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		frame.navButtons[#frame.navButtons + 1] = { button = button, page = page, dirtyDot = dot }
		y = y - 19
	end
	navChild:SetHeight(math.abs(y) + 10)

	-- Right: page scroll + content ----
	local rightPanel = CreateFrame("Frame", nil, frame)
	rightPanel:SetPoint("TOPLEFT", navPanel, "TOPRIGHT", 8, 0)
	rightPanel:SetPoint("BOTTOMRIGHT", -12, 44)
	backdropOf(rightPanel)

	local tabBar = CreateFrame("Frame", nil, rightPanel)
	tabBar:SetPoint("TOPLEFT", 6, -6)
	tabBar:SetPoint("TOPRIGHT", -26, -6)
	tabBar:SetHeight(24)
	tabBar:Hide()
	tabBar.buttons = {}
	frame.tabBar = tabBar

	local scroll = CreateFrame("ScrollFrame", FRAME_NAME .. "Scroll", rightPanel, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 6, -8)
	scroll:SetPoint("BOTTOMRIGHT", -26, 8)
	frame.scroll = scroll

	local content = CreateFrame("Frame", nil, scroll)
	content:SetPoint("TOPLEFT")
	content:SetWidth(550)
	content:SetHeight(100)
	scroll:SetScrollChild(content)
	frame.content = content
	frame.rows = {}

	scroll:SetScript("OnMouseWheel", function(self, delta)
		local slider = _G[scroll:GetName() .. "ScrollBar"]
		if slider then
			local v = slider:GetValue()
			slider:SetValue(v - delta * 40)
		end
	end)

	-- Footer ----
	local close = makeButton(frame, CLOSE, 96)
	close:SetPoint("TOPRIGHT", rightPanel, "BOTTOMRIGHT", 0, -8)
	close:SetScript("OnClick", function()
		PlaySound("igMainMenuOption")
		frame:Hide()
	end)

	local apply = makeButton(frame, APPLY, 96)
	apply:SetPoint("RIGHT", close, "LEFT", -4, 0)
	apply:SetScript("OnClick", function()
		ReloadUI()
	end)
	apply:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(ns.Text("Most settings apply after a UI reload."))
		GameTooltip:Show()
	end)
	apply:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	local defaults = makeButton(frame, DEFAULT, 96)
	defaults:SetPoint("TOPLEFT", rightPanel, "BOTTOMLEFT", 0, -8)
	defaults:SetScript("OnClick", function()
		if currentPage then
			StaticPopup_Show("BUDSUI_CONFIG_RESET_PAGE", ns.Text(currentPage.name), nil, currentPage)
		end
	end)

	local totalReset = makeButton(frame, "Total Reset", 110)
	totalReset:SetPoint("LEFT", defaults, "RIGHT", 4, 0)
	totalReset:SetScript("OnClick", function()
		StaticPopup_Show("BUDSUI_CONFIG_RESET_ALL")
	end)

	local reloadButton = makeButton(frame, "Reload UI", 96)
	reloadButton:SetPoint("RIGHT", apply, "LEFT", -4, 0)
	reloadButton:SetScript("OnClick", function()
		ReloadUI()
	end)
	reloadButton:Hide()
	frame.reloadButton = reloadButton
end

-- ---------------------------------------------------------------------------
-- Open / toggle
-- ---------------------------------------------------------------------------

function ns.Toggle(pageKey)
	if InCombatLockdown() and not (frame and frame:IsShown()) then
		ns.Print("|cffffe02e" .. (ERR_NOT_IN_COMBAT or "Cannot do that in combat.") .. "|r")
		return
	end
	-- Ensure every Pages/*.lua registered (no-op in-game, .toc did it).
	ns.LoadPages()
	if not frame then
		createFrame()
	end
	if frame:IsShown() and not pageKey then
		frame:Hide()
		return
	end
	if pageKey then
		for _, page in ipairs(ns.pages) do
			if page.key == pageKey then
				showPage(page)
				refreshNav()
				break
			end
		end
	elseif not currentPage and #ns.pages > 0 then
		-- Open on the first page (OnShow re-asserts the same page).
		showPage(ns.pages[1])
		refreshNav()
	end
	frame:Show()
end

function ns.Open()
	ns.Toggle()
end

-- Legacy global used by old macros/keybinds.
function CreateUIConfig()
	ns.Toggle()
end

-- ---------------------------------------------------------------------------
-- Slash commands, game menu, interface options
-- ---------------------------------------------------------------------------

do
	SLASH_BUDSUICONFIG1 = "/kc"
	SLASH_BUDSUICONFIG2 = "/buds"
	SLASH_BUDSUICONFIG3 = "/config"
	SLASH_BUDSUICONFIG4 = "/cfg"
	SLASH_BUDSUICONFIG5 = "/configui"
	function SlashCmdList.BUDSUICONFIG(msg, editbox)
		PlaySound("igMainMenuOption")
		ns.Toggle()
	end

	SLASH_BUDSUIRESET1 = "/resetconfig"
	function SlashCmdList.BUDSUIRESET(msg)
		StaticPopup_Show("BUDSUI_CONFIG_RESET_ALL")
	end
end

do
	local menuHook = CreateFrame("Frame")
	menuHook:RegisterEvent("PLAYER_LOGIN")
	menuHook:SetScript("OnEvent", function(self)
		self:UnregisterAllEvents()
		local Menu = GameMenuFrame
		local Interface = GameMenuButtonUIOptions
		if not Menu or not Interface then
			return -- WoW 3.3.5: no such buttons, /buds still works
		end
		local button = CreateFrame("Button", "GameMenuBudsUIButton", Menu, "GameMenuButtonTemplate")
		button:SetSize(Interface:GetWidth(), Interface:GetHeight())
		button:SetPoint("TOP", Interface, "BOTTOM", 0, -1)
		button:SetText("|cff388bdbbudsUI|r")
		button:SetScript("OnClick", function()
			HideUIPanel(Menu)
			ns.Toggle()
		end)
		local KeyBinds = GameMenuButtonKeybindings
		-- Re-anchor the whole chain below our button so nothing overlaps.
		-- The default buttons are relatively chained, but other addons
		-- (e.g. budsUI AddOns button) may insert extra buttons, so anchor
		-- every known lower button explicitly, in top-to-bottom order.
		-- Missing buttons (other clients / not yet created) are skipped.
		local previous = button
		local chain = {
			"GameMenuButtonKeybindings",
			"GameMenuButtonMacros",
			"GameMenuButtonAddOns",
			"GameMenuButtonLogout",
			"GameMenuButtonQuit",
			"GameMenuButtonExit",
			"GameMenuButtonContinue",
			"GameMenuButtonReturnToGame",
		}
		for _, name in ipairs(chain) do
			local b = _G[name]
			if b then
				b:ClearAllPoints()
				b:SetPoint("TOP", previous, "BOTTOM", 0, -1)
				previous = b
			end
		end
		if KeyBinds then
			-- Grow the menu to fit the inserted button.
			Menu:SetHeight(Menu:GetHeight() + button:GetHeight() + 1)
		end
	end)
end

do
	local panel = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
	panel:Hide()
	panel.name = "|cff388bdbbudsUI|r"
	panel:SetScript("OnShow", function(self)
		if self.built then
			return
		end
		self.built = true
		local K = ns.Engine()
		local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		title:SetPoint("TOPLEFT", 16, -16)
		title:SetText("budsUI")
		local sub = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
		sub:SetWidth(420)
		sub:SetJustifyH("LEFT")
		sub:SetText(ns.Text("Type /buds to open the configuration window."))
		local open = makeButton(self, "Open Config", 140)
		open:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -12)
		open:SetScript("OnClick", function()
			ns.Toggle()
		end)
		local version = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		version:SetPoint("BOTTOMRIGHT", -16, 16)
		version:SetText(ns.Text("Version: ") .. tostring(K and K.Version or "?"))
	end)
	InterfaceOptions_AddCategory(panel)
end

_G[ADDON_NAME] = ns
