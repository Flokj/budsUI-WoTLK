local K, C, L, _ = select(2, ...):unpack()

local _G = _G
local unpack = unpack
local PlaySound, PlaySoundFile = PlaySound, PlaySoundFile
local hooksecurefunc = hooksecurefunc
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local MAX_BATTLEFIELD_QUEUES = MAX_BATTLEFIELD_QUEUES
local GetBattlefieldStatus = GetBattlefieldStatus
local UnitIsAFK = UnitIsAFK
local GetLFGDungeonRewards = GetLFGDungeonRewards
local GetLFGDungeonInfo = GetLFGDungeonInfo
local GetLFGRandomDungeonInfo = GetLFGRandomDungeonInfo
local GetNumRandomDungeons = GetNumRandomDungeons

DurabilityFrame:SetFrameStrata("HIGH")
local function SetPosition(self, _, parent)
	if (parent == "MinimapCluster") or (parent == _G["MinimapCluster"]) then
		DurabilityFrame:ClearAllPoints()
		DurabilityFrame:SetPoint("RIGHT", Minimap, "RIGHT")
		DurabilityFrame:SetScale(0.6)
	end
end
hooksecurefunc(DurabilityFrame, "SetPoint", SetPosition)

-- Move some frames (Shestak)
TicketStatusFrame:ClearAllPoints()
TicketStatusFrame:SetPoint(unpack(C.Position.Ticket))

MirrorTimer1:ClearAllPoints()
MirrorTimer1:SetPoint("TOP", UIParent, 0, -96)

UIErrorsFrame:ClearAllPoints()
UIErrorsFrame:SetPoint(unpack(C.Position.UIError))
UIErrorsFrame:SetFrameLevel(0)

RaidWarningFrame:ClearAllPoints()
RaidWarningFrame:SetPoint("TOP", UIParent, 0, -130)

-- WorldStateAlwaysUpFrame (BG/arena timer bar), FrostAtomUI-style layout.
-- All re-pointing/sizing of the rows runs synchronously inside a SECURE hook
-- on the Blizzard update, never from an addon-owned timer or at load: an
-- addon-context touch of this frame during combat lockdown taints it, its
-- OnUpdate then writes the tainted WORLDSTATEALWAYSUPFRAME_TIMESINCESTART
-- global and every in-combat RaidGroupFrame_Update (protected
-- RaidGroupButton1..40 SetPoint/Show/Hide) is blocked and counted.
-- The bar's own mover is therefore created out of combat only (see bottom).
local WORLD_STATE_WIDTH = 160
local WORLD_STATE_ROW = 16
local WORLD_STATE_ICON = 22
local max = math.max

local function layoutWorldState()
	-- Combat gate (deliberate deviation from the FrostAtom donor): the
	-- secure-hook callback still executes as addon code, and touching the
	-- frame family (SetSize/SetPoint/ClearAllPoints) during combat lockdown
	-- taints WorldStateAlwaysUpFrame; its OnUpdate then writes the tainted
	-- WORLDSTATEALWAYSUPFRAME_TIMESINCESTART global (taint-6 seed) and every
	-- in-combat RaidGroupFrame_Update pass gets blocked. Blizzard re-anchors
	-- the rows to stock positions on every update anyway, so this layout
	-- simply re-applies on the first out-of-combat update.
	if InCombatLockdown() then return end
	local shown = 0
	local previous
	for i = 1, NUM_ALWAYS_UP_UI_FRAMES or 0 do
		local name = "AlwaysUpFrame" .. i
		local frame = _G[name]
		if frame and frame:IsShown() then
			local icon, text = _G[name .. "Icon"], _G[name .. "Text"]
			local dynamic, flash = _G[name .. "DynamicIconButton"], _G[name .. "Flash"]
			local texture = icon:GetTexture()
			if texture and texture:find("UI%-PVP") then
				icon:SetTexCoord(0, 0.625, 0, 0.625)
			else
				icon:SetTexCoord(0, 1, 0, 1)
			end
			icon:SetSize(WORLD_STATE_ICON, WORLD_STATE_ICON)
			icon:ClearAllPoints()
			icon:SetPoint("LEFT")
			text:ClearAllPoints()
			text:SetPoint("LEFT", icon, "RIGHT", 3, 0)
			dynamic:SetSize(WORLD_STATE_ROW, WORLD_STATE_ROW)
			dynamic:ClearAllPoints()
			dynamic:SetPoint("LEFT", text, "RIGHT", 2, 0)
			_G[name .. "DynamicIconButtonIcon"]:SetSize(WORLD_STATE_ROW, WORLD_STATE_ROW)
			flash:SetSize(WORLD_STATE_ROW, WORLD_STATE_ROW)
			_G[name .. "FlashTexture"]:SetSize(WORLD_STATE_ROW, WORLD_STATE_ROW)
			frame:SetSize(WORLD_STATE_ICON + 3 + text:GetStringWidth(), WORLD_STATE_ROW)
			frame:ClearAllPoints()
			if previous then
				frame:SetPoint("TOPLEFT", previous, "BOTTOMLEFT")
			else
				frame:SetPoint("TOPLEFT", WorldStateAlwaysUpFrame)
			end
			previous = frame
			shown = shown + 1
		end
	end
	WorldStateAlwaysUpFrame:SetSize(WORLD_STATE_WIDTH, max(shown, 1) * WORLD_STATE_ROW)
