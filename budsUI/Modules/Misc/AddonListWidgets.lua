-- UI helpers used only by the FrostAtomUI-derived addon manager.
-- No donor core/module/config namespace is installed into budsUI.
local ADDON_NAME, Engine = ...
local K = Engine:unpack()
local ns = {}
K.AddonListUI = ns
local max, tinsert = math.max, table.insert
local L = setmetatable({}, { __index = function(_, key) return key end })
ns.L = L

function ns.SetShown(region, shown)
	if shown then region:Show() else region:Hide() end
end

local DIALOG_BORDER = "Interface\\DialogFrame\\UI-DialogBox-Border"
local DIALOG_CORNER = "Interface\\DialogFrame\\UI-DialogBox-Corner"
local TOOLTIP_BORDER = "Interface\\Tooltips\\UI-Tooltip-Border"
local TOOLTIP_BACKGROUND = "Interface\\Tooltips\\UI-Tooltip-Background"
local SCROLL_TRACK = "Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar"

local WINDOW_INSET = { left = 16, right = 16, top = 36, bottom = 16 }
ns.WINDOW_INSET = WINDOW_INSET
local PLACEHOLDER_GLYPH_SIZE, PLACEHOLDER_GLYPH_GAP = 9, 4
local LIST_HIGHLIGHT = "Interface\\QuestFrame\\UI-QuestTitleHighlight"

local PANEL_BUTTON = "Interface\\Buttons\\UI-Panel-Button-"
local PANEL_BUTTON_SIZE = { 128, 32 }
local PANEL_BUTTON_COLUMNS = { 0, 12, 68, 80 }
local PANEL_BUTTON_ROWS = { 0, 7, 15, 22 }
local PANEL_BUTTON_CAP, PANEL_BUTTON_EDGE = 12, 7


local widgetCount = 0

local function widgetName(name)
	if name then
		return name
	end
	widgetCount = widgetCount + 1
	return ADDON_NAME .. "AddonManagerWidget" .. widgetCount
end
ns.WidgetName = widgetName

local function backdrop(bgFile, edgeFile, edgeSize, tileSize, left, right, top, bottom)
	return {
		bgFile = bgFile,
		edgeFile = edgeFile,
		tile = true,
		tileSize = tileSize,
		edgeSize = edgeSize,
		insets = { left = left, right = right, top = top, bottom = bottom },
	}
end


local windowBackdrop = backdrop("Interface\\DialogFrame\\UI-DialogBox-Background", DIALOG_BORDER, 32, 32, 11, 12, 12, 11)
local insetFilledBackdrop = backdrop(TOOLTIP_BACKGROUND, TOOLTIP_BORDER, 16, 16, 5, 5, 5, 5)
local function hideWindow(self)
	self:GetParent():Hide()
end

local function createCloseButton(frame)
	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetScript("OnClick", hideWindow)
	close:SetPoint("TOPRIGHT", -3, -3)
	close:SetFrameLevel(frame:GetFrameLevel() + 6)

	local corner = frame:CreateTexture(nil, "OVERLAY")
	corner:SetTexture(DIALOG_CORNER)
	corner:SetSize(32, 32)
	corner:SetPoint("TOPRIGHT", -6, -7)
	frame.corner = corner
	return close
end

function ns.CreateWindow(name, options)
	local frame = CreateFrame("Frame", name, options.parent or UIParent)
	frame:Hide()
	frame:SetWidth(options.width)
	frame:SetFrameStrata(options.strata or "HIGH")
	frame:SetToplevel(true)
	frame:EnableMouse(true)
	tinsert(UISpecialFrames, name)
	frame:SetBackdrop(windowBackdrop)
	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.title:SetPoint("TOP", 0, -17)
	frame.title:SetText(options.title)
	frame.close = createCloseButton(frame)
	return frame
end

function ns.CreateInset(parent)
	local inset = CreateFrame("Frame", nil, parent)
	inset:SetBackdrop(insetFilledBackdrop)
	inset:SetBackdropBorderColor(1, 1, 1, 1)
	inset:SetBackdropColor(0, 0, 0, 0.6)
	return inset
end

