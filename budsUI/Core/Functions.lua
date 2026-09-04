local K, C, L, _ = select(2, ...):unpack()

local format, find, gsub = string.format, string.find, string.gsub
local match = string.match
local floor, ceil = math.floor, math.ceil
local print = print
local reverse = string.reverse
local tonumber, type = tonumber, type
local unpack, select = unpack, select
local CreateFrame = CreateFrame
local GetCombatRatingBonus = GetCombatRatingBonus
local GetSpellInfo = GetSpellInfo
local GetNumPartyMembers, GetNumRaidMembers = GetNumPartyMembers, GetNumRaidMembers
local UnitStat, UnitAttackPower, UnitBuff = UnitStat, UnitAttackPower, UnitBuff
local tinsert, tremove = tinsert, tremove
local Locale = GetLocale()

K.Backdrop = {bgFile = C.Media.Blank, edgeFile = C.Media.Blizz, edgeSize = 14, insets = {left = 2.5, right = 2.5, top = 2.5, bottom = 2.5}}
K.Border = {edgeFile = C.Media.Blizz, edgeSize = 14}
K.BorderBackdrop = {bgFile = C.Media.Blank}
K.PixelBorder = {edgeFile = C.Media.Blank, edgeSize = K.Mult, insets = {left = K.Mult, right = K.Mult, top = K.Mult, bottom = K.Mult}}
K.ShadowBackdrop = {edgeFile = C.Media.Glow, edgeSize = 3, insets = {left = 5, right = 5, top = 5, bottom = 5}}

-- This frame everything in budsUI should be anchored to for Eyefinity support.
K.UIParent = CreateFrame("Frame", "budsUIParent", UIParent)
K.UIParent:SetFrameLevel(UIParent:GetFrameLevel())
K.UIParent:SetPoint("CENTER", UIParent, "CENTER")
K.UIParent:SetSize(UIParent:GetSize())

K.TexCoords = {5/65, 59/64, 5/64, 59/64}

K.Print = function(...)
	print("|cff388bdbbudsUI|r:", ...)
end

-- Safe event handler wrapper
K.SafeEventHandler = function(handler, eventName)
	return function(self, event, ...)
		local success, err = pcall(handler, self, event, ...)
		if not success then
			if C.General.DeveloperMode then
				K.Print(format("Error in %s handler: %s", eventName or event or "unknown", tostring(err)))
			end
			-- Log to SavedVariables für Bug-Reports
			if not SavedOptions.ErrorLog then SavedOptions.ErrorLog = {} end
			table.insert(SavedOptions.ErrorLog, {
				time = date("%Y-%m-%d %H:%M:%S"),
				event = eventName or event or "unknown",
				error = tostring(err),
				addon = "budsUI"
			})
			-- Limit log size
			if #SavedOptions.ErrorLog > 50 then
				table.remove(SavedOptions.ErrorLog, 1)
			end
		end
	end
end

-- Safe OnUpdate wrapper
K.SafeOnUpdate = function(handler, frameName)
	return function(self, elapsed)
		local success, err = pcall(handler, self, elapsed)
		if not success then
			-- Stop OnUpdate on error to prevent spam
			self:SetScript("OnUpdate", nil)
			if C.General.DeveloperMode then
				K.Print(format("Error in %s OnUpdate (stopped): %s", frameName or "unknown", tostring(err)))
			end
		end
	end
end

K.SafeSetCVar = function(cvar, value)
	if GetCVar(cvar) ~= nil then
		local success = pcall(SetCVar, cvar, value)
		return success
	end
	return false
end

K.SetFontString = function(parent, fontName, fontHeight, fontStyle)
	local fs = parent:CreateFontString(nil, "OVERLAY")
	fs:SetFont(fontName, fontHeight, fontStyle)
	fs:SetJustifyH("LEFT")
	fs:SetShadowColor(0, 0, 0)
	fs:SetShadowOffset(K.Mult, -K.Mult)

	return fs
end

K.SkinFont = function(self)
	self:SetFont(C.Media.Font, C.Media.Font_Size, C.Media.Font_Style)
	self:SetShadowOffset(K.Mult, -K.Mult)
	self:SetShadowColor(0, 0, 0, 1)
