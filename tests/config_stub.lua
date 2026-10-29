-- Additional client widgets used by the real configuration renderer.
local Frame = getmetatable(UIParent).__index
local originalCreateFrame = CreateFrame
function CreateFrame(kind, name, parent, template)
	local frame = originalCreateFrame(kind, name, parent, template)
	if template == "UIDropDownMenuTemplate" then
		frame:CreateFontString(name .. "Text", "ARTWORK")
		originalCreateFrame("Button", name .. "Button", frame)
	elseif template == "OptionsSliderTemplate" then
		for _, suffix in ipairs({ "Text", "Low", "High" }) do
			frame:CreateFontString(name .. suffix, "ARTWORK")
		end
		frame.thumb = frame:CreateTexture(nil, "ARTWORK")
	elseif template == "UIPanelScrollFrameTemplate" then
		originalCreateFrame("Slider", name .. "ScrollBar", frame)
	end
	return frame
end
function Frame:GetStringWidth() return #(self.text or "") * 6 end
function Frame:SetFontString(region) self.fontString = region end
function Frame:GetFontString()
	if not self.fontString then self.fontString = self:CreateFontString(nil, "ARTWORK") end
	return self.fontString
end
function Frame:SetNormalFontObject(value) self.normalFontObject = value end
function Frame:Enable() self.enabled = true end
function Frame:Disable() self.enabled = false end
function Frame:IsEnabled() return self.enabled == false and 0 or 1 end
function Frame:SetChecked(value) self.checked = value end
function Frame:GetChecked() return self.checked end
function Frame:SetCursorPosition(value) self.cursor = value end
function Frame:HasFocus() return self.focused == true end
function Frame:EnableMouseWheel(value) self.mouseWheel = value end
function Frame:SetScrollChild(child) self.scrollChild = child end
function Frame:UpdateScrollChildRect() end
function Frame:SetVerticalScroll(value) self.scrollPosition = value end
function Frame:GetVerticalScroll() return self.scrollPosition or 0 end
function Frame:LockHighlight() self.highlightLocked = true end
function Frame:UnlockHighlight() self.highlightLocked = false end
function Frame:SetMinMaxValues(low, high) self.minimum, self.maximum = low, high end
function Frame:SetValueStep(step) self.step = step end
function Frame:SetNumeric(value) self.numeric = value end
function Frame:GetThumbTexture() return self.thumb end
function Frame:SetNormalTexture(path)
	self.normalTexture = self:CreateTexture(nil, "ARTWORK")
	self.normalTexture:SetTexture(path)
end
function Frame:GetNormalTexture() return self.normalTexture end
function Frame:Click() if self.scripts.OnClick then self.scripts.OnClick(self, "LeftButton") end end
function UIDropDownMenu_SetWidth(frame, width) frame.menuWidth = width end
function UIDropDownMenu_Initialize(frame, callback) frame.initialize = callback end
function UIDropDownMenu_CreateInfo() return {} end
function UIDropDownMenu_AddButton(info)
	Test.menuOptions[#Test.menuOptions + 1] = info
end
function UIDropDownMenu_SetSelectedValue(frame, value) frame.selectedValue = value end
function UIDropDownMenu_SetText(frame, text)
	_G[frame:GetName() .. "Text"]:SetText(text)
end
function UIDropDownMenu_EnableDropDown(frame) frame:Enable() end
function UIDropDownMenu_DisableDropDown(frame) frame:Disable() end
function InterfaceOptions_AddCategory(panel) Test.optionsPanel = panel end
function ReloadUI() Test.reloads = (Test.reloads or 0) + 1 end
Test.menuOptions = {}
UISpecialFrames = UISpecialFrames or {}
C.Nameplate = { Enable = true, BlacklistEnable = true, Blacklist = { "General" } }
C.Unitframe = { PowerFormat = "None", HealthFormat = "Current" }
budsUIData.Profiles.General = {}
min = math.min
format = string.format
NORMAL_FONT_COLOR = { r = 1, g = 0.82, b = 0 }
HIGHLIGHT_FONT_COLOR = { r = 1, g = 1, b = 1 }
GRAY_FONT_COLOR = { r = 0.5, g = 0.5, b = 0.5 }
RED_FONT_COLOR = { r = 1, g = 0, b = 0 }
function InCombatLockdown() return Test.combat == true end
function PlaySound() end
function Frame:GetValue() return self.value or 0 end
function Frame:UnregisterAllEvents() self.events = {} end
