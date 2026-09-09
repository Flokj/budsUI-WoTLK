--[[-----------------------------------------------------------------------------
Addon: budsUI
File: Modules/UnitFrames/Compat.lua
Purpose:
	Glue between the ported KkthnxUI unit frames and the budsUI engine.
	budsUI has no module framework and targets WoW 3.3.5, so this file:
	- creates the shared UnitFrames table (Module) with a tiny RegisterEvent
	  mixin backed by its own dispatch frame,
	- exposes the embedded oUF handle (Libs/oUF, X-oUF global),
	- backfills the K helpers the ported builders expect but budsUI lacks.
-----------------------------------------------------------------------------]]

local Engine = select(2, ...)
local K, C = Engine:unpack()

local oUF = Engine.oUF or _G.budsUF
Engine.oUF = oUF

local Module = {}
Module.GAP = 6
Module.Build = {}
Module.Styles = {}
Module.frames = {}
Module.all = {}
Engine.UnitFrames = Module

-- ---------------------------------------------------------------------------
-- Tiny event mixin (RegisterEvent/UnregisterEvent), same calling convention
-- as the retail module framework: handler may be a function, a method name
-- string, or nil (calls self[event]).
-- ---------------------------------------------------------------------------
local dispatch = CreateFrame("Frame")
local eventMap = {}

local function CallHandler(module, handler, event, ...)
	if handler == true then
		local fn = module[event]
		if fn then fn(module, event, ...) end
	elseif type(handler) == "string" then
		local fn = module[handler]
		if fn then fn(module, event, ...) end
	else
		handler(module, event, ...)
	end
end

dispatch:SetScript("OnEvent", function(_, event, ...)
	local handlers = eventMap[event]
	if not handlers then return end
	for module, list in pairs(handlers) do
		for i = 1, #list do
			local handler = list[i]
			if handler ~= nil then
				CallHandler(module, handler, event, ...)
			end
		end
	end
end)

