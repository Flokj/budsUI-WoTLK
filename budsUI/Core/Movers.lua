local K, C, L, _ = select(2, ...):unpack()

--[[ budsUI Movers (WotLK 3.3.5 port of the KkthnxUI placement system)
	- Mover = anchor frame, widget anchors TO the mover (not an overlay).
	- Drag with snapping to screen centre/edges + other movers, live guides,
	  live coords, optional grid, arrow-key nudge, per-mover popup (X/Y +
	  anchor picker), Move UI panel, per-mover + reset-all, slash commands.
	- WotLK-safe: no C_Timer, no SetPropagateKeyboardInput, no retail skins.
	- Back-compat: old saves C.MoverPositions[name] = {ap,"UIParent",rp,x,y}
	  keep working; K.MoverFrames table keeps working (Chatbar tinsert etc).
]]

local _G = _G
local pairs, ipairs, select, tinsert, tremove = pairs, ipairs, select, table.insert, table.remove
local abs, floor, ceil = math.abs, math.floor, math.ceil
local strfind = string.find
local unpack = unpack
local InCombatLockdown = InCombatLockdown
local GetCursorPosition = GetCursorPosition
local CreateFrame, UIParent = CreateFrame, UIParent

local movers = {}		-- key -> mover frame
local moverOrder = {}	-- creation order, for deterministic reset/list
local editing = false
local panel
local gridShown = false

local SNAP = 8 -- snap distance in UIParent pixels

local function T(s) return (L and L[s]) or s end

local function RoundNum(n)
	if n >= 0 then return floor(n + 0.5) else return ceil(n - 0.5) end
end

-- WotLK-safe delayed call (C_Timer.After does not exist on 3.3.5)
local _timers = {}
local _timerFrame = CreateFrame("Frame")
_timerFrame:Hide()
_timerFrame:SetScript("OnUpdate", function(self, elapsed)
	for i = #_timers, 1, -1 do
		local t = _timers[i]
		t.d = t.d - elapsed
		if t.d <= 0 then
			tremove(_timers, i)
			t.f()
		end
	end
	if #_timers == 0 then self:Hide() end
end)
local function DelayedCall(delay, func)
	tinsert(_timers, { d = delay, f = func })
	_timerFrame:Show()
end

-- Assigned by the popup section further down
local NotifyPopup = function() end

local THEME = {
	coords = { 0.85, 0.72, 0.42 },
	grid = { 0.72, 0.60, 0.40, 0.10 },
	center = { 0.70, 0.50, 0.25, 0.40 },
	backdrop = { 0.05, 0.05, 0.05, 0.85 },
	rest = { 0.18, 0.71, 1, 1 }, -- budsUI blue, matches the old mover
}

-- ---------------------------------------------------------------------------
-- Widget skins (Kkthnx-style look, budsUI primitives, WotLK-safe).
-- No gradients (Texture:SetGradient/CreateColor), no SetAtlas, no SetRotation:
-- flat fills + borders + fonts only.
-- ---------------------------------------------------------------------------

local BTN_BG = { 0.09, 0.114, 0.149, 0.95 }
local BTN_BG_HOVER = { 0.16, 0.24, 0.36, 1 }
local GOLD = { 0.95, 0.69, 0.26 }

local function StripButtonArt(b)
	if b.SetNormalTexture then
		b:SetNormalTexture("")
		b:SetPushedTexture("")
		b:SetDisabledTexture("")
	end
	if b.SetHighlightTexture then b:SetHighlightTexture("") end
	for i = 1, b:GetNumRegions() do
		local r = select(i, b:GetRegions())
		if r and r.GetObjectType and r:GetObjectType() == "Texture" then
			r:SetTexture(nil)
			r:SetAlpha(0)
		end
	end
end

local function SkinMoverButton(b, fontSize)
	if not b or b.__budsSkinned then return b end
	b.__budsSkinned = true
	StripButtonArt(b)
	b:SetBackdrop(K.Backdrop)
	if K.CreateBorder then K.CreateBorder(b, 10) end
	-- colors AFTER CreateBorder (it re-applies the backdrop, resetting white)
	b:SetBackdropColor(BTN_BG[1], BTN_BG[2], BTN_BG[3], BTN_BG[4])
	b:SetBackdropBorderColor(THEME.rest[1], THEME.rest[2], THEME.rest[3], THEME.rest[4])
	local fs = b.GetFontString and b:GetFontString()
	if fs then
		fs:SetFont(C.Media.Font, fontSize or 12, C.Media.Font_Style)
		fs:SetTextColor(1, 1, 1)
		fs:SetShadowOffset(0, 0)
	end
	b:HookScript("OnEnter", function(self)
		self:SetBackdropColor(BTN_BG_HOVER[1], BTN_BG_HOVER[2], BTN_BG_HOVER[3], BTN_BG_HOVER[4])
		if K.Color then self:SetBackdropBorderColor(K.Color.r, K.Color.g, K.Color.b, 1) end
		local f = self.GetFontString and self:GetFontString()
		if f then f:SetTextColor(0.7, 0.85, 1) end
	end)
	b:HookScript("OnLeave", function(self)
		self:SetBackdropColor(BTN_BG[1], BTN_BG[2], BTN_BG[3], BTN_BG[4])
		self:SetBackdropBorderColor(THEME.rest[1], THEME.rest[2], THEME.rest[3], THEME.rest[4])
		local f = self.GetFontString and self:GetFontString()
		if f then f:SetTextColor(1, 1, 1) end
	end)
	return b
