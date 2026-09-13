local K, C, L, _ = select(2, ...):unpack()

-- Media Options
C["Media"] = {
	["Backdrop_Color"] = {6/255, 6/255, 6/255, 0.9},
	["Blank"] = [[Interface\AddOns\]] .. K.Directory .. [[\Media\Textures\Blank]],
	["Blank_Font"] = [[Interface\AddOns\]] .. K.Directory .. [[\Media\Fonts\Invisible.ttf]],
	["Blizz"] = [[Interface\AddOns\]] .. K.Directory .. [[\Media\Border\Border_Default.tga]],
	["Border_Color"] = {134/255, 134/255, 134/255, 1},
	["Border_Glow"] = [[Interface\AddOns\]] .. K.Directory .. [[\Media\Border\Border_Glow.tga]],
	["Combat_Font"] = [[Interface\AddOns\]] .. K.Directory .. [[\Media\Fonts\Damage.ttf]],
	["Combat_Font_Size"] = 16,
	["Combat_Font_Size_Style"] = "OUTLINE",
	["Font"] = [[Interface\AddOns\]] .. K.Directory .. [[\Media\Fonts\Normal.ttf]],
	["Font_Size"] = 13,
	["Font_Style"] = "OUTLINE",
	["Glow"] = [[Interface\AddOns\]] .. K.Directory .. [[\Media\Textures\GlowTex.tga]],
	["Overlay_Color"] = {0/255, 0/255, 0/255, 0.9},
	["Proc_Sound"] = [[Interface\AddOns\]] .. K.Directory .. [[\Media\Sounds\Proc.ogg]],
	["Texture"] = [[Interface\TargetingFrame\UI-StatusBar]],
	["Warning_Sound"] = [[Interface\AddOns\]] .. K.Directory .. [[\Media\Sounds\Warning.ogg]],
	["Whisp_Sound"] = [[Interface\AddOns\]] .. K.Directory .. [[\Media\Sounds\Whisper.ogg]],
}
-- ActionBar Options
C["ActionBar"] = {
	["BottomBars"] = 3,
	["ButtonSize"] = 36,
	["ButtonSpace"] = 3,
	["Enable"] = true,
	["EquipBorder"] = true,
	["Hotkey"] = true,
	["Macro"] = true,
	["OutOfMana"] = {128/255, 128/255, 255/255},
	["OutOfRange"] = {204/255, 26/255, 26/255},
	["PetBarHide"] = false,
	["PetBarHorizontal"] = true,
	["RightBars"] = 2,
	["Selfcast"] = false,
	["ShowGrid"] = true,
	["SplitBars"] = false,
	["StanceBarHide"] = false,
	["StanceBarHorizontal"] = true,
}
-- Announcements Options
C["Announcements"] = {
	["Bad_Gear"] = false,
	["Feasts"] = false,
	["Interrupt"] = false,
	["Portals"] = false,
	["PullCountdown"] = true,
	["SaySapped"] = true,
	["Spells"] = false,
	["SpellsFromAll"] = false,
	["Toys"] = false,
}
-- Automation Options
C["Automation"] = {
	["AutoCollapse"] = true,
	["AutoInvite"] = false,
	["DeclineDuel"] = false,
	["LoggingCombat"] = false,
	["Resurrection"] = true,
	["ScreenShot"] = false,
	["SellGreyRepair"] = true,
	["TabBinder"] = true,
}
-- Bag Options
C["Bag"] = {
	["BagColumns"] = 10,
	["BankColumns"] = 17,
	["ButtonSize"] = 34,
	["ButtonSpace"] = 4,
	["Enable"] = true,
	["HideSoulBag"] = false,
}
-- Blizzard Options
C["Blizzard"] = {
	["CaptureBar"] = true,
	["ClassColor"] = true,
	["Durability"] = true,
	["EnhanceProfessions"] = true,
	["EnhanceTrainers"] = true,
	["TrainAllButton"] = true,
	["MoveAchievements"] = true,
	["Reputations"] = true,
}
-- Buffs & Debuffs Options
C["Aura"] = {
	["Enable"] = true,
	["BuffSize"] = 36,
	["CastBy"] = true,
	["ClassColorBorder"] = true,
}
-- Chat Options
C["Chat"] = {
	["BigHeight"] = 450,
	["BigWidth"] = 450,
	["HideTextures"] = true,
	["CombatLog"] = true,
	["DamageMeterSpam"] = false,
	["Enable"] = true,
	["Fading"] = false,
	["Filter"] = true,
	["Height"] = 220,
	["Outline"] = false,
	["Spam"] = false,
	["FadeTime"] = 20,
	["Sticky"] = true,
	["TabsMouseover"] = true,
	["TabsOutline"] = false,
	["WhispSound"] = true,
	["Width"] = 420,
}
-- Cooldown Options
C["Cooldown"] = {
	["Enable"] = true,
	["FontSize"] = 18,
	["Threshold"] = 3,
	["IgnoreWeakAuras"] = false,
}
-- Error Options
C["Error"] = {
	["Black"] = true,
	["White"] = false,
	["Combat"] = false,
}
-- Filger Options
C["Filger"] = {
	["BuffsSize"] = 34,
	["CooldownSize"] = 24,
	["Enable"] = true,
	["MaxTestIcon"] = 5,
	["PvPSize"] = 42,
	["ShowTooltip"] = false,
	["TestMode"] = false,
}
-- General Options
C["General"] = {
	["AutoScale"] = true,
	["BubbleFontSize"] = 12,
	["BubbleBackdrop"] = false,
	["ReplaceBlizzardFonts"] = true,
	["UIScale"] = 0.71,
	["MultisampleCheck"] = false,
	["WelcomeMessage"] = true,
	["DeveloperMode"] = false,
}
-- Loot Options
C["Loot"] = {
	["ConfirmDisenchant"] = false,
	["AutoGreed"] = false,
	["LootFilter"] = true,
	["IconSize"] = 30,
	["Enable"] = true,
	["GroupLoot"] = true,
	["Width"] = 222,
}
-- Minimap Options
C["Minimap"] = {
	["CollectButtons"] = true,
	["CollectDelay"] = 5,
	["Enable"] = true,
	["Ping"] = false,
	["CDR"] = true,
	["Size"] = 180,
	["SizeFarm"] = 300,
	["SizeNormal"] = 180,
	["Offsets"] = {
		["Mail"] = {2, 8},
		["Battlefield"] = {4, -4},
		["Calendar"] = {0, 5},
		["LFG"] = {2, -2},
		["Clock"] = {0, -5},
		["RightClick"] = {0, 0, -160, 0},
	}
}
-- Miscellaneous Options
C["Misc"] = {
	["AFKCamera"] = false,
	["AlreadyKnown"] = true,
	["Armory"] = false,
	["BGSpam"] = true,
	["DurabilityWarning"] = true,
	["EnhancedMail"] = true,
	["HatTrick"] = true,
	["InviteKeyword"] = "inv",
	["ItemLevel"] = true,
	["SpeedyLoad"] = false,
}
-- Nameplate Options
C["Nameplate"] = {
	["AdditionalHeight"] = 0,
	["AdditionalWidth"] = 0,
	["AuraSize"] = 20,
	["BadColor"] = {199/255, 64/255, 64/255},
	["ClassIcons"] = false,
	["Combat"] = false,
	["Enable"] = true,
	["EnhanceThreat"] = true,
	["GoodColor"] = {74/255, 173/255, 74/255},
	["HealthValue"] = true,
	["Height"] = 18,
	["NameAbbreviate"] = true,
	["NearColor"] = {217/255, 196/255, 92/255},
	["CastBarName"] = true,
	["Auras"] = false,
	["Width"] = 180,
}
-- PowerBar Options
C["PowerBar"] = {
	["Enable"] = false,
	["FontOutline"] = false,
	["Height"] = 4,
	["DKRuneBar"] = false,
	["Combo"] = false,
	["Maelstrom"] = true,
	["MaelstromSize"] = 256,
	["MaelstromPulse"] = true,
	["MaelstromPulseAt"] = 5,
	["MaelstromSpellID"] = 1153817, -- Ascension: Maelstrom Weapon
	["MaelstromKillList"] = {
		[1153817] = true, -- Ascension Maelstrom Weapon
		[53817] = true,   -- Standard WotLK Maelstrom Weapon
		[344179] = true,
		[187881] = true,
		[467442] = true,
		[170586] = true,
		[170587] = true,
		[170588] = true,
		[187890] = true,
		[170585] = true,
	},
	["Mana"] = true,
	["Rage"] = false,
	["Rune"] = false,
	["RuneCooldown"] = false,
	["ValueAbbreviate"] = true,
	["Width"] = 200,
}
-- PulseCD Options
C["PulseCD"] = {
	["Enable"] = false,
	["Size"] = 75,
	["Sound"] = false,
	["AnimationScale"] = 1.5,
	["HoldTime"] = 0,
	["Threshold"] = 3,
}
-- Skins Options
C["Skins"] = {
	["Spy"] = false,
	["ChatBubble"] = true,
	["CLCRet"] = false,
	["DBM"] = true,
	["MinimapButtons"] = true,
	["RaidRoll"] = true,
	["Recount"] = false,
	["Skada"] = true,
	["WeakAuras"] = true,
	["WorldMap"] = false,
	["WorldMapScale"] = 0.80,
	["WorldMapScaleMini"] = 1.20,
}
-- Tooltip Options
C["Tooltip"] = {
	["Scale"] = 1,
	["Achievements"] = false,
	["ArenaExperience"] = false,
	["Cursor"] = false,
	["Enable"] = true,
	["HealthValue"] = true,
	["HideCombat"] = false,
	["HideButtons"] = false,
	["InstanceLock"] = false,
	["ItemCount"] = true,
	["ItemIcon"] = true,
	["QualityBorder"] = true,
	["RaidIcon"] = true,
	["Rank"] = false,
	["SpellID"] = true,
	["Talents"] = true,
	["Target"] = true,
	["Title"] = true,
	["WhoTargetting"] = true,
}
-- Unitframe Options (oUF-based frames ported from KkthnxUI; Enable gates spawning)
C["Unitframe"] = {
	["Enable"] = true,
	["Texture"] = "budsUI_StatusBar",
	["ClassHealth"] = true,
	["ClassColorBorder"] = true,
	["ThreatHealthColor"] = false,
	["BarBackdrop"] = true,
	["Portrait"] = false,
	["PortraitStyle"] = "3D", -- 3D, 2D, Class
	["HealthPrediction"] = true, -- incoming heals on the health bar
	["RangeFade"] = false, -- need fix
	["RangeAlpha"] = 0.4,
	["GroupDispelOnly"] = true, -- party/raid debuffs: only ones you can dispel
	["AuraWatch"] = true, -- corner dots on party/raid frames for tracked heals

	["HealthFormat"] = "Both", -- None, Current, Percent, Both
	["PowerFormat"] = "Current", -- None, Current, Percent, Both
	["NameColor"] = true,
	["NameLength"] = 18,
	["NameBackground"] = false, -- dark strip behind the name/level texts
	["FontOutline"] = false, -- OUTLINE on unitframe texts instead of shadow

	["PowerColors"] = {
		["MANA"] = { 0.36, 0.55, 0.81 },
		["RAGE"] = { 0.82, 0.31, 0.31 },
		["FOCUS"] = { 0.90, 0.52, 0.28 },
		["ENERGY"] = { 0.95, 0.76, 0.32 },
		["RUNIC_POWER"] = { 0.33, 0.72, 0.88 },
	},
	["ReactionColors"] = {
		[1] = { 0.82, 0.31, 0.31 },
		[2] = { 0.82, 0.31, 0.31 },
		[3] = { 0.85, 0.45, 0.25 },
		[4] = { 0.95, 0.76, 0.32 },
		[5] = { 0.22, 0.80, 0.30 },
		[6] = { 0.22, 0.80, 0.30 },
		[7] = { 0.22, 0.80, 0.30 },
		[8] = { 0.36, 0.72, 0.88 },
	},

	["Player"] = { ["Enable"] = true, ["Width"] = 190, ["Height"] = 36, ["PowerHeight"] = 16, ["ShowPower"] = true, ["Buffs"] = false, ["Debuffs"] = false, ["ClassPower"] = true, ["AdditionalPower"] = true, ["ShowName"] = false },
	["Target"] = { ["Enable"] = true, ["Width"] = 190, ["Height"] = 36, ["PowerHeight"] = 16, ["ShowPower"] = true, ["Buffs"] = true, ["Debuffs"] = true },
	["TargetOfTarget"] = { ["Enable"] = true, ["Width"] = 90, ["Height"] = 24, ["PowerHeight"] = 12, ["ShowPower"] = false },
	["Pet"] = { ["Enable"] = true, ["Width"] = 90, ["Height"] = 18, ["PowerHeight"] = 12, ["ShowPower"] = true, ["Debuffs"] = false },
	["Focus"] = { ["Enable"] = true, ["Width"] = 180, ["Height"] = 28, ["PowerHeight"] = 12, ["ShowPower"] = true, ["Debuffs"] = true },
	["FocusTarget"] = { ["Enable"] = false, ["Width"] = 80, ["Height"] = 18, ["PowerHeight"] = 12, ["ShowPower"] = true },
	["Party"] = { ["Enable"] = false, ["Width"] = 150, ["Height"] = 22, ["PowerHeight"] = 12, ["ShowPower"] = true, ["ShowSolo"] = false, ["ShowPlayer"] = true, ["Debuffs"] = true, ["DispelHighlight"] = true, ["Portrait"] = false, ["Castbar"] = true, ["RaidStyle"] = false },
	-- Height is the health bar, the power bar (PowerHeight) sits below it.
	-- PowerMode: All, Mana, or None.
	["Raid"] = { ["Enable"] = false, ["Width"] = 80, ["Height"] = 24, ["PowerHeight"] = 6, ["PowerGap"] = 6, ["PowerMode"] = "All", ["GroupsPerRow"] = 5, ["GroupBy"] = "GROUP", ["RaidWide"] = false, ["SortDirection"] = "ASC", ["Orientation"] = "DOWN_RIGHT", ["DispelHighlight"] = true, ["ShowGroupNumber"] = true },
	["Boss"] = { ["Enable"] = true, ["Width"] = 150, ["Height"] = 24, ["PowerHeight"] = 12, ["ShowPower"] = true, ["Spacing"] = 34, ["Debuffs"] = true, ["Castbar"] = true, ["Portrait"] = true },

	["Auras"] = {
		["PerRow"] = 6,
		["NumBuffs"] = 24,
		["NumDebuffs"] = 6,
		["Spacing"] = 6,
		["OnlyPlayerDebuffs"] = false,
	},

	["ClassPower"] = {
		["Height"] = 14,
		["Spacing"] = 6,
	},

	["Castbar"] = {
		["Enable"] = true,
		["ShowIcon"] = true,
		["ShowTimer"] = true,
		["ShowSpark"] = true,
		["ShowLatency"] = true,
		["ShowTicks"] = true,
		["TimeToHold"] = 0.4,
		["PlayerWidth"] = 360,
		["PlayerHeight"] = 26,
		["TargetWidth"] = 200,
		["TargetHeight"] = 26,
		["FocusWidth"] = 180,
		["FocusHeight"] = 20,
	},

	-- Legacy budsUI keys (kept for compat with other modules/config GUI)
	["ComboFrame"] = false,
	["AuraOffsetY"] = 3,
	["BetterPowerColors"] = false,
	["CastBarScale"] = 1.2,
	["ClassIcon"] = false,
	["CombatFeedback"] = false,
	["GroupNumber"] = false,
	["PvPIcon"] = true,
	["LargeAuraSize"] = 26,
	["Outline"] = false,
	["PercentHealth"] = false,
	["Scale"] = 1.2,
	["SmallAuraSize"] = 22,
}
-- Mover positions (integrated with profiles)
C["MoverPositions"] = {}

