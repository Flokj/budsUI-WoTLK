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
local COLLECTOR_TOGGLE_SZ = 14   -- toggle button size
local ICON_INSET          = 3    -- inset from minimap edge

-- ── Blacklist ──────────────────────────────────────────────────
local BlackList = {
	["Minimap"]                    = true,
	["MiniMapPing"]                = true,
	["MinimapToggleButton"]        = true,
	["MinimapZoneTextButton"]      = true,
	["MiniMapRecordingButton"]     = true,
	["MiniMapTracking"]            = true,
	["MiniMapTrackingButton"]      = true,
	["MiniMapVoiceChatFrame"]      = true,
	["MiniMapWorldMapButton"]      = true,
	["MiniMapLFGFrame"]            = true,
	["MiniMapInstanceDifficulty"]  = true,
	["MinimapZoomIn"]              = true,
	["MinimapZoomOut"]             = true,
	["MiniMapMailFrame"]           = true,
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
}

local IGNORED_PATTERNS = {
	"^budsUI",
	"^FrostAtomUI",
	"Pin$",
	"Pin%d+",
	"Node",
	"Note",
	"^GatherMate",
	"^Questie",
	"^TomTom",
	"^Routes",
	"^QuestHelper",
	"^Carbonite",
	"^HandyNotes",
	"^ButtonCF",
}

-- ── State ──────────────────────────────────────────────────────
local collected        = {}
local collectedState   = {}
local hookedButtons    = {}
local lastChildCount   = -1

-- UI elements
local collectorPanel
local collectorToggle

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
	if not child or child:GetObjectType() ~= "Button" or collectedState[child] then
		return false
	end
	local name = child:GetName()
	if not name or BlackList[name] then
		return false
	end
	if name:find("^LibDBIcon10_") then
		return true
	end
	for i = 1, #IGNORED_PATTERNS do
		if name:find(IGNORED_PATTERNS[i]) then
			return false
		end
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

-- ── Collect buttons from a frame ────────────────────────────────
local function collectFrom(frame)
	if not frame then return end
	local children = { frame:GetChildren() }
	for i = 1, #children do
		local child = children[i]
		if isCollectable(child) then
			collectButton(child)
		end
	end
end

local function childCount()
	return Minimap:GetNumChildren() + (MinimapBackdrop and MinimapBackdrop:GetNumChildren() or 0)
end

-- ── Scan minimap for new buttons ────────────────────────────────
local function scanButtons()
	local count = childCount()
	if count == lastChildCount then
		return
	end
	local before = #collected
	pcall(collectFrom, Minimap)
	if MinimapBackdrop then
		pcall(collectFrom, MinimapBackdrop)
	end
	lastChildCount = childCount()
	if #collected ~= before then
		layoutCollector()
	end
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
		if collectorToggle and collectorToggle.glyph then
			K.SetGlyph(collectorToggle.glyph, "chevron-right", 10, "OUTLINE")
		end
	else
		collectorPanel:Hide()
		if collectorToggle and collectorToggle.glyph then
			K.SetGlyph(collectorToggle.glyph, "chevron-left", 10, "OUTLINE")
		end
	end
end

-- ── Toggle click ────────────────────────────────────────────────
local function onToggleClick()
	setCollectorOpen(not collectorPanel:IsShown())
end

-- ── Create the collector UI ─────────────────────────────────────
local function createCollector()
	-- ── Panel ──────────────────────────────────────────────────
	collectorPanel = CreateFrame("Frame", "ButtonCollectPanel", UIParent)
	collectorPanel:SetFrameStrata("HIGH")
	collectorPanel:SetClampedToScreen(true)
	collectorPanel:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -ICON_INSET - 3, 3)
	collectorPanel:SetBackdrop(K.Backdrop)
	collectorPanel:SetBackdropColor(unpack(C.Media.Backdrop_Color))
	collectorPanel:SetBackdropBorderColor(unpack(C.Media.Border_Color))
	collectorPanel:Hide()

	-- ── Toggle button ──────────────────────────────────────────
	collectorToggle = CreateFrame("Button", "ButtonCollectToggle", Minimap)
	collectorToggle:SetSize(COLLECTOR_TOGGLE_SZ, COLLECTOR_TOGGLE_SZ)
	collectorToggle:SetPoint("LEFT", Minimap, "LEFT", ICON_INSET, 0)
	collectorToggle:SetFrameLevel(Minimap:GetFrameLevel() + 2)
	collectorToggle:SetScript("OnClick", onToggleClick)
	collectorToggle:SetNormalTexture(nil)
	collectorToggle:SetPushedTexture(nil)
	collectorToggle:SetHighlightTexture(nil)
	collectorToggle:SetDisabledTexture(nil)

	-- Glyph icon (chevron)
	collectorToggle.glyph = K.CreateGlyph(collectorToggle, "chevron-left", 10, "OVERLAY", "OUTLINE")
	collectorToggle.glyph:SetPoint("CENTER", 0, 0)
	collectorToggle.glyph:SetTextColor(1, 1, 1, 0.8)

	collectorToggle:SetScript("OnEnter", function(self)
		if self.glyph then self.glyph:SetTextColor(1, 0.82, 0, 1) end
	end)
	collectorToggle:SetScript("OnLeave", function(self)
		if self.glyph then self.glyph:SetTextColor(1, 1, 1, 0.8) end
	end)

	-- Start hidden until scan finds buttons
	collectorToggle:Hide()
	collectorPanel:Hide()
end

-- ── Apply / refresh collector ───────────────────────────────────
local function applyCollector()
	if not collectorPanel then
		createCollector()
	end
	if collectorPanel then
		collectorPanel:SetBackdropBorderColor(unpack(C.Media.Border_Color))
	end
	scanButtons()
end

-- ── Event frame (periodic scan + config watcher) ────────────────
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
			return
		end
		if not collectorPanel then
			createCollector()
		end
		scanButtons()
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
	end
end