end

K.Comma = function(num)
	local Left, Number, Right = match(num, "^([^%d]*%d)(%d*)(.-)$")

	return 	Left .. reverse(gsub(reverse(Number), "(%d%d%d)", "%1,")) .. Right
end

-- ShortValue
-- We show a different value for the Chinese client.
if (Locale == "zhCN") then
	K.ShortValue = function(value)
		value = tonumber(value)
		if not value then return "" end
		if value >= 1e8 then
			return ("%.1f亿"):format(value / 1e8):gsub("%.?0+([km])$", "%1")
		elseif value >= 1e4 or value <= -1e3 then
			return ("%.1f万"):format(value / 1e4):gsub("%.?0+([km])$", "%1")
		else
			return floor(tostring(value))
		end 
	end
else
	K.ShortValue = function(value)
		value = tonumber(value)
		if not value then return "" end
		if value >= 1e6 then
			return ("%.1fm"):format(value / 1e6):gsub("%.?0+([km])$", "%1")
		elseif value >= 1e3 or value <= -1e3 then
			return ("%.1fk"):format(value / 1e3):gsub("%.?0+([km])$", "%1")
		else
			return floor(tostring(value))
		end	
	end
end

-- Rounding
K.Round = function(number, decimals)
	if (not decimals) then
		decimals = 0
	end

	return format(format("%%.%df", decimals), number)
end

-- RGBToHex Color
K.RGBToHex = function(r, g, b)
	r = r <= 1 and r >= 0 and r or 0
    g = g <= 1 and g >= 0 and g or 0
    b = b <= 1 and b >= 0 and b or 0

    return format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

K.CheckChat = function(warning)
    local numParty, numRaid = GetNumPartyMembers(), GetNumRaidMembers()
    if (numRaid > 0) then
        if warning and (UnitIsPartyLeader("player")) or (UnitIsRaidOfficer("player")) then
            return "RAID_WARNING"
        else
            return "RAID"
        end
        elseif (numParty > 0) then
            return "PARTY"
        end
    return "SAY"
end

local RoleUpdater = CreateFrame("Frame")
local roleUpdateThrottle = 0
local ROLE_UPDATE_INTERVAL = 0.5 -- Update max 2x/Sekunde

local function CheckRole(self, event, unit)
	if event == "UNIT_AURA" and unit ~= "player" then return end
	
	-- Throttle UNIT_AURA updates
	if event == "UNIT_AURA" then
		local now = GetTime()
		if (now - roleUpdateThrottle) < ROLE_UPDATE_INTERVAL then
			return
		end
		roleUpdateThrottle = now
	end
	
	-- Wrap in pcall for error safety
	local success, err = pcall(function()
		if (K.Class == "PALADIN" and UnitBuff("player", K.GetSpellInfo(25780))) and GetCombatRatingBonus(CR_DEFENSE_SKILL) > 100 or
		(K.Class == "WARRIOR" and GetBonusBarOffset() == 2) or
		(K.Class == "DEATHKNIGHT" and UnitBuff("player", K.GetSpellInfo(48263))) or
		(K.Class == "DRUID" and GetBonusBarOffset() == 3) then
			K.Role = "Tank"
		else
			local playerint = select(2, UnitStat("player", 4))
			local playeragi	= select(2, UnitStat("player", 2))
			local base, posBuff, negBuff = UnitAttackPower("player")
			local playerap = base + posBuff + negBuff

			if ((playerap > playerint) or (playeragi > playerint)) and not (UnitBuff("player", K.GetSpellInfo(24858)) or UnitBuff("player", K.GetSpellInfo(65139))) then
				K.Role = "Melee"
			else
				K.Role = "Caster"
			end
		end
	end)
	
	if not success and C.General.DeveloperMode then
		K.Print("CheckRole error:", err)
	end
	
	-- Unregister useless events
	if event == "PLAYER_ENTERING_WORLD" then
		if K.Class ~= "WARRIOR" and K.Class ~= "DRUID" and K.Class ~= "PALADIN" and K.Class ~= "DEATHKNIGHT" then
			RoleUpdater:UnregisterEvent("UPDATE_BONUS_ACTIONBAR")
		end
		RoleUpdater:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
