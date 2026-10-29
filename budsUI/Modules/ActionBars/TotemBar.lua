local K, C, L, _ = select(2, ...):unpack()
if C.ActionBar.Enable ~= true or K.Class ~= "SHAMAN" then return end

local InCombatLockdown = InCombatLockdown
local RegisterStateDriver = RegisterStateDriver
local hooksecurefunc = hooksecurefunc
local max, min, ceil, floor = math.max, math.min, math.ceil, math.floor
local ipairs, pairs, type = ipairs, pairs, type
local unpack = unpack

local BLIZZARD_BUTTON_SIZE = 30
local VISIBILITY_SHOWN = "[vehicleui] hide; show"
local ARROW_WIDTH, ARROW_HEIGHT = 28, 18
local ARROW_HIGHLIGHT_WIDTH, ARROW_HIGHLIGHT_HEIGHT = 20, 11
local FLYOUT_PADDING = 5
local FLYOUT_CLOSE_GAP = 2

local holder, bar
local items = {}

local function GridPoint(point, i, perRow, size)
	i = i - 1
	local column, row = i % perRow, floor(i / perRow)
	local xSign = point:find("RIGHT") and -1 or 1
	local ySign = point:find("BOTTOM") and 1 or -1
	return point, xSign * column * size, ySign * row * size
end

local function sizeArrow(button, width, height)
	if not button then return 0 end
	height = height or width * ARROW_HEIGHT / ARROW_WIDTH
	button:SetSize(width, height)
	local hl = button:GetHighlightTexture()
	if hl then
		hl:SetSize(width * ARROW_HIGHLIGHT_WIDTH / ARROW_WIDTH, height * ARROW_HIGHLIGHT_HEIGHT / ARROW_HEIGHT)
	end
	return height
end

local function sizeOpenButton(button)
	local parent = button and button:GetParent()
	if parent then
		sizeArrow(button, parent:GetWidth(), parent:GetHeight())
	end
end

local function SkinTotemButton(button)
	if not button or button.__skinned then return end
	local name = button:GetName()
	local icon = name and _G[name .. "Icon"] or button.icon
	local normal = name and _G[name .. "NormalTexture"] or button:GetNormalTexture()
	local border = name and _G[name .. "Border"]
	local highlight = button:GetHighlightTexture()
	local pushed = button:GetPushedTexture()

	if normal then
		normal:SetTexture("")
		normal:Hide()
		normal:SetAlpha(0)
	end
	button:SetNormalTexture("")
	button.SetNormalTexture = K.Noop

	if border then
		border:Hide()
		border:SetTexture("")
	end

	if not button.backdrop then
		local backdrop = CreateFrame("Frame", nil, button)
		backdrop:SetBackdrop(K.Backdrop)
		backdrop:SetBackdropColor(unpack(C.Media.Backdrop_Color))
		backdrop:SetBackdropBorderColor(unpack(C.Media.Border_Color))
		backdrop:ClearAllPoints()
		backdrop:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
		backdrop:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
		backdrop:SetFrameLevel(button:GetFrameLevel() > 0 and button:GetFrameLevel() - 1 or 0)
		button.backdrop = backdrop
	end

	if icon then
		icon:SetTexCoord(unpack(K.TexCoords))
		icon:ClearAllPoints()
		icon:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
		icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
	end

	if highlight then
		highlight:SetTexture(1, 1, 1, 0.3)
		highlight:ClearAllPoints()
		highlight:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
		highlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
	end

	if pushed then
		pushed:SetTexture(0, 0, 0, 0.4)
		pushed:ClearAllPoints()
		pushed:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
		pushed:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
	end

	button.__skinned = true
end

local function SkinFlyout()
	local flyout = MultiCastFlyoutFrame
	if not flyout then return end
	if flyout.top then flyout.top:Hide() end
	if flyout.middle then flyout.middle:Hide() end

	if not flyout.backdrop then
		local backdrop = CreateFrame("Frame", nil, flyout)
		backdrop:SetBackdrop(K.Backdrop)
		backdrop:SetBackdropColor(unpack(C.Media.Backdrop_Color))
		backdrop:SetBackdropBorderColor(unpack(C.Media.Border_Color))
		backdrop:ClearAllPoints()
		backdrop:SetPoint("TOPLEFT", flyout, "TOPLEFT", 0, 0)
		backdrop:SetPoint("BOTTOMRIGHT", flyout, "BOTTOMRIGHT", 0, 0)
		backdrop:SetFrameLevel(flyout:GetFrameLevel() > 0 and flyout:GetFrameLevel() - 1 or 0)
		flyout.backdrop = backdrop
	end
end

local function layoutFlyout()
	local flyout = MultiCastFlyoutFrame
	if not flyout or not flyout:IsShown() or not flyout.buttons then
		return
	end

	local size = C.ActionBar.TotemFlyoutSize or 26
	local gap = C.ActionBar.TotemFlyoutSpace or 2
	local perColumn = C.ActionBar.TotemFlyoutRows or 10
	local step = size + gap

	local shown = 0
	for _, button in ipairs(flyout.buttons) do
		if button:IsShown() then
			local column, row = floor(shown / perColumn), shown % perColumn
			button:SetSize(size, size)
			button:ClearAllPoints()
			button:SetPoint(
				"BOTTOMLEFT",
				flyout,
				"BOTTOMLEFT",
				FLYOUT_PADDING + column * step,
				FLYOUT_PADDING + row * step
			)
			SkinTotemButton(button)
			shown = shown + 1
		end
	end

	local columns = max(ceil(shown / perColumn), 1)
	local rows = max(min(shown, perColumn), 1)
	local close = MultiCastFlyoutFrameCloseButton
	local closeHeight = sizeArrow(close, size)
	if close then
		close:ClearAllPoints()
		close:SetPoint("TOP", flyout, "TOP", 0, -FLYOUT_PADDING)
	end
	flyout:SetSize(
		columns * step - gap + FLYOUT_PADDING * 2,
		rows * step - gap + FLYOUT_CLOSE_GAP + closeHeight + FLYOUT_PADDING * 2
	)
