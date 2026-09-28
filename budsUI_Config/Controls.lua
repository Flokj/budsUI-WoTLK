-- budsUI_Config :: Controls.lua
-- Universal option-row controls, FrostAtomUI_Config-inspired, adapted for budsUI.
-- Lua 5.1 / WoW 3.3.5a safe. No external glyph/icon fonts (plain text widgets).
--
-- Schema entry fields (all pages use these):
--   header      : section title (row becomes a section header, no control)
--   description : plain info text (row becomes a wrapped label)
--   label       : option label shown on the left
--   type        : "toggle" | "number" | "string" | "select" | "color"
--               | "execute" | "input" | "custom" | "description"
--   group       : top-level C table key, e.g. "General" ("budsUI_DB compatible")
--   option      : key inside C[group], e.g. "AutoScale"
--   key         : nested key inside C[group][option], e.g. "Width" for Unitframe
--                 ("Player" sub-tables, PowerColors, ReactionColors, ...)
--   path        : alternative dotted path, e.g. "Unitframe.Player.Width"
--                 (used when group/option/key are not given)
--   get / set   : override accessors. set(value) replaces profile write.
--   min/max/step: numeric range (number type)
--   width       : control width override (string/select/input)
--   maxLetters  : editbox char limit
--   values      : select options: {{value, label}, ...} or function() -> list
--   placeholder : select text shown when value is nil
--   text        : execute button text (defaults to label)
--   func        : execute button handler
--   confirm     : confirmation popup text (string) or function() -> string|nil
--   enabledBy   : "Group.Option" string or list of them (ALL must be on)
--   enabledByAny: list of "Group.Option" (ANY must be on)
--   disabled / disabledDesc : function() -> bool + explanation line
--   desc        : tooltip/description line
--   advanced    : collapsed under "More settings" expander
--   reload      : change needs UI reload (shows Reload button + hint)
--   noReset     : excluded from Defaults reset / modified tracking
--   zeroText    : number value 0 display text (e.g. "Off")
--   percent     : number displayed as percent
--   unit        : number unit suffix, e.g. "s"
--   validate    : string/input check: function(text) -> ok, message
--   build       : custom type: function(row, entry) builds widgets
--   refresh     : custom type: function(row)
--   setEnabled  : custom type: function(row, enabled)
--   height      : custom type: row height override
--
-- Every creator returns a row frame with:
--   row.entry, row.label, row:Refresh(), row:SetEnabled(enabled)

local ADDON_NAME, ns = ...

local floor, max, min, ceil = math.floor, math.max, math.min, math.ceil
local tinsert = tinsert

ns.pages = ns.pages or {}
ns.creators = ns.creators or {}

ns.ROW_HEIGHT = 26
ns.CONTROL_X = 230

local ROW_HEIGHT = ns.ROW_HEIGHT
local CONTROL_X = ns.CONTROL_X
local LABEL_X = 8
local CHILD_INDENT = 16
local SLIDER_WIDTH = 170
local VALUE_BOX_WIDTH = 52
local RESET_WIDTH = 22
local HIGHLIGHT_TEXTURE = "Interface\\QuestFrame\\UI-QuestLogTitleHighlight"

-- ---------------------------------------------------------------------------
-- Engine access (lazy so file load order never matters)
-- ---------------------------------------------------------------------------

local function Engine()
	local addon = _G["budsUI"]
	if addon and addon.unpack then
		local K, C = addon:unpack()
		return K, C
	end
	return nil, nil
end

function ns.Engine()
	return Engine()
end

function ns.LiveConfig()
	local _, C = Engine()
	return C
end

-- ---------------------------------------------------------------------------
-- Page registry
-- ---------------------------------------------------------------------------

function ns.RegisterPage(page)
	page.name = page.name or page.key or "?"
	page.key = page.key or page.name
	page.schema = page.schema or {}
	tinsert(ns.pages, page)
	table.sort(ns.pages, function(a, b)
		return (a.order or 99) < (b.order or 99)
	end)
end

-- ---------------------------------------------------------------------------
-- Value access: group/option/key (budsUIData compatible) or dotted path
-- ---------------------------------------------------------------------------

