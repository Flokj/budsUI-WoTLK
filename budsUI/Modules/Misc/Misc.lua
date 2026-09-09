local K, C, L, _ = select(2, ...):unpack()

local _G = _G
local unpack = unpack
local PlaySound, PlaySoundFile = PlaySound, PlaySoundFile
local hooksecurefunc = hooksecurefunc
local CreateFrame = CreateFrame
local MAX_BATTLEFIELD_QUEUES = MAX_BATTLEFIELD_QUEUES
local GetBattlefieldStatus = GetBattlefieldStatus
local UnitIsAFK = UnitIsAFK
local GetZoneText = GetZoneText
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

WorldStateAlwaysUpFrame:ClearAllPoints()
WorldStateAlwaysUpFrame:SetPoint("TOP", UIParent, 0, -10)

hooksecurefunc("WorldStateAlwaysUpFrame_Update", function()
	-- Delay execution to ensure all child frames are created by Blizzard/DBM first
	K.Delay(0.1, function()
		for i = 1, NUM_ALWAYS_UP_UI_FRAMES do
			local frame = _G["AlwaysUpFrame"..i]
			if not frame then return end

			local text = _G["AlwaysUpFrame"..i.."Text"]
			if text then
				text:ClearAllPoints()
				text:SetPoint("CENTER", frame, "CENTER", 0, 0)
				text:SetJustifyH("CENTER")
				text:SetFont(C.Media.Font, C.Media.Font_Size)
			end

			local icon = _G["AlwaysUpFrame"..i.."Icon"]
			if icon then
				icon:ClearAllPoints()
				icon:SetPoint("RIGHT", text, "LEFT", 12, -8)
			end

			local dynamicIcon = _G["AlwaysUpFrame"..i.."DynamicIconButton"]
			if dynamicIcon then
				dynamicIcon:ClearAllPoints()
				dynamicIcon:SetPoint("LEFT", text, "RIGHT", 0, 0)
			end
		end
	end)
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

-- Remove Boss Emote spam during BG(ArathiBasin SpamFix by Partha)
if C.Misc.BGSpam == true then
	local Fixer = CreateFrame("Frame")
	local RaidBossEmoteFrame, spamDisabled = RaidBossEmoteFrame

	local function DisableSpam()
		if GetZoneText() == L_ZONE_ARATHIBASIN then
			RaidBossEmoteFrame:UnregisterEvent("RAID_BOSS_EMOTE")
			spamDisabled = true
		elseif spamDisabled then
			RaidBossEmoteFrame:RegisterEvent("RAID_BOSS_EMOTE")
			spamDisabled = false
		end
	end

	Fixer:RegisterEvent("PLAYER_ENTERING_WORLD")
	Fixer:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	Fixer:SetScript("OnEvent", DisableSpam)
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

--------------------------------------------------
-- Game DBM OFF
RaidBossEmoteFrame:SetAlpha(0)
--RaidNotice_AddMessage = function() end -- Raid Warning

-- Test Hite PP/Bg text
HK=' '
local s for i=1,19 do for j=0,1 do s=("PVP_RANK_%d_%d"):format(i,j) _G[s],_G[s.."_FEMALE"]=nil end end

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