end

hooksecurefunc("WorldStateAlwaysUpFrame_Update", layoutWorldState)

-- FrostAtom runs layoutWorldState() once at load; same, but only out of
-- combat (an addon-context touch of the bar while locked down is the taint
-- seed; the secure hook covers rendering meanwhile).
local wsInit = CreateFrame("Frame")
wsInit:SetScript("OnUpdate", function(self)
	if InCombatLockdown() then return end
	self:SetScript("OnUpdate", nil)
	layoutWorldState()
end)

-- Vehicle Indicator
local VehicleAnchor = CreateFrame("Frame", "VehicleAnchor", UIParent)
VehicleAnchor:SetPoint(unpack(C.Position.Vehicle))
VehicleAnchor:SetSize(VehicleSeatIndicator:GetWidth(), VehicleSeatIndicator:GetHeight())

hooksecurefunc(VehicleSeatIndicator, "SetPoint", function(_, _, parent)
	if parent == "MinimapCluster" or parent == _G["MinimapCluster"] then
		VehicleSeatIndicator:ClearAllPoints()
		VehicleSeatIndicator:SetPoint("BOTTOM", VehicleAnchor, "BOTTOM", 0, 24)
		VehicleSeatIndicator:SetFrameStrata("LOW")
	end
end)

local AchFilter = CreateFrame("Frame", nil, UIParent)
AchFilter:RegisterEvent("ADDON_LOADED")
AchFilter:SetScript("OnEvent", function(self, event, addon)
	if addon == "Blizzard_AchievementUI" then
		AchievementFrame_SetFilter(3)
	end
end)

-- Force readycheck warning
local ShowReadyCheckHook = function(self, initiator)
	if initiator ~= "player" then
		PlaySound("ReadyCheck", "Master")
	end
end
hooksecurefunc("ShowReadyCheck", ShowReadyCheckHook)

-- Force other warning
local ForceWarning = CreateFrame("Frame")
ForceWarning:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
ForceWarning:RegisterEvent("BATTLEFIELD_MGR_ENTRY_INVITE")
ForceWarning:RegisterEvent("LFG_PROPOSAL_SHOW")
ForceWarning:RegisterEvent("RESURRECT_REQUEST")
ForceWarning:SetScript("OnEvent", function(self, event)
	if event == "UPDATE_BATTLEFIELD_STATUS" then
		for i = 1, MAX_BATTLEFIELD_QUEUES do
			local status = GetBattlefieldStatus(i)
			if status == "confirm" then
				PlaySound("PVPTHROUGHQUEUE", "Master")
				break
			end
			i = i + 1
		end
	elseif event == "BATTLEFIELD_MGR_ENTRY_INVITE" then
		PlaySound("PVPTHROUGHQUEUE", "Master")
	elseif event == "LFG_PROPOSAL_SHOW" then
		PlaySound("ReadyCheck", "Master")
	elseif event == "RESURRECT_REQUEST" then
		PlaySoundFile("Sound\\Spells\\Resurrection.wav", "Master")
	end
end)

