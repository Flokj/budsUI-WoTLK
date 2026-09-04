local K, C, L, _ = select(2, ...):unpack()
if C.Misc.AlreadyKnown ~= true then return end

local _G = _G
local match = string.match
local ceil = math.ceil
local fmod = math.fmod
local IsAddOnLoaded = IsAddOnLoaded
local CreateFrame = CreateFrame
local IsAlreadyKnown = IsAlreadyKnown
local GetItemInfo = GetItemInfo
local GetMerchantNumItems = GetMerchantNumItems
local GetNumBuybackItems = GetNumBuybackItems
local isUsable = isUsable
local GetAuctionItemInfo = GetAuctionItemInfo
local canUse = canUse
local hooksecurefunc = hooksecurefunc

if IsAddOnLoaded("RecipeKnown") or IsAddOnLoaded("AlreadyKnown") then return end
local knowncolor = { r = 0.1, g = 1.0, b = 0.2 }
local tooltip = CreateFrame("GameTooltip")
tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

-- Move knowns to module scope so it can be accessed by throttled function
local knowns = {}

local IsAlreadyKnown
do

	-- things we have to care. please let me know if any lack or surplus here.
	local weapon, armor, container, consumable, glyph, trade_goods, recipe, gem, miscallaneous, quest = GetAuctionItemClasses()
	local knowables = { [consumable] = true, [glyph] = true, [recipe] = true, [miscallaneous] = true, }

	local lines = {}
	for i = 1, 40 do
		lines[i] = tooltip:CreateFontString()
		tooltip:AddFontStrings(lines[i], tooltip:CreateFontString())
	end

	function IsAlreadyKnown (itemLink)
		if ( not itemLink ) then
			return
		end

		local itemID = itemLink:match("item:(%d+):")
		if ( knowns[itemID] ) then
			return true
		end

		local _, _, _, _, _, itemType = GetItemInfo(itemLink)
		if ( not knowables[itemType] ) then
			return
		end

		tooltip:ClearLines()
		tooltip:SetHyperlink(itemLink)

		for i = 1, tooltip:NumLines() do
			if ( lines[i]:GetText() == ITEM_SPELL_KNOWN ) then
				knowns[itemID] = true
				return true
			end
		end
	end
end

-- Throttle setup: defer remaining tooltip scans if too many uncached items
local MAX_SCANS_PER_FRAME = 10
local scanBudget = MAX_SCANS_PER_FRAME
local deferFrame = CreateFrame("Frame")
deferFrame:Hide()

local function ResetScanBudget()
	scanBudget = MAX_SCANS_PER_FRAME
end

local function ThrottledIsAlreadyKnown(itemLink, deferCallback)
	if not itemLink then return end
	-- Cached items are free (no tooltip scan needed)
	local itemID = itemLink:match("item:(%d+):")
	if itemID and knowns[itemID] then return true end
	-- Budget check for uncached items requiring tooltip scan
	if scanBudget <= 0 then
		-- Defer remaining checks to next frame
		if deferCallback then
			deferFrame:SetScript("OnUpdate", function(self)
				self:SetScript("OnUpdate", nil)
				self:Hide()
				ResetScanBudget()
				deferCallback()
			end)
			deferFrame:Show()
		end
		return nil, true -- nil result, deferred flag
	end
	scanBudget = scanBudget - 1
	return IsAlreadyKnown(itemLink)
end

