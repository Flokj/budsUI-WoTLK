local K, C, L, _ = select(2, ...):unpack()
if C.Bag.Enable ~= true then return end

local tonumber = tonumber
local select = select
local ipairs = ipairs
local floor = math.floor
local wipe = table.wipe
local CreateFrame, UIParent = CreateFrame, UIParent
local GetContainerItemCooldown = GetContainerItemCooldown
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetContainerNumFreeSlots = GetContainerNumFreeSlots

--[[
A featureless, 'pure' version of Stuffing.
This version should work on absolutely everything,
but I've removed pretty much all of the options.

All credits of this bags script is by Stuffing and his author Hungtar.
--]]

local BAGS_BACKPACK = {0, 1, 2, 3, 4}
local BAGS_BANK = {-1, 5, 6, 7, 8, 9, 10, 11}
local ST_NORMAL = 1
local ST_SOULBAG = 2
local ST_SPECIAL = 3
local ST_QUIVER = 4
local bag_bars = 0
local show_keyring = 0

-- Extracted constants (previously hardcoded magic numbers)
local HEARTHSTONE_ID = 6948
local SORT_MAX_ITERATIONS = 100
local FRAME_POOL_MAX_SIZE = 120
local hide_soulbag = C.Bag.HideSoulBag

-- Hide bags options in default interface
-- WoW 3.3.5 Compatibility: InterfaceOptionsDisplayPanelShowFreeBagSpace doesn't exist in 3.3.5
-- This element was added in later WoW versions to show free bag space in the interface options
-- If the element doesn't exist, we gracefully skip hiding it (no functionality impact)
if InterfaceOptionsDisplayPanelShowFreeBagSpace then
	InterfaceOptionsDisplayPanelShowFreeBagSpace:Hide()
end

Stuffing = CreateFrame("Frame", nil, UIParent)
Stuffing:RegisterEvent("ADDON_LOADED")
Stuffing:RegisterEvent("PLAYER_ENTERING_WORLD")
Stuffing:SetScript("OnEvent", function(this, event, ...)
	if IsAddOnLoaded("AdiBags") or IsAddOnLoaded("cargBags_Nivaya") or IsAddOnLoaded("cargBags") or IsAddOnLoaded("Bagnon") or IsAddOnLoaded("Combuctor") then return end
	Stuffing[event](this, ...)
end)

local function Stuffing_OnShow()
	Stuffing:PLAYERBANKSLOTS_CHANGED(29)

	for i = 0, #BAGS_BACKPACK - 1 do
		Stuffing:BAG_UPDATE(i)
	end

	Stuffing:Layout()
	Stuffing:SearchReset()
	PlaySound("igBackPackOpen")
end

local function StuffingBank_OnHide()
	CloseBankFrame()
	if Stuffing.frame:IsShown() then
		Stuffing.frame:Hide()
	end
	PlaySound("igBackPackClose")
end

local function Stuffing_OnHide()
	if Stuffing.bankFrame and Stuffing.bankFrame:IsShown() then
		Stuffing.bankFrame:Hide()
	end
	PlaySound("igBackPackClose")
end

local function Stuffing_Open()
	if not Stuffing.frame:IsShown() then
		Stuffing.frame:Show()
	end
end

local function Stuffing_Close()
	Stuffing.frame:Hide()
end

local function Stuffing_Toggle()
	if Stuffing.frame:IsShown() then
		Stuffing.frame:Hide()
	else
		Stuffing.frame:Show()
	end
end

local function Stuffing_ToggleBag(id)
	if id == -2 then
		if show_keyring == 1 then
			show_keyring = 0
		else
			show_keyring = 1
		end
		Stuffing:Layout()
		if show_keyring == 1 and not Stuffing.frame:IsShown() then
			Stuffing:Open()
		end
		return
	end
	Stuffing_Toggle()
end

-- bag slot stuff
local trashButton = {}
local trashBag = {}

-- mostly from carg.bags_Aurora
local QUEST_ITEM_STRING = nil

function Stuffing:SlotUpdate(b)
	local texture, count, locked = GetContainerItemInfo(b.bag, b.slot)
	local clink = GetContainerItemLink(b.bag, b.slot)

	if b.cooldown and StuffingFrameBags and StuffingFrameBags:IsShown() then
		-- WoW 3.3.5 Compatibility: GetContainerItemCooldown returns only 2 values (start, duration)
		-- The 3rd parameter (enable) was added in Cataclysm 4.0
		local start, duration = GetContainerItemCooldown(b.bag, b.slot)
		CooldownFrame_SetTimer(b.cooldown, start, duration, 1)
	end

	if(clink) then
		local name, _, rarity = GetItemInfo(clink)
		if name then
			b.name, b.rarity = name, rarity
			local isQuestItem, questId, isActive = GetContainerItemQuestInfo(b.bag, b.slot)
			if isQuestItem or questId or isActive then
				b.qitem = true
			else
				b.qitem = nil
			end
		else
			b.name, b.rarity, b.qitem = nil, nil, nil
		end
	else
		b.name, b.rarity, b.qitem = nil, nil, nil
	end

	SetItemButtonTexture(b.frame, texture)
	SetItemButtonCount(b.frame, count)
	SetItemButtonDesaturated(b.frame, locked)

	if b.Glow then
		b.Glow:Hide()
		if b.rarity then
			if b.rarity > 1 then
				b.Glow:SetVertexColor(GetItemQualityColor(b.rarity))
				b.Glow:Show()
			elseif b.qitem then
				b.Glow:SetVertexColor(1, 1, 0)
				b.Glow:Show()
			end
		end
	end

	if b.bag ~= -2 or show_keyring == 1 then
		b.frame:Show()
	end