-- Auto select current event boss from LFD tool(EventBossAutoSelect by Nathanyel)
local firstLFD
LFDParentFrame:HookScript("OnShow", function()
	if not firstLFD then
		firstLFD = 1
		for i = 1, GetNumRandomDungeons() do
			local id = GetLFGRandomDungeonInfo(i)
			local isHoliday = select(14, GetLFGDungeonInfo(id))
			if isHoliday and not GetLFGDungeonRewards(id) then
				LFDQueueFrame_SetType(id)
			end
		end
	end
end)

-- Disable Boss Emotes (all zones at once).
if C.Misc.BGSpam == true then
	RaidBossEmoteFrame:UnregisterEvent("RAID_BOSS_EMOTE")
end

-- Undress button in auction dress-up frame(by Nefarion)
local strip = CreateFrame("Button", "DressUpFrameUndressButton", DressUpFrame, "UIPanelButtonTemplate")
strip:SetText(L_MISC_UNDRESS)
strip:SetHeight(22)
strip:SetWidth(strip:GetTextWidth() + 40)
strip:SetPoint("RIGHT", DressUpFrameResetButton, "LEFT", -2, 0)
strip:RegisterForClicks("AnyUp")
strip:SetScript("OnClick", function(self, button)
	if button == "RightButton" then
		self.model:UndressSlot(19)
	else
		self.model:Undress()
	end
	PlaySound("gsTitleOptionOK")
end)
strip.model = DressUpModel

strip:RegisterEvent("AUCTION_HOUSE_SHOW")
strip:RegisterEvent("AUCTION_HOUSE_CLOSED")
strip:SetScript("OnEvent", function(self)
	if AuctionFrame:IsVisible() and self.model ~= SideDressUpModel then
		self:SetParent(SideDressUpModel)
		self:ClearAllPoints()
		self:SetPoint("TOP", SideDressUpModelResetButton, "BOTTOM", 0, -3)
		self.model = SideDressUpModel
	elseif self.model ~= DressUpModel then
		self:SetParent(DressUpModel)
		self:ClearAllPoints()
		self:SetPoint("RIGHT", DressUpFrameResetButton, "LEFT", -2, 0)
		self.model = DressUpModel
	end
end)

--------------------------------------------------
ZoneTextFrame:UnregisterAllEvents()
ZoneTextFrame:SetScript("OnShow", function() this:Hide() end)
ZoneTextFrame:Hide()
SubZoneTextFrame:UnregisterAllEvents()
SubZoneTextFrame:SetScript("OnShow", function() this:Hide() end)
SubZoneTextFrame:Hide()

--------------------------------------------------
-- Item/Spell link

function SlashCmdList.IDLINK(msg, editbox)
local name, rank = GetSpellInfo(msg);
    if name == nil then return end
    print("Spell: " ..GetSpellLink(msg).." "..rank)
end
SLASH_IDLINK1 = '/is'  
function SlashCmdList.ITLINK(msg, editbox)
  local _, itemLink, _, _, _, _, _, _, _, _ = GetItemInfo(msg)
if itemLink == nil then return end
    print("Item: " ..itemLink)
end
SLASH_ITLINK1 = '/it'

--------------------------------------------------
-- Suppressing detailed loot spamm

