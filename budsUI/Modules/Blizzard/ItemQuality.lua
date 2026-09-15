local K, C, L, _ = select(2, ...):unpack()

-- Item quality borders on Blizzard frames (replaces the oGlow library).
-- KkthnxUI-style: no pipes/filters, the budsUI flat border on each slot is
-- painted directly in the same update that fills the slot. Quality rare (2)
-- and above gets a colored border, everything else keeps the default one.

local function BorderOwner(slotFrame)
	if slotFrame:IsObjectType("Frame") then
		return slotFrame
	end
	-- TradeSkill reagent icon textures: wrap in a border frame anchored to it
	local wrap = slotFrame.budsQualityWrap
	if not wrap then
		wrap = CreateFrame("Frame", nil, slotFrame:GetParent())
		wrap:SetAllPoints(slotFrame)
		wrap:EnableMouse(false)
		slotFrame.budsQualityWrap = wrap
	end
	return wrap
end

local function SetBorder(slotFrame, ...)
	if not slotFrame then return end

	local quality = -1
	for i = 1, select("#", ...) do
		local link = select(i, ...)
		if link then
			local q = select(3, GetItemInfo(link))
			if q then quality = math.max(quality, q) end
		end
	end

	local owner = BorderOwner(slotFrame)
	if not owner then return end
	if not owner.BorderTextures then
		K.CreateBorder(owner)
	end

	if quality and quality > 1 then
		owner:SetBackdropBorderColor(GetItemQualityColor(quality))
	else
		owner:SetBackdropBorderColor(unpack(C.Media.Border_Color))
	end
end

--------------------------------------------------
-- BAGS + BANK (only with Blizzard containers,
-- budsUI bags paint their own quality glow)
--------------------------------------------------

if C.Bag.Enable ~= true then
	local function UpdateBagContainer(frame)
		local id = frame:GetID()
		local name = frame:GetName()
		local size = frame.size
		for i = 1, size do
			local bid = size - i + 1
			SetBorder(_G[name .. "Item" .. bid], GetContainerItemLink(id, i))
		end
	end

	hooksecurefunc("ContainerFrame_Update", function(frame)
		UpdateBagContainer(frame)
	end)

	local bankUpdater = CreateFrame("Frame")
	bankUpdater:RegisterEvent("BANKFRAME_OPENED")
	bankUpdater:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	bankUpdater:SetScript("OnEvent", function()
		if BankFrame:IsShown() then
			for i = 1, NUM_BANKGENERIC_SLOTS or 28 do
				SetBorder(_G["BankFrameItem" .. i], GetContainerItemLink(-1, i))
			end
		end
	end)
end

--------------------------------------------------
-- CHARACTER + INSPECT (skipped with Fizzle)
--------------------------------------------------

local PAPERDOLL_SLOTS = {
	"Head", "Neck", "Shoulder", "Shirt", "Chest", "Waist", "Legs", "Feet", "Wrist",
	"Hands", "Finger0", "Finger1", "Trinket0", "Trinket1", "Back", "MainHand",
	"SecondaryHand", "Ranged", "Tabard",
}

