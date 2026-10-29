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
	["Filger"] = true, ["General"] = true, ["InternalCooldowns"] = true, ["Loot"] = true,
	["Minimap"] = true, ["Misc"] = true, ["MoverPositions"] = true,
	["Nameplate"] = true, ["PowerBar"] = true, ["PulseCD"] = true,
	["Skins"] = true, ["ThreatMeter"] = true, ["Tooltip"] = true, ["Unitframe"] = true,
}

-- ---------------------------------------------------------------------------
-- Delta / Pruning Helper
-- ---------------------------------------------------------------------------
local EPSILON = 0.0001
local function SameValue(a, b)
	if type(a) == "number" and type(b) == "number" then
		return math.abs(a - b) < EPSILON
	end
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return a == b
	end
	for k, v in pairs(a) do
		if not SameValue(v, b[k]) then
			return false
		end
	end
	for k in pairs(b) do
		if a[k] == nil then
			return false
		end
	end
	return true
end

local function PruneTable(target, defaults)
	if type(target) ~= "table" or type(defaults) ~= "table" then
		return
	end
	for key, value in pairs(target) do
		local default = defaults[key]
		if default ~= nil and SameValue(value, default) then
			target[key] = nil
		elseif type(value) == "table" and type(default) == "table" then
			PruneTable(value, default)
			if next(value) == nil then
				target[key] = nil
			end
		end
	end
end

function K.PruneProfile(profile)
	if type(profile) ~= "table" or type(K.ConfigDefaults) ~= "table" then
		return profile
	end
	PruneTable(profile, K.ConfigDefaults)
	return profile
end

-- API to create a new profile. If copyFrom is provided, deep copy it and prune. Otherwise start clean (empty delta).
function K.CreateProfile(profileName, copyFrom)
	if budsUIData.Profiles[profileName] then return false end -- Already exists
	local newProfile = {}
	if type(copyFrom) == "table" then
		newProfile = CopyTable(copyFrom)
	elseif copyFrom and budsUIData.Profiles[copyFrom] then
		newProfile = CopyTable(budsUIData.Profiles[copyFrom])
	else
		-- New clean profile inherits pristine defaults, delta starts empty!
		newProfile = {}
	end
	K.PruneProfile(newProfile)
	budsUIData.Profiles[profileName] = newProfile
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

-- API to save current live C values into the active profile as a clean delta
function K.SaveProfile()
	local activeProfile = K.GetActiveProfile()
	if not activeProfile or not budsUIData.Profiles[activeProfile] then return false end
	local P = budsUIData.Profiles[activeProfile]

	for group, options in pairs(C) do
		if type(options) == "table" and ALLOWED_GROUPS[group] then
			for option, value in pairs(options) do
				local def = K.ConfigDefaults and K.ConfigDefaults[group] and K.ConfigDefaults[group][option]
				if not SameValue(value, def) then
					if not P[group] then P[group] = {} end
					if type(value) == "table" then
						P[group][option] = CopyTable(value)
					else
						P[group][option] = value
					end
				elseif P[group] and P[group][option] ~= nil then
					P[group][option] = nil
				end
			end
			if P[group] and next(P[group]) == nil then
				P[group] = nil
			end
		end
	end
	return true
end

local EXPORT_PREFIX = "BUDS1:"

-- API to export a profile as a compact encoded string
function K.ExportProfile(profileName)
	local data = budsUIData.Profiles[profileName]
	if not data then return nil end
	local copy = CopyTable(data)
	K.PruneProfile(copy)
	local payload = {
		version = K.PROFILE_SCHEMA_VERSION or 1,
		profile = copy,
	}
	if K.Serialize and K.Encode then
		local serialized = K.Serialize(payload)
		local encoded = K.Encode(serialized)
		if encoded then
			return EXPORT_PREFIX .. encoded
		end
	end
	-- Fallback to table serializer if encode fails
	return K.Serialize and K.Serialize(copy) or nil
end

-- API to import a profile from an exported string
function K.ImportProfile(profileName, dataString)
	if not dataString or dataString == "" then return false end
	if budsUIData.Profiles[profileName] then return false end -- Name already exists
	dataString = strtrim(dataString)

	local profileData
	if dataString:sub(1, #EXPORT_PREFIX) == EXPORT_PREFIX then
		if not K.Decode or not K.Deserialize then return false end
		local decoded, err = K.Decode(dataString:sub(#EXPORT_PREFIX + 1))
		if not decoded then
			return false, err
		end
		local payload = K.Deserialize(decoded)
		if type(payload) ~= "table" then
			return false, "malformed payload"
		end
		local version = payload.version or 1
		local data = payload.profile or payload
		if K.MigrateProfile then
			K.MigrateProfile(data, version)
		end
		K.PruneProfile(data)
		profileData = data
	else
		-- Legacy fallback: raw Lua table string
		if dataString:find("[%a_][%w_]*%s*%(") then return false end
		if dataString:find("loadstring") or dataString:find("dofile") or dataString:find("pcall") or dataString:find("require") then
			return false
		end
		local parsed = K.Deserialize and K.Deserialize(dataString)
		if not parsed then
			local func = loadstring("return " .. dataString)
			if not func then return false end
			setfenv(func, {})
			local ok, result = pcall(func)
			if not ok or type(result) ~= "table" then return false end
			parsed = result
		end
		K.PruneProfile(parsed)
		profileData = parsed
	end

	budsUIData.Profiles[profileName] = profileData
	return true
end