local function splitPath(path)
	local keys = {}
	for key in tostring(path):gmatch("[^.]+") do
		keys[#keys + 1] = tonumber(key) or key
	end
	return keys
end

local function resolveKeys(entry)
	if entry.group ~= nil then
		if entry.key ~= nil then
			return { entry.group, entry.option, entry.key }
		end
		return { entry.group, entry.option }
	elseif entry.path then
		return splitPath(entry.path)
	end
	return nil
end

function ns.Get(entry)
	if entry.get then
		return entry.get()
	end
	local _, C = Engine()
	if not C then
		return nil
	end
	local keys = resolveKeys(entry)
	if not keys then
		return nil
	end
	local node = C
	for i = 1, #keys do
		if type(node) ~= "table" then
			return nil
		end
		node = node[keys[i]]
	end
	return node
end

-- Profile-aware write: mirrors the legacy SetValue() semantics so budsUIData
-- keeps the exact same keys as the old monolith, and live C updates instantly.
function ns.Set(entry, value)
	if entry.set then
		entry.set(value)
		return
	end
	if value == nil then
		return
	end
	local K, C = Engine()
	local keys = resolveKeys(entry)
	if not K or not C or not keys or #keys < 2 then
		return
	end
	local group, option, key = keys[1], keys[2], keys[3]

	local active
	if K.GetActiveProfile then
		active = K.GetActiveProfile()
	end
	if active and active ~= "Unknown" and _G["budsUIData"]
			and _G["budsUIData"].Profiles and _G["budsUIData"].Profiles[active] then
		local P = _G["budsUIData"].Profiles[active]
		if not P[group] then
			P[group] = {}
		end
		if key ~= nil then
			if type(P[group][option]) ~= "table" then
				P[group][option] = {}
			end
			if type(value) == "table" and type(P[group][option][key]) == "table" then
				for k, v in pairs(value) do
					P[group][option][key][k] = v
				end
			else
				P[group][option][key] = value
			end
		else
			if type(value) == "table" and type(P[group][option]) == "table" then
				for k, v in pairs(value) do
					P[group][option][k] = v
				end
			else
				P[group][option] = value
			end
		end
	end

	if C[group] then
		if key ~= nil then
			if type(C[group][option]) ~= "table" then
				C[group][option] = {}
			end
			if type(value) == "table" and type(C[group][option][key]) == "table" then
				for k, v in pairs(value) do
					C[group][option][key][k] = v
				end
			else
				C[group][option][key] = value
			end
		else
			if type(value) == "table" and type(C[group][option]) == "table" then
				for k, v in pairs(value) do
					C[group][option][k] = v
				end
			else
				C[group][option] = value
			end
		end
	end

	if entry.reload then
		ns.FlagReload()
	end
end

-- ---------------------------------------------------------------------------
-- Defaults / modified tracking (pristine snapshot lives in K.ConfigDefaults)
-- ---------------------------------------------------------------------------

local function defaultOf(entry)
	local K = Engine()
	if not K or type(K.ConfigDefaults) ~= "table" then
		return nil, false
	end
	local keys = resolveKeys(entry)
	if not keys then
		return nil, false
	end
	local node = K.ConfigDefaults
	for i = 1, #keys do
		if type(node) ~= "table" then
			return nil, false
		end
		node = node[keys[i]]
	end
	if node == nil then
		return nil, false
	end
	return node, true
end
ns.DefaultOf = defaultOf

local EPSILON = 0.0001

local function sameValue(a, b)
	if type(a) == "number" and type(b) == "number" then
		return math.abs(a - b) < EPSILON
	end
	if type(a) ~= "table" or type(b) ~= "table" then
		return a == b
	end
	for k, v in pairs(a) do
		if not sameValue(v, b[k]) then
			return false
		end
	end
	for k in pairs(b) do
		if a[k] == nil then
			return false
		end
	end
	return true
end

function ns.IsModified(entry)
	if entry.noReset or entry.get then
		return false
	end
	if entry.isDefault then
		return not entry.isDefault()
	end
	local def, known = defaultOf(entry)
	if not known then
		return false
	end
	return not sameValue(ns.Get(entry), def)
end

local function copyValue(value)
	if type(value) ~= "table" then
		return value
	end
	local t = {}
	for k, v in pairs(value) do
		t[k] = v
	end
	return t
end

function ns.ResetEntry(entry)
	if entry.reset then
		entry.reset()
		return
	end
	local K = Engine()
	local def, known = defaultOf(entry)
	if not known or not K then
		-- No pristine default: drop the profile override, live value returns
		-- to default on next ReloadUI.
		local keys = resolveKeys(entry)
		local active = K and K.GetActiveProfile and K.GetActiveProfile()
		if keys and active and _G["budsUIData"] and _G["budsUIData"].Profiles
				and _G["budsUIData"].Profiles[active] then
			local P = _G["budsUIData"].Profiles[active]
			if keys[3] ~= nil then
				if type(P[keys[1]]) == "table" and type(P[keys[1]][keys[2]]) == "table" then
					P[keys[1]][keys[2]][keys[3]] = nil
				end
			elseif type(P[keys[1]]) == "table" then
				P[keys[1]][keys[2]] = nil
			end
		end
		ns.Print("Default will be restored after ReloadUI.")
		return
	end
	ns.Set(entry, copyValue(def))
end

function ns.FormatDefault(value)
	if type(value) == "boolean" then
		return value and "On" or "Off"
	elseif type(value) == "number" then
		return tostring(floor(value * 100 + 0.5) / 100)
	elseif type(value) == "table" and type(value[1]) == "number" then
		local r = floor((value[1] or 0) * 255 + 0.5)
		local g = floor((value[2] or 0) * 255 + 0.5)
		local b = floor((value[3] or 0) * 255 + 0.5)
		return format("|cff%02x%02x%02xthis color|r", r, g, b)
	elseif value ~= nil then
		return tostring(value)
	end
	return nil
end

function ns.Print(...)
	local K = Engine()
	if K and K.Print then
		K.Print(...)
	else
		print("|cff388bdbbudsUI_Config|r:", ...)
	end
end

-- Overridden by Core.lua once the frame exists.
function ns.FlagReload()
end

function ns.Confirm(text, action)
	ns._confirmAction = action
	StaticPopup_Show("BUDSUI_CONFIG_CONFIRM", text)
end

StaticPopupDialogs["BUDSUI_CONFIG_CONFIRM"] = {
	text = "%s",
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		if ns._confirmAction then
			local action = ns._confirmAction
			ns._confirmAction = nil
			action()
		end
	end,
	OnHide = function()
		ns._confirmAction = nil
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	preferredIndex = 3,
}

-- ---------------------------------------------------------------------------
-- Formatting helpers
-- ---------------------------------------------------------------------------

local function roundTo(value, step)
	if not step or step == 0 then
		return value
	end
	return floor(value / step + 0.5) * step
end

function ns.FormatNumber(value, step)
	step = step or 1
	if step >= 1 then
		return tostring(floor(value + 0.5))
	end
	local text = ("%.2f"):format(value):gsub("0+$", "")
	return (text:gsub("%.$", ""))
end

function ns.FormatValue(entry, value)
	if entry.zeroText and value == 0 then
		return entry.zeroText
	end
	if entry.percent then
		return ns.FormatNumber(value * 100, (entry.step or 0.05) * 100) .. "%"
	end
	if entry.unit then
		return ns.FormatNumber(value, entry.step or 1) .. entry.unit
	end
	return ns.FormatNumber(value, entry.step or 1)
end

function ns.ParseNumber(entry, text)
	text = strtrim(tostring(text or ""))
	local number = text:match("^[-+]?[%d.,]+")
	local value = number and tonumber((number:gsub(",", ".")))
	if value and entry.percent then
		return value / 100
	end
	return value
end

-- ---------------------------------------------------------------------------
-- Small widget helpers (3.3.5-safe, no glyph fonts)
-- ---------------------------------------------------------------------------

local function setTextEnabled(region, enabled)
	local color = enabled and HIGHLIGHT_FONT_COLOR or GRAY_FONT_COLOR
	region:SetTextColor(color.r, color.g, color.b)
end
ns.SetTextEnabled = setTextEnabled

local function setControlEnabled(control, enabled)
	if enabled then
		control:Enable()
	else
		control:Disable()
	end
end
ns.SetControlEnabled = setControlEnabled

local function setEditBoxEnabled(box, enabled)
	box:EnableMouse(enabled)
	setTextEnabled(box, enabled)
	if not enabled then
		box:ClearFocus()
	end
end
ns.SetEditBoxEnabled = setEditBoxEnabled

local function bindRow(control, row)
	control:HookScript("OnEnter", function()
		ns.RowEnter(row)
	end)
	control:HookScript("OnLeave", function()
		ns.RowLeave(row)
	end)
end
ns.BindRow = bindRow

local function bindHighlight(control, row)
	control:HookScript("OnEnter", function()
		row.highlight:Show()
	end)
	control:HookScript("OnLeave", function()
		row.highlight:Hide()
	end)
end
ns.BindHighlight = bindHighlight

local widgetSeq = 0
local function nextName(prefix)
	widgetSeq = widgetSeq + 1
	return "budsUIConfig" .. (prefix or "Widget") .. widgetSeq
end

function ns.CreateButton(parent, text, width, gray, height)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width or 100, height or 23)
	button:SetText(text or "")
	if gray then
		button:SetNormalFontObject("GameFontHighlight")
	end
	return button
