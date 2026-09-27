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

-- Hidden tooltip to detect BoE (3.3.5 has no bind-type API)
local bindTip = CreateFrame("GameTooltip", "budsUIBagBindTip", nil, "GameTooltipTemplate")
bindTip:SetOwner(UIParent, "ANCHOR_NONE")

local function IsBoE(bag, slot)
	bindTip:ClearLines()
	bindTip:SetBagItem(bag, slot)
	for i = 1, bindTip:NumLines() do
		local line = _G["budsUIBagBindTipTextLeft" .. i]
		if line and line:GetText() == ITEM_BIND_ON_EQUIP then
			return true
		end
	end
	return false
end

-- ElvUI-style eligibility: wearable gear only, no bags/tabards/ammo
local function IsEligible(rarity, equipLoc)
	if not rarity or rarity <= 1 then return false end
	if not equipLoc or equipLoc == "" then return false end
	return equipLoc ~= "INVTYPE_BAG" and equipLoc ~= "INVTYPE_TABARD"
		and equipLoc ~= "INVTYPE_AMMO" and equipLoc ~= "INVTYPE_QUIVER"
end

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

	if b.rarity then
		if b.rarity > 1 then
			b.frame:SetBackdropBorderColor(GetItemQualityColor(b.rarity))
		elseif b.qitem then
			b.frame:SetBackdropBorderColor(1, 1, 0)
		else
			b.frame:SetBackdropBorderColor(unpack(C.Media.Border_Color))
		end
	else
		b.frame:SetBackdropBorderColor(unpack(C.Media.Border_Color))
	end

	-- ElvUI-style: always clear texts first, then set conditionally,
	-- so no stale ilvl/bind stays on a reused cell.
	if b.ilvl then
		b.ilvl:SetText("")
	end
	if b.bindType then
		b.bindType:SetText("")
	end
	if C.Bag.ShowItemLevel and clink then
		local _, _, rarity, itemLevel, _, _, _, _, equipLoc = GetItemInfo(clink)
		if itemLevel and itemLevel > 1 and IsEligible(rarity, equipLoc) then
			if b.ilvl then
				local r, g, bl = GetItemQualityColor(rarity)
				b.ilvl:SetText(itemLevel)
				b.ilvl:SetTextColor(r, g, bl)
				if b.bindType and IsBoE(b.bag, b.slot) then
					b.bindType:SetText("BoE")
					b.bindType:SetTextColor(r, g, bl)
				end
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
			-- ElvUI-style: reused buttons must refresh, bag contents may have
			-- changed (e.g. bags swapped) while the (bag, slot) key stayed.
			self:SlotUpdate(v)
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

	-- Frames are recycled through trashButton (e.g. after swapping bags):
	-- reuse their texts instead of stacking new FontStrings, orphans would
	-- keep showing the stale ilvl on the cell.
	if ret.frame.ilvl then
		ret.ilvl = ret.frame.ilvl
	else
		local il = ret.frame:CreateFontString(nil, "OVERLAY")
		il:SetFont(C.Media.Font, C.Media.Font_Size, C.Media.Font_Style)
		il:SetPoint("TOP", ret.frame, "TOP", 0, -2)
		il:SetShadowColor(0, 0, 0)
		il:SetShadowOffset(1, -1)
		il:SetText("")
		ret.ilvl = il
		ret.frame.ilvl = il
	end

	if ret.frame.bindType then
		ret.bindType = ret.frame.bindType
	else
		local bt = ret.frame:CreateFontString(nil, "OVERLAY")
		bt:SetFont(C.Media.Font, C.Media.Font_Size, C.Media.Font_Style)
		bt:SetPoint("BOTTOMLEFT", ret.frame, "BOTTOMLEFT", 1, 1)
		bt:SetShadowColor(0, 0, 0)
		bt:SetShadowOffset(1, -1)
		bt:SetText("")
		ret.bindType = bt
		ret.frame.bindType = bt
	end

	if not ret.frame.BorderTextures then
		K.CreateBorder(ret.frame)
	end

	-- Texts above the border (same OVERLAY layer, higher sublevel)
	local cnt = _G[ret.frame:GetName() .. "Count"]
	if cnt and cnt.SetDrawLayer then cnt:SetDrawLayer("OVERLAY", 1) end
	if ret.ilvl and ret.ilvl.SetDrawLayer then ret.ilvl:SetDrawLayer("OVERLAY", 1) end
	if ret.bindType and ret.bindType.SetDrawLayer then ret.bindType:SetDrawLayer("OVERLAY", 1) end

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
						b.frame:SetBackdropBorderColor(unpack(C.Media.Border_Color))
					else
						if minLevel and minLevel > K.Level then
							_G[b.frame:GetName().."IconTexture"]:SetVertexColor(1, 0.1, 0.1)
						end
						SetItemButtonDesaturated(b.frame, false)
						b.frame:SetAlpha(1)
						b.frame:SetBackdropBorderColor(0.8, 0.8, 0.3)
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

	Stuffing:SetBagsForSorting(args)
	Stuffing:SortBags()