end

local function placeButton(button, index, columns, slot)
	if not button then return end
	if button:IsProtected() and InCombatLockdown() then
		return
	end
	local point, x, y = GridPoint("BOTTOMLEFT", index, columns, slot)
	button:ClearAllPoints()
	button:SetPoint(point, bar, point, x, y)
	SkinTotemButton(button)
end

local eventFrame = CreateFrame("Frame")

local function layoutButtons()
	local combat = InCombatLockdown()
	if combat then
		eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	else
		eventFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end

	local buttonSize = C.ActionBar.TotemButtonSize or C.ActionBar.ButtonSize or 32
	local spacing = C.ActionBar.TotemButtonSpace or C.ActionBar.ButtonSpace or 4
	local maxCols = C.ActionBar.TotemColumns or 6
	local scale = buttonSize / BLIZZARD_BUTTON_SIZE
	local gap = spacing / scale
	local slot = BLIZZARD_BUTTON_SIZE + gap

	bar:SetParent(holder)
	bar:ClearAllPoints()
	bar:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 0)
	bar:SetScale(scale)

	if MultiCastFlyoutFrame then
		MultiCastFlyoutFrame:SetScale(1 / scale)
	end

	wipe(items)
	if MultiCastSummonSpellButton and MultiCastSummonSpellButton:IsShown() then
		items[#items + 1] = MultiCastSummonSpellButton
	end
	for i = 1, (bar.numActiveSlots or 4) do
		items[#items + 1] = i
	end
	if MultiCastRecallSpellButton and MultiCastRecallSpellButton:IsShown() then
		items[#items + 1] = MultiCastRecallSpellButton
	end

	local count = max(#items, 1)
	local columns = max(min(maxCols, count), 1)
	local rows = ceil(count / columns)

	for index, item in ipairs(items) do
		if type(item) == "number" then
			local slotButton = _G["MultiCastSlotButton" .. item]
			placeButton(slotButton, index, columns, slot)
			for page = 1, NUM_MULTI_CAST_PAGES do
				local id = (page - 1) * NUM_MULTI_CAST_BUTTONS_PER_PAGE + item
				local actionButton = _G["MultiCastActionButton" .. id]
				placeButton(actionButton, index, columns, slot)
			end
		else
			placeButton(item, index, columns, slot)
		end
	end

	local width, height = columns * slot - gap, rows * slot - gap
	bar:SetSize(width, height)
	holder:SetSize(width * scale, height * scale)
	if holder.budsUI_Mover then
		holder.budsUI_Mover:SetSize(width * scale, height * scale)
	end
end

eventFrame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_REGEN_ENABLED" then
		layoutButtons()
	end
end)

local function InitTotemBar()
	bar = MultiCastActionBarFrame
	if not bar then return end

	bar.ignoreFramePositionManager = true
	if UIPARENT_MANAGED_FRAME_POSITIONS then
		UIPARENT_MANAGED_FRAME_POSITIONS.MultiCastActionBarFrame = nil
		UIPARENT_MANAGED_FRAME_POSITIONS.MULTICASTACTIONBAR_YPOS = nil
	end

	holder = CreateFrame("Frame", "budsUITotemBar", UIParent, "SecureHandlerStateTemplate")
	holder:SetSize(200, 36)
	holder:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 145)

	-- Keybindings
	for i = 1, NUM_MULTI_CAST_PAGES * NUM_MULTI_CAST_BUTTONS_PER_PAGE do
		local btn = _G["MultiCastActionButton" .. i]
		if btn then
			btn.bindingName = "CLICK " .. btn:GetName() .. ":LeftButton"
			btn.blizzardBinding = "MULTICASTACTIONBUTTON" .. i
		end
	end
	if MultiCastRecallSpellButton then
		MultiCastRecallSpellButton.bindingName = "CLICK MultiCastRecallSpellButton:LeftButton"
		MultiCastRecallSpellButton.blizzardBinding = "MULTICASTRECALLBUTTON1"
	end
	if MultiCastSummonSpellButton then
		MultiCastSummonSpellButton.bindingName = "CLICK MultiCastSummonSpellButton:LeftButton"
		local function updateSummonBinding()
			MultiCastSummonSpellButton.blizzardBinding = "MULTICASTSUMMONBUTTON" .. MultiCastSummonSpellButton:GetID()
		end
		updateSummonBinding()
		hooksecurefunc("ChangeMultiCastActionPage", updateSummonBinding)
	end

	bar:SetScript("OnUpdate", nil)
	bar:SetScript("OnShow", nil)
	bar:SetScript("OnHide", nil)
	bar:EnableMouse(false)

	SkinFlyout()

	hooksecurefunc("MultiCastActionBarFrame_Update", layoutButtons)
	hooksecurefunc("MultiCastFlyoutFrame_ToggleFlyout", layoutFlyout)
	hooksecurefunc("MultiCastFlyoutFrameOpenButton_Show", sizeOpenButton)

	layoutButtons()
	RegisterStateDriver(holder, "visibility", VISIBILITY_SHOWN)

	-- Register mover in budsUI
	K.CreateMover(holder, "TotemBar", "Totem Bar", { "BOTTOM", UIParent, "BOTTOM", -314, 118 }, 200, 36, "BOTTOMLEFT")
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN")
	InitTotemBar()
end)
