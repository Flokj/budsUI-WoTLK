local K, C, L, _ = select(2, ...):unpack()
if C.Minimap.Enable ~= true or C.Minimap.CollectButtons ~= true then return end

-- ═══════════════════════════════════════════════════════════════
--  Minimap button collector — FrostAtomUI-style:
--    • toggle arrow on the LEFT edge of the minimap
--    • panel with collected buttons tucked to the LEFT of minimap
--    • buttons arranged in a 4-column grid
-- ═══════════════════════════════════════════════════════════════

local unpack = unpack
local ipairs = ipairs
local ceil, floor, min = math.ceil, math.floor, math.min
local CreateFrame, UIParent = CreateFrame, UIParent
local tinsert = table.insert

-- Grid layout constants (matching FrostAtomUI proportions)
local COLLECTOR_CELL      = 32   -- cell size for each button
local COLLECTOR_COLUMNS   = 4    -- grid columns
local COLLECTOR_PADDING   = 6    -- padding inside the panel
local COLLECTOR_TOGGLE_SZ = 22   -- toggle button size
local ICON_INSET          = 3    -- inset from minimap edge

-- ── Blacklist ──────────────────────────────────────────────────
local BlackList = {
	["Minimap"]                    = true,
	["MiniMapPing"]                = true,
	["MinimapToggleButton"]        = true,
	["MinimapZoneTextButton"]      = true,
	["MiniMapRecordingButton"]     = true,
	["MiniMapTracking"]            = true,
	["MiniMapVoiceChatFrame"]      = true,
	["MiniMapWorldMapButton"]      = true,
	["MiniMapLFGFrame"]            = true,
	["MinimapZoomIn"]              = true,
	["MinimapZoomOut"]             = true,
	["MiniMapMailFrame"]            = true,
	["BattlefieldMinimap"]         = true,
	["MinimapBackdrop"]            = true,
	["GameTimeFrame"]              = true,
	["TimeManagerClockButton"]     = true,
	["FeedbackUIButton"]           = true,
	["HelpOpenTicketButton"]       = true,
	["MiniMapBattlefieldFrame"]    = true,
	["QueueStatusMinimapButton"]   = true,
	["ButtonCollectFrame"]         = true,
	["ButtonCollectPanel"]         = true,
	["ButtonCollectToggle"]        = true,
	["HandyNotesPin"]              = true,
}

-- ── State ──────────────────────────────────────────────────────
local collected        = {}
local collectedState   = {}
local hookedButtons    = {}
local lastChildCount   = -1

-- UI elements
local collectorPanel
local collectorToggle
local toggleGlyph

-- ── Grid layout ─────────────────────────────────────────────────
local function layoutCollector()
	local shown = 0
	for i = 1, #collected do
		local bu = collected[i]
		if bu and bu:IsShown() then
			local methods = getmetatable(bu).__index
			local col = shown % COLLECTOR_COLUMNS
			local row = floor(shown / COLLECTOR_COLUMNS)
			methods.ClearAllPoints(bu)
			methods.SetPoint(bu, "CENTER", collectorPanel, "TOPRIGHT",
				-COLLECTOR_PADDING - (col + 0.5) * COLLECTOR_CELL,
				-COLLECTOR_PADDING - (row + 0.5) * COLLECTOR_CELL)
			shown = shown + 1
		end
	end
	if shown == 0 then
		collectorToggle:Hide()
		collectorPanel:Hide()
	else
		local columns = min(shown, COLLECTOR_COLUMNS)
		local rows    = ceil(shown / COLLECTOR_COLUMNS)
		collectorPanel:SetSize(
			columns * COLLECTOR_CELL + COLLECTOR_PADDING * 2,
			rows    * COLLECTOR_CELL + COLLECTOR_PADDING * 2)
		collectorToggle:Show()
	end
end

-- ── Visibility change hook ──────────────────────────────────────
local function onCollectedVisibility(bu)
	if collectedState[bu] then
		layoutCollector()
	end
end

-- ── Collectability test ─────────────────────────────────────────
local function isCollectable(child)
	if child:GetObjectType() ~= "Button" or collectedState[child] then
		return false
	end
	local name = child:GetName()
	if not name or BlackList[name] then
		return false
	end
	return true
end