end
RoleUpdater:RegisterEvent("PLAYER_ENTERING_WORLD")
RoleUpdater:RegisterEvent("UNIT_AURA")
RoleUpdater:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
RoleUpdater:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
RoleUpdater:RegisterEvent("CHARACTER_POINTS_CHANGED")
RoleUpdater:SetScript("OnEvent", CheckRole)
CheckRole()

function K.ShortenString(string, numChars, dots)
	local bytes = string:len()
	if(bytes <= numChars) then
		return string
	else
		local len, pos = 0, 1
		while(pos <= bytes) do
			len = len + 1
			local c = string:byte(pos)
			if(c > 0 and c <= 127) then
				pos = pos + 1
			elseif(c >= 192 and c <= 223) then
				pos = pos + 2
			elseif(c >= 224 and c <= 239) then
				pos = pos + 3
			elseif(c >= 240 and c <= 247) then
				pos = pos + 4
			end
			if(len == numChars) then break end
		end

		if(len == numChars and pos <= bytes) then
			return string:sub(1, pos - 1)..(dots and "..." or "")
		else
			return string
		end
	end
end

K.RuneColor = {
	[1] = {r = 0.7, g = 0.1, b = 0.1},
	[2] = {r = 0.7, g = 0.1, b = 0.1},
	[3] = {r = 0.4, g = 0.8, b = 0.2},
	[4] = {r = 0.4, g = 0.8, b = 0.2},
	[5] = {r = 0.0, g = 0.6, b = 0.8},
	[6] = {r = 0.0, g = 0.6, b = 0.8},
}

K.ComboColor = {
	[1] = {r = 1.0, g = 1.0, b = 1.0},
	[2] = {r = 1.0, g = 1.0, b = 1.0},
	[3] = {r = 1.0, g = 1.0, b = 1.0},
	[4] = {r = 0.9, g = 0.7, b = 0.0},
	[5] = {r = 1.0, g = 0.0, b = 0.0},
}

K.TimeColors = {
	[0] = "|cffeeeeee",
	[1] = "|cffeeeeee",
	[2] = "|cffeeeeee",
	[3] = "|cffeeeeee",
	[4] = "|cfffe0000"
}

K.TimeFormats = {
	[0] = {"%dd", "%dd"},
	[1] = {"%dh", "%dh"},
	[2] = {"%dm", "%dm"},
	[3] = {"%ds", "%d"},
	[4] = {"%.1fs", "%.1f"}
}

K.GetTimeInfo = function(s, threshhold)
	local Day, Hour, Minute = 86400, 3600, 60
	local Dayish, Hourish, Minuteish = 3600 * 23.5, 60 * 59.5, 59.5
	local HalfDayish, HalfHourish, HalfMinuteish = Day / 2 + 0.5, Hour / 2 + 0.5, Minute / 2 + 0.5

	if(s < Minute) then
		if(s >= threshhold) then
			return floor(s), 3, 0.51
		else
			return s, 4, 0.051
		end
	elseif(s < Hour) then
		local Minutes = floor((s / Minute) + 0.5)
		return ceil(s / Minute), 2, Minutes > 1 and (s - (Minutes * Minute - HalfMinuteish)) or (s - Minuteish)
	elseif(s < Day) then
		local Hours = floor((s / Hour) + 0.5)
		return ceil(s / Hour), 1, Hours > 1 and (s - (Hours * Hour - HalfHourish)) or (s - Hourish)
	else
		local Days = floor((s / Day) + 0.5)
		return ceil(s / Day), 0, Days > 1 and (s - (Days * Day - HalfDayish)) or (s - Dayish)
	end
end

K.FormatMoney = function(value)
	if value >= 1e4 then
		return format("|cffffd700%dg |r|cffc7c7cf%ds |r|cffeda55f%dc|r", value/1e4, strsub(value, -4) / 1e2, strsub(value, -2))
	elseif value >= 1e2 then
		return format("|cffc7c7cf%ds |r|cffeda55f%dc|r", strsub(value, -4) / 1e2, strsub(value, -2))
	else
		return format("|cffeda55f%dc|r", strsub(value, -2))
	end
