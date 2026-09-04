local K, C, L, _ = select(2, ...):unpack()

local tonumber = tonumber
local lower, match = string.lower, string.match
local print = print
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers
local CreateFrame = CreateFrame

-- GitHub Release Check
local function CheckGitHubVersion()
	local versionFrame = CreateFrame("Frame")
	versionFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	versionFrame:SetScript("OnEvent", function(self, event)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		
		-- Wait 5 seconds after login to check
		K.Delay(5, function()
			local currentVersion = K.Version
			-- GitHub API URL for latest release
			local url = "https://api.github.com/repos/Budtender3000/budsUI/releases/latest"
			
			-- Note: WoW 3.3.5 doesn't have HTTP API, so we use a workaround
			-- This will be checked via addon communication when playing with others
			-- For now, show a reminder to check GitHub
			if not budsUICheckedVersion then
				K.Print("|cff388bdbbudsUI v"..currentVersion.."|r")
				K.Print("Check for updates: |cff00ff00https://github.com/Budtender3000/budsUI/releases|r")
				budsUICheckedVersion = true
			end
		end)
	end)
end

CheckGitHubVersion()

--	Check outdated UI version
local Check = function(self, event, prefix, message, channel, sender)
	local numParty, numRaid = GetNumPartyMembers(), GetNumRaidMembers()
	if event == "CHAT_MSG_ADDON" then
		if prefix ~= "budsUIVersion" or sender == K.Name then return end
		if tonumber(message) ~= nil and tonumber(message) > tonumber(K.Version) then
			print("|cfff02c35"..L_MISC_UI_OUTDATED.."|r")
			K.Print("Download latest version: |cff00ff00https://github.com/Budtender3000/budsUI/releases|r")
			self:UnregisterEvent("CHAT_MSG_ADDON")
		end
	else
		if numRaid > 0 then
			SendAddonMessage("budsUIVersion", tonumber(K.Version), "RAID")
		elseif numParty > 0 then
			SendAddonMessage("budsUIVersion", tonumber(K.Version), "PARTY")
		elseif IsInGuild() then
			SendAddonMessage("budsUIVersion", tonumber(K.Version), "GUILD")
		end
	end
	-- Remind people to delete old budsUI_Filger
	if event == "PLAYER_ENTERING_WORLD" and (select(4, GetAddOnInfo("budsUI_Filger"))) then
		K.Print("|cffff3300".."Please, delete budsUI_Filger, it is now built-in.".."|r")
		DisableAddOn("budsUI_Filger") -- Just incase they ignore the message.
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("CHAT_MSG_ADDON")

local function UpdateGroupEvents()
	local numParty, numRaid = GetNumPartyMembers(), GetNumRaidMembers()
	if numRaid > 0 or numParty > 0 then
		frame:RegisterEvent("RAID_ROSTER_UPDATE")
		frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
	else
		frame:UnregisterEvent("RAID_ROSTER_UPDATE")
		frame:UnregisterEvent("PARTY_MEMBERS_CHANGED")
	end
end

frame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		UpdateGroupEvents()
	elseif event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" then
		UpdateGroupEvents()
	end
	Check(self, event, ...)
end)

-- Whisper UI version (rate-limited: 10s cooldown per sender)
local Whisper = CreateFrame("Frame")
local whisperCooldowns = {}
local WHISPER_COOLDOWN = 10
Whisper:RegisterEvent("CHAT_MSG_WHISPER")
Whisper:SetScript("OnEvent", function(self, event, text, name, ...)
	if text:lower():match("ui_version") then
		if event == "CHAT_MSG_WHISPER" then
			local now = GetTime()
			if not whisperCooldowns[name] or (now - whisperCooldowns[name]) >= WHISPER_COOLDOWN then
				whisperCooldowns[name] = now
				K.Delay(2, SendChatMessage, "budsUI "..K.Version, "WHISPER", nil, name)
			end
		end
	end
end)