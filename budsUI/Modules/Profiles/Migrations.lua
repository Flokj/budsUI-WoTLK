local K, C, L, _ = select(2, ...):unpack()

K.PROFILE_SCHEMA_VERSION = 1

local migrations = {}

-- Migration 1: Prune bloated legacy full-dump profiles against K.ConfigDefaults
migrations[1] = function(profile)
	if type(profile) == "table" and K.PruneProfile then
		K.PruneProfile(profile)
	end
end

function K.MigrateProfile(profile, fromVersion)
	if type(profile) ~= "table" then return profile end
	fromVersion = tonumber(fromVersion) or 0
	for v = fromVersion + 1, K.PROFILE_SCHEMA_VERSION do
		if migrations[v] then
			migrations[v](profile)
		end
	end
	return profile
end

function K.RunAllMigrations()
	if type(budsUIData) ~= "table" then return end
	local currentVersion = tonumber(budsUIData.SchemaVersion) or 0
	if currentVersion < K.PROFILE_SCHEMA_VERSION then
		if type(budsUIData.Profiles) == "table" then
			for _, profile in pairs(budsUIData.Profiles) do
				K.MigrateProfile(profile, currentVersion)
			end
		end
		budsUIData.SchemaVersion = K.PROFILE_SCHEMA_VERSION
	end
end