local SLICE_X = {
	{ "LEFT", 0, "LEFT", PANEL_BUTTON_CAP },
	{ "LEFT", PANEL_BUTTON_CAP, "RIGHT", -PANEL_BUTTON_CAP },
	{ "RIGHT", -PANEL_BUTTON_CAP, "RIGHT", 0 },
}
local SLICE_Y = {
	{ "TOP", 0, "TOP", -PANEL_BUTTON_EDGE },
	{ "TOP", -PANEL_BUTTON_EDGE, "BOTTOM", PANEL_BUTTON_EDGE },
	{ "BOTTOM", PANEL_BUTTON_EDGE, "BOTTOM", 0 },
}

local function sliceTextures(button, layer, blend)
	local parts = {}
	local width, height = PANEL_BUTTON_SIZE[1], PANEL_BUTTON_SIZE[2]
	for row = 1, 3 do
		for column = 1, 3 do
			local texture = button:CreateTexture(nil, layer)
			texture:SetTexCoord(
				PANEL_BUTTON_COLUMNS[column] / width,
				PANEL_BUTTON_COLUMNS[column + 1] / width,
				PANEL_BUTTON_ROWS[row] / height,
				PANEL_BUTTON_ROWS[row + 1] / height
			)
			local x, y = SLICE_X[column], SLICE_Y[row]
			texture:SetPoint("TOPLEFT", button, y[1] .. x[1], x[2], y[2])
			texture:SetPoint("BOTTOMRIGHT", button, y[3] .. x[3], x[4], y[4])
			if blend then
				texture:SetBlendMode(blend)
			end
			parts[#parts + 1] = texture
		end
	end
	return parts
end

local function setSlices(parts, file)
	for _, texture in ipairs(parts) do
		texture:SetTexture(file)
	end
end

local function paintPanelButton(button)
	local state
	if not button:IsEnabled() then
		state = "Disabled"
	elseif button.sliceDown then
		state = button.sliceGray and "Disabled-Down" or "Down"
	else
		state = button.sliceGray and "Disabled" or "Up"
	end
	setSlices(button.slices, PANEL_BUTTON .. state)
end

local function pressPanelButton(button)
	button.sliceDown = button:IsEnabled() and true or nil
	paintPanelButton(button)
end

local function releasePanelButton(button)
	button.sliceDown = nil
	paintPanelButton(button)
end

function ns.SkinPanelButton(button, gray)
	for _, texture in ipairs({
		button:GetNormalTexture(),
		button:GetPushedTexture(),
		button:GetDisabledTexture(),
		button:GetHighlightTexture(),
	}) do
		texture:SetTexture(nil)
	end
	button.sliceGray = gray
	button.slices = sliceTextures(button, "BACKGROUND")
	setSlices(sliceTextures(button, "HIGHLIGHT", "ADD"), PANEL_BUTTON .. "Highlight")
	button:HookScript("OnMouseDown", pressPanelButton)
	button:HookScript("OnMouseUp", releasePanelButton)
	button:HookScript("OnShow", releasePanelButton)
	button:HookScript("OnEnable", paintPanelButton)
	button:HookScript("OnDisable", paintPanelButton)
	paintPanelButton(button)
end

function ns.CreateButton(parent, text, width, height, name, gray)
	local button =
		CreateFrame("Button", widgetName(name), parent, gray and "UIPanelButtonGrayTemplate" or "UIPanelButtonTemplate")
	ns.SkinPanelButton(button, gray)
	button:SetSize(width or 100, height or 22)
	button:SetText(text or "")
	button.text = button:GetFontString()
	return button
end

function ns.FitButton(button, padding, minWidth)
	button:SetWidth(max(minWidth or 0, button:GetTextWidth() + (padding or 24)))
end

local function playCheckSound(self)
	PlaySound(self:GetChecked() and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
end

local function setCheckLabel(check, text)
	check.text:SetText(text or "")
	check:SetHitRectInsets(0, -(check.text:GetStringWidth() + 4), 0, 0)
end

function ns.CreateCheckButton(parent, text, name, small)
	local check = CreateFrame("CheckButton", widgetName(name), parent, "UICheckButtonTemplate")
	check:SetSize(26, 26)
	local label = _G[check:GetName() .. "Text"]
	label:SetFontObject(_G[small and "GameFontHighlightSmall" or "GameFontHighlight"])
	label:ClearAllPoints()
	label:SetPoint("LEFT", check, "RIGHT", 0, 1)
	check.text = label
	check.SetLabel = setCheckLabel
	check:SetScript("PostClick", playCheckSound)
	setCheckLabel(check, text)
	return check
end

local function updatePlaceholder(box)
	local shown = box:GetText() == "" and not box.focused
	ns.SetShown(box.placeholder, shown)
	if box.placeholderGlyph then
		ns.SetShown(box.placeholderGlyph, shown)
	end
end

function ns.CreateEditBox(parent, width, height, name, placeholder, glyph)
	local box = CreateFrame("EditBox", widgetName(name), parent, "InputBoxTemplate")
	box:SetSize(width or 120, height or 20)
	box:SetAutoFocus(false)
	box:SetTextInsets(0, 0, 0, 0)
	if placeholder then
		local text = box:CreateFontString(nil, "ARTWORK", "GameFontDisable")
		text:SetText(placeholder)
		box.placeholder = text
		if glyph ~= false then
			local icon = ns.CreateGlyph(box, glyph or "magnifying-glass", PLACEHOLDER_GLYPH_SIZE, "ARTWORK")
			icon:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
			icon:SetPoint("LEFT", 1, 0)
			text:SetPoint("LEFT", icon, "RIGHT", PLACEHOLDER_GLYPH_GAP, 0)
			box.placeholderGlyph = icon
		else
			text:SetPoint("LEFT", 1, 0)
		end
		box:HookScript("OnEditFocusGained", function(self)
			self.focused = true
			updatePlaceholder(self)
		end)
		box:HookScript("OnEditFocusLost", function(self)
			self.focused = nil
			updatePlaceholder(self)
		end)
		box:HookScript("OnTextChanged", updatePlaceholder)
	end
	return box
end

function ns.SkinSlimScrollBar(bar, up, down)
	up = up or _G[bar:GetName() .. "ScrollUpButton"]
	down = down or _G[bar:GetName() .. "ScrollDownButton"]
	local thumb = bar:GetThumbTexture()
	thumb:SetSize(18, 24)
	thumb:SetTexCoord(0.2, 0.8, 0.125, 0.875)
	local track = bar:CreateTexture(nil, "BACKGROUND")
	track:SetTexture(0, 0, 0, 0.3)
	track:SetWidth(12)
	track:SetPoint("TOP", up, "BOTTOM", 0, 2)
	track:SetPoint("BOTTOM", down, "TOP", 0, -2)
	bar.track = track
	return bar
end

function ns.CreateFauxScrollFrame(parent, name, slim)
	local scroll = CreateFrame("ScrollFrame", widgetName(name), parent, "FauxScrollFrameTemplate")
	scroll.scrollBar = _G[scroll:GetName() .. "ScrollBar"]
	if slim then
		ns.SkinSlimScrollBar(scroll.scrollBar)
	end
	return scroll
end

ns.SCROLLBAR_TRACK_WIDTH = 30

function ns.AddHighlight(button)
	button:SetHighlightTexture(LIST_HIGHLIGHT)
	local highlight = button:GetHighlightTexture()
	highlight:SetBlendMode("ADD")
	return highlight
end

local CYRILLIC_LOWER = {}
for byte = 0x80, 0xAF do
	local upper = "\208" .. string.char(byte)
	if byte < 0x90 then
		CYRILLIC_LOWER[upper] = "\209" .. string.char(byte + 0x10)
	elseif byte < 0xA0 then
		CYRILLIC_LOWER[upper] = "\208" .. string.char(byte + 0x20)
	else
		CYRILLIC_LOWER[upper] = "\209" .. string.char(byte - 0x20)
	end
end

function ns.Lower(text)
	return (text:lower():gsub("\208[\128-\175]", CYRILLIC_LOWER))
end

local glyphFont = [=[Interface\AddOns\]=] .. ADDON_NAME .. [=[\Media\Fonts\fa-solid-900.ttf]=]
local glyphCodes = { ["caret-down"] = 0xf0d7, ["caret-right"] = 0xf0da, ["magnifying-glass"] = 0xf002 }
function ns.SetGlyph(region, name, size)
	if size then region:SetFont(glyphFont, size, ""); region:SetTextHeight(size) end
	local code = assert(glyphCodes[name], "unknown addon-manager glyph")
	region:SetText(string.char(0xE0 + math.floor(code / 0x1000), 0x80 + math.floor(code / 0x40) % 0x40, 0x80 + code % 0x40))
end
function ns.CreateGlyph(parent, name, size, layer)
	local glyph = parent:CreateFontString(nil, layer or "OVERLAY")
	ns.SetGlyph(glyph, name, size)
	return glyph
end