end

local function SkinMoverEditBox(e)
	if not e or e.__budsSkinned then return e end
	e.__budsSkinned = true
	for i = 1, e:GetNumRegions() do
		local r = select(i, e:GetRegions())
		if r and r.GetObjectType and r:GetObjectType() == "Texture" then
			r:SetTexture(nil)
			r:SetAlpha(0)
		end
	end
	e:SetBackdrop(K.Backdrop)
	if K.CreateBorder then K.CreateBorder(e, 10) end
	e:SetBackdropColor(0.06, 0.06, 0.06, 0.9)
	e:SetBackdropBorderColor(THEME.rest[1], THEME.rest[2], THEME.rest[3], THEME.rest[4])
	e:SetFont(C.Media.Font, 12, C.Media.Font_Style)
	e:SetTextColor(1, 1, 1)
	if e.SetTextInsets then e:SetTextInsets(5, 5, 0, 0) end
	e:HookScript("OnEditFocusGained", function(self)
		if K.Color then self:SetBackdropBorderColor(K.Color.r, K.Color.g, K.Color.b, 1) end
	end)
	e:HookScript("OnEditFocusLost", function(self)
		self:SetBackdropBorderColor(THEME.rest[1], THEME.rest[2], THEME.rest[3], THEME.rest[4])
	end)
	return e
end

local function SkinMoverCheckBox(box)
	if not box or box.__budsSkinned then return box end
	box.__budsSkinned = true
	if box.SetNormalTexture then
		box:SetNormalTexture("")
		box:SetPushedTexture("")
		box:SetDisabledTexture("")
	end
	-- keep the checked + highlight art, put a dark budsUI box behind it
	if box.CreateBackdrop then
		box:CreateBackdrop("Default")
		if box.backdrop then
			box.backdrop:SetBackdropBorderColor(THEME.rest[1], THEME.rest[2], THEME.rest[3], THEME.rest[4])
		end
	end
	return box
end

local function SkinMoverCloseButton(b)
	if not b or b.__budsSkinned then return b end
	b.__budsSkinned = true
	StripButtonArt(b)
	b:SetBackdrop(K.Backdrop)
	if K.CreateBorder then K.CreateBorder(b, 10) end
	b:SetBackdropColor(0.35, 0.1, 0.1, 0.95)
	b:SetBackdropBorderColor(THEME.rest[1], THEME.rest[2], THEME.rest[3], THEME.rest[4])
	local x = b:CreateFontString(nil, "OVERLAY")
	x:SetFont(C.Media.Font, 12, C.Media.Font_Style)
	x:SetPoint("CENTER", 0, 1)
	x:SetText("X")
	x:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
	b:HookScript("OnEnter", function(self)
		self:SetBackdropColor(0.6, 0.18, 0.18, 1)
	end)
	b:HookScript("OnLeave", function(self)
		self:SetBackdropColor(0.35, 0.1, 0.1, 0.95)
	end)
	return b
end

-- Thin top accent line, the flat WotLK-safe echo of Kkthnx's gradient header
local function AddTopLine(frame)
	local top = frame:CreateTexture(nil, "BORDER")
	top:SetTexture(THEME.rest[1], THEME.rest[2], THEME.rest[3], 0.35)
	top:SetHeight(1)
	top:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
	top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
end

-- ---------------------------------------------------------------------------
-- Storage (live C.MoverPositions + persistent profile copy, like the old code)
-- ---------------------------------------------------------------------------

local function GetProfile()
	local activeProfile = K.GetActiveProfile and K.GetActiveProfile()
	if activeProfile and budsUIData and budsUIData.Profiles and budsUIData.Profiles[activeProfile] then
		return budsUIData.Profiles[activeProfile]
	end
end

local function SaveEntry(key, value)
	C.MoverPositions[key] = value
	local profile = GetProfile()
	if profile then
		if not profile.MoverPositions then profile.MoverPositions = {} end
		profile.MoverPositions[key] = value
	end
end

local function ClearEntries()
	C.MoverPositions = {}
	local profile = GetProfile()
	if profile then profile.MoverPositions = {} end
end

