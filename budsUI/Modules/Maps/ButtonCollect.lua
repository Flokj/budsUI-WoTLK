local K, C, L, _ = select(2, ...):unpack()
if C.Minimap.Enable ~= true or C.Minimap.CollectButtons ~= true then return end

local unpack = unpack
local ipairs = ipairs
local ceil = math.ceil
local CreateFrame, UIParent = CreateFrame, UIParent
local tinsert = table.insert

local buttonSize = 20

-- Collect minimap buttons in one line
local BlackList = {
	["Minimap"] = true,
	["MiniMapPing"] = true,
	["MinimapToggleButton"] = true,
	["MinimapZoneTextButton"] = true,
	["MiniMapRecordingButton"] = true,
	["MiniMapTracking"] = true,
	["MiniMapVoiceChatFrame"] = true,
	["MiniMapWorldMapButton"] = true,
	["MiniMapLFGFrame"] = true,
	["MinimapZoomIn"] = true,
	["MinimapZoomOut"] = true,
	["MiniMapMailFrame"] = true,
	["BattlefieldMinimap"] = true,
	["MinimapBackdrop"] = true,
	["GameTimeFrame"] = true,
	["TimeManagerClockButton"] = true,
	["FeedbackUIButton"] = true,
	["HelpOpenTicketButton"] = true,
	["MiniMapBattlefieldFrame"] = true,
	["QueueStatusMinimapButton"] = true,
	["ButtonCollectFrame"] = true,
	["HandyNotesPin"] = true,
}

local buttons = {}
local button = CreateFrame("Frame", "ButtonCollectFrame", UIParent)
local line = ceil(C.Minimap.Size / buttonSize)

local function PositionAndStyle()
	button:SetSize(buttonSize, buttonSize)
	button:SetPoint(unpack(C.Position.MinimapButtons))
	for i = 1, #buttons do
		local bu = buttons[i]
		if not bu.OldClearAllPoints then
			bu.OldClearAllPoints = bu.ClearAllPoints
			bu.OldSetPoint = bu.SetPoint
		end

		bu:OldClearAllPoints()
		if i == 1 then
			bu:OldSetPoint("TOP", button, "TOP", 0, 0)
		elseif i == line then
			bu:OldSetPoint("TOPRIGHT", buttons[1], "TOPLEFT", -1, 0)
		else
			bu:OldSetPoint("TOP", buttons[i-1], "BOTTOM", 0, -1)
		end

		bu.ClearAllPoints = K.Noop
		bu.SetPoint = K.Noop
		bu:SetAlpha(0)
		if not bu.isHooked then
			bu:HookScript("OnEnter", function()
				if InCombatLockdown() then return end
				K:UIFrameFadeIn(bu, 0.4, bu:GetAlpha(), 1)
			end)
			bu:HookScript("OnLeave", function()
				if InCombatLockdown() then return end
				K:UIFrameFadeOut(bu, 1, bu:GetAlpha(), 0)
			end)
			bu.isHooked = true
		end
	end
end

local function CollectButtons()
	local children = {Minimap:GetChildren()}
	for i = 1, #children do
		local child = children[i]
		local success, name = pcall(child.GetName, child)
		if success and name and not BlackList[name] then
			if child:GetObjectType() == "Button" and child:GetNumRegions() >= 3 and child:IsShown() then
				local isAlreadyCollected = false
				for _, b in ipairs(buttons) do
					if b == child then
						isAlreadyCollected = true
						break
					end
				end
				if not isAlreadyCollected then
					child:SetParent(button)
					tinsert(buttons, child)
				end
			end
		end
	end
	if #buttons == 0 then
		button:Hide()
	else
		button:Show()
	end
	PositionAndStyle()
end

local collect = CreateFrame("Frame")
collect:RegisterEvent("PLAYER_ENTERING_WORLD")
collect:SetScript("OnEvent", function(self)
	CollectButtons()
	K.Delay(C.Minimap.CollectDelay, CollectButtons)
end)