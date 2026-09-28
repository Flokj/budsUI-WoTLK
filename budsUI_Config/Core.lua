-- budsUI_Config :: Core.lua
-- Main config window: left navigation, right page content,
-- Close / Reload / Defaults footer. Pages register via ns.RegisterPage().
-- Lua 5.1 / WoW 3.3.5a safe.

local ADDON_NAME, ns = ...

local max = math.max
local tinsert = tinsert

local FRAME_NAME = "budsUIConfigFrame"
local WIDTH, HEIGHT = 780, 520
local NAV_WIDTH = 160

local frame
local currentPage

ns.pages = ns.pages or {}

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
	"ThreatMeter",
	"Tooltip",
	"Unitframe",
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

showPage = function(page)
	currentPage = page
	-- Category title removed: right panel shows no header text.
	if frame.titleText then
		frame.titleText:SetText("")
		frame.titleText:Hide()
	end
	buildPageContent(frame.content, page.schema or {}, frame.rows)
	frame.scroll:SetVerticalScroll(0)
	ns.RefreshPage()
end

local function refreshNav()
	for _, info in ipairs(frame.navButtons) do
		if info.page == currentPage then
			info.button:LockHighlight()
		else
			info.button:UnlockHighlight()
		end
	end
end

local function selectPage(page)
	showPage(page)
	refreshNav()
end

-- ---------------------------------------------------------------------------
-- Reset
-- ---------------------------------------------------------------------------

StaticPopupDialogs["BUDSUI_CONFIG_RESET_PAGE"] = {
	text = "Reset all %s settings on this page to defaults?",
	button1 = YES,
	button2 = CANCEL,
	OnAccept = function(self, page)
		if page then
			for _, entry in ipairs(page.schema) do
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
	text = "Reset ALL budsUI settings of the active profile to defaults? The UI will be reloaded.",
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

local function makeButton(parent, text, width)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width or 100, 23)
	button:SetText(text)
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

	-- Left: nav (fixed list, all 22 pages fit without scrolling) ----
	local navPanel = CreateFrame("Frame", nil, frame)
	navPanel:SetPoint("TOPLEFT", 12, -40)
	navPanel:SetSize(NAV_WIDTH, HEIGHT - 40 - 44)
	backdropOf(navPanel)

	-- Plain container instead of a ScrollFrame: no scrollbar needed.
	local navList = CreateFrame("Frame", nil, navPanel)
	navList:SetPoint("TOPLEFT", 4, -6)
	navList:SetPoint("BOTTOMRIGHT", -4, 6)

	local navChild = navList

	frame.navButtons = {}
	local y = -2
	for _, page in ipairs(ns.pages) do
		local button = CreateFrame("Button", nil, navChild)
		button:SetPoint("TOPLEFT", 2, y)
		button:SetSize(NAV_WIDTH - 36, 18)
		local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		label:SetAllPoints()
		label:SetJustifyH("LEFT")
		label:SetText(page.name or page.key or "?")
		button:SetFontString(label)
		button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
		local p = page
		button:SetScript("OnClick", function()
			PlaySound("igMainMenuOptionCheckBoxOn")
			selectPage(p)
		end)
		frame.navButtons[#frame.navButtons + 1] = { button = button, page = page }
		y = y - 19
	end
	-- navList is anchor-fixed (TOPLEFT/BOTTOMRIGHT of navPanel): 22 rows of
	-- 19px = ~420px fit into the ~424px tall list, no scrollbar needed.

	-- Right: page scroll + content ----
	local rightPanel = CreateFrame("Frame", nil, frame)
	rightPanel:SetPoint("TOPLEFT", navPanel, "TOPRIGHT", 8, 0)
	rightPanel:SetPoint("BOTTOMRIGHT", -12, 44)
	backdropOf(rightPanel)

	local scroll = CreateFrame("ScrollFrame", FRAME_NAME .. "Scroll", rightPanel, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 6, -8)
	scroll:SetPoint("BOTTOMRIGHT", -26, 8)
	frame.scroll = scroll

	local content = CreateFrame("Frame", nil, scroll)
	content:SetPoint("TOPLEFT")
	content:SetWidth(560)
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
		GameTooltip:SetText("Most settings apply after a UI reload.")
		GameTooltip:Show()
	end)
	apply:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	local defaults = makeButton(frame, DEFAULT, 96)
	defaults:SetPoint("TOPLEFT", rightPanel, "BOTTOMLEFT", 0, -8)
	defaults:SetScript("OnClick", function()
		if currentPage then
			StaticPopup_Show("BUDSUI_CONFIG_RESET_PAGE", currentPage.name, nil, currentPage)
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
		sub:SetText("Type /buds to open the configuration window.")
		local open = makeButton(self, "Open Config", 140)
		open:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -12)
		open:SetScript("OnClick", function()
			ns.Toggle()
		end)
		local version = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		version:SetPoint("BOTTOMRIGHT", -16, 16)
		version:SetText("Version: " .. tostring(K and K.Version or "?"))
	end)
	InterfaceOptions_AddCategory(panel)
end

_G[ADDON_NAME] = ns