end

-- FrostAtomUI-style multi-phase bag sorting with reverse fill (start from end of bags)
local MOVES_PER_FRAME = 12
local MOVE_TIMEOUT = 2
local MAX_REPLANS = 5
local CACHE_RETRY_DELAY = 0.5
local MAX_CACHE_RETRIES = 6

local CLASS_ORDER = { 2, 1, 8, 3, 5, 6, 11, 12, 7, 4, 9, 10 }

local PINNED = {
	[6948] = 1, -- Hearthstone
}

local SLOT_ORDER = {
	INVTYPE_HEAD = 1,
	INVTYPE_NECK = 2,
	INVTYPE_SHOULDER = 3,
	INVTYPE_CLOAK = 4,
	INVTYPE_CHEST = 5,
	INVTYPE_ROBE = 5,
	INVTYPE_BODY = 6,
	INVTYPE_TABARD = 7,
	INVTYPE_WRIST = 8,
	INVTYPE_HAND = 9,
	INVTYPE_WAIST = 10,
	INVTYPE_LEGS = 11,
	INVTYPE_FEET = 12,
	INVTYPE_FINGER = 13,
	INVTYPE_TRINKET = 14,
	INVTYPE_2HWEAPON = 15,
	INVTYPE_WEAPONMAINHAND = 16,
	INVTYPE_WEAPON = 17,
	INVTYPE_WEAPONOFFHAND = 18,
	INVTYPE_SHIELD = 19,
	INVTYPE_HOLDABLE = 20,
	INVTYPE_RANGED = 21,
	INVTYPE_RANGEDRIGHT = 22,
	INVTYPE_THROWN = 23,
	INVTYPE_RELIC = 24,
	INVTYPE_AMMO = 25,
}

local ids, counts, maxStacks = {}, {}, {}
local itemOrder, itemFamilies = {}, {}
local moves = {}
local slots, sorted, sortedPosition, initialOrder = {}, {}, {}, {}
local targetItems, targetSlots, sourceUsed, emptySlots = {}, {}, {}, {}
local normalBags, specialtyBags, bagFamilies = {}, {}, {}
local typeOrder, subTypeOrder = {}, {}
local busy = {}
local activeFrame, waitingFrame
local replans = 0
local cacheRetries = 0
local reverseFill = false -- REVERSED: items sort first, destinations built from bottom-up
local uncached = false

local BAGS_BACKPACK_REV = {4, 3, 2, 1, 0} -- Reversed: start from bag 4 (bottom-right) to bag 0 (backpack)
local BAGS_BANK_REV = {11, 10, 9, 8, 7, 6, 5, -1} -- Reversed bank bags

local function slotKey(bag, slot)
	return bag * 100 + slot
end

local function decodeSlotKey(key)
	return floor(key / 100), key % 100
end

local function buildTypeOrder()
	local types = { GetAuctionItemClasses() }
	for i = 1, #types do
		local itemType = types[i]
		typeOrder[itemType] = CLASS_ORDER[i] or i
		local subOrder = {}
		subTypeOrder[itemType] = subOrder
		local subTypes = { GetAuctionItemSubClasses(i) }
		for j = 1, #subTypes do
			subOrder[subTypes[j]] = j
		end
	end
end

local function cacheItem(id)
	if itemOrder[id] then
		return
	end
	local name, _, quality, level, _, itemType, subType, _, equipLoc, _, price = GetItemInfo(id)
	if not name then
		uncached = true
	end
	local subOrder = subTypeOrder[itemType]
	itemOrder[id] = ("%d%02d%02d%02d%d%04d%02d%08d%s"):format(
		quality == 0 and 1 or 0,
		PINNED[id] or 99,
		typeOrder[itemType] or 99,
		SLOT_ORDER[equipLoc] or 99,
		9 - (quality or 0),
		9999 - (level or 0),
		subOrder and subOrder[subType] or 99,
		99999999 - (price or 0),
		name or ""
	)

	local family = GetItemFamily(id)
	if family and family > 0 and equipLoc == "INVTYPE_QUIVER" then
		family = 1
	end
	itemFamilies[id] = family
end

