local K, C, L, _ = select(2, ...):unpack()
if C.Chat.Enable ~= true then return end

local BUTTON_SIZE = 20
local GLYPH = "angles-down"
local GLYPH_SIZE = 14
local FLASH_DURATION = 0.4
local SCROLL_METHODS = {
	"ScrollUp",
	"ScrollDown",
	"PageUp",
	"PageDown",
	"ScrollToTop",
	"ScrollToBottom",
	"SetScrollOffset",
	"Clear",
}

local buttons = {}

local function update(chatFrame)
	local button = buttons[chatFrame]
	if not button then return end
	if (C.Chat.ScrollButton ~= false) and not chatFrame:AtBottom() then
		button:Show()
	else
		button.flash:Hide()
		button:Hide()
	end
end

local function onMessage(chatFrame)
	update(chatFrame)
	local button = buttons[chatFrame]
	if button and button:IsShown() then
		button.flash:Show()
	end
end

local function onClick(self)
	local chat = self:GetParent()
	chat:ScrollToBottom()
	update(chat)
end

local function playFlash(self)
	self.animation:Play()
end

local function stopFlash(self)
	self.animation:Stop()
end

local function createButton(chatFrame)
	local button = CreateFrame("Button", nil, chatFrame)
	button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	button:SetPoint("BOTTOMRIGHT", chatFrame, "BOTTOMRIGHT", 0, 2)
	button:SetFrameLevel(chatFrame:GetFrameLevel() + 5)

	button.glyph = K.CreateGlyph(button, GLYPH, GLYPH_SIZE, "ARTWORK", "OUTLINE")
	button.glyph:SetPoint("CENTER")
	button.glyph:SetTextColor(0.75, 0.75, 0.75)

	button:SetScript("OnClick", onClick)
	button:SetScript("OnEnter", function(self)
		self.glyph:SetTextColor(1, 0.82, 0)
	end)
	button:SetScript("OnLeave", function(self)
		self.glyph:SetTextColor(0.75, 0.75, 0.75)
	end)
	button:SetScript("OnMouseDown", function(self)
		self.glyph:SetPoint("CENTER", 1, -1)
	end)
	button:SetScript("OnMouseUp", function(self)
		self.glyph:SetPoint("CENTER", 0, 0)
	end)
	button:Hide()

	local flash = CreateFrame("Frame", nil, button)
	flash:SetAllPoints()
	local glyph = K.CreateGlyph(flash, GLYPH, GLYPH_SIZE, "OVERLAY", "OUTLINE")
	glyph:SetTextColor(1, 0.82, 0)
	glyph:SetPoint("CENTER", button.glyph)

	local animation = flash:CreateAnimationGroup()
	local alpha = animation:CreateAnimation("Alpha")
	alpha:SetChange(-1)
	alpha:SetDuration(FLASH_DURATION)
	animation:SetLooping("BOUNCE")
	flash.animation = animation
	flash:SetScript("OnShow", playFlash)
	flash:SetScript("OnHide", stopFlash)
	flash:Hide()

	button.flash = flash
	buttons[chatFrame] = button

	hooksecurefunc(chatFrame, "AddMessage", onMessage)
	for i = 1, #SCROLL_METHODS do
		if chatFrame[SCROLL_METHODS[i]] then
			hooksecurefunc(chatFrame, SCROLL_METHODS[i], update)
		end
	end
end

local scrollModule = CreateFrame("Frame")
scrollModule:RegisterEvent("PLAYER_LOGIN")
scrollModule:SetScript("OnEvent", function(self)
	for i = 1, NUM_CHAT_WINDOWS do
		local chatFrame = _G["ChatFrame" .. i]
		if chatFrame then
			createButton(chatFrame)
		end
	end
end)