end

function Stuffing:BagSlotUpdate(bag)
	if not self.buttons then
		return
	end

	for _, v in ipairs(self.buttons) do
		if v.bag == bag then
			self:SlotUpdate(v)
		end
	end
end

function Stuffing:BagFrameSlotNew(slot, p)
	for _, v in ipairs(self.bagframe_buttons) do
		if v.slot == slot then
			return v, false
		end
	end

	local ret = {}

	if slot > 3 then
		ret.slot = slot
		slot = slot - 4
		ret.frame = CreateFrame("CheckButton", "StuffingBBag"..slot, p, "BankItemButtonBagTemplate")
		ret.frame:StripTextures()
		ret.frame:SetID(slot + 4)
		table.insert(self.bagframe_buttons, ret)

		BankFrameItemButton_Update(ret.frame)
		BankFrameItemButton_UpdateLocked(ret.frame)

		if not ret.frame.tooltipText then
			ret.frame.tooltipText = ""
		end
	else
		ret.frame = CreateFrame("CheckButton", "StuffingFBag"..slot.."Slot", p, "BagSlotButtonTemplate")
		ret.frame:StripTextures()
		ret.slot = slot
		table.insert(self.bagframe_buttons, ret)
	end

	ret.frame:CreateBackdrop(2)
	ret.frame:SetNormalTexture("")
	ret.frame:SetCheckedTexture("")

	ret.icon = _G[ret.frame:GetName().."IconTexture"]
	ret.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	ret.icon:SetPoint("TOPLEFT", ret.frame, 2, -2)
	ret.icon:SetPoint("BOTTOMRIGHT", ret.frame, -2, 2)

	return ret
end

function Stuffing:SlotNew(bag, slot)
	for _, v in ipairs(self.buttons) do
		if v.bag == bag and v.slot == slot then
			v.lock = false
			return v, false
		end
	end

	local tpl = "ContainerFrameItemButtonTemplate"

	if bag == -1 then
		tpl = "BankItemButtonGenericTemplate"
	end

	local ret = {}

	if #trashButton > 0 then
		local f = -1
		for i, v in ipairs(trashButton) do
			local b, s = v:GetName():match("(%d+)_(%d+)")

			b = tonumber(b)
			s = tonumber(s)

			if b == bag and s == slot then
				f = i
				break
			else
				v:Hide()
			end
		end

		if f ~= -1 then
			ret.frame = trashButton[f]
			table.remove(trashButton, f)
			ret.frame:Show()
		end
	end

	if not ret.frame then
		ret.frame = CreateFrame("Button", "StuffingBag"..bag.."_"..slot, self.bags[bag], tpl)

		local c = _G[ret.frame:GetName().."Count"]
		c:SetFont(C.Media.Font, C.Media.Font_Size, C.Media.Font_Style)
		c:SetPoint("BOTTOMRIGHT", 1, 1)
	end

	if 1 == 1 and not ret.Glow then
		-- from carg.bags_Aurora
		local glow = ret.frame:CreateTexture(nil, "OVERLAY")
		glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
		glow:SetBlendMode("ADD")
		glow:SetAlpha(.8)
		glow:SetPoint("CENTER", ret.frame)
		ret.Glow = glow
	end

	ret.bag = bag
	ret.slot = slot
	ret.frame:SetID(slot)

	ret.cooldown = _G[ret.frame:GetName().."Cooldown"]
	ret.cooldown:SetInside()
	ret.cooldown:Show()

	self:SlotUpdate(ret)

	return ret, true
end

-- from OneBag
local BAGTYPE_QUIVER = 0x0001 + 0x0002
local BAGTYPE_SOUL = 0x004
local BAGTYPE_PROFESSION = 0x0008 + 0x0010 + 0x0020 + 0x0040 + 0x0080 + 0x0200 + 0x0400

function Stuffing:BagType(bag)
	local bagType = select(2, GetContainerNumFreeSlots(bag))

	if bagType and bit.band(bagType, BAGTYPE_QUIVER) > 0 then
		return ST_QUIVER
	elseif bagType and bit.band(bagType, BAGTYPE_SOUL) > 0 then
		return ST_SOULBAG
	elseif bagType and bit.band(bagType, BAGTYPE_PROFESSION) > 0 then
		return ST_SPECIAL
	end

	return ST_NORMAL
end

function Stuffing:BagNew(bag, f)
	for i, v in pairs(self.bags) do
		if v:GetID() == bag then
			v.bagType = self:BagType(bag)
			return v
		end
	end

	local ret

	if #trashBag > 0 then
		local f = -1
		for i, v in pairs(trashBag) do
			if v:GetID() == bag then
				f = i
				break
			end
		end

		if f ~= -1 then
			ret = trashBag[f]
			table.remove(trashBag, f)
			ret:Show()
			ret.bagType = self:BagType(bag)
			return ret
		end
	end

	ret = CreateFrame("Frame", "StuffingBag"..bag, f)
	ret.bagType = self:BagType(bag)

	ret:SetID(bag)
	return ret
end