end

-- Add time before calling a function
local waitTable = {}
local waitFrame
local MAX_WAIT_RECORDS = 100 -- Prevent unbounded growth

K.Delay = function(delay, func, ...)
	if(type(delay) ~= "number" or type(func) ~= "function") then
		return false
	end
	
	-- Cleanup abgelaufene Records wenn zu viele
	if #waitTable > MAX_WAIT_RECORDS then
		local cleaned = {}
		for i = 1, #waitTable do
			if waitTable[i][2] ~= nil then
				table.insert(cleaned, waitTable[i])
			end
		end
		waitTable = cleaned
	end
	
	if(waitFrame == nil) then
		waitFrame = CreateFrame("Frame", "WaitFrame", UIParent)
		waitFrame:SetScript("OnUpdate", function (self, elapse)
			local count = #waitTable
			local i = 1
			while(i <= count) do
				local waitRecord = waitTable[i]
				if(waitRecord[2] == nil) then
					tremove(waitTable, i)
					count = count - 1
				else
					local d = waitRecord[1]
					if(d > elapse) then
						waitRecord[1] = d - elapse
						i = i + 1
					else
						tremove(waitTable, i)
						count = count - 1
						
						-- Wrap callback in pcall
						local success, err = pcall(waitRecord[2], unpack(waitRecord[3]))
						if not success and C.General.DeveloperMode then
							K.Print("K.Delay callback error:", err)
						end
					end
				end
			end
			
			-- Stop OnUpdate wenn keine Delays mehr
			if count == 0 then
				self:SetScript("OnUpdate", nil)
			end
		end)
	end
	
	local record = {delay, func, {...}}
	tinsert(waitTable, record)
	
	-- Restart OnUpdate wenn gestoppt
	if not waitFrame:GetScript("OnUpdate") then
		waitFrame:SetScript("OnUpdate", waitFrame:GetScript("OnUpdate"))
	end
	
	return record
end

K.CancelDelay = function(record)
	if record then
		record[2] = nil
	end
end

-- Spell Info Cache (Issue #6 & #8: Reduce GetSpellInfo API calls)
K.SpellCache = {}
local SPELL_CACHE_LIMIT = 500 -- Prevent unbounded growth

K.GetSpellInfo = function(spellID)
	if not spellID then return nil end
	
	-- Check cache first
	if K.SpellCache[spellID] then
		return unpack(K.SpellCache[spellID])
	end
	
	-- Cache miss - fetch from API
	local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spellID)
	if name then
		-- Limit cache size
		if K.GetTableLength(K.SpellCache) >= SPELL_CACHE_LIMIT then
			-- Clear oldest entries (simple approach: clear half the cache)
			local count = 0
			for k in pairs(K.SpellCache) do
				K.SpellCache[k] = nil
				count = count + 1
				if count >= SPELL_CACHE_LIMIT / 2 then
					break
				end
			end
		end
		
		-- Store in cache
		K.SpellCache[spellID] = {name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange}
		return name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange
	end
	
	return nil
end