if not (GetLocale=="enGB" or GetLocale=="enUS") then
	LOOT_ROLL_ALL_PASSED = "Everyone passed on: %s";
	LOOT_ROLL_DISENCHANT = "%s has selected Disenchant for: %s";
	LOOT_ROLL_DISENCHANT_SELF = "You have selected Disenchant for: %s";
	LOOT_ROLL_GREED = "%s has selected Greed for: %s";
	LOOT_ROLL_GREED_SELF = "You have selected Greed for: %s";
	LOOT_ROLL_NEED = "%s has selected Need for: %s";
	LOOT_ROLL_NEED_SELF = "You have selected Need for: %s";
	LOOT_ROLL_PASSED = "%s passed on: %s";
	LOOT_ROLL_PASSED_AUTO = "%s automatically passed on: %s because he cannot loot that item.";
	LOOT_ROLL_PASSED_AUTO_FEMALE = "%s automatically passed on: %s because she cannot loot that item.";
	LOOT_ROLL_PASSED_SELF = "You passed on: %s";
	LOOT_ROLL_PASSED_SELF_AUTO = "You automatically passed on: %s because you cannot loot that item.";
	LOOT_ROLL_ROLLED_DE = "Disenchant Roll - %d for %s by %s";
	LOOT_ROLL_ROLLED_GREED = "Greed Roll - %d for %s by %s";
	LOOT_ROLL_ROLLED_NEED = "Need Roll - %d for %s by %s";
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", function(self, event, msg)
	if msg:match("(.*) has?v?e? selected (.+) for: (.+)") or msg:match("(.+) Roll . (%d+) for (.+) by (.+)")
		or msg:match("You passed on: ") or msg:match(" automatically passed on: ") or (msg:match(" passed on: ") and not msg:match("Everyone passed on: ")) then
		return true
	end
end)

-- Easy Item Destroy 
local TypeDeleteLine = gsub(DELETE_GOOD_ITEM, "[\r\n]", "@")
local _, TypeDeleteLine = strsplit("@", TypeDeleteLine, 2)
TypeDeleteLine = gsub(TypeDeleteLine, "@", "")

StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkEnter = function(self, link, text, region, boundsLeft, boundsBottom, boundsWidth, boundsHeight)
    GameTooltip:SetOwner(self, "ANCHOR_PRESERVE")
    GameTooltip:ClearAllPoints()
    local cursorClearance = 30
    GameTooltip:SetPoint("TOPLEFT", region, "BOTTOMLEFT", boundsLeft, boundsBottom - cursorClearance)
    GameTooltip:SetHyperlink(link)
end

StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkLeave = function(self)
    GameTooltip:Hide()
end

StaticPopupDialogs["DELETE_ITEM"].OnHyperlinkEnter = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkEnter
StaticPopupDialogs["DELETE_ITEM"].OnHyperlinkLeave = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkLeave

local easyDelFrame = CreateFrame("Frame")
easyDelFrame:RegisterEvent("DELETE_ITEM_CONFIRM")
easyDelFrame:SetScript("OnEvent", function()
    local link = select(3, GetCursorInfo())
    
    if StaticPopup1EditBox:IsShown() then
        StaticPopup1:SetHeight(StaticPopup1:GetHeight() - 10)
        StaticPopup1EditBox:Hide()
        StaticPopup1Button1:Enable()
        if link then
            StaticPopup1Text:SetText(gsub(StaticPopup1Text:GetText(), TypeDeleteLine, "") .. "\n" .. link)
        end
    else
        StaticPopup1:SetHeight(StaticPopup1:GetHeight() + 40)
        StaticPopup1EditBox:Hide()
        StaticPopup1Button1:Enable()
        if link then
            StaticPopup1Text:SetText(gsub(StaticPopup1Text:GetText(), TypeDeleteLine, "") .. "\n\n" .. link)
        end
    end
end)

--------------------------------------------------
-- Bags/Micro menu: bottom right corner (FrostAtomUI-style movable + fade)
for i = 0, NUM_BAG_SLOTS - 1 do
	(_G["CharacterBag" .. i .. "Slot"]):Kill()
end

local MICRO_BUTTONS = {
	"CharacterMicroButton",
	"SpellbookMicroButton",
	"TalentMicroButton",
	"AchievementMicroButton",
	"QuestLogMicroButton",
	"SocialsMicroButton",
	"PVPMicroButton",
	"LFDMicroButton",
	"MainMenuMicroButton",
	"HelpMicroButton",
}

