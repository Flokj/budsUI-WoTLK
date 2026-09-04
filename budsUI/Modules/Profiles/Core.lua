local K, C, L, _ = select(2, ...):unpack()

-- Initialize Profile System Data Structure if it doesn't exist
if type(budsUIData) ~= "table" then
	budsUIData = {
		ActiveProfiles = {},
		CharacterData = {},
		Profiles = {}
	}
end

if type(budsUIData.ActiveProfiles) ~= "table" then budsUIData.ActiveProfiles = {} end
if type(budsUIData.CharacterData) ~= "table" then budsUIData.CharacterData = {} end
if type(budsUIData.Profiles) ~= "table" then budsUIData.Profiles = {} end

-- Reusable merge function: applies profile settings over C defaults
local function MergeProfileIntoC()
	if type(budsUIData) ~= "table" then return end
	if type(budsUIData.ActiveProfiles) ~= "table" then return end
	if type(budsUIData.Profiles) ~= "table" then return end
	
	local realmKey = K.Realm .. "-" .. K.Name
	local activeProfileName = budsUIData.ActiveProfiles[realmKey]
	
	if activeProfileName and budsUIData.Profiles[activeProfileName] then
		local profileSettings = budsUIData.Profiles[activeProfileName]
		
		for group, options in pairs(profileSettings) do
			if C[group] then
				if group == "MoverPositions" then
					C[group] = {}
					for option, value in pairs(options) do
						C[group][option] = value
					end
				else
					for option, value in pairs(options) do
						if C[group][option] ~= nil then
							if type(value) == "table" and type(C[group][option]) == "table" then
								for k, v in pairs(value) do
									C[group][option][k] = v
								end
							else
								C[group][option] = value
							end
						end
					end
				end
			end
		end
	end
end

-- Helper function to ensure a valid profile exists for the current character
local function EnsureValidProfile()
	local realmKey = K.Realm .. "-" .. K.Name
	local activeProfileName = budsUIData.ActiveProfiles[realmKey]
	
	-- Check if we have a valid active profile
	if not activeProfileName or not budsUIData.Profiles[activeProfileName] then
		-- No valid profile exists, create a default one
		local defaultProfileName = "Default"
		
		-- If "Default" already exists but isn't assigned, use it
		if not budsUIData.Profiles[defaultProfileName] then
			-- Create new default profile from current C settings
			K.CreateProfile(defaultProfileName)
		end
		
		-- Assign this profile to the current character
		budsUIData.ActiveProfiles[realmKey] = defaultProfileName
	end
end

-- 1) File-load merge: runs immediately so modules that check C.xxx.Enable get correct values
MergeProfileIntoC()

-- 2) ADDON_LOADED merge: fallback in case SavedVariables loaded after file execution
local profileMergeFrame = CreateFrame("Frame")
profileMergeFrame:RegisterEvent("ADDON_LOADED")
profileMergeFrame:SetScript("OnEvent", function(self, event, addon)
	if addon ~= "budsUI" then return end
	
	-- Re-validate structure after WTF data is guaranteed loaded
	if type(budsUIData) ~= "table" then
		budsUIData = { ActiveProfiles = {}, CharacterData = {}, Profiles = {} }
	end
	if type(budsUIData.ActiveProfiles) ~= "table" then budsUIData.ActiveProfiles = {} end
	if type(budsUIData.CharacterData) ~= "table" then budsUIData.CharacterData = {} end
	if type(budsUIData.Profiles) ~= "table" then budsUIData.Profiles = {} end
	
	-- Ensure a valid profile exists for this character
	EnsureValidProfile()
	
	MergeProfileIntoC()
	self:UnregisterEvent(event)
end)