function Stuffing:SearchUpdate(str)
	str = string.lower(str)

	for _, b in ipairs(self.buttons) do
		if b.frame and not b.name then
			b.frame:SetAlpha(0.2)
			SetItemButtonDesaturated(b.frame, true)
		end
		if b.name then
			local ilink = GetContainerItemLink(b.bag, b.slot)
			if ilink then
				local name, _, _, _, minLevel, _, _, _, equipSlot = GetItemInfo(ilink)
				if name then
					equipSlot = (equipSlot and _G[equipSlot]) or ""

					local match = string.find(string.lower(b.name), str) or string.find(string.lower(equipSlot), str)

					if not match then
						if minLevel and minLevel > K.Level then
							_G[b.frame:GetName().."IconTexture"]:SetVertexColor(0.5, 0.5, 0.5)
						end
						SetItemButtonDesaturated(b.frame, true)
						b.frame:SetAlpha(0.2)
						if b.Glow then b.Glow:Hide() end
					else
						if minLevel and minLevel > K.Level then
							_G[b.frame:GetName().."IconTexture"]:SetVertexColor(1, 0.1, 0.1)
						end
						SetItemButtonDesaturated(b.frame, false)
						b.frame:SetAlpha(1)
						if b.Glow then
							b.Glow:Show()
							b.Glow:SetVertexColor(0.8, 0.8, 0.3)
						end
					end
				end
			end
		end
	end
end

function Stuffing:SearchReset()
	for _, b in ipairs(self.buttons) do
		if (b.level and b.level > K.Level) then
			_G[b.frame:GetName().."IconTexture"]:SetVertexColor(1, 0.1, 0.1)
		end
		b.frame:SetAlpha(1)
		SetItemButtonDesaturated(b.frame, false)
	end
end

-- Drop down menu stuff from Postal
local Stuffing_DDMenu = CreateFrame("Frame", "StuffingDropDownMenu")
Stuffing_DDMenu.displayMode = "MENU"
Stuffing_DDMenu.info = {}
Stuffing_DDMenu.HideMenu = function()
	if UIDROPDOWNMENU_OPEN_MENU == Stuffing_DDMenu then
		CloseDropDownMenus()
	end
end

local function DragFunction(self, mode)
	for index = 1, select("#", self:GetChildren()) do
		local frame = select(index, self:GetChildren())
		if frame:GetName() and frame:GetName():match("StuffingBag") then
			if mode then
				frame:Hide()
			else
				frame:Show()
			end
		end
	end
end

function Stuffing:CreateBagFrame(w)
	local n = "StuffingFrame" .. w
	local f = CreateFrame("Frame", n, UIParent)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:SetFrameStrata("HIGH")
	f:SetFrameLevel(5)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self)
		self:StartMoving()
		DragFunction(self, true)
	end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		DragFunction(self, false)
		self:SetUserPlaced(true)
	end)

	if w == "Bank" then
		f:SetPoint(unpack(C.Position.Bank))
	else
		f:SetPoint(unpack(C.Position.Bag))
	end

	if w == "Bank" then
		-- Buy button
		f.b_purchase = CreateFrame("Button", "StuffingPurchaseButton"..w, f)
		f.b_purchase:SetSize(80, 20)
		f.b_purchase:SetPoint("TOPLEFT", 10, -4)
		f.b_purchase:RegisterForClicks("AnyUp")
		-- Define custom popup to avoid Blizzard's MoneyFrame nil error in 3.3.5/Ascension
		if not StaticPopupDialogs["BUDSUI_BUY_BANK_SLOT"] then
			StaticPopupDialogs["BUDSUI_BUY_BANK_SLOT"] = {
				text = CONFIRM_BUY_BANK_SLOT,
				button1 = YES,
				button2 = NO,
				OnAccept = function()
					PurchaseSlot()
				end,
				OnShow = function(self)
					MoneyFrame_Update(self:GetName().."MoneyFrame", GetBankSlotCost() or 0)
				end,
				hasMoneyFrame = 1,
				timeout = 0,
				hideOnEscape = 1,
				preferredIndex = 3,
			}
		end

		f.b_purchase:SetScript("OnClick", function(self)
			if GetNumBankSlots() >= 7 then return end
			StaticPopup_Show("BUDSUI_BUY_BANK_SLOT")
		end)
		f.b_purchase:FontString("text", C.Media.Font, C.Media.Font_Size, C.Media.Font_Style)
		f.b_purchase.text:SetPoint("CENTER")
		f.b_purchase.text:SetText("|cff388bdb"..BANKSLOTPURCHASE.."|r")
		f.b_purchase:SetFontString(f.b_purchase.text)
		local _, full = GetNumBankSlots()
		if full then
			f.b_purchase:Hide()
		else
			f.b_purchase:Show()
		end
	end

	-- close button
	f.b_close = CreateFrame("Button", "Stuffing_CloseButton"..w, f, "UIPanelCloseButton")
	f.b_close:SetSize(32, 32)
	f.b_close:RegisterForClicks("AnyUp")
	f.b_close:SetPoint("TOPRIGHT", -3, -3)
	f.b_close:SetScript("OnClick", function(self, btn)
		if btn == "RightButton" then
			if Stuffing_DDMenu.initialize ~= Stuffing.Menu then
				CloseDropDownMenus()
				Stuffing_DDMenu.initialize = Stuffing.Menu
			end
			ToggleDropDownMenu(nil, nil, Stuffing_DDMenu, self:GetName(), 0, 0)
			return
		end
		self:GetParent():Hide()
	end)

	local tooltip_hide = function()
		GameTooltip:Hide()
	end

	local tooltip_show = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT", 19, 7)
		GameTooltip:ClearLines()
		GameTooltip:SetText(L_BAG_RIGHT_CLICK_CLOSE)
	end

	f.b_close:HookScript("OnEnter", tooltip_show)
	f.b_close:HookScript("OnLeave", tooltip_hide)

	-- create the bags frame
	local fb = CreateFrame("Frame", n.."BagsFrame", f)
	fb:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 3)
	fb:SetFrameStrata("MEDIUM")
	f.bags_frame = fb

	return f
end

