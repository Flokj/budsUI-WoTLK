-- Test-only WoW API surface for real Lua 5.1 module smoke tests.
Test = {
	now = 100,
	locale = "enUS",
	playerGUID = "0x0000000000000001",
	health = 2000,
	healthMax = 10000,
	instanceType = "pvp",
	messages = {},
	frames = {},
	refCalls = 0,
}

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in pairs(value) do result[key] = copy(item) end
	return result
end
CopyTable = copy
wipe = function(value)
	for key in pairs(value) do value[key] = nil end
	return value
end
tinsert = table.insert
strtrim = function(value) return value:match("^%s*(.-)%s*$") end
strsplit = function(separator, value)
	local first, rest = value:match("^(.-)" .. separator .. "(.*)$")
	return first or value, rest
end
bit = { band = function(a, b)
	local result, place = 0, 1
	while a > 0 and b > 0 do
		if a % 2 == 1 and b % 2 == 1 then result = result + place end
		a, b, place = math.floor(a / 2), math.floor(b / 2), place * 2
	end
	return result
end }

local Frame = {}
local function makeRegion(kind, name, parent)
	local object = setmetatable({
		kind = kind, name = name, parent = parent, shown = true,
		scripts = {}, events = {}, points = {}, width = 0, height = 0,
		color = { 1, 1, 1, 1 }, lines = {},
	}, { __index = Frame })
	if name then _G[name] = object end
	return object
