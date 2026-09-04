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

-- A local function returning the hardcoded Buds Preset, replacing the old BudtenderPreset.lua
local function GetBudsPreset()
	return {
		["ActionBar"] = {
			["BottomBars"] = 3,
			["ButtonSize"] = 36,
			["ButtonSpace"] = 3,
			["Enable"] = true,
			["EquipBorder"] = true,
			["Hotkey"] = true,
			["Macro"] = true,
			["OutOfMana"] = {0.50196078431373, 0.50196078431373, 1},
			["OutOfRange"] = {0.8, 0.10196078431373, 0.10196078431373},
			["PetBarHide"] = false,
			["PetBarHorizontal"] = false,
			["RightBars"] = 2,
			["Selfcast"] = false,
			["ShowGrid"] = true,
			["SplitBars"] = false,
			["StanceBarHide"] = false,
			["StanceBarHorizontal"] = true,
			["ToggleMode"] = true,
		},
		["Announcements"] = {
			["Bad_Gear"] = true,
			["Feasts"] = true,
			["Interrupt"] = false,
			["Portals"] = true,
			["PullCountdown"] = true,
			["SaySapped"] = true,
			["Spells"] = false,
			["SpellsFromAll"] = false,
			["Toys"] = false,
		},
		["Aura"] = {
			["BuffSize"] = 32,
			["CastBy"] = false,
			["ClassColorBorder"] = false,
			["Enable"] = false,
		},
		["Automation"] = {
			["AutoCollapse"] = true,
			["AutoInvite"] = false,
			["DeclineDuel"] = false,
			["LoggingCombat"] = false,
			["Resurrection"] = false,
			["ScreenShot"] = false,
			["SellGreyRepair"] = true,
			["TabBinder"] = true,
		},
		["Bag"] = {
			["BagColumns"] = 10,
			["BankColumns"] = 17,
			["ButtonSize"] = 34,
			["ButtonSpace"] = 4,
			["Enable"] = true,
			["HideSoulBag"] = false,
		},
		["Blizzard"] = {
			["Capturebar"] = true,
			["ClassColor"] = true,
			["DarkTextures"] = false,
			["DarkTexturesColor"] = {0.30196078431373, 0.30196078431373, 0.30196078431373},
			["Durability"] = true,
			["MoveAchievements"] = true,
			["Reputations"] = true,
		},
		["Chat"] = {
			["CombatLog"] = true,
			["DamageMeterSpam"] = false,
			["Enable"] = true,
			["FadeTime"] = 20,
			["Fading"] = false,
			["Filter"] = true,
			["Height"] = 150,
			["HideTextures"] = true,
			["Outline"] = false,
			["Spam"] = false,
			["Sticky"] = true,
			["TabsMouseover"] = false,
			["TabsOutline"] = false,
			["WhispSound"] = true,
			["Width"] = 500,
		},
		["Cooldown"] = {
			["Enable"] = true,
			["FontSize"] = 20,
			["Threshold"] = 3,
		},
		["Error"] = {
			["Black"] = true,
			["Combat"] = false,
			["White"] = false,
		},
		["Filger"] = {
			["BuffsSize"] = 37,
			["CooldownSize"] = 30,
			["Enable"] = true,
			["MaxTestIcon"] = 5,
			["PvPSize"] = 60,
			["ShowTooltip"] = false,
			["TestMode"] = false,
		},
		["General"] = {
			["AutoScale"] = true,
			["BubbleBackdrop"] = false,
			["BubbleFontSize"] = 12,
			["DeveloperMode"] = false,
			["MultisampleCheck"] = false,
			["ReplaceBlizzardFonts"] = true,
			["UIScale"] = 0.71111111111111,
			["WelcomeMessage"] = true,
		},
		["Loot"] = {
			["AutoGreed"] = true,
			["ConfirmDisenchant"] = true,
			["Enable"] = false,
			["GroupLoot"] = true,
			["IconSize"] = 30,
			["LootFilter"] = true,
			["Width"] = 222,
		},
		["Minimap"] = {
			["CollectButtons"] = true,
			["Enable"] = true,
			["Ping"] = true,
			["Size"] = 150,
		},
		["Misc"] = {
			["AFKCamera"] = true,
			["AlreadyKnown"] = true,
			["Armory"] = false,
			["BGSpam"] = true,
			["DurabilityWarning"] = true,
			["EnhancedMail"] = true,
			["HatTrick"] = true,
			["InviteKeyword"] = "inv",
			["ItemLevel"] = true,
			["SpeedyLoad"] = false,
		},
		["MoverPositions"] = {
			["TargetCastbarAnchor"] = {"CENTER", "UIParent", "CENTER", 0, -127},
		},
		["Nameplate"] = {
			["AdditionalHeight"] = 0,
			["AdditionalWidth"] = 0,
			["AuraSize"] = 20,
			["Auras"] = false,
			["BadColor"] = {0.78039215686275, 0.25098039215686, 0.25098039215686},
			["CastBarName"] = true,
			["ClassIcons"] = false,
			["Combat"] = false,
			["Enable"] = true,
			["EnhanceThreat"] = false,
			["GoodColor"] = {0.29019607843137, 0.67843137254902, 0.29019607843137},
			["HealthValue"] = true,
			["Height"] = 9,
			["NameAbbreviate"] = true,
			["NearColor"] = {0.85098039215686, 0.76862745098039, 0.36078431372549},
			["Width"] = 120,
		},
		["PowerBar"] = {
			["Combo"] = true,
			["DKRuneBar"] = false,
			["Enable"] = false,
			["FontOutline"] = false,
			["Height"] = 4,
			["Maelstrom"] = true,
			["MaelstromPulse"] = true,
			["MaelstromPulseAt"] = 5,
			["MaelstromSize"] = 256,
			["Mana"] = true,
			["Rage"] = false,
			["Rune"] = false,
			["RuneCooldown"] = false,
			["ValueAbbreviate"] = true,
			["Width"] = 200,
		},
		["PulseCD"] = {
			["AnimationScale"] = 1.5,
			["Enable"] = true,
			["HoldTime"] = 0,
			["Size"] = 75,
			["Sound"] = false,
			["Threshold"] = 3,
		},
		["Skins"] = {
			["CLCRet"] = false,
			["ChatBubble"] = true,
			["DBM"] = true,
			["MinimapButtons"] = true,
			["Recount"] = false,
			["Skada"] = false,
			["Spy"] = false,
			["WeakAuras"] = false,
			["WorldMap"] = true,
		},
		["Tooltip"] = {
			["Achievements"] = true,
			["ArenaExperience"] = true,
			["Cursor"] = true,
			["Enable"] = true,
			["HealthValue"] = true,
			["HideButtons"] = false,
			["HideCombat"] = false,
			["InstanceLock"] = false,
			["ItemCount"] = true,
			["ItemIcon"] = true,
			["QualityBorder"] = true,
			["RaidIcon"] = false,
			["Rank"] = false,
			["Scale"] = 1,
			["SpellID"] = false,
			["Talents"] = false,
			["Target"] = true,
			["Title"] = true,
			["WhoTargetting"] = false,
		},
		["Unitframe"] = {
			["AuraOffsetY"] = 3,
			["BetterPowerColors"] = false,
			["CastBarScale"] = 1.2,
			["ClassHealth"] = true,
			["ClassIcon"] = false,
			["ComboFrame"] = true,
			["CombatFeedback"] = true,
			["Enable"] = true,
			["EnhancedFrames"] = true,
			["GroupNumber"] = false,
			["LargeAuraSize"] = 26,
			["Outline"] = false,
			["PercentHealth"] = false,
			["PvPIcon"] = true,
			["Scale"] = 1.2,
			["SmallAuraSize"] = 22,
			["SmoothBars"] = false,
		},
	}
end

K.GetBudsPreset = GetBudsPreset

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