-- Helper function to get table length
K.GetTableLength = function(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

-- String Builder for efficient concatenation (Issue #6: Optimize string operations)
local stringBuilder = {}

K.BuildString = function(...)
	wipe(stringBuilder)
	local argCount = select("#", ...)
	for i = 1, argCount do
		local arg = select(i, ...)
		stringBuilder[i] = tostring(arg)
	end
	return table.concat(stringBuilder)
end


-- Config Validation System (Issue #7: Prevent invalid config errors)
K.ConfigValidationRules = {
	-- General settings
	["General.UIScale"] = {"number", 0.4, 1.2},
	["General.DeveloperMode"] = {"boolean"},
	["General.AutoScale"] = {"boolean"},
	
	-- Nameplate settings
	["Nameplate.Enable"] = {"boolean"},
	["Nameplate.Width"] = {"number", 50, 300},
	["Nameplate.Height"] = {"number", 5, 50},
	["Nameplate.AdditionalWidth"] = {"number", 0, 100},
	["Nameplate.AdditionalHeight"] = {"number", 0, 50},
	["Nameplate.AuraSize"] = {"number", 10, 50},
	["Nameplate.Auras"] = {"boolean"},
	["Nameplate.EnhanceThreat"] = {"boolean"},
	["Nameplate.HealthValue"] = {"boolean"},
	
	-- ActionBar settings
	["ActionBar.Enable"] = {"boolean"},
	["ActionBar.ButtonSize"] = {"number", 20, 60},
	["ActionBar.ButtonSpace"] = {"number", 1, 10},
	["ActionBar.Hotkey"] = {"boolean"},
	["ActionBar.Macro"] = {"boolean"},
	
	-- Unitframe settings
	["Unitframe.Enable"] = {"boolean"},
	["Unitframe.CastbarLatency"] = {"boolean"},
	["Unitframe.CombatFeedback"] = {"boolean"},
	
	-- Filger settings
	["Filger.Enable"] = {"boolean"},
	["Filger.TestMode"] = {"boolean"},
	["Filger.MaxTestIcon"] = {"number", 1, 20},
	
	-- Chat settings
	["Chat.Enable"] = {"boolean"},
	["Chat.WhisperSound"] = {"boolean"},
	["Chat.LinkBrackets"] = {"boolean"},
	
	-- Minimap settings
	["Minimap.Enable"] = {"boolean"},
	["Minimap.Size"] = {"number", 100, 300},
}

K.GetConfig = function(path, default)
	local keys = {strsplit(".", path)}
	local value = C
	for _, key in ipairs(keys) do
		if type(value) ~= "table" then
			if C.General.DeveloperMode then
				K.Print(format("Config path invalid: %s, using default: %s", path, tostring(default)))
			end
			return default
		end
		value = value[key]
		if value == nil then
			if C.General.DeveloperMode then
				K.Print(format("Config missing: %s, using default: %s", path, tostring(default)))
			end
			return default
		end
	end
	return value
end

K.ValidateConfig = function()
	local errors = {}
	local warnings = {}
	
	for path, rule in pairs(K.ConfigValidationRules) do
		local keys = {strsplit(".", path)}
		local value = C
		local pathValid = true
		
		-- Navigate to the config value
		for _, key in ipairs(keys) do
			if type(value) ~= "table" then
				pathValid = false
				break
			end
			value = value[key]
			if value == nil then
				pathValid = false
				break
			end
		end
		
		if pathValid and value ~= nil then
			local expectedType = rule[1]
			local actualType = type(value)
			
			-- Type check
			if actualType ~= expectedType then
				table.insert(errors, format("%s: expected %s, got %s (value: %s)", 
					path, expectedType, actualType, tostring(value)))
			elseif expectedType == "number" and rule[2] and rule[3] then
				-- Range check for numbers
				local min, max = rule[2], rule[3]
				if value < min or value > max then
					table.insert(warnings, format("%s: value %.2f out of recommended range [%.2f, %.2f]", 
						path, value, min, max))
				end
			end
		end
	end
	
	-- Report errors
	if #errors > 0 then
		K.Print("=== Config Validation Errors ===")
		for _, err in ipairs(errors) do
			K.Print("|cffff0000ERROR:|r " .. err)
		end
	end
	
	-- Report warnings
	if #warnings > 0 and C.General.DeveloperMode then
		K.Print("=== Config Validation Warnings ===")
		for _, warn in ipairs(warnings) do
			K.Print("|cffffff00WARNING:|r " .. warn)
		end
	end
	
	if #errors > 0 then
		K.Print("Config validation found errors. Use /budsui to fix settings.")
		return false
	end
	
	return true
end

-- Run config validation on login
local configValidationFrame = CreateFrame("Frame")
configValidationFrame:RegisterEvent("PLAYER_LOGIN")
configValidationFrame:SetScript("OnEvent", function()
	-- Delay validation to ensure all configs are loaded
	K.Delay(2, function()
		if C.General.DeveloperMode then
			K.Print("Running config validation...")
		end
		K.ValidateConfig()
	end)
end)