local function scanBags(bags)
	for i = 1, #bags do
		local bag = bags[i]
		local bagSlots = GetContainerNumSlots(bag)
		-- REVERSED: iterate slots from END to START
		for slot = bagSlots, 1, -1 do
			local id = GetContainerItemID(bag, slot)
			if id then
				local key = slotKey(bag, slot)
				local _, count = GetContainerItemInfo(bag, slot)
				local _, _, _, _, _, _, _, maxStack = GetItemInfo(id)
				ids[key] = id
				counts[key] = count or 1
				maxStacks[key] = maxStack or 1
				cacheItem(id)
			end
		end
	end
end

local function resetScan()
	wipe(ids)
	wipe(counts)
	wipe(maxStacks)
	wipe(itemOrder)
	wipe(itemFamilies)
	uncached = false
end

local function updateLocation(from, to)
	if ids[from] == ids[to] and counts[to] < maxStacks[to] then
		local stackSize = maxStacks[to]
		if counts[to] + counts[from] > stackSize then
			counts[from] = counts[from] - (stackSize - counts[to])
			counts[to] = stackSize
		else
			counts[to] = counts[to] + counts[from]
			ids[from], counts[from], maxStacks[from] = nil, nil, nil
		end
	else
		ids[from], ids[to] = ids[to], ids[from]
		counts[from], counts[to] = counts[to], counts[from]
		maxStacks[from], maxStacks[to] = maxStacks[to], maxStacks[from]
	end
end

local function addMove(from, to)
	updateLocation(from, to)
	moves[#moves + 1] = {
		from = from,
		to = to,
		fromId = ids[from] or false,
		toId = ids[to],
		toCount = counts[to],
	}
end

local function isSlotLocked(key)
	local bag, slot = decodeSlotKey(key)
	local _, _, locked = GetContainerItemInfo(bag, slot)
	return locked
end