-- merchant frame
local function MerchantFrame_UpdateMerchantInfo()
	ResetScanBudget()
	local numItems = GetMerchantNumItems()

	for i = 1, MERCHANT_ITEMS_PER_PAGE do
		local index = (MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE + i
		if ( index > numItems ) then
			return
		end

		local button = _G["MerchantItem" .. i .. "ItemButton"]

		if ( button and button:IsShown() ) then
			local _, _, _, _, numAvailable, isUsable = GetMerchantItemInfo(index)

			if ( isUsable and IsAlreadyKnown(GetMerchantItemLink(index)) ) then
				local r, g, b = knowncolor.r, knowncolor.g, knowncolor.b
				if ( numAvailable == 0 ) then
					r, g, b = r * 0.5, g * 0.5, b * 0.5
				end

				SetItemButtonTextureVertexColor(button, r, g, b)
			end
		end
	end
end

hooksecurefunc("MerchantFrame_UpdateMerchantInfo", MerchantFrame_UpdateMerchantInfo)

local function MerchantFrame_UpdateBuybackInfo ()
	local numItems = GetNumBuybackItems()

	for index = 1, BUYBACK_ITEMS_PER_PAGE do
		if ( index > numItems ) then
			return
		end

		local button = _G["MerchantItem" .. index .. "ItemButton"]

		if ( button and button:IsShown() ) then
			local _, _, _, _, _, isUsable = GetBuybackItemInfo(index)

			if ( isUsable and IsAlreadyKnown(GetBuybackItemLink(index)) ) then
				SetItemButtonTextureVertexColor(button, knowncolor.r, knowncolor.g, knowncolor.b)
			end
		end
	end
end

hooksecurefunc("MerchantFrame_UpdateBuybackInfo", MerchantFrame_UpdateBuybackInfo)


-- guild bank frame

local function GuildBankFrame_Update ()
	if ( GuildBankFrame.mode ~= "bank" ) then
		return
	end

	local tab = GetCurrentGuildBankTab()

	for i = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
		local button = _G["GuildBankColumn" .. ceil((i - 0.5) / NUM_SLOTS_PER_GUILDBANK_GROUP) .. "Button" .. fmod(i, NUM_SLOTS_PER_GUILDBANK_GROUP)]

		if ( button and button:IsShown() ) then
			local texture, _, locked = GetGuildBankItemInfo(tab, i)

			if ( texture and not locked ) then
				if ( IsAlreadyKnown(GetGuildBankItemLink(tab, i)) ) then
					SetItemButtonTextureVertexColor(button, knowncolor.r, knowncolor.g, knowncolor.b)
				else
					SetItemButtonTextureVertexColor(button, 1, 1, 1)
				end
			end
		end
	end
end

local isBlizzard_GuildBankUILoaded
if ( IsAddOnLoaded("Blizzard_GuildBankUI") ) then
	isBlizzard_GuildBankUILoaded = true

	hooksecurefunc("GuildBankFrame_Update", GuildBankFrame_Update)
end


-- auction frame

local function AuctionFrameBrowse_Update()
	ResetScanBudget()
	local numItems = GetNumAuctionItems("list")
	local offset = FauxScrollFrame_GetOffset(BrowseScrollFrame)

	for i = 1, NUM_BROWSE_TO_DISPLAY do
		local index = offset + i
		if ( index > numItems ) then
			return
		end

		local texture = _G["BrowseButton" .. i .. "ItemIconTexture"]

		if ( texture and texture:IsShown() ) then
			local _, _, _, _, canUse = GetAuctionItemInfo("list", index)

			if canUse then
				local known, deferred = ThrottledIsAlreadyKnown(GetAuctionItemLink("list", index), AuctionFrameBrowse_Update)
				if deferred then return end
				if known then
					texture:SetVertexColor(knowncolor.r, knowncolor.g, knowncolor.b)
				end
			end
		end
	end
end

local function AuctionFrameBid_Update ()
	local numItems = GetNumAuctionItems("bidder")
	local offset = FauxScrollFrame_GetOffset(BidScrollFrame)

	for i = 1, NUM_BIDS_TO_DISPLAY do
		local index = offset + i
		if ( index > numItems ) then
			return
		end

		local texture = _G["BidButton" .. i .. "ItemIconTexture"]

		if ( texture and texture:IsShown() ) then
			local _, _, _, _, canUse = GetAuctionItemInfo("bidder", index)

			if ( canUse and IsAlreadyKnown(GetAuctionItemLink("bidder", index)) ) then
				texture:SetVertexColor(knowncolor.r, knowncolor.g, knowncolor.b)
			end
		end
	end
end

local function AuctionFrameAuctions_Update ()
	local numItems = GetNumAuctionItems("owner")
	local offset = FauxScrollFrame_GetOffset(AuctionsScrollFrame)

	for i = 1, NUM_AUCTIONS_TO_DISPLAY do
		local index = offset + i
		if ( index > numItems ) then
			return
		end

		local texture = _G["AuctionsButton" .. i .. "ItemIconTexture"]

		if ( texture and texture:IsShown() ) then
			-- WoW 3.3.5 Compatibility: GetAuctionItemInfo returns only 11 values, not 13
			-- saleStatus is at position 11 in 3.3.5, not 13
			local _, _, _, _, canUse, _, _, _, _, _, saleStatus = GetAuctionItemInfo("owner", index)

			if ( canUse and IsAlreadyKnown(GetAuctionItemLink("owner", index)) ) then
				local r, g, b = knowncolor.r, knowncolor.g, knowncolor.b
				if ( saleStatus == 1 ) then
					r, g, b = r * 0.5, g * 0.5, b * 0.5
				end

				texture:SetVertexColor(r, g, b)
			end
		end
	end
end

local isBlizzard_AuctionUILoaded
if ( IsAddOnLoaded("Blizzard_AuctionUI") ) then
	isBlizzard_AuctionUILoaded = true

	hooksecurefunc("AuctionFrameBrowse_Update", AuctionFrameBrowse_Update)
	hooksecurefunc("AuctionFrameBid_Update", AuctionFrameBid_Update)
	hooksecurefunc("AuctionFrameAuctions_Update", AuctionFrameAuctions_Update)
end

-- for LoD addons

if ( not (isBlizzard_GuildBankUILoaded and isBlizzard_AuctionUILoaded) ) then
	local function OnEvent (self, event, addonName)
		if ( addonName == "Blizzard_GuildBankUI" ) then
			isBlizzard_GuildBankUILoaded = true

			hooksecurefunc("GuildBankFrame_Update", GuildBankFrame_Update)
		elseif ( addonName == "Blizzard_AuctionUI" ) then
			isBlizzard_AuctionUILoaded = true

			hooksecurefunc("AuctionFrameBrowse_Update", AuctionFrameBrowse_Update)
			hooksecurefunc("AuctionFrameBid_Update", AuctionFrameBid_Update)
			hooksecurefunc("AuctionFrameAuctions_Update", AuctionFrameAuctions_Update)
		end

		if ( isBlizzard_GuildBankUILoaded and isBlizzard_AuctionUILoaded ) then
			self:UnregisterEvent(event)
			self:SetScript("OnEvent", nil)
			OnEvent = nil
		end
	end

	tooltip:SetScript("OnEvent", OnEvent)
	tooltip:RegisterEvent("ADDON_LOADED")
end