-- ── Collect one button ──────────────────────────────────────────
local function collectButton(button)
	local state = { parent = button:GetParent(), strata = button:GetFrameStrata() }
	for i = 1, button:GetNumPoints() do
		state[i] = { button:GetPoint(i) }
	end
	collectedState[button] = state
	collected[#collected + 1] = button
	button:SetParent(collectorPanel)
	button:SetFrameStrata(collectorPanel:GetFrameStrata())
	-- Prevent external code from repositioning the button.
	button.ClearAllPoints = K.Noop
	button.SetPoint       = K.Noop
	if not hookedButtons[button] then
		hookedButtons[button] = true
		button:HookScript("OnShow", onCollectedVisibility)
		button:HookScript("OnHide", onCollectedVisibility)
	end
end

-- ── Scan minimap for new buttons ────────────────────────────────
local function scanButtons()
	local children = { Minimap:GetChildren() }
	for i = 1, #children do
		local child = children[i]
		if isCollectable(child) then
			collectButton(child)
		end
	end
	if MinimapBackdrop then
		local bdChildren = { MinimapBackdrop:GetChildren() }
		for i = 1, #bdChildren do
			local child = bdChildren[i]
			if isCollectable(child) then
				collectButton(child)
			end
		end
	end
	if MinimapCluster then
		local clusterChildren = { MinimapCluster:GetChildren() }
		for i = 1, #clusterChildren do
			local child = clusterChildren[i]
			if isCollectable(child) then
				collectButton(child)
			end
		end
	end
	lastChildCount = Minimap:GetNumChildren()
	layoutCollector()
end

-- ── Release all collected buttons back to originals ─────────────
local function releaseButtons()
	for i = #collected, 1, -1 do
		local button = collected[i]
		local state  = collectedState[button]
		collected[i]        = nil
		collectedState[button] = nil
		button.ClearAllPoints = nil
		button.SetPoint       = nil
		button:SetParent(state.parent)
		button:SetFrameStrata(state.strata)
		button:ClearAllPoints()
		for j = 1, #state do
			if type(state[j]) == "table" then
				button:SetPoint(unpack(state[j]))
			end
		end
	end
	hookedButtons = {}
	lastChildCount = -1
end

-- ── Toggle panel open / closed ──────────────────────────────────
local function setCollectorOpen(open)
	if open then
		collectorPanel:Show()
		toggleGlyph:SetText(">")   -- right-pointing = panel visible
	else
		collectorPanel:Hide()
		toggleGlyph:SetText("<")   -- left-pointing  = panel hidden
	end
end

-- ── Toggle click ────────────────────────────────────────────────
local function onToggleClick()
	setCollectorOpen(not collectorPanel:IsShown())
end

-- ── Toggle hover glow ───────────────────────────────────────────
local function onToggleEnter()
	K:UIFrameFadeIn(collectorToggle, 0.25, 0.6, 1.0)
end
local function onToggleLeave()
	if not InCombatLockdown() then
		K:UIFrameFadeOut(collectorToggle, 0.25, 1.0, 0.6)
	end
end

-- ── Create the collector UI ─────────────────────────────────────
local function createCollector()
	-- ── Panel ──────────────────────────────────────────────────
	collectorPanel = CreateFrame("Frame", "ButtonCollectPanel", UIParent)
	collectorPanel:SetFrameStrata("HIGH")
	collectorPanel:SetClampedToScreen(true)
	collectorPanel:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMLEFT",
		-ICON_INSET - COLLECTOR_TOGGLE_SZ - 4, -3)
	collectorPanel:SetBackdrop(K.Backdrop)
	collectorPanel:SetBackdropColor(0.05, 0.05, 0.05, 0.85)
	collectorPanel:SetBackdropBorderColor(unpack(C.Media.Border_Color))
	collectorPanel:Hide()

	-- ── Toggle button ──────────────────────────────────────────
	collectorToggle = CreateFrame("Button", "ButtonCollectToggle", Minimap)
	collectorToggle:SetSize(COLLECTOR_TOGGLE_SZ, COLLECTOR_TOGGLE_SZ)
	collectorToggle:SetPoint("LEFT", ICON_INSET, 0)
	collectorToggle:SetFrameLevel(Minimap:GetFrameLevel() + 2)
	collectorToggle:SetScript("OnClick",     onToggleClick)
	collectorToggle:SetScript("OnEnter",     onToggleEnter)
	collectorToggle:SetScript("OnLeave",     onToggleLeave)
	-- No backdrop — arrow only, no white box.
	collectorToggle:SetNormalTexture(nil)
	collectorToggle:SetPushedTexture(nil)
	collectorToggle:SetHighlightTexture(nil)
	collectorToggle:SetDisabledTexture(nil)

	-- Glyph text (arrow character)
	toggleGlyph = collectorToggle:CreateFontString(nil, "OVERLAY")
	toggleGlyph:SetFont(C.Media.Font, 14, "OUTLINE")
	toggleGlyph:SetTextColor(1, 1, 1, 1)
	toggleGlyph:SetPoint("CENTER", 0, 0)
	toggleGlyph:SetText("<")   -- start closed → left-pointing

	-- Start hidden until scan finds buttons
	collectorToggle:Hide()
	collectorPanel:Hide()
end

-- ── Apply / refresh collector ───────────────────────────────────
local function applyCollector()
	if not collectorPanel then
		createCollector()
	end
	-- Refresh border colour from current config
	if collectorPanel then
		collectorPanel:SetBackdropBorderColor(unpack(C.Media.Border_Color))
	end
	scanButtons()
end

-- ── Event frame ─────────────────────────────────────────────────
-- Fires once on login, then polls config every second so that
-- toggling CollectButtons / Enable in-game picks up changes
-- without a UI reload.
local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnUpdate", function(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed >= 1 then
		self.elapsed = 0
		if C.Minimap.Enable ~= true or C.Minimap.CollectButtons ~= true then
			-- Config says disable → release and hide.
			releaseButtons()
			if collectorPanel then
				collectorPanel:Hide()
				collectorToggle:Hide()
			end
			self:SetScript("OnUpdate", nil)
			return
		end
		if not collectorPanel then
			createCollector()
		end
		applyCollector()
		self:SetScript("OnUpdate", nil)
	end
end)

-- ── Expose release for cleanup (used by Kill.lua) ──────────────
function K.ReleaseMinimapButtons()
	if collectorPanel then
		releaseButtons()
		collectorPanel:Hide()
		collectorToggle:Hide()
		collectorPanel = nil
		collectorToggle = nil
		toggleGlyph    = nil
	end
end
