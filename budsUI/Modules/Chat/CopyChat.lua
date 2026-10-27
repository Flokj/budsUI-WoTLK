local K, C, L, _ = select(2, ...):unpack()

local _G = _G
local format = string.format
local gsub = string.gsub
local pairs = pairs
local unpack = unpack
local find = string.find
local select = select
local tinsert = tinsert
local CreateFrame, UIParent = CreateFrame, UIParent
local ToggleFrame = ToggleFrame
local GetSpellInfo = GetSpellInfo

-- Copy Chat
local lines = {}
-- T12: Idiomatic Lua: declare multiple locals without redundant nil assignment
-- T13: Removed dead code `tex = select(3, GetSpellInfo(6310))` — tex was never referenced
local frame, editBox, isf
local sizes = {
	":14:14",
	":15:15",
	":16:16",
	":12:20",
	":14"
}

-- T14: Fixed typo: CreatCopyFrame -> CreateCopyFrame
local function CreateCopyFrame()
	frame = CreateFrame("Frame", "CopyFrame", UIParent)
	frame:SetBackdrop(K.Backdrop)
	frame:SetBackdropBorderColor(unpack(C.Media.Border_Color))
	frame:SetBackdropColor(unpack(C.Media.Backdrop_Color))
	frame:SetSize(730, 500)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
	frame:SetFrameStrata("DIALOG")
	tinsert(UISpecialFrames, "CopyFrame")
	frame:Hide()

	local scrollArea = CreateFrame("ScrollFrame", "CopyScroll", frame, "UIPanelScrollFrameTemplate")
	scrollArea:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -30)
	-- T15: Removed first BOTTOMRIGHT SetPoint here; set together with final position after close button (line ~67)

	editBox = CreateFrame("EditBox", "CopyBox", frame)
	editBox:SetMultiLine(true)
	editBox:SetMaxLetters(99999)
	editBox:EnableMouse(true)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject(ChatFontNormal)
	editBox:SetSize(700, 500)
	editBox:SetScript("OnEscapePressed", function() frame:Hide() end)

	scrollArea:SetScrollChild(editBox)

	editBox:SetScript("OnTextSet", function(self)
		local text = self:GetText()

		for _, size in pairs(sizes) do
			if find(text, size) and not find(text, size.."]") then
				self:SetText(gsub(text, size, ":12:12"))
			end
		end
	end)

	local close = CreateFrame("Button", "CopyCloseButton", frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	scrollArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 8)

	isf = true
end

local scrollDown = function()
	CopyScroll:SetVerticalScroll((CopyScroll:GetVerticalScrollRange()) or 0)
end

local function Copy(cf)
	local text = ""
	for i = 1, cf:GetNumMessages() do
		text = text..cf:GetMessageInfo(i).."\n"
	end
	text = text:gsub("|[Tt]Interface\\TargetingFrame\\UI%-RaidTargetingIcon_(%d):0|[Tt]", "{rt%1}")
	text = text:gsub("|[Tt][^|]+|[Tt]", "")
	if not isf then CreateCopyFrame() end
	if frame:IsShown() then frame:Hide() return end
	frame:Show()
	editBox:SetText(text)
	K.Delay(0.25, scrollDown)
end

for i = 1, NUM_CHAT_WINDOWS do
	local cf = _G[format("ChatFrame%d", i)]
	if cf then
		local button = CreateFrame("Button", format("ButtonCF%d", i), cf)
		button:SetPoint("TOPRIGHT", cf, "TOPRIGHT", 2, 2)
		button:SetSize(16, 16)
		button:SetFrameLevel(cf:GetFrameLevel() + 5)
		button:SetAlpha(0.35)

		button.glyph = K.CreateGlyph(button, "copy", 11, "ARTWORK", "OUTLINE")
		button.glyph:SetPoint("CENTER")
		button.glyph:SetTextColor(0.75, 0.75, 0.75)

		button:SetScript("OnMouseUp", function(self, btn)
			if btn == "RightButton" then
				ToggleFrame(ChatMenu)
			elseif btn == "MiddleButton" then
				RandomRoll(1, 100)
			else
				Copy(cf)
			end
		end)
		button:HookScript("OnEnter", function(self)
			self:SetAlpha(1)
			if self.glyph then
				self.glyph:SetTextColor(1, 0.82, 0)
			end
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L_CHAT_COPY or "Copy Chat", 1, 1, 1)
			GameTooltip:AddLine(L_CHAT_COPY_HINT or "|cff00ff00Left Click:|r Copy\n|cff00ff00Right Click:|r Chat Menu\n|cff00ff00Middle Click:|r /roll 1-100", 0.75, 0.75, 0.75)
			GameTooltip:Show()
		end)
		button:HookScript("OnLeave", function(self)
			self:SetAlpha(0.35)
			if self.glyph then
				self.glyph:SetTextColor(0.75, 0.75, 0.75)
			end
			GameTooltip:Hide()
		end)
		button:HookScript("OnMouseDown", function(self)
			if self.glyph then
				self.glyph:SetPoint("CENTER", 1, -1)
			end
		end)
		button:HookScript("OnMouseUp", function(self)
			if self.glyph then
				self.glyph:SetPoint("CENTER", 0, 0)
			end
		end)
	end
end

-- T16: Moved slash command outside loop; added required SLASH_* binding so command is actually registered
SLASH_COPYCHAT1 = "/copychat"
SLASH_COPYCHAT2 = "/copy"
SlashCmdList.COPYCHAT = function()
	Copy(_G["ChatFrame1"])
end