-- Slash commands for Bags
SlashCmdList["STUFFING_BAGS"] = function(msg)
	msg = msg and string.lower(msg)
	if msg == "purchase yes" then
		if not Stuffing.bankFrame or not Stuffing.bankFrame:IsShown() then
			K.Print(L_BAG_OPEN_BANK)
			return
		end
		local _, full = GetNumBankSlots()
		if full then
			K.Print(L_BAG_NO_SLOTS)
			return
		end
		PurchaseSlot()
	else
		K.Print(L_BAG_BUY_SLOTS)
	end
end
SLASH_STUFFING_BAGS1 = "/bags"

function Stuffing:InitBank()
	if self.bankFrame then
		return
	end

	local f = self:CreateBagFrame("Bank")
	f:SetScript("OnHide", StuffingBank_OnHide)
	self.bankFrame = f
end

function Stuffing:InitBags()
	if self.frame then return end

	self.buttons = {}
	self.bags = {}
	self.bagframe_buttons = {}

	local f = self:CreateBagFrame("Bags")
	f:SetScript("OnShow", Stuffing_OnShow)
	f:SetScript("OnHide", Stuffing_OnHide)

	-- search editbox(tekKonfigAboutPanel.lua)
	local editbox = CreateFrame("EditBox", nil, f)
	editbox:Hide()
	editbox:SetAutoFocus(true)
	editbox:SetHeight(32)

	local left = editbox:CreateTexture(nil, "BACKGROUND")
	left:SetSize(8, 20)
	left:SetPoint("LEFT", -5, 0)
	left:SetTexture("Interface\\Common\\Common-Input-Border")
	left:SetTexCoord(0, 0.0625, 0, 0.625)

	local right = editbox:CreateTexture(nil, "BACKGROUND")
	right:SetSize(8, 20)
	right:SetPoint("RIGHT", 0, 0)
	right:SetTexture("Interface\\Common\\Common-Input-Border")
	right:SetTexCoord(0.9375, 1, 0, 0.625)

	local center = editbox:CreateTexture(nil, "BACKGROUND")
	center:SetHeight(20)
	center:SetPoint("RIGHT", right, "LEFT", 0, 0)
	center:SetPoint("LEFT", left, "RIGHT", 0, 0)
	center:SetTexture("Interface\\Common\\Common-Input-Border")
	center:SetTexCoord(0.0625, 0.9375, 0, 0.625)

	local resetAndClear = function(self)
		self:GetParent().detail:Show()
		self:GetParent().gold:Show()
		self:ClearFocus()
		Stuffing:SearchReset()
	end

	local updateSearch = function(self, t)
		if t == true then
			Stuffing:SearchUpdate(self:GetText())
		end
	end

	editbox:SetScript("OnEscapePressed", resetAndClear)
	editbox:SetScript("OnEnterPressed", resetAndClear)
	editbox:SetScript("OnEditFocusLost", editbox.Hide)
	editbox:SetScript("OnEditFocusGained", editbox.HighlightText)
	editbox:SetScript("OnTextChanged", updateSearch)
	editbox:SetText(SEARCH)

	local detail = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
	detail:SetPoint("TOPLEFT", f, 11, -10)
	detail:SetPoint("RIGHT", f, -140, -10)
	detail:SetHeight(13)
	detail:SetJustifyH("LEFT")
	detail:SetText("|cff388bdb"..SEARCH.."|r")
	editbox:SetAllPoints(detail)

	local gold = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
	gold:SetJustifyH("RIGHT")
	gold:SetPoint("RIGHT", f.b_close, "LEFT", -10, 0)

	f:SetScript("OnEvent", function(self)
		self.gold:SetText(K.FormatMoney(GetMoney()))
	end)
	f:RegisterEvent("PLAYER_MONEY")
	f:RegisterEvent("PLAYER_LOGIN")
	f:RegisterEvent("PLAYER_TRADE_MONEY")
	f:RegisterEvent("TRADE_MONEY_CHANGED")

	local OpenEditbox = function(self)
		self:GetParent().detail:Hide()
		self:GetParent().gold:Hide()
		self:GetParent().editbox:Show()
		self:GetParent().editbox:HighlightText()
	end

	local button = CreateFrame("Button", nil, f)
	button:EnableMouse(1)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:SetAllPoints(detail)
	button:SetScript("OnClick", function(self, btn)
		if btn == "RightButton" then
			OpenEditbox(self)
		else
			if self:GetParent().editbox:IsShown() then
				self:GetParent().editbox:Hide()
				self:GetParent().editbox:ClearFocus()
				self:GetParent().detail:Show()
				self:GetParent().gold:Show()
				Stuffing:SearchReset()
			end
		end
	end)

	local tooltip_hide = function()
		GameTooltip:Hide()
	end

	local tooltip_show = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", -12, 11)
		GameTooltip:ClearLines()
		GameTooltip:SetText(L_BAG_RIGHT_CLICK_SEARCH)
	end

	button:SetScript("OnEnter", tooltip_show)
	button:SetScript("OnLeave", tooltip_hide)

	f.editbox = editbox
	f.detail = detail
	f.button = button
	f.gold = gold
	self.frame = f
	f:Hide()
end