end

local function playCheckSound(check)
	PlaySound(check:GetChecked() and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
end
ns.PlayCheckSound = playCheckSound

-- ---------------------------------------------------------------------------
-- Row frame + tooltip + reset affordance
-- ---------------------------------------------------------------------------

local function isChildEntry(entry)
	if entry.indent ~= nil then
		return entry.indent
	end
	return entry.enabledBy ~= nil or entry.enabledByAny ~= nil
end

function ns.RowEnter(row)
	row.highlight:Show()
	local entry = row.entry
	if not entry then
		return
	end
	local parts = {}
	if entry.desc then
		local descText = strtrim(tostring(entry.desc)):gsub("%s*%.$", "")
		local labelText = entry.label and strtrim(tostring(entry.label)):gsub("%s*%.$", "") or nil
		if not (labelText and descText == labelText) then
			parts[#parts + 1] = { entry.desc, NORMAL_FONT_COLOR }
		end
	end
	if row.problem then
		parts[#parts + 1] = { row.problem.text, row.problem.color or RED_FONT_COLOR }
	end
	if entry.reload then
		parts[#parts + 1] = { "Requires a UI reload (APPLY button below).", { r = 1, g = 0.5, b = 0.25 } }
	end
	if entry.type == "number" and entry.min and entry.max then
		local rangeEntry = { min = entry.min, max = entry.max, step = entry.step or 1, percent = entry.percent, unit = entry.unit, zeroText = entry.zeroText }
		parts[#parts + 1] = {
			ns.FormatValue(rangeEntry, entry.min) .. " - " .. ns.FormatValue(rangeEntry, entry.max),
			GRAY_FONT_COLOR,
		}
	end
	if row.modified then
		local def, known = ns.DefaultOf(entry)
		if known then
			parts[#parts + 1] = { "Default: " .. (ns.FormatDefault(def) or "?"), GRAY_FONT_COLOR }
		end
	end
	if not entry.desc and #parts == 0 then
		return
	end
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	if GameTooltip.ClearLines then
		GameTooltip:ClearLines()
	end
	GameTooltip:SetText(entry.label or "", HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
	for _, part in ipairs(parts) do
		GameTooltip:AddLine(part[1], part[2].r, part[2].g, part[2].b, true)
	end
	GameTooltip:Show()
end

function ns.RowLeave(row)
	row.highlight:Hide()
	GameTooltip:Hide()
end

local function createRow(parent, entry)
	local row = CreateFrame("Frame", nil, parent)
	row:SetPoint("LEFT")
	row:SetPoint("RIGHT")
	row.entry = entry
	row:EnableMouse(true)
	row:SetScript("OnEnter", ns.RowEnter)
	row:SetScript("OnLeave", ns.RowLeave)

	local highlight = row:CreateTexture(nil, "BACKGROUND")
	highlight:SetTexture(HIGHLIGHT_TEXTURE)
	highlight:SetBlendMode("ADD")
	highlight:SetVertexColor(0.196, 0.388, 0.8, 0.35)
	highlight:SetAllPoints()
	highlight:Hide()
	row.highlight = highlight

	local indent = isChildEntry(entry) and CHILD_INDENT or 0
	local label = row:CreateFontString(nil, "ARTWORK")
	label:SetFontObject("GameFontHighlight")
	label:SetPoint("LEFT", LABEL_X + indent, 0)
	label:SetWidth(CONTROL_X - LABEL_X - 10 - indent)
	label:SetJustifyH("LEFT")
	label:SetText(entry.label or entry.header or "")
	row.label = label
	row:SetHeight(max(ROW_HEIGHT, label:GetStringHeight() + 8))

	-- Modified dot + reset button (hidden unless the value differs from default).
	local dot = row:CreateFontString(nil, "OVERLAY")
	dot:SetFontObject("GameFontNormalSmall")
	dot:SetText("|cff59bfff*|r")
	dot:SetPoint("RIGHT", label, "LEFT", -2, 0)
	dot:Hide()
	row.changedDot = dot

	if not entry.noReset and (entry.group or entry.path) and not entry.header and not entry.description then
		local reset = ns.CreateButton(row, "R", RESET_WIDTH, true, 18)
		reset:SetPoint("RIGHT", -2, 0)
		reset:SetScript("OnClick", function()
			PlaySound("igMainMenuOptionCheckBoxOff")
			ns.ResetEntry(entry)
			ns.RefreshPage()
		end)
		reset:SetScript("OnEnter", function()
			row.highlight:Show()
			GameTooltip:SetOwner(reset, "ANCHOR_RIGHT")
			if GameTooltip.ClearLines then
				GameTooltip:ClearLines()
			end
			local def, known = ns.DefaultOf(entry)
			if known then
				GameTooltip:SetText("Default: " .. (ns.FormatDefault(def) or "?"), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
			else
				GameTooltip:SetText(entry.label or "Default", HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
			end
			GameTooltip:AddLine("Click to reset", GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
			GameTooltip:Show()
		end)
		reset:SetScript("OnLeave", function()
			GameTooltip:Hide()
			ns.RowEnter(row)
		end)
		reset:Hide()
		row.resetButton = reset
	end

	row.Update = function()
		local modified = ns.IsModified(entry)
		row.modified = modified
		if row.changedDot then
			if modified then row.changedDot:Show() else row.changedDot:Hide() end
		end
		if row.resetButton then
			if modified then row.resetButton:Show() else row.resetButton:Hide() end
		end
	end

	return row
end
ns.CreateRow = createRow

local function afterChange(row)
	if ns.RefreshPage then
		ns.RefreshPage()
	elseif row and row.Refresh then
		row.Refresh()
	end
end

-- ---------------------------------------------------------------------------
-- Creators
-- ---------------------------------------------------------------------------

local creators = ns.creators

function creators.header(parent, entry)
	local header = CreateFrame("Frame", nil, parent)
	header:SetPoint("LEFT")
	header:SetPoint("RIGHT")
	header:SetHeight(26)
	header.entry = entry
	header.Refresh = function() end
	header.SetEnabled = function() end
	header.Update = function() end

	local label = header:CreateFontString(nil, "ARTWORK")
	label:SetFontObject("GameFontNormal")
	label:SetTextColor(0x38 / 255, 0x8b / 255, 0xdb / 255)
	label:SetPoint("BOTTOM", 0, 6)
	label:SetJustifyH("CENTER")
	label:SetText(entry.header or "")
	header.label = label

	local rule = header:CreateTexture(nil, "ARTWORK")
	rule:SetTexture(0x38 / 255, 0x8b / 255, 0xdb / 255, 0.35)
	rule:SetHeight(1)
	rule:SetPoint("BOTTOMLEFT", 5, 2)
	rule:SetPoint("BOTTOMRIGHT", -5, 2)
	return header
end

function creators.description(parent, entry)
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetPoint("LEFT")
	holder:SetPoint("RIGHT")
	holder.entry = entry
	holder.Refresh = function() end
	holder.SetEnabled = function() end
	holder.Update = function() end

	local text = holder:CreateFontString(nil, "ARTWORK")
	text:SetFontObject("GameFontHighlightSmall")
	text:SetPoint("TOPLEFT", LABEL_X, -2)
	text:SetWidth(500)
	text:SetJustifyH("LEFT")
	text:SetText(entry.description or "")
	holder.label = text
	holder:SetHeight(text:GetStringHeight() + 8)
	return holder
end

function creators.toggle(parent, entry)
	local row = createRow(parent, entry)
	-- Center of free space between label end (~CONTROL_X) and R button start:
	-- checkX = (labelEnd + rStart) / 2. Spacer auto-tracks row width / R pos.
	local space = CreateFrame("Frame", nil, row)
	space:EnableMouse(false)
	space:SetPoint("TOP", row, "TOP", 0, 0)
	space:SetPoint("BOTTOM", row, "BOTTOM", 0, 0)
	space:SetPoint("LEFT", row, "LEFT", CONTROL_X, 0)
	if row.resetButton then
		space:SetPoint("RIGHT", row.resetButton, "LEFT", -2, 0)
	else
		space:SetPoint("RIGHT", row, "RIGHT", -2, 0)
	end
	local check = CreateFrame("CheckButton", nextName("Check"), row, "InterfaceOptionsCheckButtonTemplate")
	check:SetPoint("CENTER", space, "CENTER", 0, 0)
	check:SetHitRectInsets(0, 0, 0, 0)
	check:SetScript("OnClick", function(self)
		playCheckSound(self)
		ns.Set(entry, self:GetChecked() and true or false)
		afterChange(row)
	end)
	bindRow(check, row)
	row:SetScript("OnMouseUp", function(_, btn)
		if btn == "LeftButton" and check:IsEnabled() == 1 then
			check:Click()
		end
	end)

	row.Refresh = function()
		check:SetChecked(ns.Get(entry) and true or false)
	end
	row.SetEnabled = function(_, enabled)
		setControlEnabled(check, enabled)
	end
	return row
end

local function createEditBox(parent, width, numeric)
	local box = CreateFrame("EditBox", nextName("Box"), parent)
	box:SetAutoFocus(false)
	box:SetSize(width, 20)
	box:SetJustifyH("LEFT")
	box:SetFontObject("GameFontHighlight")
	box:SetTextInsets(4, 4, 0, 0)
	local K, C = Engine()
	if K and K.Backdrop then
		box:SetBackdrop(K.Backdrop)
		if C and C.Media and C.Media.Backdrop_Color then
			box:SetBackdropColor(unpack(C.Media.Backdrop_Color))
		else
			box:SetBackdropColor(0, 0, 0, 0.5)
		end
		if C and C.Media and C.Media.Border_Color then
			box:SetBackdropBorderColor(unpack(C.Media.Border_Color))
		end
	else
		box:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 12,
			insets = { left = 2, right = 2, top = 2, bottom = 2 },
		})
		box:SetBackdropColor(0, 0, 0, 0.5)
	end
	if numeric then
		box:SetMaxLetters(9)
		box:SetNumeric(true)
	end
	box:HookScript("OnEditFocusGained", function(self)
		self.editing = true
		self.committed = self:GetText()
	end)
	box:SetScript("OnEscapePressed", function(self)
		self.cancelled = true
		self:ClearFocus()
	end)
	box:SetScript("OnEnterPressed", box.ClearFocus)
	box:SetScript("OnEditFocusLost", function(self)
		self.editing = nil
		self:HighlightText(0, 0)
		if self.cancelled then
			self.cancelled = nil
			self:SetText(self.committed or "")
			self:SetCursorPosition(0)
			if self.OnCancel then
				self:OnCancel()
			end
		elseif self.OnCommit then
			self:OnCommit()
		end
	end)
	return box
end
ns.CreateEditBox = createEditBox

local function validateRow(row, box, text, pending)
	local ok, message = true, nil
	if text and row.entry.validate then
		ok, message = row.entry.validate(text)
	end
	local problem
	if message then
		problem = { text = message, color = ok and NORMAL_FONT_COLOR or RED_FONT_COLOR, rejected = pending and not ok }
	end
	row.problem = problem
	return ok and true or false
end
ns.ValidateRow = validateRow

function creators.number(parent, entry)
	local row = createRow(parent, entry)
	local sMin, sMax, sStep = entry.min or 0, entry.max or 100, entry.step or 1

	local slider = CreateFrame("Slider", nextName("Slider"), row, "OptionsSliderTemplate")
	slider:SetPoint("LEFT", CONTROL_X, 0)
	slider:SetWidth(SLIDER_WIDTH)
	slider:SetMinMaxValues(sMin, sMax)
	slider:SetValueStep(sStep)
	_G[slider:GetName() .. "Low"]:SetText("")
	_G[slider:GetName() .. "High"]:SetText("")
	bindRow(slider, row)

	local box = createEditBox(row, VALUE_BOX_WIDTH, true)
	box:SetPoint("LEFT", slider, "RIGHT", 10, 0)
	bindRow(box, row)

	local function commit(value)
		value = roundTo(max(sMin, min(sMax, value)), sStep)
		ns.Set(entry, value)
		afterChange(row)
	end

	local refreshing = false
	slider:SetScript("OnValueChanged", function(self, value)
		if refreshing then
			return
		end
		_G[self:GetName() .. "Text"]:SetText(ns.FormatValue(entry, roundTo(value, sStep)))
		commit(value)
	end)
	box.OnCommit = function(self)
		local value = ns.ParseNumber(entry, self:GetText())
		if value then
			commit(value)
		else
			row.Refresh()
		end
	end

	row.Refresh = function()
		local value = tonumber(ns.Get(entry)) or sMin
		refreshing = true
		slider:SetValue(value)
		refreshing = false
		_G[slider:GetName() .. "Text"]:SetText(ns.FormatValue(entry, value))
		if not box.editing then
			box:SetText(ns.FormatValue(entry, value))
			box:SetCursorPosition(0)
		end
	end
	row.SetEnabled = function(_, enabled)
		setControlEnabled(slider, enabled)
		local shade = enabled and 1 or 0.5
		slider:GetThumbTexture():SetVertexColor(shade, shade, shade)
		setEditBoxEnabled(box, enabled)
	end
	return row
end

function creators.string(parent, entry)
	local row = createRow(parent, entry)
	local box = createEditBox(row, entry.width or 220, false)
	box:SetPoint("LEFT", CONTROL_X + 6, 0)
	box:SetMaxLetters(entry.maxLetters or 64)
	row.box = box
	box.OnCommit = function(self)
		local text = self:GetText()
		if validateRow(row, self, text, true) then
			ns.Set(entry, text)
			afterChange(row)
		end
	end
	box.OnCancel = function(self)
		validateRow(row, self)
		row.Refresh()
	end
	bindRow(box, row)
	row.Refresh = function()
		if box.editing or (row.problem and row.problem.rejected) then
			return
		end
		local text = ns.Get(entry) or ""
		box:SetText(text)
		box:SetCursorPosition(0)
		validateRow(row, box, text)
	end
	row.SetEnabled = function(_, enabled)
		setEditBoxEnabled(box, enabled)
	end
	return row
end

function creators.input(parent, entry)
	local row = createRow(parent, entry)
	local box = createEditBox(row, entry.width or 200, false)
	box:SetPoint("LEFT", CONTROL_X + 6, 0)
	box:SetMaxLetters(entry.maxLetters or 64)
	bindRow(box, row)
	local button = ns.CreateButton(row, entry.text or "Save", 80)
	button:SetPoint("LEFT", box, "RIGHT", 8, 0)
	bindRow(button, row)

	local function submit()
		local text = strtrim(box:GetText() or "")
		if text ~= "" and validateRow(row, box, text, true) then
			box:SetText("")
			entry.func(text)
			afterChange(row)
		end
	end
	box:SetScript("OnEnterPressed", function(self)
		submit()
		self:ClearFocus()
	end)
	box.OnCancel = function(self)
		self:SetText("")
		validateRow(row, self)
	end
	button:SetScript("OnClick", submit)

	row.Refresh = function() end
	row.SetEnabled = function(_, enabled)
		setEditBoxEnabled(box, enabled)
		setControlEnabled(button, enabled)
	end
	return row
end

local function optionList(entry)
	local values = entry.values
	if type(values) == "function" then
		return values() or {}
	end
	return values or {}
end

local function optionLabel(values, value)
	for _, option in ipairs(values) do
		if option[1] == value then
			return option[2]
		end
	end
end

function creators.select(parent, entry)
	local row = createRow(parent, entry)
	local dropdown = CreateFrame("Frame", nextName("Drop"), row, "UIDropDownMenuTemplate")
	dropdown:SetPoint("LEFT", CONTROL_X - 16, -2)
	UIDropDownMenu_SetWidth(dropdown, entry.width or 140)
	local text = _G[dropdown:GetName() .. "Text"]
	text:SetFontObject("GameFontHighlightSmall")
	text:SetJustifyH("LEFT")
	row.dropdown = dropdown

	local function current()
		return ns.Get(entry)
	end

	UIDropDownMenu_Initialize(dropdown, function(_, level)
		local values = optionList(entry)
		local selected = current()
		for _, option in ipairs(values) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = option[2]
			info.value = option[1]
			info.checked = option[1] == selected
			info.tooltipTitle = option[2]
			info.tooltipText = option.desc or option[3]
			info.func = function()
				PlaySound("igMainMenuOptionCheckBoxOn")
				ns.Set(entry, option[1])
				afterChange(row)
			end
			UIDropDownMenu_AddButton(info, level)
		end
	end)
	bindRow(_G[dropdown:GetName() .. "Button"], row)

	row.Refresh = function()
		local values = optionList(entry)
		local value = current()
		if optionLabel(values, value) then
			UIDropDownMenu_SetSelectedValue(dropdown, value)
			UIDropDownMenu_SetText(dropdown, optionLabel(values, value))
		else
			UIDropDownMenu_SetText(dropdown, entry.placeholder or "")
		end
	end
	row.SetEnabled = function(_, enabled)
		if enabled then
			UIDropDownMenu_EnableDropDown(dropdown)
		else
			UIDropDownMenu_DisableDropDown(dropdown)
		end
	end
	return row
end

function creators.color(parent, entry)
	local row = createRow(parent, entry)

	local swatch = CreateFrame("Button", nil, row)
	swatch:SetSize(16, 16)
	swatch:SetPoint("LEFT", CONTROL_X + 2, 0)
	swatch:SetNormalTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
	local fill = swatch:GetNormalTexture()
	local background = swatch:CreateTexture(nil, "BACKGROUND")
	background:SetTexture(1, 1, 1)
	background:SetSize(14, 14)
	background:SetPoint("CENTER")
	swatch:SetScript("OnEnter", function()
		background:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
		ns.RowEnter(row)
	end)
	swatch:SetScript("OnLeave", function()
		background:SetVertexColor(1, 1, 1)
		ns.RowLeave(row)
	end)

	local hex = row:CreateFontString(nil, "ARTWORK")
	hex:SetFontObject("GameFontHighlightSmall")
	hex:SetPoint("LEFT", swatch, "RIGHT", 8, 0)

	local function current()
		local color = ns.Get(entry) or { 1, 1, 1 }
		return color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1
	end

	local function apply(r, g, b, a)
		local color = ns.Get(entry) or {}
		if r ~= color[1] or g ~= color[2] or b ~= color[3] or (entry.alpha and a ~= (color[4] or 1)) then
			ns.Set(entry, entry.alpha and { r, g, b, a } or { r, g, b })
			afterChange(row)
		end
	end

	local function paint()
		local r, g, b, a = current()
		if swatch:IsEnabled() ~= 1 then
			local gray = r * 0.3 + g * 0.59 + b * 0.11
			r, g, b = gray, gray, gray
		end
		fill:SetVertexColor(r, g, b, a)
	end

	swatch:SetScript("OnClick", function()
		local r, g, b, a = current()
		ColorPickerFrame.hasOpacity = entry.alpha and true or false
		ColorPickerFrame.opacity = 1 - a
		ColorPickerFrame.previousValues = { r, g, b, a }
		ColorPickerFrame.func = function()
			local nr, ng, nb = ColorPickerFrame:GetColorRGB()
			apply(nr, ng, nb, entry.alpha and 1 - OpacitySliderFrame:GetValue() or 1)
		end
		ColorPickerFrame.opacityFunc = ColorPickerFrame.func
		ColorPickerFrame.cancelFunc = function(previous)
			apply(previous[1], previous[2], previous[3], previous[4])
		end
		ColorPickerFrame:SetColorRGB(r, g, b)
		ColorPickerFrame:Hide()
		ColorPickerFrame:Show()
	end)

	row.Refresh = function()
		local r, g, b = current()
		paint()
		hex:SetText(("%02x%02x%02x"):format(r * 255, g * 255, b * 255))
	end
	row.SetEnabled = function(_, enabled)
		setControlEnabled(swatch, enabled)
		setTextEnabled(hex, enabled)
		paint()
	end
	return row
end

function creators.execute(parent, entry)
	local row = createRow(parent, entry)
	local button = ns.CreateButton(row, entry.text or entry.label or "Run", entry.width or 140, entry.confirm ~= nil)
	button:SetPoint("LEFT", CONTROL_X, 0)
	button:SetScript("OnClick", function()
		local function run()
			entry.func()
			afterChange(row)
		end
		local confirm = entry.confirm
		if type(confirm) == "function" then
			confirm = confirm()
		end
		if confirm then
			ns.Confirm(confirm, run)
		else
			run()
		end
	end)
	bindRow(button, row)
	row.Refresh = function() end
	row.SetEnabled = function(_, enabled)
		setControlEnabled(button, enabled)
	end
	return row
end

function creators.custom(parent, entry)
	local row = createRow(parent, entry)
	if entry.height then
		row:SetHeight(entry.height)
	end
	entry.build(row)
	row.Refresh = function()
		if entry.refresh then
			entry.refresh(row)
		end
	end
	row.SetEnabled = function(_, enabled)
		if entry.setEnabled then
			entry.setEnabled(row, enabled)
		end
	end
	return row
end

-- ---------------------------------------------------------------------------
-- Export popup (Profiles page "Export" action)
-- ---------------------------------------------------------------------------

StaticPopupDialogs["BUDSUI_CONFIG_EXPORT"] = {
	text = "Copy with Ctrl+C, close with Escape.",
	button1 = CLOSE,
	hasEditBox = 1,
	maxLetters = 0,
	OnShow = function(self)
		local box = _G[self:GetName() .. "EditBox"]
		box:SetText(ns._exportText or "")
		box:HighlightText()
		box:SetFocus()
	end,
	OnHide = function(self)
		local box = _G[self:GetName() .. "EditBox"]
		box:SetText("")
		ns._exportText = nil
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	preferredIndex = 3,
}

function ns.ShowExport(text)
	ns._exportText = text or ""
	StaticPopup_Show("BUDSUI_CONFIG_EXPORT")
end

-- ---------------------------------------------------------------------------
-- Compat aliases (some pages/guides refer to FormNumber instead of
-- FormatNumber; both map to the same implementation).
-- ---------------------------------------------------------------------------

ns.FormNumber = ns.FormatNumber
ns.FormValue = ns.FormatValue

_G["budsUI_Config"] = ns