if not select(4, GetAddOnInfo("Fizzle")) then
	local function UpdatePaperDoll()
		if CharacterFrame:IsShown() then
			for key, slotName in ipairs(PAPERDOLL_SLOTS) do
				local slotID = key % 20
				SetBorder(_G["Character" .. slotName .. "Slot"], GetInventoryItemLink("player", slotID))
			end
		end
	end

	CharacterFrame:HookScript("OnShow", UpdatePaperDoll)

	local charUpdater = CreateFrame("Frame")
	charUpdater:RegisterEvent("UNIT_INVENTORY_CHANGED")
	charUpdater:SetScript("OnEvent", function(_, _, unit)
		if unit == "player" then UpdatePaperDoll() end
	end)

	-- Inspect: item links may arrive later than the frame, poll the missing ones
	local missing = {}
	local pollFrame = CreateFrame("Frame")
	pollFrame:Hide()
	local pollTime = 0
	pollFrame:SetScript("OnUpdate", function(self, elapsed)
		pollTime = pollTime + elapsed
		if pollTime >= 3 then
			local unit = InspectFrame.unit
			if not unit then
				wipe(missing)
				self:Hide()
				return
			end
			for i, slotName in next, missing do
				local itemLink = GetInventoryItemLink(unit, i)
				if itemLink then
					SetBorder(_G["Inspect" .. slotName .. "Slot"], itemLink)
					missing[i] = nil
				end
			end
			if not next(missing) then self:Hide() end
		end
	end)

	local function UpdateInspect()
		if not InspectFrame or not InspectFrame:IsShown() then return end
		local unit = InspectFrame.unit
		for i, slotName in next, PAPERDOLL_SLOTS do
			local itemLink = GetInventoryItemLink(unit, i)
			if GetInventoryItemTexture(unit, i) and not itemLink then
				missing[i] = slotName
				pollFrame:Show()
			end
			SetBorder(_G["Inspect" .. slotName .. "Slot"], itemLink)
		end
	end

	local inspectUpdater = CreateFrame("Frame")
	local function InspectEnable()
		inspectUpdater:RegisterEvent("PLAYER_TARGET_CHANGED")
		inspectUpdater:RegisterEvent("UNIT_INVENTORY_CHANGED")
		inspectUpdater:RegisterEvent("INSPECT_READY")
		InspectFrame:HookScript("OnShow", UpdateInspect)
	end
	inspectUpdater:SetScript("OnEvent", function(_, event, ...)
		if event == "ADDON_LOADED" then
			local addon = ...
			if addon == "Blizzard_InspectUI" then
				InspectEnable()
				inspectUpdater:UnregisterEvent("ADDON_LOADED")
			end
		elseif event == "UNIT_INVENTORY_CHANGED" then
			local unit = ...
			if InspectFrame.unit == unit then UpdateInspect() end
		else
			UpdateInspect()
		end
	end)
	if IsAddOnLoaded("Blizzard_InspectUI") then
		InspectEnable()
	else
		inspectUpdater:RegisterEvent("ADDON_LOADED")
	end
end

--------------------------------------------------
-- GUILD BANK
--------------------------------------------------

do
	local function UpdateGBank()
		if not IsAddOnLoaded("Blizzard_GuildBankUI") then return end
		local tab = GetCurrentGuildBankTab()
		for i = 1, MAX_GUILDBANK_SLOTS_PER_TAB or 98 do
			local index = math.fmod(i, 14)
			if index == 0 then index = 14 end
			local column = math.ceil((i - 0.5) / 14)
			SetBorder(_G["GuildBankColumn" .. column .. "Button" .. index], GetGuildBankItemLink(tab, i))
		end
	end

	local updater = CreateFrame("Frame")
	updater:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED")
	updater:RegisterEvent("GUILDBANKFRAME_OPENED")
	updater:SetScript("OnEvent", UpdateGBank)
end

--------------------------------------------------
-- TRADE
--------------------------------------------------

do
	local function UpdateTradeSide(prefix, linkFunc)
		return function(_, _, index)
			SetBorder(_G["Trade" .. prefix .. "Item" .. index .. "ItemButton"], linkFunc(index))
		end
	end
	local updatePlayer = UpdateTradeSide("Player", GetTradePlayerItemLink)
	local updateTarget = UpdateTradeSide("Recipient", GetTradeTargetItemLink)

	local function UpdateTrade()
		for i = 1, MAX_TRADE_ITEMS or 8 do
			SetBorder(_G["TradePlayerItem" .. i .. "ItemButton"], GetTradePlayerItemLink(i))
			SetBorder(_G["TradeRecipientItem" .. i .. "ItemButton"], GetTradeTargetItemLink(i))
		end
	end

	local updater = CreateFrame("Frame")
	updater:RegisterEvent("TRADE_UPDATE")
	updater:RegisterEvent("TRADE_SHOW")
	updater:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")
	updater:RegisterEvent("TRADE_TARGET_ITEM_CHANGED")
	updater:SetScript("OnEvent", function(_, event, _, index)
		if event == "TRADE_PLAYER_ITEM_CHANGED" then
			updatePlayer(nil, nil, index)
		elseif event == "TRADE_TARGET_ITEM_CHANGED" then
			updateTarget(nil, nil, index)
		else
			UpdateTrade()
		end
	end)
end

--------------------------------------------------
-- TRADESKILL
--------------------------------------------------

