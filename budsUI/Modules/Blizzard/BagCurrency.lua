local K, C, L, _ = select(2, ...):unpack()

-- Pinned currencies in the bags: the tokens watched in the currency tab get a
-- strip along the bottom of the Stuffing window (Blizzard's token frame floats
-- free once its ContainerFrame host is killed).

local _G = _G
local CreateFrame, UIParent = CreateFrame, UIParent
local GameTooltip = GameTooltip
local format = string.format

local MAX_WATCHED_TOKENS = MAX_WATCHED_TOKENS or 20
local BAR_HEIGHT = 16
local ICON_SIZE = 14
local TOKEN_GAP = 10
local BAND_PADDING = 8

local ARENA_ICON = "Interface\\PVPFrame\\PVP-ArenaPoints-Icon"
local HONOR_ICON = "Interface\\TargetingFrame\\UI-PVP-%s"

local bar, buttons = nil, {}
local bandApplied = 0
local SyncBand

local function IsEnabled()
	return C.Bag ~= nil and C.Bag.Currency == true
end

local function OpenCurrencyTab()
	if not _G.TokenFrame then
		LoadAddOn("Blizzard_TokenUI")
	end
	if _G.ToggleCharacter then
		ToggleCharacter("TokenFrame")
	end
end

-- ---------------------------------------------------------------------------
-- Token buttons
-- ---------------------------------------------------------------------------

local function CreateToken(index)
	local button = CreateFrame("Button", "budsUIBagCurrencyToken" .. index, bar)
	button:SetID(index)
	button:SetHeight(BAR_HEIGHT)

	button.icon = button:CreateTexture(nil, "ARTWORK")
	button.icon:SetSize(ICON_SIZE, ICON_SIZE)
	button.icon:SetPoint("LEFT", 0, 0)

	button.count = button:CreateFontString(nil, "OVERLAY")
	button.count:SetFont(C.Media.Font, 12, C.Media.Font_Style)
	button.count:SetPoint("LEFT", button.icon, "RIGHT", 3, 0)

	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if GameTooltip.SetBackpackToken then
			GameTooltip:SetBackpackToken(self:GetID())
		elseif self.currencyType == 1 then
			GameTooltip:SetText(ARENA_POINTS, 1, 1, 1)
			GameTooltip:AddLine(TOOLTIP_ARENA_POINTS, 1, 1, 1, 1)
		elseif self.currencyType == 2 then
			GameTooltip:SetText(HONOR_POINTS, 1, 1, 1)
			GameTooltip:AddLine(TOOLTIP_HONOR_POINTS, 1, 1, 1, 1)
		elseif self.itemID then
			GameTooltip:SetHyperlink("item:" .. self.itemID)
		elseif self.name then
			GameTooltip:SetText(self.name, 1, 1, 1)
		end
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	button:SetScript("OnClick", OpenCurrencyTab)
	return button
end

-- The arena/honor icons are sheets, not square icons: without their own
-- texcoords they render as a zoomed fragment (looks like a broken PvP icon).
local function ApplyIcon(button, currencyType, icon)
	local texture = button.icon
	if currencyType == 1 then
		texture:SetTexture(ARENA_ICON)
		texture:SetTexCoord(0, 1, 0, 1)
	elseif currencyType == 2 then
		local faction = UnitFactionGroup("player")
		texture:SetTexture(faction and format(HONOR_ICON, faction) or icon)
		texture:SetTexCoord(0.03125, 0.59375, 0.03125, 0.59375)
	else
		texture:SetTexture(icon)
		texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	end
end

local function BandHeight()
	if not bar or not bar.rows or bar.rows < 1 then return 0 end
	return bar.rows * BAR_HEIGHT + BAND_PADDING
end