function Stuffing:Layout(lb)
	local slots = 0
	local rows = 0
	local off = 26
	local cols, f, bs

	if lb then
		bs = BAGS_BANK
		cols = C.Bag.BankColumns
		f = self.bankFrame
		f:SetAlpha(1)
	else
		bs = BAGS_BACKPACK
		if show_keyring == 1 then
			bs = {0, 1, 2, 3, 4, -2}
		end
		cols = C.Bag.BagColumns
		f = self.frame

		f.gold:SetText(K.FormatMoney(GetMoney(), C.Media.Font_Size))
		f.editbox:SetFont(C.Media.Font, C.Media.Font_Size, C.Media.Font_Style)
		f.detail:SetFont(C.Media.Font, C.Media.Font_Size, C.Media.Font_Style)
		f.gold:SetFont(C.Media.Font, C.Media.Font_Size, C.Media.Font_Style)

		f.detail:ClearAllPoints()
		f.detail:SetPoint("TOPLEFT", f, 12, -8)
		f.detail:SetPoint("RIGHT", f, -140, 0)
	end

	-- Hide all existing buttons for this frame before re-layouting
	for _, v in ipairs(self.buttons) do
		if (lb and (v.bag == -1 or v.bag >= 5)) or (not lb and (v.bag == -2 or (v.bag >= 0 and v.bag <= 4))) then
			v.frame:Hide()
		end
	end

	f:SetClampedToScreen(1)
	f:SetBackdrop(K.Backdrop)
	f:SetBackdropColor(unpack(C.Media.Backdrop_Color))
	f:SetBackdropBorderColor(unpack(C.Media.Border_Color))

	-- bag frame stuff
	local fb = f.bags_frame
	if bag_bars == 1 then
		fb:SetClampedToScreen(1)
		fb:SetBackdrop(K.Backdrop)
		fb:SetBackdropColor(unpack(C.Media.Backdrop_Color))
		fb:SetBackdropBorderColor(unpack(C.Media.Border_Color))

		local bsize = C.Bag.ButtonSize

		local w = 2 * 10
		w = w +((#bs - 1) * bsize)
		w = w +((#bs - 2) * 4)

		fb:SetHeight(2 * 10 + bsize)
		fb:SetWidth(w)
		fb:Show()
	else
		fb:Hide()
	end

	local idx = 0
	for _, v in ipairs(bs) do
		if(not lb and v >= 0 and v <= 3) or(lb and v ~= -1) then
			local bsize = C.Bag.ButtonSize
			local b = self:BagFrameSlotNew(v, fb)
			local xoff = 10

			xoff = xoff +(idx * bsize) -- 31)
			xoff = xoff +(idx * 4)

			b.frame:ClearAllPoints()
			b.frame:SetPoint("LEFT", fb, "LEFT", xoff, 0)
			b.frame:SetSize(bsize, bsize)

			-- Lets see what bag we are hovering over.
			local btns = self.buttons
			b.frame:HookScript("OnEnter", function(self)
				local bag
				if isBank then bag = v else bag = v + 1 end

				for ind, val in ipairs(btns) do
					if val.bag == bag then
						val.frame:SetAlpha(1)
					else
						val.frame:SetAlpha(0.2)
					end
				end
			end)

			b.frame:HookScript("OnLeave", function(self)
				for _, btn in ipairs(btns) do
					btn.frame:SetAlpha(1)
				end
			end)

			b.frame:SetScript("OnClick", nil)

			idx = idx + 1
		end
	end

	for _, i in ipairs(bs) do
		local x = GetContainerNumSlots(i)
		if x > 0 then
			if not self.bags[i] then
				self.bags[i] = self:BagNew(i, f)
			end

			if not (hide_soulbag == true and self.bags[i].bagType == ST_SOULBAG) then
				slots = slots + GetContainerNumSlots(i)
			end
		end
	end

	rows = floor(slots / cols)
	if(slots % cols) ~= 0 then
		rows = rows + 1
	end

	f:SetWidth(cols * C.Bag.ButtonSize +(cols - 1) * C.Bag.ButtonSpace + 10 * 2)
	f:SetHeight(rows * C.Bag.ButtonSize +(rows - 1) * C.Bag.ButtonSpace + off + 10 * 2)

	local idx = 0
	for _, i in ipairs(bs) do
		local bag_cnt = GetContainerNumSlots(i)
		local specialType = select(2, GetContainerNumFreeSlots(i))
		if bag_cnt > 0 then
			self.bags[i] = self:BagNew(i, f)
			local bagType = self.bags[i].bagType

			if not (hide_soulbag == true and bagType == ST_SOULBAG) then
				self.bags[i]:Show()
				for j = 1, bag_cnt do
					local b, isnew = self:SlotNew(i, j)
					local xoff
					local yoff
					local x =(idx % cols)
					local y = floor(idx / cols)

					if isnew then
						table.insert(self.buttons, idx + 1, b)
					end

					xoff = 10 +(x * C.Bag.ButtonSize) +(x * C.Bag.ButtonSpace)
					yoff = off + 10 +(y * C.Bag.ButtonSize) +((y - 1) * C.Bag.ButtonSpace)
					yoff = yoff * -1

					b.frame:ClearAllPoints()
					b.frame:SetPoint("TOPLEFT", f, "TOPLEFT", xoff, yoff)
					b.frame:SetSize(C.Bag.ButtonSize, C.Bag.ButtonSize)
					b.frame:Show()
					
					b.frame:StyleButton(true)
					b.frame.lock = false
					b.frame:SetAlpha(1)

					local normalTex = _G[b.frame:GetName() .. "NormalTexture"]
					normalTex:SetSize(C.Bag.ButtonSize / 37 * 64, C.Bag.ButtonSize / 37 * 64)
					b.normalTex = normalTex

					b.frame:SetBackdrop{bgFile = C.Media.Blank, insets = {left = 1, right = 1, top = 1, bottom = 1}}
					b.frame:SetBackdropColor(unpack(C.Media.Backdrop_Color))

					if bagType == ST_QUIVER then
						normalTex:SetVertexColor(0.8, 0.8, 0.2)
						b.frame.lock = true
					elseif bagType == ST_SOULBAG then
						normalTex:SetVertexColor(0.8, 0.2, 0.2)
						b.frame.lock = true
					elseif bagType == ST_NORMAL then
						normalTex:SetVertexColor(unpack(C.Media.Border_Color))
					elseif bagType == ST_SPECIAL then
						if specialType == 0x0008 then -- Leatherworking
							normalTex:SetVertexColor(0.8, 0.7, 0.3)
							b.frame.lock = true
						elseif specialType == 0x0010 then -- Inscription
							normalTex:SetVertexColor(0.3, 0.3, 0.8)
						elseif specialType == 0x0020 then -- Herbs
							normalTex:SetVertexColor(0.3, 0.7, 0.3)
						elseif specialType == 0x0040 then -- Enchanting
							normalTex:SetVertexColor(0.6, 0, 0.6)
						elseif specialType == 0x0080 then -- Engineering
							normalTex:SetVertexColor(0.9, 0.4, 0.1)
						elseif specialType == 0x0200 then -- Gems
							normalTex:SetVertexColor(0, 0.7, 0.8)
						elseif specialType == 0x0400 then -- Mining
							normalTex:SetVertexColor(0.4, 0.3, 0.1)
						end
						b.frame.lock = true
					end

					local iconTex = _G[b.frame:GetName() .. "IconTexture"]

					iconTex:Show()
					b.iconTex = iconTex

					if b.Glow then
						b.Glow:SetSize(C.Bag.ButtonSize / 37 * 64, C.Bag.ButtonSize / 37 * 64)
					end

					idx = idx + 1
				end
			end
		end
	end
end

local function Stuffing_Sort(args)
	if not args then
		args = ""
	end

	Stuffing.itmax = 0
	Stuffing:SetBagsForSorting(args)
	Stuffing:SortBags()
end

function Stuffing:SetBagsForSorting(c)
	Stuffing_Open()

	self.sortBags = {}

	local cmd = ((c == nil or c == "") and {"d"} or {strsplit("/", c)})

	for _, s in ipairs(cmd) do
		if s == "c" then
			self.sortBags = {}
		elseif s == "d" then
			if not self.bankFrame or not self.bankFrame:IsShown() then
				for _, i in ipairs(BAGS_BACKPACK) do
					if self.bags[i] and self.bags[i].bagType == ST_NORMAL then
						table.insert(self.sortBags, i)
					end
				end
			else
				for _, i in ipairs(BAGS_BANK) do
					if self.bags[i] and self.bags[i].bagType == ST_NORMAL then
						table.insert(self.sortBags, i)
					end
				end
			end
		elseif s == "p" then
			if not self.bankFrame or not self.bankFrame:IsShown() then
				for _, i in ipairs(BAGS_BACKPACK) do
					if self.bags[i] and self.bags[i].bagType == ST_SPECIAL then
						table.insert(self.sortBags, i)
					end
				end
			else
				for _, i in ipairs(BAGS_BANK) do
					if self.bags[i] and self.bags[i].bagType == ST_SPECIAL then
						table.insert(self.sortBags, i)
					end
				end
			end
		else
			if tonumber(s) == nil then
				K.Print(string.format(L["Error: don't know what \"%s\" means."], s))
			end

			table.insert(self.sortBags, tonumber(s))
		end
	end
end

function Stuffing:ADDON_LOADED(addon)
	if addon ~= "budsUI" then return nil end

	self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("ITEM_LOCK_CHANGED")
	self:RegisterEvent("BANKFRAME_OPENED")
	self:RegisterEvent("BANKFRAME_CLOSED")
	self:RegisterEvent("GUILDBANKFRAME_OPENED")
	self:RegisterEvent("GUILDBANKFRAME_CLOSED")
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	self:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED")
	self:RegisterEvent("BAG_CLOSED")
	self:RegisterEvent("BAG_UPDATE_COOLDOWN")

	self:InitBags()

	tinsert(UISpecialFrames, "StuffingFrameBags")

	-- hook functions
	ToggleBackpack = Stuffing_Toggle
	ToggleBag = Stuffing_ToggleBag
	ToggleAllBags = Stuffing_Toggle
	ToggleKeyRing = function() Stuffing_ToggleBag(-2) end
	OpenAllBags = Stuffing_Open
	OpenBackpack = Stuffing_Open
	CloseAllBags = Stuffing_Close
	CloseBackpack = Stuffing_Close

	--BankFrame:SetScale(0.00001)
	--BankFrame:SetAlpha(0)
	--BankFrame:SetPoint("TOPLEFT")
	BankFrame:UnregisterAllEvents()

	for i = 1, NUM_CONTAINER_FRAMES do
		_G['ContainerFrame'..i]:Kill()
	end
end

function Stuffing:PLAYER_ENTERING_WORLD()
	Stuffing:UnregisterEvent("PLAYER_ENTERING_WORLD")
	ToggleBackpack()
	ToggleBackpack()
end

function Stuffing:PLAYERBANKSLOTS_CHANGED(id)
	if id > 28 then
		for _, v in ipairs(self.bagframe_buttons) do
			if v.frame and v.frame.GetInventorySlot then

				BankFrameItemButton_Update(v.frame)
				BankFrameItemButton_UpdateLocked(v.frame)

				if not v.frame.tooltipText then
					v.frame.tooltipText = ""
				end
			end
		end
	end

	if self.bankFrame and self.bankFrame:IsShown() then
		self:BagSlotUpdate(-1)
	end
end

function Stuffing:BAG_UPDATE(id)
	self:BagSlotUpdate(id)
end

function Stuffing:ITEM_LOCK_CHANGED(bag, slot)
	if slot == nil then return end
	for _, v in ipairs(self.buttons) do
		if v.bag == bag and v.slot == slot then
			self:SlotUpdate(v)
			break
		end
	end
end

function Stuffing:BANKFRAME_OPENED()
	if not self.bankFrame then
		self:InitBank()
	end

	self:Layout(true)
	for _, x in ipairs(BAGS_BANK) do
		self:BagSlotUpdate(x)
	end

	self.bankFrame:Show()
	Stuffing_Open()
end

function Stuffing:BANKFRAME_CLOSED()
	if not self.bankFrame then
		return
	end

	self.bankFrame:Hide()
end

function Stuffing:GUILDBANKFRAME_OPENED()
	Stuffing_Open()
end

function Stuffing:GUILDBANKFRAME_CLOSED()
	Stuffing_Close()
end

function Stuffing:BAG_CLOSED(id)
	local b = self.bags[id]
	if b then
		table.remove(self.bags, id)
		b:Hide()
		if #trashBag < FRAME_POOL_MAX_SIZE then
			table.insert(trashBag, #trashBag + 1, b)
		end
	end

	-- Reverse iteration: safe to table.remove without skipping elements
	for i = #self.buttons, 1, -1 do
		local v = self.buttons[i]
		if v.bag == id then
			-- Clean up scripts and cooldowns before recycling
			v.frame:SetScript("OnUpdate", nil)
			v.frame:SetScript("OnEnter", nil)
			v.frame:SetScript("OnLeave", nil)
			if v.cooldown then
				v.cooldown:Hide()
			end

			v.frame:Hide()
			v.frame.lock = false

			if #trashButton < FRAME_POOL_MAX_SIZE then
				table.insert(trashButton, #trashButton + 1, v.frame)
			end
			table.remove(self.buttons, i)
		end
	end
end

function Stuffing:BAG_UPDATE_COOLDOWN()
	for i, v in pairs(self.buttons) do
		self:SlotUpdate(v)
	end
end

function Stuffing:SortOnUpdate(e)
	if not self.elapsed then
		self.elapsed = 0
	end

	if not self.itmax then
		self.itmax = 0
	end

	self.elapsed = self.elapsed + e

	if self.elapsed < 0.1 then
		return
	end

	self.elapsed = 0
	self.itmax = self.itmax + 1

	local changed, blocked = false, false

	if self.sortList == nil or next(self.sortList, nil) == nil then
		-- Wait for all item locks to be released
		local locks = false

		for i, v in pairs(self.buttons) do
			local _, _, l = GetContainerItemInfo(v.bag, v.slot)
			if l then
				locks = true
			else
				v.block = false
			end
		end

		if locks then
			-- Something still locked
			return
		else
			-- All unlocked. get a new table
			self:SetScript("OnUpdate", nil)
			self:SortBags()

			if self.sortList == nil then
				return
			end
		end
	end

	-- Go through the list and move stuff if we can
	for i, v in ipairs(self.sortList) do
		repeat
			if v.ignore then
				blocked = true
				break
			end

			if v.srcSlot.block then
				changed = true
				break
			end

			if v.dstSlot.block then
				changed = true
				break
			end

			local _, _, l1 = GetContainerItemInfo(v.dstSlot.bag, v.dstSlot.slot)
			local _, _, l2 = GetContainerItemInfo(v.srcSlot.bag, v.srcSlot.slot)

			if l1 then
				v.dstSlot.block = true
			end

			if l2 then
				v.srcSlot.block = true
			end

			if l1 or l2 then
				break
			end

			if v.sbag ~= v.dbag or v.sslot ~= v.dslot then
				if v.srcSlot.name ~= v.dstSlot.name then
					v.srcSlot.block = true
					v.dstSlot.block = true
					PickupContainerItem(v.sbag, v.sslot)
					PickupContainerItem(v.dbag, v.dslot)
					changed = true
					break
				end
			end
		until true
	end

	self.sortList = nil

	if (not changed and not blocked) or self.itmax > SORT_MAX_ITERATIONS then
		if self.itmax > SORT_MAX_ITERATIONS then
			K.Print("|cffffe02eBags: Sort timed out after " .. SORT_MAX_ITERATIONS .. " iterations.|r")
		end
		self:SetScript("OnUpdate", nil)
		self.sortList = nil
	end
end

local function InBags(x)
	if not Stuffing.bags[x] then
		return false
	end

	for _, v in ipairs(Stuffing.sortBags) do
		if x == v then
			return true
		end
	end
	return false
end

function Stuffing:SortBags()
	local free
	local total = 0
	local bagtypeforfree

	if StuffingFrameBank and StuffingFrameBank:IsShown() then
		for i = 5, 11 do
			free, bagtypeforfree = GetContainerNumFreeSlots(i)
			if bagtypeforfree == 0 then
				total = free + total
			end
		end
		total = GetContainerNumFreeSlots(-1) + total
	else
		for i = 0, 4 do
			free, bagtypeforfree = GetContainerNumFreeSlots(i)
			if bagtypeforfree == 0 then
				total = free + total
			end
		end
	end

	if total == 0 then
		print("|cfff02c35"..ERROR_CAPS.." - "..ERR_INV_FULL.."|r")
		return
	end

	local bs = self.sortBags
	if #bs < 1 then
		return
	end

	local st = {}
	local bank = false

	Stuffing_Open()

	for i, v in pairs(self.buttons) do
		if InBags(v.bag) then
			self:SlotUpdate(v)

			if v.name then
				local _, cnt, _, _, _, _, clink = GetContainerItemInfo(v.bag, v.slot)
				if clink then
					local n, _, q, iL, rL, c1, c2, _, Sl = GetItemInfo(clink)
					if n then
						if n == GetItemInfo(HEARTHSTONE_ID) then c1 = "1" end
						table.insert(st, {srcSlot = v, sslot = v.slot, sbag = v.bag, sort = q..c1..c2..rL..n..iL..Sl..(#self.buttons - i)})
					end
				end
			end
		end
	end

	-- Sort them
	table.sort(st, function(a, b)
		return a.sort > b.sort
	end)

	-- For each button we want to sort, get a destination button
	local st_idx = #bs
	local dbag = bs[st_idx]
	local dslot = GetContainerNumSlots(dbag)

	for i, v in ipairs(st) do
		v.dbag = dbag
		v.dslot = dslot
		v.dstSlot = self:SlotNew(dbag, dslot)

		dslot = dslot - 1

		if dslot == 0 then
			while true do
				st_idx = st_idx - 1

				if st_idx < 0 then
					break
				end

				dbag = bs[st_idx]

				if Stuffing:BagType(dbag) == ST_NORMAL or Stuffing:BagType(dbag) == ST_SPECIAL or dbag < 1 then
					break
				end
			end

			dslot = GetContainerNumSlots(dbag)
		end
	end

	-- Throw various stuff out of the search list
	-- Optimized: iterate backwards to avoid index shifting issues
	for i = #st, 1, -1 do
		local v = st[i]
		-- Source is same as destination
		if (v.sslot == v.dslot) and (v.sbag == v.dbag) then
			table.remove(st, i)
		end
	end

	-- Kick off moving of stuff, if needed
	if st == nil or next(st, nil) == nil then
		self:SetScript("OnUpdate", nil)
	else
		self.sortList = st
		self:SetScript("OnUpdate", Stuffing.SortOnUpdate)
	end
end

function Stuffing:RestackOnUpdate(e)
	if not self.elapsed then
		self.elapsed = 0
	end

	self.elapsed = self.elapsed + e

	if self.elapsed < 0.1 then return end

	self.elapsed = 0
	self:Restack()
end

function Stuffing:Restack()
	local st = {}

	Stuffing_Open()

	for i, v in pairs(self.buttons) do
		if InBags(v.bag) then
			local _, cnt, _, _, _, _, clink = GetContainerItemInfo(v.bag, v.slot)
			if clink then
				local n, _, _, _, _, _, _, s = GetItemInfo(clink)

				if n and cnt ~= s then
					if not st[n] then
						st[n] = {{item = v, size = cnt, max = s}}
					else
						table.insert(st[n], {item = v, size = cnt, max = s})
					end
				end
			end
		end
	end

	local did_restack = false

	for i, v in pairs(st) do
		if #v > 1 then
			for j = 2, #v, 2 do
				local a, b = v[j - 1], v[j]
				local _, _, l1 = GetContainerItemInfo(a.item.bag, a.item.slot)
				local _, _, l2 = GetContainerItemInfo(b.item.bag, b.item.slot)

				if l1 or l2 then
					did_restack = true
				else
					PickupContainerItem(a.item.bag, a.item.slot)
					PickupContainerItem(b.item.bag, b.item.slot)
					did_restack = true
				end
			end
		end
	end

	if did_restack then
		self:SetScript("OnUpdate", Stuffing.RestackOnUpdate)
	else
		self:SetScript("OnUpdate", nil)
	end
end

function Stuffing:PLAYERBANKBAGSLOTS_CHANGED()
	if not StuffingPurchaseButtonBank then return end
	local _, full = GetNumBankSlots()
	if full then
		StuffingPurchaseButtonBank:Hide()
	else
		StuffingPurchaseButtonBank:Show()
	end
end

function Stuffing.Menu(self, level)
	if not level then
		return
	end

	local info = self.info

	wipe(info)

	if level ~= 1 then
		return
	end

	wipe(info)
	info.text = L_BAG_SORT_MENU
	info.notCheckable = 1
	info.func = function()
		if InCombatLockdown() or UnitIsDeadOrGhost("player") then
			K.Print("|cffffe02e"..L_ERR_NOT_IN_COMBAT.."|r") return
		end
		Stuffing_Sort("d")
	end
	UIDropDownMenu_AddButton(info, level)

	wipe(info)
	info.text = L_BAG_STACK_MENU
	info.notCheckable = 1
	info.func = function()
		if InCombatLockdown() or UnitIsDeadOrGhost("player") then
			K.Print("|cffffe02e"..L_ERR_NOT_IN_COMBAT.."|r") return
		end
		Stuffing:SetBagsForSorting("d")
		Stuffing:Restack()
	end
	UIDropDownMenu_AddButton(info, level)

	wipe(info)
	info.text = L_BAG_SHOW_BAGS
	info.checked = function()
		return bag_bars == 1
	end

	info.func = function()
		if bag_bars == 1 then
			bag_bars = 0
		else
			bag_bars = 1
		end
		Stuffing:Layout()
		if Stuffing.bankFrame and Stuffing.bankFrame:IsShown() then
			Stuffing:Layout(true)
		end

	end
	UIDropDownMenu_AddButton(info, level)

	wipe(info)
	info.text = KEYRING
	info.checked = function()
		return show_keyring == 1
	end
	info.func = function()
		if show_keyring == 1 then
			show_keyring = 0
		else
			show_keyring = 1
		end
		Stuffing:Layout()
	end
	UIDropDownMenu_AddButton(info, level)

	wipe(info)
	info.disabled = nil
	info.notCheckable = 1
	info.text = CLOSE
	info.func = self.HideMenu
	info.tooltipTitle = CLOSE
	UIDropDownMenu_AddButton(info, level)
end