local microMenu = CreateFrame("Frame", "budsUIMicroMenu", UIParent)
local microButtons = {}
for _, name in ipairs(MICRO_BUTTONS) do
	local button = _G[name]
	if button then
		button:SetParent(microMenu)
		button:Show()
		microButtons[#microButtons + 1] = button
	end
end

local MICRO_BUTTON_WIDTH = 28
local MICRO_BUTTON_HEIGHT = 58
local MICRO_SPACING = -3
local MICRO_MENU_HEIGHT = 40

local function layoutMicroMenu()
	local width = 0
	for index, button in ipairs(microButtons) do
		button:ClearAllPoints()
		button:SetPoint("BOTTOMLEFT", microMenu, "BOTTOMLEFT", width, 0)
		width = width + MICRO_BUTTON_WIDTH + MICRO_SPACING
	end
	-- FrostAtomUI crops the menu frame to 40px; buttons overflow it upward.
	microMenu:SetSize(math.max(width - MICRO_SPACING, 0), MICRO_MENU_HEIGHT)
end
layoutMicroMenu()
hooksecurefunc("UpdateMicroButtons", function()
	if InCombatLockdown() then
		return
	end
	local needs = false
	for _, button in ipairs(microButtons) do
		if button:GetParent() ~= microMenu then
			needs = true
			break
		end
	end
	if needs then
		layoutMicroMenu()
	end
end)

local BACKPACK_SIZE = 32
MainMenuBarBackpackButton:SetParent(UIParent)
MainMenuBarBackpackButton:SetSize(BACKPACK_SIZE, BACKPACK_SIZE)
MainMenuBarBackpackButtonNormalTexture:SetSize(BACKPACK_SIZE * 64 / 36, BACKPACK_SIZE * 64 / 36)

-- Mouseover fade (FrostAtomUI-style), applied to the whole strip + bag button.
local fadeFrames = { MainMenuBarBackpackButton }
for _, button in ipairs(microButtons) do
	fadeFrames[#fadeFrames + 1] = button
end

local fadeState = {}
local fadeDriver = CreateFrame("Frame")
fadeDriver:SetScript("OnUpdate", function(_, elapsed)
	local any = false
	for frame, target in pairs(fadeState) do
		any = true
		local alpha = frame:GetAlpha()
		local next = alpha + (target - alpha) * math.min(elapsed * 8, 1)
		if math.abs(target - next) < 0.01 then
			frame:SetAlpha(target)
			fadeState[frame] = nil
		else
			frame:SetAlpha(next)
		end
	end
	if not any then
		fadeState = {}
	end
end)

local function fadeGroup(target)
	for _, frame in ipairs(fadeFrames) do
		fadeState[frame] = target
	end
end

local function applyMicroFade(instant)
	local target = C.Misc.MicroMenuFade == true and 0.1 or 1
	if instant then
		for _, frame in ipairs(fadeFrames) do
			frame:SetAlpha(target)
		end
	else
		fadeGroup(target)
	end
end
applyMicroFade(true)

for _, frame in ipairs(fadeFrames) do
	frame:HookScript("OnEnter", function()
		fadeGroup(1)
	end)
	frame:HookScript("OnLeave", function()
		if C.Misc.MicroMenuFade ~= true then
			return
		end
		fadeGroup(0.1)
	end)
end

-- Movers (deferred: Core/Movers.lua loads after the modules).
-- WorldState's mover is created out of combat only (InCombatLockdown + regen
-- poll): anchoring the bar from addon code during combat lockdown taints it
-- and spawns the blocked-action cascade (see the world-state block above).
-- K.CreateMover is idempotent, so re-creating micro/bag movers per tick until
-- then is harmless.
local moverWait = CreateFrame("Frame")
moverWait:SetScript("OnUpdate", function()
	if not K.CreateMover then return end
	K.CreateMover(microMenu, "MicroMenu", "Micro menu",
		{ "BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -2, 2 },
		microMenu:GetWidth(), microMenu:GetHeight())
	K.CreateMover(MainMenuBarBackpackButton, "BagButton", "Bag button",
		{ "BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -256, 5 },
		BACKPACK_SIZE, BACKPACK_SIZE)
	if InCombatLockdown() then return end
	K.CreateMover(WorldStateAlwaysUpFrame, "WorldState", "World state",
		{ "TOP", UIParent, "TOP", 0, -30 },
		WORLD_STATE_WIDTH, WORLD_STATE_ROW * 2)
	moverWait:SetScript("OnUpdate", nil)
end)