local ANCHOR_POINTS = { "CENTER", "TOP", "BOTTOM", "LEFT", "RIGHT", "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }
K.MoverAnchorPoints = ANCHOR_POINTS

-- Screen coordinates of one named point on a frame
local function PointCoords(frame, point)
	local left, bottom = frame:GetLeft(), frame:GetBottom()
	local width, height = frame:GetWidth(), frame:GetHeight()
	if not (left and bottom and width and height) then return end
	local x, y = left + width / 2, bottom + height / 2
	if strfind(point, "LEFT") then x = left
	elseif strfind(point, "RIGHT") then x = left + width end
	if strfind(point, "TOP") then y = bottom + height
	elseif strfind(point, "BOTTOM") then y = bottom end
	return x, y
end

-- Where a mover sits right now, measured from one of UIParent's points
local function OffsetFor(mover, point)
	local mx, my = PointCoords(mover, point)
	local ux, uy = PointCoords(UIParent, point)
	if not (mx and ux) then return 0, 0 end
	return RoundNum(mx - ux), RoundNum(my - uy)
end

-- Read a saved position. Shapes:
--   new:    { point = "TOP", x = 0, y = -80 }
--   legacy: { "TOP", "UIParent", "TOP", 0, -80 }
--   ancient:{ x, y } (bare pair = CENTER anchor)
local function SavedFor(mover)
	local saved = C.MoverPositions and C.MoverPositions[mover.moverKey]
	if not saved then return end
	if type(saved) ~= "table" then return end
	if saved.point or saved.x then
		return saved.point or "CENTER", saved.x or 0, saved.y or 0, true
	end
	if type(saved[1]) == "number" and type(saved[2]) == "number" then
		return "CENTER", saved[1], saved[2], true
	end
	if type(saved[1]) == "string" then
		return saved[1], saved[2], saved[3], saved[4], saved[5]
	end
end

local function CurrentPoint(mover)
	local saved = C.MoverPositions and C.MoverPositions[mover.moverKey]
	if type(saved) == "table" then
		if type(saved.point) == "string" then return saved.point end
		if type(saved[1]) == "number" then return "CENTER" end
		if type(saved[1]) == "string" then return saved[1] end
	end
	local default = mover.moverDefault
	return (default and default[1]) or "CENTER"
end
K.GetMoverPoint = CurrentPoint

local function ApplyOffset(mover, offsetX, offsetY, point)
	point = point or CurrentPoint(mover)
	SaveEntry(mover.moverKey, { point = point, x = offsetX, y = offsetY })
	mover:ClearAllPoints()
	mover:SetPoint(point, UIParent, point, offsetX, offsetY)
end

local function ResolveParent(rel)
	if rel == nil or rel == "UIParent" then return UIParent end
	if type(rel) == "table" then return rel end
	return _G[rel] or UIParent
end

local function RestorePosition(mover)
	mover:ClearAllPoints()
	local a, b, c, d, e = SavedFor(mover)
	if a == nil then
		local default = mover.moverDefault
		mover:SetPoint(default[1], ResolveParent(default[2]), default[3] or default[1], default[4] or 0, default[5] or 0)
		return
	end
	if type(a) == "string" and type(b) == "number" then
		-- new {point,x,y} or ancient {x,y}
		mover:SetPoint(a, UIParent, a, b, c or 0)
		return
	end
	if type(a) == "string" then
		-- legacy {ap, parent, rp, x, y}
		mover:SetPoint(a, ResolveParent(b), c or a, d or 0, e or 0)
		return
	end
	local default = mover.moverDefault
	mover:SetPoint(default[1], ResolveParent(default[2]), default[3] or default[1], default[4] or 0, default[5] or 0)
end

local function CurrentOffset(mover)
	return OffsetFor(mover, CurrentPoint(mover))
end

-- Re-pin a mover by a different point without moving it on screen
local function SetAnchorPoint(mover, point)
	local x, y = OffsetFor(mover, point)
	ApplyOffset(mover, x, y, point)
end

-- ---------------------------------------------------------------------------
-- Guides and grid
-- ---------------------------------------------------------------------------

local guideV, guideH
local function Guides()
	if not guideV then
		local holder = CreateFrame("Frame", nil, UIParent)
		holder:SetAllPoints(UIParent)
		holder:SetFrameStrata("TOOLTIP")
		guideV = holder:CreateTexture(nil, "OVERLAY")
		guideV:SetTexture(0.4, 0.9, 0.4, 0.9)
		guideV:SetWidth(1)
		guideV:Hide()
		guideH = holder:CreateTexture(nil, "OVERLAY")
		guideH:SetTexture(0.4, 0.9, 0.4, 0.9)
		guideH:SetHeight(1)
		guideH:Hide()
	end
	return guideV, guideH
end

local grid
local function BuildGrid()
	if grid then return grid end
	grid = CreateFrame("Frame", "budsUI_MoverGrid", UIParent)
	grid:SetAllPoints(UIParent)
	grid:SetFrameStrata("BACKGROUND")

	local w, h = UIParent:GetWidth(), UIParent:GetHeight()
	local step = 32
	local function Line(vertical, pos)
		local tex = grid:CreateTexture(nil, "BACKGROUND")
		tex:SetTexture(THEME.grid[1], THEME.grid[2], THEME.grid[3], THEME.grid[4])
		if vertical then
			tex:SetWidth(1)
			tex:SetHeight(h)
			tex:SetPoint("LEFT", UIParent, "LEFT", pos, 0)
		else
			tex:SetWidth(w)
			tex:SetHeight(1)
			tex:SetPoint("TOP", UIParent, "TOP", 0, -pos)
		end
	end
	for x = 0, w, step do Line(true, x) end
	for y = 0, h, step do Line(false, y) end
	local cv = grid:CreateTexture(nil, "ARTWORK")
	cv:SetTexture(THEME.center[1], THEME.center[2], THEME.center[3], THEME.center[4])
	cv:SetWidth(1)
	cv:SetHeight(h)
	cv:SetPoint("CENTER")
	local ch = grid:CreateTexture(nil, "ARTWORK")
	ch:SetTexture(THEME.center[1], THEME.center[2], THEME.center[3], THEME.center[4])
	ch:SetWidth(w)
	ch:SetHeight(1)
	ch:SetPoint("CENTER")

	grid:Hide()
	return grid
end

function K.ToggleMoverGrid(show)
	if show == nil then show = not gridShown end
	gridShown = show
	local g = BuildGrid()
	if show then g:Show() else g:Hide() end
end

-- ---------------------------------------------------------------------------
-- Snapping
-- ---------------------------------------------------------------------------

local function SnapTargets(self)
	local ux, uy = UIParent:GetCenter()
	local halfW, halfH = UIParent:GetWidth() / 2, UIParent:GetHeight() / 2
	local xs = { 0, -halfW, halfW }
	local ys = { 0, halfH, -halfH }
	for _, mover in ipairs(moverOrder) do
		if mover ~= self and mover:IsShown() then
			local cx, cy = mover:GetCenter()
			if cx then
				local ox, oy = cx - ux, cy - uy
				local hw, hh = mover:GetWidth() / 2, mover:GetHeight() / 2
				xs[#xs + 1] = ox
				xs[#xs + 1] = ox - hw
				xs[#xs + 1] = ox + hw
				ys[#ys + 1] = oy
				ys[#ys + 1] = oy - hh
				ys[#ys + 1] = oy + hh
			end
		end
	end
	return xs, ys
end

local function SnapAxis(value, half, targets)
	local edges = { value, value - half, value + half }
	local best, bestLine, bestDelta
	for _, edge in ipairs(edges) do
		for _, target in ipairs(targets) do
			local d = abs(edge - target)
			if d <= SNAP and (not best or d < best) then
				best = d
				bestLine = target
				bestDelta = target - edge
			end
		end
	end
	if bestDelta then value = value + bestDelta end
	return value, bestLine
end

-- ---------------------------------------------------------------------------
-- Dragging
-- ---------------------------------------------------------------------------

local function OnMoveUpdate(self)
	local scale = self:GetEffectiveScale()
	local mx, my = GetCursorPosition()
	local cx = mx / scale - self.__grabX
	local cy = my / scale - self.__grabY
	local ux, uy = UIParent:GetCenter()
	local ox, oy = cx - ux, cy - uy

	local xs, ys = SnapTargets(self)
	local lineX, lineY
	ox, lineX = SnapAxis(ox, self:GetWidth() / 2, xs)
	oy, lineY = SnapAxis(oy, self:GetHeight() / 2, ys)

	self:ClearAllPoints()
	self:SetPoint("CENTER", UIParent, "CENTER", RoundNum(ox), RoundNum(oy))

	if self.Coords then
		local point = CurrentPoint(self)
		local px, py = OffsetFor(self, point)
		self.Coords:SetText(point .. "  " .. px .. ", " .. py)
	end
	NotifyPopup(self)

	local vg, hg = Guides()
	if lineX then
		vg:ClearAllPoints()
		vg:SetPoint("CENTER", UIParent, "CENTER", lineX, 0)
		vg:SetHeight(UIParent:GetHeight())
		vg:Show()
	else
		vg:Hide()
	end
	if lineY then
		hg:ClearAllPoints()
		hg:SetPoint("CENTER", UIParent, "CENTER", 0, lineY)
		hg:SetWidth(UIParent:GetWidth())
		hg:Show()
	else
		hg:Hide()
	end
end

local function OnDragStart(self)
	if InCombatLockdown() then return end
	local scale = self:GetEffectiveScale()
	local mx, my = GetCursorPosition()
	local cx, cy = self:GetCenter()
	self.__grabX = mx / scale - cx
	self.__grabY = my / scale - cy
	self:SetScript("OnUpdate", OnMoveUpdate)
end

local function OnDragStop(self)
	self:SetScript("OnUpdate", nil)
	local ox, oy = CurrentOffset(self)
	ApplyOffset(self, ox, oy)
	NotifyPopup(self)
	local vg, hg = Guides()
	vg:Hide()
	hg:Hide()
end

-- Arrow keys nudge the hovered mover one pixel at a time
local nudge = {
	UP = { 0, 1 },
	DOWN = { 0, -1 },
	LEFT = { -1, 0 },
	RIGHT = { 1, 0 },
}

local function OnKeyDown(self, key)
	local step = nudge[key]
	if not step then
		if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(true) end
		return
	end
	if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(false) end
	local ox, oy = CurrentOffset(self)
	ApplyOffset(self, ox + step[1], oy + step[2])
	if self.Coords then
		self.Coords:SetText(CurrentPoint(self) .. "  " .. (ox + step[1]) .. ", " .. (oy + step[2]))
	end
	NotifyPopup(self)
end

-- ---------------------------------------------------------------------------
-- Factory
-- ---------------------------------------------------------------------------

local function CaptureDefault(frame)
	local ap, parent, rp, x, y = frame:GetPoint(1)
	if ap then
		return { ap, parent or UIParent, rp or ap, x or 0, y or 0 }
	end
	return { "CENTER", UIParent, "CENTER", 0, 0 }
end

function K.CreateMover(frame, key, label, defaultPoint, width, height, attachPoint)
	if not frame or not key then return end
	if movers[key] then return movers[key] end

	local mover = CreateFrame("Frame", "budsUI_Mover_" .. key, UIParent)
	mover:SetWidth(width or frame:GetWidth() or 100)
	mover:SetHeight(height or frame:GetHeight() or 30)
	mover:SetFrameStrata("HIGH")
	mover:SetClampedToScreen(true)
	mover:EnableMouse(false)
	mover:RegisterForDrag("LeftButton")
	mover:SetScript("OnDragStart", OnDragStart)
	mover:SetScript("OnDragStop", OnDragStop)
	mover:Hide()

	mover.moverKey = key
	if defaultPoint and defaultPoint[1] then
		mover.moverDefault = { defaultPoint[1], defaultPoint[2] or UIParent, defaultPoint[3] or defaultPoint[1], defaultPoint[4] or 0, defaultPoint[5] or 0 }
	else
		mover.moverDefault = CaptureDefault(frame)
	end
	mover.moverLabel = label or key

	mover:SetBackdrop(K.Backdrop)
	if K.CreateBorder then K.CreateBorder(mover) end
	-- NOTE: CreateBorder re-applies the backdrop internally, which resets
	-- its color to white, so the tint must be set AFTER it.
	mover:SetBackdropColor(THEME.backdrop[1], THEME.backdrop[2], THEME.backdrop[3], THEME.backdrop[4])
	mover:SetBackdropBorderColor(THEME.rest[1], THEME.rest[2], THEME.rest[3], THEME.rest[4])

	local text = mover:CreateFontString(nil, "OVERLAY")
	text:SetFont(C.Media.Font, 12, C.Media.Font_Style)
	text:SetPoint("CENTER")
	text:SetText(mover.moverLabel)
	text:SetTextColor(1, 1, 1)
	mover.Label = text

	local coords = mover:CreateFontString(nil, "OVERLAY")
	coords:SetFont(C.Media.Font, 11, C.Media.Font_Style)
	coords:SetPoint("BOTTOM", mover, "TOP", 0, 5)
	coords:SetTextColor(THEME.coords[1], THEME.coords[2], THEME.coords[3])
	mover.Coords = coords

	mover:SetScript("OnMouseUp", function(self)
		if editing then K.OpenMoverPopup(self) end
	end)

	mover:SetScript("OnEnter", function(self)
		if not editing then return end
		if self.EnableKeyboard then
			self:EnableKeyboard(true)
			self:SetScript("OnKeyDown", OnKeyDown)
		end
		if K.Color then
			self:SetBackdropBorderColor(K.Color.r, K.Color.g, K.Color.b, 1)
		else
			self:SetBackdropBorderColor(1, 0.82, 0.4, 1)
		end
	end)
	mover:SetScript("OnLeave", function(self)
		if self.EnableKeyboard then self:EnableKeyboard(false) end
		self:SetScript("OnKeyDown", nil)
		self:SetBackdropBorderColor(THEME.rest[1], THEME.rest[2], THEME.rest[3], THEME.rest[4])
	end)

	RestorePosition(mover)

	frame:ClearAllPoints()
	frame:SetPoint(attachPoint or "TOPLEFT", mover, attachPoint or "TOPLEFT", 0, 0)

	movers[key] = mover
	moverOrder[#moverOrder + 1] = mover
	frame.budsUI_Mover = mover

	return mover
end

-- Back-compat: modules do tinsert(K.MoverFrames, SomeFrame).
-- Lazily adopt anything in that list when edit mode opens.
if type(K.MoverFrames) ~= "table" then K.MoverFrames = {} end

-- Default holder list from the old overlay mover. Kept by NAME (not globals)
-- so holders created by modules always resolve, whenever they appear.
local LEGACY_MOVER_NAMES = {
	"AchievementAnchor",
	"ActionBarAnchor",
	"Bar3Holder",
	"Bar4Holder",
	"BuffsAnchor",
	"CaptureBarAnchor",
	"ChatFrame1",
	"LootRollAnchor",
	"MinimapAnchor",
	"PetActionBarAnchor",
	"PulseCDAnchor",
	"RightActionBarAnchor",
	"SPECIAL_P_BUFF_ICON_Anchor",
	"ShiftHolder",
	"budsUI_COOLDOWN_Anchor",
	"budsUI_PVE_PVP_CC_Anchor",
	"budsUI_PVE_PVP_DEBUFF_Anchor",
	"budsUI_P_BUFF_ICON_Anchor",
	"budsUI_P_PROC_ICON_Anchor",
	"budsUI_T_BUFF_Anchor",
	"budsUI_T_DEBUFF_ICON_Anchor",
	"budsUI_T_DE_BUFF_BAR_Anchor",
	"TooltipAnchor",
	"VehicleAnchor",
	"WatchFrameAnchor",
}

function K.RegisterMoverFrame(frame, label, defaultPoint, width, height)
	if type(frame) == "string" then frame = _G[frame] end
	if not frame then return end
	local name = frame:GetName()
	if not name then return end
	return K.CreateMover(frame, name, label or name, defaultPoint, width, height)
end

local function AdoptLegacyFrames()
	for _, name in ipairs(LEGACY_MOVER_NAMES) do
		local frame = _G[name]
		if frame and type(frame) == "table" and frame.GetName and frame:GetName() then
			if not movers[name] then K.RegisterMoverFrame(frame) end
		end
	end
	for _, entry in pairs(K.MoverFrames) do
		local frame = entry
		if type(entry) == "string" then frame = _G[entry] end
		if frame and type(frame) == "table" and frame.GetName and frame:GetName() then
			if not movers[frame:GetName()] then
				K.RegisterMoverFrame(frame)
			end
		end
	end
end

-- Let a frame be dragged directly with the left mouse button (bags/loot style).
-- On release its mover slides underneath and the position saves normally.
function K.EnableFrameDrag(frame)
	local mover = frame and frame.budsUI_Mover
	if not mover then return end
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetClampedToScreen(true)
	frame:SetScript("OnDragStart", function(self)
		if InCombatLockdown() or editing then return end
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local left, top = self:GetLeft(), self:GetTop()
		if not left then return end
		mover:ClearAllPoints()
		mover:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
		local ox, oy = CurrentOffset(mover)
		ApplyOffset(mover, ox, oy)
		self:ClearAllPoints()
		self:SetPoint("TOPLEFT", mover, "TOPLEFT", 0, 0)
	end)
end

function K.GetMover(key) return movers[key] end

function K.GetMoverList()
	local list = {}
	for _, mover in ipairs(moverOrder) do
		list[#list + 1] = { key = mover.moverKey, label = mover.moverLabel }
	end
	return list
end

function K.ResetMover(key)
	local mover = movers[key]
	if not mover then return end
	SaveEntry(key, nil)
	if C.MoverPositions then C.MoverPositions[key] = nil end
	local profile = GetProfile()
	if profile and profile.MoverPositions then profile.MoverPositions[key] = nil end
	RestorePosition(mover)
end

function K.FlashMover(key)
	local mover = movers[key]
	if not mover or not editing then return end
	mover:SetBackdropBorderColor(1, 0.82, 0.4, 1)
	DelayedCall(0.6, function()
		if mover.SetBackdropBorderColor then
			mover:SetBackdropBorderColor(THEME.rest[1], THEME.rest[2], THEME.rest[3], THEME.rest[4])
		end
	end)
end

-- ---------------------------------------------------------------------------
-- Per-mover popup: name, X/Y inputs, anchor picker, nudge pad
-- ---------------------------------------------------------------------------

local popup, popupTarget

local function RefreshPopup()
	if not popup or not popupTarget then return end
	local ox, oy = CurrentOffset(popupTarget)
	popup.Title:SetText(popupTarget.moverLabel)
	popup.X:SetText(tostring(ox))
	popup.Y:SetText(tostring(oy))
	popup.X:SetCursorPosition(0)
	popup.Y:SetCursorPosition(0)
	local point = CurrentPoint(popupTarget)
	popup.Anchor:SetText(point)
	popup.AnchorNote:SetText("Offsets are from " .. point .. " of UIParent")
end

NotifyPopup = function(mover)
	if popup and popup:IsShown() and popupTarget == mover then RefreshPopup() end
end

local function Nudge(dx, dy)
	if not popupTarget then return end
	local ox, oy = CurrentOffset(popupTarget)
	ApplyOffset(popupTarget, ox + dx, oy + dy)
	RefreshPopup()
end

local function ApplyInputs()
	if not popupTarget then return end
	local x = tonumber(popup.X:GetText())
	local y = tonumber(popup.Y:GetText())
	if x and y then ApplyOffset(popupTarget, RoundNum(x), RoundNum(y)) end
	RefreshPopup()
end

local function BuildPopup()
	if popup then return popup end

	popup = CreateFrame("Frame", "budsUI_MoverPopup", UIParent)
	popup:SetWidth(232)
	popup:SetHeight(244)
	popup:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 260)
	popup:SetFrameStrata("DIALOG")
	popup:SetMovable(true)
	popup:EnableMouse(true)
	popup:RegisterForDrag("LeftButton")
	popup:SetScript("OnDragStart", popup.StartMoving)
	popup:SetScript("OnDragStop", popup.StopMovingOrSizing)
	popup:SetBackdrop(K.Backdrop)
	if K.CreateBorder then K.CreateBorder(popup) end
	-- (after CreateBorder: it resets backdrop color to white)
	popup:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
	popup:SetBackdropBorderColor(THEME.rest[1], THEME.rest[2], THEME.rest[3], THEME.rest[4])
	AddTopLine(popup)

	local title = popup:CreateFontString(nil, "OVERLAY")
	title:SetFont(C.Media.Font, 12, C.Media.Font_Style)
	title:SetPoint("TOP", 0, -8)
	title:SetTextColor(THEME.coords[1], THEME.coords[2], THEME.coords[3])
	popup.Title = title

	local close = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -4, -4)
	close:SetWidth(22)
	close:SetHeight(22)
	SkinMoverCloseButton(close)

	local function MakeArrow(label, x, y, dx, dy)
		local b = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
		b:SetWidth(30)
		b:SetHeight(24)
		b:SetPoint("TOPLEFT", popup, "TOPLEFT", x, y)
		b:SetText(label)
		SkinMoverButton(b, 13)
		b:SetScript("OnClick", function() Nudge(dx, dy) end)
		return b
	end

	MakeArrow("^", 56, -32, 0, 1)
	MakeArrow("<", 24, -58, -1, 0)
	MakeArrow(">", 88, -58, 1, 0)
	MakeArrow("v", 56, -84, 0, -1)

	local function MakeInput(label, yOff)
		local text = popup:CreateFontString(nil, "OVERLAY")
		text:SetFont(C.Media.Font, 11, C.Media.Font_Style)
		text:SetPoint("TOPLEFT", popup, "TOPLEFT", 132, yOff)
		text:SetText(label)
		local edit = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
		edit:SetWidth(70)
		edit:SetHeight(22)
		edit:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 2, -3)
		edit:SetAutoFocus(false)
		SkinMoverEditBox(edit)
		edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() ApplyInputs() end)
		edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
		return edit
	end

	popup.X = MakeInput("X", -32)
	popup.Y = MakeInput("Y", -76)

	local anchorLabel = popup:CreateFontString(nil, "OVERLAY")
	anchorLabel:SetFont(C.Media.Font, 11, C.Media.Font_Style)
	anchorLabel:SetPoint("TOPLEFT", popup, "TOPLEFT", 16, -122)
	anchorLabel:SetText(T("Anchor"))

	local anchor = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
	anchor:SetWidth(130)
	anchor:SetHeight(22)
	anchor:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -14, -118)
	SkinMoverButton(anchor, 11)
	anchor:SetScript("OnClick", function()
		if not popupTarget then return end
		local current = CurrentPoint(popupTarget)
		local index = 1
		for i, point in ipairs(ANCHOR_POINTS) do
			if point == current then index = i break end
		end
		SetAnchorPoint(popupTarget, ANCHOR_POINTS[(index % #ANCHOR_POINTS) + 1])
		RefreshPopup()
	end)
	popup.Anchor = anchor

	local anchorNote = popup:CreateFontString(nil, "OVERLAY")
	anchorNote:SetFont(C.Media.Font, 10, C.Media.Font_Style)
	anchorNote:SetPoint("TOPLEFT", anchorLabel, "BOTTOMLEFT", 0, -12)
	anchorNote:SetTextColor(0.6, 0.6, 0.6)
	anchorNote:SetWidth(200)
	anchorNote:SetJustifyH("LEFT")
	popup.AnchorNote = anchorNote

	local reset = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
	reset:SetWidth(200)
	reset:SetHeight(22)
	reset:SetPoint("TOPLEFT", anchorNote, "BOTTOMLEFT", -2, -8)
	reset:SetText(T("Reset"))
	SkinMoverButton(reset, 12)
	reset:SetScript("OnClick", function()
		if popupTarget then
			K.ResetMover(popupTarget.moverKey)
			RefreshPopup()
		end
	end)

	return popup
end

local function OpenPopup(mover)
	popupTarget = mover
	BuildPopup()
	RefreshPopup()
	popup:Show()
end
K.OpenMoverPopup = OpenPopup

-- ---------------------------------------------------------------------------
-- Edit mode + panel
-- ---------------------------------------------------------------------------

local function BuildPanel()
	if panel then return panel end

	panel = CreateFrame("Frame", "budsUI_MoverPanel", UIParent)
	panel:SetWidth(240)
	panel:SetHeight(140)
	panel:SetPoint("TOP", UIParent, "TOP", 0, -120)
	panel:SetFrameStrata("DIALOG")
	panel:SetMovable(true)
	panel:EnableMouse(true)
	panel:RegisterForDrag("LeftButton")
	panel:SetScript("OnDragStart", panel.StartMoving)
	panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
	panel:SetBackdrop(K.Backdrop)
	if K.CreateBorder then K.CreateBorder(panel) end
	-- (after CreateBorder: it resets backdrop color to white)
	panel:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
	panel:SetBackdropBorderColor(THEME.rest[1], THEME.rest[2], THEME.rest[3], THEME.rest[4])
	AddTopLine(panel)

	local title = panel:CreateFontString(nil, "OVERLAY")
	title:SetFont(C.Media.Font, 13, C.Media.Font_Style)
	title:SetPoint("TOP", panel, "TOP", 0, -8)
	title:SetTextColor(THEME.coords[1], THEME.coords[2], THEME.coords[3])
	title:SetText(T("Move UI"))

	local hint = panel:CreateFontString(nil, "OVERLAY")
	hint:SetFont(C.Media.Font, 10, C.Media.Font_Style)
	hint:SetPoint("TOP", title, "BOTTOM", 0, -6)
	hint:SetWidth(220)
	hint:SetJustifyH("CENTER")
	hint:SetText(T("Drag to move, edges snap. Hover + arrows nudge. Click for popup."))

	local gridCheck = CreateFrame("CheckButton", "budsUI_MoverGridCheck", panel, "InterfaceOptionsCheckButtonTemplate")
	gridCheck:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 4, -8)
	gridCheck:SetHitRectInsets(0, -60, 0, 0)
	_G[gridCheck:GetName() .. "Text"]:SetText(T("Grid"))
	local gridText = _G[gridCheck:GetName() .. "Text"]
	if gridText then
		gridText:SetFont(C.Media.Font, 12, C.Media.Font_Style)
		gridText:SetTextColor(1, 1, 1)
	end
	SkinMoverCheckBox(gridCheck)
	gridCheck:SetChecked(gridShown)
	gridCheck:SetScript("OnClick", function(self)
		K.ToggleMoverGrid(self:GetChecked() and true or false)
	end)

	local lock = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	lock:SetWidth(100)
	lock:SetHeight(22)
	lock:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 10, 10)
	lock:SetText(T("Lock"))
	SkinMoverButton(lock, 12)
	lock:SetScript("OnClick", function() K.ToggleMovers(false) end)

	local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	reset:SetWidth(100)
	reset:SetHeight(22)
	reset:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -10, 10)
	reset:SetText(T("Reset All"))
	SkinMoverButton(reset, 12)
	reset:SetScript("OnClick", function() K.ResetMovers() end)

	return panel
end

function K.ToggleMovers(show)
	if show == nil then show = not editing end
	if show and InCombatLockdown() then
		K.Print("|cffffe02e" .. ERR_NOT_IN_COMBAT .. "|r")
		return
	end

	if show then AdoptLegacyFrames() end
	editing = show

	for _, mover in ipairs(moverOrder) do
		mover:EnableMouse(show)
		if show then mover:Show() else mover:Hide() end
		if not show then
			if mover.EnableKeyboard then mover:EnableKeyboard(false) end
			mover:SetScript("OnKeyDown", nil)
			mover:SetScript("OnUpdate", nil)
		end
	end

	local p = BuildPanel()
	if show then p:Show() else p:Hide() end
	if not show then
		if gridShown then K.ToggleMoverGrid(false) end
		if popup then popup:Hide() end
	end
end

function K.MoversEnabled() return editing end

function K.ResetMovers()
	ClearEntries()
	for _, mover in ipairs(moverOrder) do RestorePosition(mover) end
	K.Print(T("Frame positions reset."))
end

-- ---------------------------------------------------------------------------
-- Legacy slash commands (kept): /moveui /mui /mm /mmm [+ reset]
-- ---------------------------------------------------------------------------

local placed = {
	"Butsu",
	"StuffingFrameBags",
	"StuffingFrameBank",
	"alDamageMeterFrame",
	"PlayerFrame",
	"TargetFrame",
}

local function InitMove(msg)
	if InCombatLockdown() then K.Print("|cffffe02e" .. ERR_NOT_IN_COMBAT .. "|r") return end
	if msg and (msg == "reset" or msg == "куыуе") then
		ClearEntries()
		for _, v in pairs(placed) do
			if _G[v] then _G[v]:SetUserPlaced(false) end
		end
		ReloadUI()
		return
	end
	K.ToggleMovers()
end

SlashCmdList.MOVING = InitMove
SLASH_MOVING1 = "/moveui"
SLASH_MOVING2 = "/mui"
SLASH_MOVING3 = "/mm"
SLASH_MOVING4 = "/mmm"

-- ---------------------------------------------------------------------------
-- Restore on login. Movers first, then legacy direct-position entries
-- (e.g. WorldMapFrame) that have no mover.
-- ---------------------------------------------------------------------------

local restoreFrame = CreateFrame("Frame")
restoreFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
restoreFrame:SetScript("OnEvent", function(self, event)
	self:UnregisterEvent(event)
	if InCombatLockdown() then
		local waiter = CreateFrame("Frame")
		waiter:RegisterEvent("PLAYER_REGEN_ENABLED")
		waiter:SetScript("OnEvent", function(w)
			w:UnregisterAllEvents()
			for _, mover in ipairs(moverOrder) do RestorePosition(mover) end
		end)
		return
	end
	AdoptLegacyFrames()
	for _, mover in ipairs(moverOrder) do RestorePosition(mover) end
	-- Fallback for plain saved frames without a mover
	for frame_name, point in pairs(C.MoverPositions or {}) do
		if not movers[frame_name] and _G[frame_name] and type(point) == "table" and type(point[1]) == "string" and #point >= 4 then
			local ok = pcall(function()
				_G[frame_name]:ClearAllPoints()
				_G[frame_name]:SetPoint(point[1], ResolveParent(point[2]), point[3] or point[1], point[4] or 0, point[5] or 0)
			end)
			if not ok then end
		end
	end
end)

-- Leaving combat is the first safe moment: close edit mode if it is open
local combat = CreateFrame("Frame")
combat:RegisterEvent("PLAYER_REGEN_DISABLED")
combat:SetScript("OnEvent", function()
	if editing then K.ToggleMovers(false) end
end)