local function Refresh()
	if not bar then return end

	if not IsEnabled() then
		bar:Hide()
		for i = 1, #buttons do
			buttons[i]:Hide()
		end
	else
		local shown, previous, x, row = 0, nil, 0, 0
		local limit = bar:GetWidth() - 4
		for i = 1, MAX_WATCHED_TOKENS do
			local name, count, currencyType, icon, itemID = GetBackpackCurrencyInfo(i)
			local button = buttons[i]
			if name then
				button = button or CreateToken(i)
				buttons[i] = button
				button.name, button.itemID = name, itemID
				button.currencyType = currencyType
				ApplyIcon(button, currencyType, icon)
				button.count:SetText(K.ShortValue(count) or tostring(count or 0))
				button:SetWidth(ICON_SIZE + 3 + button.count:GetStringWidth())
				button:ClearAllPoints()
				local width = button:GetWidth()
				local newRow = previous ~= nil and limit > 0 and x + TOKEN_GAP + width > limit
				if not previous then
					button:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
					x = width
				elseif newRow then
					-- Wrap: the bar grows a row and the frame band with it.
					row = row + 1
					button:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, -row * BAR_HEIGHT)
					x = width
				else
					button:SetPoint("LEFT", previous, "RIGHT", TOKEN_GAP, 0)
					x = x + TOKEN_GAP + width
				end
				button:Show()
				previous, shown = button, shown + 1
			elseif button then
				button:Hide()
			end
		end

		bar.rows = shown > 0 and (row + 1) or 0
		bar:SetHeight(bar.rows * BAR_HEIGHT)
		if shown > 0 then
			bar:Show()
		else
			bar:Hide()
		end
	end

	-- The bags Layout recomputes the frame height on every update, so the band
	-- is reserved by the Layout wrapper below; here only the toggle is handled.
	SyncBand()
end

-- ---------------------------------------------------------------------------
-- Bag frame band
-- ---------------------------------------------------------------------------

SyncBand = function()
	local frame = _G.Stuffing and Stuffing.frame
	if not frame or not frame:IsShown() then return end
	local wanted = (bar ~= nil and bar:IsShown()) and BandHeight() or 0
	if wanted == bandApplied then return end
	frame:SetHeight(frame:GetHeight() - bandApplied + wanted)
	bandApplied = wanted
end

local function WrapLayout(frame)
	if frame.LayoutWrapped or not Stuffing or not Stuffing.Layout then return end
	frame.LayoutWrapped = true

	local layout = Stuffing.Layout
	Stuffing.Layout = function(self, bank)
		layout(self, bank)
		-- Layout rebuilds the height from scratch, so the band is re-reserved after it.
		bandApplied = 0
		if not bank and bar and bar:IsShown() then
			Refresh()
		end
	end
end

local function EnsureBar()
	local stuff = _G.Stuffing
	local frame = stuff and stuff.frame
	if not frame or bar then return end

	bar = CreateFrame("Frame", "budsUIBagCurrencyBar", frame)
	bar:SetHeight(BAR_HEIGHT)
	bar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 6)
	bar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 6)
	bar:Hide()

	WrapLayout(frame)
	Refresh()

	frame:HookScript("OnShow", Refresh)
end

-- ---------------------------------------------------------------------------
-- Blizzard leftovers and events
-- ---------------------------------------------------------------------------

local function HideBlizzardTokenFrame()
	if not IsEnabled() then return end
	local tokenFrame = _G.BackpackTokenFrame
	if not tokenFrame or tokenFrame.budsUIHidden then return end
	tokenFrame.budsUIHidden = true
	tokenFrame:Hide()
	tokenFrame:HookScript("OnShow", function(self)
		if IsEnabled() and bar then
			self:Hide()
		end
	end)
end

-- The Stuffing window is built during ADDON_LOADED; wait for it, but do not
-- keep a per-frame check alive when the bags are disabled.
local waitFrame = CreateFrame("Frame")
waitFrame.elapsed = 0
waitFrame:SetScript("OnUpdate", function(self, elapsed)
	if not _G.Stuffing or not Stuffing.frame then
		self.elapsed = self.elapsed + elapsed
		if self.elapsed > 10 then
			self:SetScript("OnUpdate", nil)
		end
		return
	end
	self:SetScript("OnUpdate", nil)
	EnsureBar()
end)

local events = CreateFrame("Frame", nil, UIParent)
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
events:RegisterEvent("ADDON_LOADED")

-- BackpackTokenFrame_Update lives in the load-on-demand Blizzard_TokenUI, so the
-- hook waits for the global instead of erroring at load time.
local tokenUpdateHooked = false
local function HookTokenUpdate()
	if tokenUpdateHooked or type(hooksecurefunc) ~= "function" then return end
	if type(BackpackTokenFrame_Update) ~= "function" then return end
	tokenUpdateHooked = true
	hooksecurefunc("BackpackTokenFrame_Update", Refresh)
end

events:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == "Blizzard_TokenUI" then
			HookTokenUpdate()
			HideBlizzardTokenFrame()
		end
		return
	end
	if event == "PLAYER_ENTERING_WORLD" then
		EnsureBar()
		HookTokenUpdate()
		HideBlizzardTokenFrame()
	end
	Refresh()
end)

HookTokenUpdate()
if type(hooksecurefunc) == "function" and type(SetCurrencyBackpack) == "function" then
	hooksecurefunc("SetCurrencyBackpack", Refresh)
end

K.RefreshBagCurrency = Refresh