-- Config Validation to prevent UI breakage from invalid user input
local function ValidateConfig()
	-- General limits
	if type(C.General.UIScale) == "number" then
		C.General.UIScale = math.max(0.4, math.min(1.2, C.General.UIScale))
	else
		C.General.UIScale = 0.71
	end
	
	if type(C.General.BubbleFontSize) == "number" then
		C.General.BubbleFontSize = math.max(8, math.min(32, C.General.BubbleFontSize))
	else
		C.General.BubbleFontSize = 12
	end

	-- Media limits
	if type(C.Media.Font_Size) == "number" then
		C.Media.Font_Size = math.max(8, math.min(32, C.Media.Font_Size))
	else
		C.Media.Font_Size = 12
	end

	if type(C.Media.Combat_Font_Size) == "number" then
		C.Media.Combat_Font_Size = math.max(8, math.min(64, C.Media.Combat_Font_Size))
	else
		C.Media.Combat_Font_Size = 16
	end

	-- Chat limits
	if type(C.Chat.Width) == "number" then
		C.Chat.Width = math.max(200, math.min(800, C.Chat.Width))
	else
		C.Chat.Width = 400
	end

	if type(C.Chat.Height) == "number" then
		C.Chat.Height = math.max(100, math.min(600, C.Chat.Height))
	else
		C.Chat.Height = 150
	end

	if type(C.Chat.BigWidth) == "number" then
		C.Chat.BigWidth = math.max(200, math.min(800, C.Chat.BigWidth))
	else
		C.Chat.BigWidth = 400
	end

	if type(C.Chat.BigHeight) == "number" then
		C.Chat.BigHeight = math.max(100, math.min(800, C.Chat.BigHeight))
	else
		C.Chat.BigHeight = 400
	end

	-- PowerBar limits
	if type(C.PowerBar.MaelstromSize) == "number" then
		C.PowerBar.MaelstromSize = math.max(64, math.min(512, C.PowerBar.MaelstromSize))
	else
		C.PowerBar.MaelstromSize = 256
	end

	-- Unitframe limits
	if type(C.Unitframe.Scale) == "number" then
		C.Unitframe.Scale = math.max(0.5, math.min(2.5, C.Unitframe.Scale))
	else
		C.Unitframe.Scale = 1.2
	end

	if type(C.Unitframe.CastBarScale) == "number" then
		C.Unitframe.CastBarScale = math.max(0.5, math.min(2.5, C.Unitframe.CastBarScale))
	else
		C.Unitframe.CastBarScale = 1.2
	end

	if type(C.Unitframe.LargeAuraSize) == "number" then
		C.Unitframe.LargeAuraSize = math.max(10, math.min(50, C.Unitframe.LargeAuraSize))
	else
		C.Unitframe.LargeAuraSize = 26
	end

	if type(C.Unitframe.SmallAuraSize) == "number" then
		C.Unitframe.SmallAuraSize = math.max(10, math.min(50, C.Unitframe.SmallAuraSize))
	else
		C.Unitframe.SmallAuraSize = 22
	end

	if type(C.Unitframe.AuraOffsetY) == "number" then
		C.Unitframe.AuraOffsetY = math.max(-20, math.min(20, C.Unitframe.AuraOffsetY))
	else
		C.Unitframe.AuraOffsetY = 3
	end
end

ValidateConfig()

-- Snapshot pristine defaults for budsUI_Config (option tooltips, right-click reset).
-- Runs here because Settings builds C from defaults and Modules/Profiles merges
-- the active profile into C afterwards. Deep copy so later merges never mutate it.
do
	local function DeepCopyDefaults(src)
		if type(src) ~= "table" then return src end
		local copy = {}
		for k, v in pairs(src) do
			copy[k] = DeepCopyDefaults(v)
		end
		return copy
	end
	K.ConfigDefaults = DeepCopyDefaults(C)
end