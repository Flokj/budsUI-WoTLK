local K, C, L, _ = select(2, ...):unpack()

local _G = _G
local collectgarbage = collectgarbage
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown

INTERFACE_ACTION_BLOCKED = ""

-- Suppress Ascension's CallBoardUI debug print: "no cost data for CategoryType: nil Category: nil"
-- This is a debug message printed by the game's own CallBoard Lua when no category is selected.
do
	local origAddMessage = DEFAULT_CHAT_FRAME.AddMessage
	DEFAULT_CHAT_FRAME.AddMessage = function(self, msg, ...)
		if type(msg) == "string" and msg:find("no cost data for CategoryType:") then
			return
		end
		return origAddMessage(self, msg, ...)
	end
end

-- Polyfill FontString:WrapText() for Ascension's custom FrameXML
-- Ascension_CharacterFrame uses WrapText() which is a Retail-only API.
-- In WotLK 3.3.5a the equivalent is SetWordWrap().
do
	local holder = CreateFrame("Frame")
	local tmp = holder:CreateFontString()
	local mt = getmetatable(tmp).__index
	if mt and not mt.WrapText then
		mt.WrapText = function(self, enable)
			return self:SetWordWrap(enable ~= false)
		end
	end
end

-- Fix RemoveTalent() taint
FCF_StartAlertFlash = K.Noop

local TaintFix = CreateFrame("Frame")
TaintFix:SetScript("OnUpdate", function(self, elapsed)
	if LFRBrowseFrame.timeToClear then
		LFRBrowseFrame.timeToClear = nil
	end
end)

LFRBrowseFrameListScrollFrame:ClearAllPoints()
LFRBrowseFrameListScrollFrame:SetPoint("TOPLEFT", LFRBrowseFrameListButton1, "TOPLEFT", 0, 0)
LFRBrowseFrameListScrollFrame:SetPoint("BOTTOMRIGHT", LFRBrowseFrameListButton19, "BOTTOMRIGHT", 5, -2)
LFRQueueFrameSpecificListScrollFrame:ClearAllPoints()
LFRQueueFrameSpecificListScrollFrame:SetPoint("TOPLEFT", LFRQueueFrameSpecificListButton1, "TOPLEFT", 0, 0)
LFRQueueFrameSpecificListScrollFrame:SetPoint("BOTTOMRIGHT", LFRQueueFrameSpecificListButton14, "BOTTOMRIGHT", 0, -2)

-- Misclicks for some popups
StaticPopupDialogs.RESURRECT.hideOnEscape = nil
StaticPopupDialogs.AREA_SPIRIT_HEAL.hideOnEscape = nil
StaticPopupDialogs.PARTY_INVITE.hideOnEscape = nil
StaticPopupDialogs.CONFIRM_SUMMON.hideOnEscape = nil
StaticPopupDialogs.ADDON_ACTION_FORBIDDEN.button1 = nil
StaticPopupDialogs.TOO_MANY_LUA_ERRORS.button1 = nil
StaticPopupDialogs.CONFIRM_BATTLEFIELD_ENTRY.button2 = nil