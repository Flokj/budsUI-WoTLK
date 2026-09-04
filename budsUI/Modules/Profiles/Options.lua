local K, C, L, _ = select(2, ...):unpack()

-- API to set active profile for current character
function K.SetProfile(profileName)
	if not budsUIData.Profiles[profileName] then return false end
	local realmKey = K.Realm .. "-" .. K.Name
	budsUIData.ActiveProfiles[realmKey] = profileName
	return true
end

local ALLOWED_GROUPS = {
	["ActionBar"] = true, ["Announcements"] = true, ["Aura"] = true,
	["Automation"] = true, ["Bag"] = true, ["Blizzard"] = true,
	["Chat"] = true, ["Cooldown"] = true, ["Error"] = true,
	["Filger"] = true, ["General"] = true, ["Loot"] = true,
	["Minimap"] = true, ["Misc"] = true, ["MoverPositions"] = true,
	["Nameplate"] = true, ["PowerBar"] = true, ["PulseCD"] = true,
	["Skins"] = true, ["Tooltip"] = true, ["Unitframe"] = true,
}

-- API to create a new profile. If copyFrom is provided, deep copy it. Otherwise deep copy C
function K.CreateProfile(profileName, copyFrom)
	if budsUIData.Profiles[profileName] then return false end -- Already exists
	budsUIData.Profiles[profileName] = {}
	
	local sourceTable = C
	if type(copyFrom) == "table" then
		sourceTable = copyFrom
	elseif copyFrom and budsUIData.Profiles[copyFrom] then
		sourceTable = budsUIData.Profiles[copyFrom]
	end
	
	for group, options in pairs(sourceTable) do
		if type(options) == "table" and ALLOWED_GROUPS[group] then
			budsUIData.Profiles[profileName][group] = {}
			for option, value in pairs(options) do
				if type(value) == "table" then
					budsUIData.Profiles[profileName][group][option] = {}
					for k, v in pairs(value) do
						budsUIData.Profiles[profileName][group][option][k] = v
					end
				else
					budsUIData.Profiles[profileName][group][option] = value
				end
			end
		end
	end
	return true
end

-- API to delete a profile
function K.DeleteProfile(profileName)
	if budsUIData.Profiles[profileName] then
		budsUIData.Profiles[profileName] = nil
		return true
	end
	return false
end

-- API to get currently active profile name
function K.GetActiveProfile()
	local realmKey = K.Realm .. "-" .. K.Name
	return budsUIData.ActiveProfiles[realmKey] or "Unknown"
end

-- API to rename a profile
function K.RenameProfile(oldName, newName)
	if not budsUIData.Profiles[oldName] then return false end
	if budsUIData.Profiles[newName] then return false end -- Target name already exists
	if oldName == newName then return false end
	
	budsUIData.Profiles[newName] = budsUIData.Profiles[oldName]
	budsUIData.Profiles[oldName] = nil
	
	-- Update all character mappings that pointed to the old name
	for realmKey, profileName in pairs(budsUIData.ActiveProfiles) do
		if profileName == oldName then
			budsUIData.ActiveProfiles[realmKey] = newName
		end
	end
	return true
end

-- API to save current live C values into the active profile
function K.SaveProfile()
	local activeProfile = K.GetActiveProfile()
	if not activeProfile or not budsUIData.Profiles[activeProfile] then return false end
	
	for group, options in pairs(C) do
		if type(options) == "table" and ALLOWED_GROUPS[group] then
			if not budsUIData.Profiles[activeProfile][group] then
				budsUIData.Profiles[activeProfile][group] = {}
			end
			for option, value in pairs(options) do
				if type(value) == "table" then
					budsUIData.Profiles[activeProfile][group][option] = {}
					for k, v in pairs(value) do
						budsUIData.Profiles[activeProfile][group][option][k] = v
					end
				else
					budsUIData.Profiles[activeProfile][group][option] = value
				end
			end
		end
	end
	return true
end

-- Simple Lua table serializer (for profile export/import)
local function SerializeValue(val, indent)
	local t = type(val)
	if t == "string" then
		return string.format("%q", val)
	elseif t == "number" then
		return tostring(val)
	elseif t == "boolean" then
		return val and "true" or "false"
	elseif t == "table" then
		local parts = {}
		local prefix = string.rep(" ", indent or 0)
		local inner = prefix .. " "
		
		-- Sort keys for deterministic output
		local keys = {}
		for k in pairs(val) do table.insert(keys, k) end
		table.sort(keys, function(a, b)
			if type(a) == type(b) then return tostring(a) < tostring(b) end
			return type(a) < type(b)
		end)
		for _, k in ipairs(keys) do
			local keyStr
			if type(k) == "string" then
				keyStr = "[" .. string.format("%q", k) .. "]"
			else
				keyStr = "[" .. tostring(k) .. "]"
			end
			table.insert(parts, inner .. keyStr .. "=" .. SerializeValue(val[k], (indent or 0) + 1))
		end
		if #parts == 0 then return "{}" end
		return "{\n" .. table.concat(parts, ",\n") .. "\n" .. prefix .. "}"
	end
	return "nil"
end

-- API to export a profile as a copyable string
function K.ExportProfile(profileName)
	local data = budsUIData.Profiles[profileName]
	if not data then return nil end
	return SerializeValue(data, 0)
end

-- Simple Lua table deserializer (for profile import)
function K.ImportProfile(profileName, dataString)
	if not dataString or dataString == "" then return false end
	if budsUIData.Profiles[profileName] then return false end -- Name already exists
	
	-- Security: Only allow table literals, no function calls
	-- Check for dangerous patterns
	if dataString:find("[%a_][%w_]*%s*%(") then return false end -- function calls
	if dataString:find("loadstring") then return false end
	if dataString:find("dofile") then return false end
	if dataString:find("pcall") then return false end
	if dataString:find("require") then return false end
	
	local func = loadstring("return " .. dataString)
	if not func then return false end
	
	-- Execute in a sandboxed environment
	setfenv(func, {})
	local ok, result = pcall(func)
	if not ok or type(result) ~= "table" then return false end
	
	budsUIData.Profiles[profileName] = result
	return true
end