end
function CreateFrame(kind, name, parent, template)
	local object = makeRegion(kind, name, parent)
	object.template = template
	Test.frames[#Test.frames + 1] = object
	if template == "FauxScrollFrameTemplate" then
		makeRegion("Slider", name .. "ScrollBar", object)
	end
	return object
end
function Frame:GetName() return self.name end
function Frame:GetParent() return self.parent end
function Frame:SetParent(parent) self.parent = parent end
function Frame:SetSize(width, height) self.width, self.height = width, height end
function Frame:GetSize() return self.width, self.height end
function Frame:SetWidth(width) self.width = width end
function Frame:SetHeight(height) self.height = height end
function Frame:GetWidth() return self.width end
function Frame:GetHeight() return self.height end
function Frame:ClearAllPoints() self.points = {} end
function Frame:SetPoint(...) self.points[#self.points + 1] = { ... } end
function Frame:GetPoint(index) return unpack(self.points[index or 1] or {}) end
function Frame:SetAllPoints(target) self.allPoints = target or self.parent end
function Frame:SetBackdrop(backdrop)
	self.backdrop = copy(backdrop)
	-- Client SetBackdrop resets the background tint; Border.lua invokes it.
	self.backdropColor = { 1, 1, 1, 1 }
end
function Frame:GetBackdrop() return copy(self.backdrop) end
function Frame:SetBackdropColor(...) self.backdropColor = { ... } end
function Frame:GetBackdropColor() return unpack(self.backdropColor or { 1, 1, 1, 1 }) end
function Frame:SetBackdropBorderColor(...) self.borderColor = { ... } end
function Frame:SetVertexColor(...) self.color = { ... } end
function Frame:GetVertexColor() return unpack(self.color) end
function Frame:SetAlpha(value) self.alpha = value end
function Frame:SetTexture(value) self.texture = value end
function Frame:SetDrawLayer(layer) self.drawLayer = layer end
function Frame:GetDrawLayer() return self.drawLayer end
function Frame:SetTexCoord(...) self.texCoord = { ... } end
function Frame:CreateTexture(name, layer)
	local object = makeRegion("Texture", name, self)
	object.drawLayer = layer
	return object
end
function Frame:CreateFontString(name, layer)
	return makeRegion("FontString", name, self)
end
function Frame:SetFont(...) self.font = { ... } end
function Frame:SetFontObject(value) self.fontObject = value end
function Frame:SetText(value) self.text = value end
function Frame:GetText() return self.text or "" end
function Frame:GetStringHeight() return 12 end
function Frame:SetFormattedText(pattern, ...) self.text = string.format(pattern, ...) end
function Frame:SetTextColor(...) self.textColor = { ... } end
function Frame:SetHighlightTexture(value)
	self.highlight = makeRegion("Texture", nil, self)
	self.highlight:SetTexture(value)
end
function Frame:GetHighlightTexture() return self.highlight end
function Frame:SetFrameStrata(value) self.strata = value end
function Frame:SetFrameLevel(value) self.frameLevel = value end
function Frame:GetFrameLevel() return self.frameLevel or 1 end
function Frame:SetScript(event, callback) self.scripts[event] = callback end
function Frame:GetScript(event) return self.scripts[event] end
function Frame:HookScript(event, callback)
	local previous = self.scripts[event]
	self.scripts[event] = function(...)
		if previous then previous(...) end
		callback(...)
	end
end
function Frame:RegisterEvent(event) self.events[event] = true end
function Frame:UnregisterEvent(event) self.events[event] = nil end
function Frame:IsEventRegistered(event) return self.events[event] == true end
function Frame:Show()
	if self.shown then return end
	self.shown = true
	if self.scripts.OnShow then self.scripts.OnShow(self) end
end
function Frame:Hide()
	if not self.shown then return end
	self.shown = false
	if self.scripts.OnHide then self.scripts.OnHide(self) end
end
function Frame:IsShown() return self.shown end
function Frame:SetValue(value) self.value = value end
function Frame:SetFocus() self.focused = true end
function Frame:ClearFocus() self.focused = false end
function Frame:HighlightText() self.highlightedText = true end
function Frame:SetMaxLetters(value) self.maxLetters = value end
function Frame:SetOwner(...) self.owner = { ... }; self.lines = {} end
function Frame:AddLine(...) self.lines[#self.lines + 1] = { ... } end
function Frame:ClearLines() self.lines = {} end
function Frame:SetHyperlink(link) self.lastLink = link end
for _, name in ipairs({
	"SetClampedToScreen", "EnableMouse", "SetMovable", "RegisterForDrag",
	"SetJustifyH", "SetWordWrap", "SetAutoFocus", "SetMultiLine", "SetTextInsets",
	"SetHitRectInsets", "SetBlendMode", "SetAttribute", "StartMoving", "StopMovingOrSizing",
}) do
	Frame[name] = function() end
end

UIParent = CreateFrame("Frame", "UIParent")
ChatFrame1 = CreateFrame("Frame", "ChatFrame1", UIParent)
GameTooltip = CreateFrame("GameTooltip", "GameTooltip", UIParent)
ItemRefTooltip = CreateFrame("GameTooltip", "ItemRefTooltip", UIParent)
SlashCmdList, UISpecialFrames, StaticPopupDialogs = {}, {}, {}
CLOSE, OKAY, INTERRUPTED = "Close", "Okay", "Interrupted"
GameFontHighlightSmall, GameFontHighlight = "SmallFont", "HighlightFont"
IsModifiedClick = function() return false end
ShowUIPanel = function(frame) frame:Show() end
HideUIPanel = function(frame) frame:Hide() end
GetLocale = function() return Test.locale end
GetTime = function() return Test.now end
UnitGUID = function(unit) return unit == "player" and Test.playerGUID or nil end
UnitHealth = function() return Test.health end
UnitHealthMax = function() return Test.healthMax end
IsInInstance = function() return Test.instanceType ~= "none", Test.instanceType end
GetSpellInfo = function(id)
	assert(type(id) == "number", "GetSpellInfo needs a spell ID")
	return "Spell " .. id, "", "Icon " .. id
end
GetPlayerInfoByGUID = function() return "Mage", "MAGE" end
FauxScrollFrame_GetOffset = function(frame) return frame.offset or 0 end
FauxScrollFrame_SetOffset = function(frame, value) frame.offset = value end
FauxScrollFrame_Update = function(frame, count, visible, height)
	frame.count, frame.visible, frame.rowHeight = count, visible, height
end
FauxScrollFrame_OnVerticalScroll = function(frame, value, height, callback)
	frame.offset = math.floor(value / height)
	callback()
end
function SetItemRef(...)
	Test.refCalls = Test.refCalls + 1
	Test.refArgs = { n = select("#", ...), ... }
	return "standard-ref"
end
function StaticPopup_Show(key)
	local dialog = assert(StaticPopupDialogs[key], "Unknown popup")
	local popup = _G.TestPopup or CreateFrame("Frame", "TestPopup", UIParent)
	if not _G.TestPopupEditBox then CreateFrame("EditBox", "TestPopupEditBox", popup) end
	if dialog.OnShow then dialog.OnShow(popup) end
	Test.lastPopupKey = key
	return popup
end
ChatFrame_AddMessageEventFilter = function(event, filter)
	Test.chatFilters = Test.chatFilters or {}
	Test.chatFilters[event] = Test.chatFilters[event] or {}
	Test.chatFilters[event][#Test.chatFilters[event] + 1] = filter
end
ChatFrame_GetMessageEventFilters = function(event)
	return Test.chatFilters and Test.chatFilters[event] or nil
end
ChatEdit_ChooseBoxForSend = function() error("URL copying must not touch the chat draft") end
ChatEdit_ActivateChat = function() error("URL copying must not activate the chat input") end

K = { Directory = "budsUI-0.7.1", Name = "Player", Realm = "Realm", Class = "MAGE" }
C = {
	Media = {
		Font = "NormalFont", Font_Style = "OUTLINE",
		Backdrop_Color = { 0.02, 0.02, 0.02, 0.9 }, Border_Color = { 0.5, 0.5, 0.5, 1 },
	},
	Chat = { Enable = true },
	Tooltip = { Enable = true },
	Misc = { DeathRecap = true, DeathRecapAutoOpen = true, DeathRecapHeals = true, DeathRecapEntries = 5 },
}
K.Backdrop = { bgFile = "Blank", edgeFile = "Border", insets = { left = 2, right = 2, top = 2, bottom = 2 } }
K.Print = function(...)
	-- The real engine (Core/Functions.lua) prefixes every message with the addon name.
	Test.messages[#Test.messages + 1] = "|cff388bdbbudsUI|r: " .. table.concat({ ... }, " ")
end
K.GetActiveProfile = function() return "Default" end
K.CreateMover = function(frame, key, label, point, width, height)
	local mover = CreateFrame("Frame", "budsUI_Mover_" .. key, UIParent)
	mover:SetSize(width, height)
	frame.budsUI_Mover = mover
	return mover
end
Engine = { K, C, {}, {} }
function Engine:unpack() return self[1], self[2], self[3], self[4] end
budsUI = Engine
budsUIData = { Profiles = { Default = {} }, ActiveProfiles = { ["Realm-Player"] = "Default" } }
configNS = {}

function Fire(event, ...)
	local count = #Test.frames
	for index = 1, count do
		local frame = Test.frames[index]
		if frame.events[event] and frame.scripts.OnEvent then
			frame.scripts.OnEvent(frame, event, ...)
		end
	end
end