function Module:RegisterEvent(event, handler)
	local handlers = eventMap[event]
	if not handlers then
		handlers = {}
		eventMap[event] = handlers
		dispatch:RegisterEvent(event)
	end
	handler = handler or true
	local list = handlers[self]
	if not list then
		list = {}
		handlers[self] = list
	end
	for i = 1, #list do
		if list[i] == handler then return end
	end
	list[#list + 1] = handler
end

function Module:UnregisterEvent(event, handler)
	local handlers = eventMap[event]
	if not handlers then return end
	local list = handlers[self]
	if not list then return end
	if handler ~= nil then
		for i = #list, 1, -1 do
			if list[i] == handler then table.remove(list, i) end
		end
		if #list > 0 then return end
	end
	handlers[self] = nil
	if not next(handlers) then
		eventMap[event] = nil
		dispatch:UnregisterEvent(event)
	end
end

function Module:UnregisterAllEvents()
	for event, handlers in pairs(eventMap) do
		if handlers[self] then
			handlers[self] = nil
			if not next(handlers) then
				eventMap[event] = nil
				dispatch:UnregisterEvent(event)
			end
		end
	end
end

-- ---------------------------------------------------------------------------
-- Backfilled K helpers (only defined when budsUI does not provide them)
-- ---------------------------------------------------------------------------
if not K.Print then
	function K.Print(...)
		print("|cff388bdbbudsUI|r: " .. string.format(...))
	end
end

function Module.Texture()
	local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
	if LSM then
		local tex = LSM:Fetch("statusbar", C.Unitframe.Texture or "budsUI_StatusBar")
		if tex then
			return tex
		end
	end
	return C.Media.Texture
end

function Module.GetTexture()
	return Module.Texture()
end
if not K.GetTexture then K.GetTexture = Module.GetTexture end

local function ShadowOffset(style)
	if style and string.find(style, "OUTLINE") then return 0, 0 end
	return 1, -1
end

if not K.FontOutlineStyle then
	function K.FontOutlineStyle()
		return (C.General and C.General.FontOutline) and "OUTLINE" or ""
	end
end

if not K.SetFont then
	function K.SetFont(fontString, size, style)
		fontString:SetFont(C.Media.Font, size or 12, style or "")
		fontString:SetShadowColor(0, 0, 0, 1)
		fontString:SetShadowOffset(ShadowOffset(style))
		return fontString
	end
end

if not K.CreateBackground then
	function K.CreateBackground(frame, r, g, b, a)
		local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
		bg:SetAllPoints()
		bg:SetTexture(r or 0.06, g or 0.06, b or 0.06, a or 0.9)
		return bg
	end
end

if not K.CreateGradientBackground then
	function K.CreateGradientBackground(frame, alpha)
		local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
		bg:SetAllPoints()
		bg:SetTexture(0.05, 0.05, 0.05, alpha or 0.9)
		return bg
	end
end

-- Gradient strip used above health bars / portraits for the name and level.
-- Returns a faux shade object with a real Holder frame, matching the retail
-- call sites (shade.Holder, shade:SetColor, shade:Show).
if not K.CreateTextShade then
	function K.CreateTextShade(parent, layer, subLevel)
		local holder = CreateFrame("Frame", nil, parent)
		local tex = holder:CreateTexture(nil, layer or "BACKGROUND", nil, subLevel or -2)
		tex:SetAllPoints()
		tex:SetTexture(0, 0, 0, 0.55)
		local shade = { Holder = holder, Texture = tex }
		function shade:SetColor(r, g, b, a) tex:SetTexture(r, g, b, a) end
		function shade:Show() holder:Show() end
		function shade:Hide() holder:Hide() end
		return shade
	end
end

if not K.DisablePixelSnap then
	function K.DisablePixelSnap() end
end

if not K.ResetBorderColor then
	function K.ResetBorderColor(frame)
		if frame and frame.SetBackdropBorderColor then
			frame:SetBackdropBorderColor()
		end
	end
end

if not K.ShortValue then
	function K.ShortValue(value)
		value = tonumber(value) or 0
		local absValue = value < 0 and -value or value
		if absValue >= 1e6 then
			return string.format("%.1fm", value / 1e6)
		elseif absValue >= 1e3 then
			return string.format("%.1fk", value / 1e3)
		end
		return tostring(math.floor(value + 0.5))
	end
end

if not K.PlayerIsTank then
	function K.PlayerIsTank()
		if UnitGroupRolesAssigned then
			return UnitGroupRolesAssigned("player") == "TANK"
		end
		return false
	end
end

if not K.ThreatFillColor then
	local THREAT_AGGRO = { 0.9, 0.2, 0.2 }
	local THREAT_WARN = { 0.9, 0.7, 0.2 }
	function K.ThreatFillColor(status, isTank)
		if isTank then
			if status == 3 then return THREAT_WARN end
			if status == 2 or status == 1 then return THREAT_WARN end
			return THREAT_AGGRO
		else
			if status == 3 then return THREAT_AGGRO end
			if status == 2 or status == 1 then return THREAT_WARN end
		end
	end
end

if not K.StyleCooldownSwipe then
	function K.StyleCooldownSwipe(cd)
		if not cd then return end
		if cd.SetDrawEdge and cd.SetDrawEdge ~= nil then
			pcall(cd.SetDrawEdge, cd, false)
		end
	end
end

-- Shared palette (KkthnxUI accent language on the budsUI blue).
if not K.Colors then
	K.Colors = {
		accent = { 0.22, 0.55, 0.86 },
		gold = { 1.0, 0.82, 0.4 },
		info = { 0.22, 0.55, 0.86 },
	}
end
if not K.StripColor then K.StripColor = { 0.05, 0.05, 0.08 } end
if not K.GradientAlpha then
	K.GradientAlpha = { hover = 0.22, select = 0.28, strip = 0.85 }
end

-- Refresh every live health border (called once after spawn).
function K.RefreshBorderColors()
	for _, frame in ipairs(Module.all) do
		if Module.RefreshHealthBorder then
			Module.RefreshHealthBorder(frame)
		end
	end
end