do
	local function UpdateTradeSkill(id)
		local itemLink = GetTradeSkillItemLink(id)
		if itemLink then
			SetBorder(TradeSkillSkillIcon, itemLink)
		end
		for i = 1, GetTradeSkillNumReagents(id) do
			SetBorder(_G["TradeSkillReagent" .. i .. "IconTexture"], GetTradeSkillReagentItemLink(id, i))
		end
	end

	local hooked
	local function HookTradeSkill()
		if hooked then return end
		hooked = true
		hooksecurefunc("TradeSkillFrame_SetSelection", UpdateTradeSkill)
	end

	local updater = CreateFrame("Frame")
	updater:SetScript("OnEvent", function(self, _, addon)
		if addon == "Blizzard_TradeSkillUI" then
			HookTradeSkill()
			self:UnregisterEvent("ADDON_LOADED")
		end
	end)
	if IsAddOnLoaded("Blizzard_TradeSkillUI") then
		HookTradeSkill()
	else
		updater:RegisterEvent("ADDON_LOADED")
	end
end

--------------------------------------------------
-- MERCHANT
--------------------------------------------------

do
	local function UpdateMerchant()
		if MerchantFrame:IsShown() then
			if MerchantFrame.selectedTab == 1 then
				for i = 1, MERCHANT_ITEMS_PER_PAGE do
					local index = (((MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE) + i)
					SetBorder(_G["MerchantItem" .. i .. "ItemButton"], GetMerchantItemLink(index))
				end
				SetBorder(MerchantBuyBackItemItemButton, GetBuybackItemLink(GetNumBuybackItems()))
			else
				for i = 1, BUYBACK_ITEMS_PER_PAGE do
					SetBorder(_G["MerchantItem" .. i .. "ItemButton"], GetBuybackItemLink(i))
				end
			end
		end
	end

	hooksecurefunc("MerchantFrame_Update", UpdateMerchant)
end

--------------------------------------------------
-- MAIL
--------------------------------------------------

do
	local function UpdateSend()
		if not SendMailFrame:IsShown() then return end
		for i = 1, ATTACHMENTS_MAX_SEND do
			SetBorder(_G["SendMailAttachment" .. i], GetSendMailItemLink(i))
		end
	end

	local stack = {}
	local function UpdateInbox()
		local numItems = GetInboxNumItems()
		local index = ((InboxFrame.pageNum - 1) * INBOXITEMS_TO_DISPLAY) + 1
		for i = 1, INBOXITEMS_TO_DISPLAY do
			if index <= numItems then
				for j = 1, ATTACHMENTS_MAX_RECEIVE do
					local attachLink = GetInboxItemLink(index, j)
					if attachLink then table.insert(stack, attachLink) end
				end
			end
			SetBorder(_G["MailItem" .. i .. "Button"], unpack(stack))
			wipe(stack)
			index = index + 1
		end
	end

	local function UpdateLetter()
		if not InboxFrame.openMailID then return end
		for i = 1, ATTACHMENTS_MAX_RECEIVE do
			local itemLink = GetInboxItemLink(InboxFrame.openMailID, i)
			if itemLink then
				SetBorder(_G["OpenMailAttachmentButton" .. i], itemLink)
			end
		end
	end

	hooksecurefunc("OpenMail_Update", UpdateLetter)
	hooksecurefunc("InboxFrame_Update", UpdateInbox)

	local updater = CreateFrame("Frame")
	updater:RegisterEvent("MAIL_SHOW")
	updater:RegisterEvent("MAIL_SEND_INFO_UPDATE")
	updater:RegisterEvent("MAIL_SEND_SUCCESS")
	updater:SetScript("OnEvent", UpdateSend)
end

--------------------------------------------------
-- LOOT (only with Blizzard loot frame,
-- budsUI loot paints its own)
--------------------------------------------------

if C.Loot.Enable ~= true then
	local updater = CreateFrame("Frame")
	updater:RegisterEvent("LOOT_OPENED")
	updater:RegisterEvent("LOOT_SLOT_CLEARED")
	updater:RegisterEvent("LOOT_SLOT_CHANGED")
	updater:SetScript("OnEvent", function()
		if LootFrame:IsShown() then
			for i = 1, LOOTFRAME_NUMBUTTONS or 4 do
				local slotFrame = _G["LootButton" .. i]
				local slot = slotFrame.slot
				local itemLink
				if slot then itemLink = GetLootSlotLink(slot) end
				SetBorder(slotFrame, itemLink)
			end
		end
	end)
end