local function stackItems(sourceBags, targetBags, partialOnly)
	for i = 1, #targetBags do
		local bag = targetBags[i]
		local bagSlots = GetContainerNumSlots(bag)
		for slot = 1, bagSlots do
			local key = slotKey(bag, slot)
			local id = ids[key]
			if id and counts[key] ~= maxStacks[key] and not isSlotLocked(key) then
				targetItems[id] = (targetItems[id] or 0) + 1
				targetSlots[#targetSlots + 1] = key
			end
		end
	end

	-- REVERSED: iterate source bags from END to START
	for b = #sourceBags, 1, -1 do
		local bag = sourceBags[b]
		local bagSlots = GetContainerNumSlots(bag)
		for slot = bagSlots, 1, -1 do
			local source = slotKey(bag, slot)
			local id = ids[source]
			if id and targetItems[id] and not isSlotLocked(source) and (not partialOnly or counts[source] < maxStacks[source]) then
				for i = #targetSlots, 1, -1 do
					local target = targetSlots[i]
					if not ids[source] or not targetItems[id] then
						break
					end
					if ids[target] == id and target ~= source and counts[target] ~= maxStacks[target] and not sourceUsed[target] then
						addMove(source, target)
						sourceUsed[source] = true
						if counts[target] == maxStacks[target] then
							targetItems[id] = targetItems[id] > 1 and targetItems[id] - 1 or nil
						end
					end
				end
			end
		end
	end

	wipe(targetItems)
	wipe(targetSlots)
	wipe(sourceUsed)
end

local function canGoInBag(id, bag)
	local itemFamily = itemFamilies[id]
	if not itemFamily then
		return false
	end
	local bagFamily = bagFamilies[bag]
	return bagFamily == 0 or bit.band(itemFamily, bagFamily) > 0
end

local function fillEmptySlots(sourceBags, targetBags)
	for i = 1, #targetBags do
		local bag = targetBags[i]
		local bagSlots = GetContainerNumSlots(bag)
		for slot = 1, bagSlots do
			local key = slotKey(bag, slot)
			if not ids[key] and not isSlotLocked(key) then
				emptySlots[#emptySlots + 1] = key
			end
		end
	end

	-- REVERSED: iterate source bags from END to START
	for b = #sourceBags, 1, -1 do
		local bag = sourceBags[b]
		local bagSlots = GetContainerNumSlots(bag)
		for slot = bagSlots, 1, -1 do
			if #emptySlots == 0 then
				break
			end
			local source = slotKey(bag, slot)
			local id = ids[source]
			local targetBag = decodeSlotKey(emptySlots[1])
			if id and not isSlotLocked(source) and canGoInBag(id, targetBag) then
				addMove(source, tremove(emptySlots, 1))
			end
		end
	end
	wipe(emptySlots)
end

local function compare(a, b)
	local aId, bId = ids[a], ids[b]
	if not (aId and bId) then
		if reverseFill then
			return aId == nil and bId ~= nil
		end
		return aId ~= nil and bId == nil
	end

	if aId ~= bId then
		local aOrder, bOrder = itemOrder[aId], itemOrder[bId]
		if aOrder ~= bOrder then
			return aOrder < bOrder
		end
		return aId < bId
	end

	local aCount, bCount = counts[a], counts[b]
	if aCount ~= bCount then
		return aCount > bCount
	end
	return initialOrder[a] < initialOrder[b]
end

local function sameContent(a, b)
	return ids[a] == ids[b] and counts[a] == counts[b]
end

local function sortSlots(bags)
	wipe(sorted)
	wipe(initialOrder)

	local index = 0
	for i = 1, #bags do
		local bag = bags[i]
		local bagSlots = GetContainerNumSlots(bag)
		-- REVERSED: iterate slots from END to START (bottom-up fill)
		for slot = bagSlots, 1, -1 do
			local key = slotKey(bag, slot)
			if not isSlotLocked(key) then
				index = index + 1
				initialOrder[key] = index
				slots[index] = key
				sorted[index] = key
			end
		end
	end
	table.sort(sorted, compare)
	for i = 1, index do
		sortedPosition[sorted[i]] = i
	end

	for i = 1, index do
		local source, destination = sorted[i], slots[i]
		if source ~= destination and ids[source] and not sameContent(source, destination) then
			addMove(source, destination)
			local sourceIndex, destinationIndex = sortedPosition[source], sortedPosition[destination]
			sorted[sourceIndex], sorted[destinationIndex] = destination, source
			sortedPosition[source], sortedPosition[destination] = destinationIndex, sourceIndex
		end
	end

	wipe(slots)
	wipe(sorted)
	wipe(sortedPosition)
	wipe(initialOrder)
end

function Stuffing:SetBagsForSorting(c)
	Stuffing_Open()

	self.sortBags = {}

	local cmd = ((c == nil or c == "") and {"d"} or {strsplit("/", c)})

	for _, s in ipairs(cmd) do
		if s == "c" then
			self.sortBags = {}
		elseif s == "d" then
			-- REVERSED: use reversed bag lists
			if not self.bankFrame or not self.bankFrame:IsShown() then
				for _, i in ipairs(BAGS_BACKPACK_REV) do
					if self.bags[i] and self.bags[i].bagType == ST_NORMAL then
						table.insert(self.sortBags, i)
					end
				end
			else
				for _, i in ipairs(BAGS_BANK_REV) do
					if self.bags[i] and self.bags[i].bagType == ST_NORMAL then
						table.insert(self.sortBags, i)
					end
				end
			end
		elseif s == "p" then
			if not self.bankFrame or not self.bankFrame:IsShown() then
				for _, i in ipairs(BAGS_BACKPACK_REV) do
					if self.bags[i] and self.bags[i].bagType == ST_SPECIAL then
						table.insert(self.sortBags, i)
					end
				end
			else
				for _, i in ipairs(BAGS_BANK_REV) do
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
	self:RegisterEvent("GET_ITEM_INFO_RECEIVED")

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

function Stuffing:GET_ITEM_INFO_RECEIVED()
	if self.frame and self.frame:IsShown() and self.buttons then
		for _, b in ipairs(self.buttons) do
			self:SlotUpdate(b)
		end
	end
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

-- Ticker-based sort execution (FrostAtomUI style)
local ticker = CreateFrame("Frame")
ticker:Hide()

-- Forward declarations
local planMoves, slotState, moveFinished, issueMove

local function stop(message)
	wipe(moves)
	wipe(busy)
	ticker:Hide()
	if activeFrame then
		activeFrame:SetScript("OnUpdate", nil)
		activeFrame = nil
	end
	if message then
		K.Print(message)
	end
end

local function replan()
	replans = replans + 1
	if replans > MAX_REPLANS then
		return stop("|cffffe02eBags: Sorting failed after too many replans.|r")
	end
	if not planMoves(activeFrame) then
		if uncached then
			return stop("|cffffe02eBags: Sorting failed, items not cached.|r")
		end
		return stop("|cff388bdbBags: Sorting complete.|r")
	end
end

slotState = function(key)
	local bag, slot = decodeSlotKey(key)
	local _, count, locked = GetContainerItemInfo(bag, slot)
	return GetContainerItemID(bag, slot) or false, count or 0, locked
end

moveFinished = function(move)
	local toId, toCount, toLocked = slotState(move.to)
	local fromId, _, fromLocked = slotState(move.from)
	if toLocked or fromLocked then
		return false
	end
	return toId == move.toId and toCount == move.toCount and fromId == move.fromId
end

issueMove = function(move)
	local sourceBag, sourceSlot = decodeSlotKey(move.from)
	local targetBag, targetSlot = decodeSlotKey(move.to)
	local sourceId, sourceCount = slotState(move.from)
	local targetId, targetCount = slotState(move.to)
	if not sourceId then
		return false
	end

	-- Handle partial stack moves
	if sourceId == targetId and move.toCount > targetCount and move.toCount < targetCount + sourceCount then
		SplitContainerItem(sourceBag, sourceSlot, move.toCount - targetCount)
	else
		PickupContainerItem(sourceBag, sourceSlot)
	end
	if GetCursorInfo() ~= "item" then
		return false
	end
	PickupContainerItem(targetBag, targetSlot)
	if GetCursorInfo() then
		ClearCursor()
		return false
	end
	move.started = GetTime()
	return true
end

planMoves = function(frame)
	local bags = frame.sortBags
	wipe(moves)
	resetScan()
	scanBags(bags)
	if uncached then
		wipe(moves)
		return false
	end

	wipe(normalBags)
	wipe(specialtyBags)
	wipe(bagFamilies)
	for i = 1, #bags do
		local bag = bags[i]
		if GetContainerNumSlots(bag) > 0 then
			local _, family = GetContainerNumFreeSlots(bag)
			family = family or 0
			bagFamilies[bag] = family
			if family == 0 then
				normalBags[#normalBags + 1] = bag
			else
				local group = specialtyBags[family]
				if not group then
					group = {}
					specialtyBags[family] = group
				end
				group[#group + 1] = bag
			end
		end
	end

	-- Phase 1: Stack items within specialty bags
	for _, group in pairs(specialtyBags) do
		stackItems(group, group, true)
		stackItems(normalBags, group)
		fillEmptySlots(normalBags, group)
		sortSlots(group)
	end

	-- Phase 2: Stack items in normal bags (partial only)
	stackItems(normalBags, normalBags, true)

	-- Phase 3: Sort normal bags
	sortSlots(normalBags)

	return #moves > 0
end

local function start(frame)
	waitingFrame = nil
	if not frame:IsShown() or InCombatLockdown() then
		frame:SetScript("OnUpdate", nil)
		return
	end

	replans = 0
	if not planMoves(frame) then
		if uncached then
			cacheRetries = cacheRetries + 1
			if cacheRetries > MAX_CACHE_RETRIES then
				frame:SetScript("OnUpdate", nil)
				K.Print("|cffffe02eBags: Some items are not cached yet, try again.|r")
				return
			end
			waitingFrame = frame
			-- Simple delay using OnUpdate
			local elapsed = 0
			frame:SetScript("OnUpdate", function(self, e)
				elapsed = elapsed + e
				if elapsed >= CACHE_RETRY_DELAY then
					self:SetScript("OnUpdate", nil)
					start(frame)
				end
			end)
			return
		end
		frame:SetScript("OnUpdate", nil)
		K.Print("|cff388bdbBags: Already sorted.|r")
		return
	end

	activeFrame = frame
	ticker:Show()
end

ticker:SetScript("OnUpdate", function()
	if InCombatLockdown() then
		return stop("|cffffe02eBags: Sorting interrupted by combat.|r")
	end
	if not moves[1] then
		return replan()
	end
	if GetCursorInfo() then
		return
	end

	wipe(busy)
	local issued = 0
	local now = GetTime()
	local i = 1
	while moves[i] do
		local move = moves[i]
		local from, to = move.from, move.to
		if move.started then
			if moveFinished(move) then
				tremove(moves, i)
				i = i - 1
			elseif now - move.started > MOVE_TIMEOUT then
				return replan()
			else
				busy[from], busy[to] = true, true
			end
		else
			if not (busy[from] or busy[to]) and issued < MOVES_PER_FRAME then
				local _, _, fromLocked = slotState(from)
				local _, _, toLocked = slotState(to)
				if not (fromLocked or toLocked) then
					if not issueMove(move) then
						return replan()
					end
					issued = issued + 1
				end
			end
			busy[from], busy[to] = true, true
		end
		i = i + 1
	end
end)

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
	if ticker:IsShown() or waitingFrame or InCombatLockdown() then
		return
	end
	if not next(typeOrder) then
		buildTypeOrder()
	end
	cacheRetries = 0
	-- Ensure the frame has sortBags reference
	local frame = self.frame or self.bankFrame
	if frame then
		frame.sortBags = self.sortBags
	end
	start(frame)
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