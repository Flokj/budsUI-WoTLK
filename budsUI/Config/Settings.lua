local K, C, L, _ = select(2, ...):unpack()

-- Media Options
C["Media"] = {
	["Backdrop_Color"] = {5/255, 5/255, 5/255, 0.8},
	["Blank"] = [[Interface\AddOns\]] .. K.Directory .. [[\Media\Textures\Blank]],
	["Blank_Font"] = [[Interface\AddOns\]] .. K.Directory .. [[\Media\Fonts\Invisible.ttf]],
	["Blizz"] = [[Interface\AddOns\]] .. K.Directory .. [[\Media\Border\Border_Default.tga]],
	["Border_Color"] = {255/255, 255/255, 255/255, 1},
	["Border_Glow"] = [[Interface\AddOns\]] .. K.Directory .. [[\Media\Border\Border_Glow.tga]],
	["Combat_Font"] = [[Interface\AddOns\]] .. K.Directory .. [[\Media\Fonts\Damage.ttf]],
	["Combat_Font_Size"] = 16,
	["Combat_Font_Size_Style"] = "OUTLINE",
	["Font"] = [[Interface\AddOns\]] .. K.Directory .. [[\Media\Fonts\Normal.ttf]],
	["Font_Size"] = 12,
	["Font_Style"] = "OUTLINE",
	["Glow"] = [[Interface\AddOns\]] .. K.Directory .. [[\Media\Textures\GlowTex.tga]],
	["Overlay_Color"] = {0/255, 0/255, 0/255, 0.8},
	["Proc_Sound"] = [[Interface\AddOns\]] .. K.Directory .. [[\Media\Sounds\Proc.ogg]],
	["Texture"] = [[Interface\TargetingFrame\UI-StatusBar]],
	["Warning_Sound"] = [[Interface\AddOns\]] .. K.Directory .. [[\Media\Sounds\Warning.ogg]],
	["Whisp_Sound"] = [[Interface\AddOns\]] .. K.Directory .. [[\Media\Sounds\Whisper.ogg]],
}
-- ActionBar Options
C["ActionBar"] = {
	["BarsLocked"] = false,
	["BottomBars"] = 3,
	["ButtonSize"] = 36,
	["ButtonSpace"] = 3,
	["Enable"] = true,
	["EquipBorder"] = false,
	["Hotkey"] = true,
	["Macro"] = true,
	["OutOfMana"] = {128/255, 128/255, 255/255},
	["OutOfRange"] = {204/255, 26/255, 26/255},
	["PetBarHide"] = false,
	["PetBarHorizontal"] = false,
	["RightBars"] = 2,
	["Selfcast"] = false,
	["ShowGrid"] = true,
	["SplitBars"] = false,
	["StanceBarHide"] = false,
	["StanceBarHorizontal"] = true,
	["ToggleMode"] = true,
}
-- Announcements Options
C["Announcements"] = {
	["Bad_Gear"] = false,
	["Feasts"] = false,
	["Interrupt"] = false,
	["Portals"] = false,
	["PullCountdown"] = true,
	["SaySapped"] = false,
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
	["Resurrection"] = false,
	["ScreenShot"] = false,
	["SellGreyRepair"] = false,
	["TabBinder"] = false,
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
	["Capturebar"] = true,
	["ClassColor"] = true,
	["Durability"] = true,
	["MoveAchievements"] = true,
	["Reputations"] = true,
}
-- Buffs & Debuffs Options
C["Aura"] = {
	["Enable"] = false,
	["BuffSize"] = 32,
	["CastBy"] = false,
	["ClassColorBorder"] = false,
}
-- Chat Options
C["Chat"] = {
	["BigHeight"] = 400,
	["BigWidth"] = 400,
	["HideTextures"] = true,
	["CombatLog"] = true,
	["DamageMeterSpam"] = false,
	["Enable"] = true,
	["Fading"] = false,
	["Filter"] = true,
	["Height"] = 150,
	["Outline"] = false,
	["Spam"] = false,
	["FadeTime"] = 20,
	["Sticky"] = true,
	["TabsMouseover"] = true,
	["TabsOutline"] = false,
	["WhispSound"] = true,
	["Width"] = 400,
}
-- Cooldown Options
C["Cooldown"] = {
	["Enable"] = true,
	["FontSize"] = 20,
	["Threshold"] = 3,
}
-- Error Options
C["Error"] = {
	["Black"] = true,
	["White"] = false,
	["Combat"] = false,
}
-- Filger Options
C["Filger"] = {
	["BuffsSize"] = 37,
	["CooldownSize"] = 30,
	["Enable"] = true,
	["MaxTestIcon"] = 5,
	["PvPSize"] = 60,
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
	["Ping"] = true,
	["Size"] = 150,
	["SizeFarm"] = 300,
	["SizeNormal"] = 144,
	["Offsets"] = {
		["Mail"] = {6, 10},
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
	["AlreadyKnown"] = false,
	["Armory"] = false,
	["BGSpam"] = false,
	["DurabilityWarning"] = false,
	["EnhancedMail"] = true,
	["HatTrick"] = true,
	["InviteKeyword"] = "inv",
	["ItemLevel"] = false,
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
	["EnhanceThreat"] = false,
	["GoodColor"] = {74/255, 173/255, 74/255},
	["HealthValue"] = true,
	["Height"] = 9,
	["NameAbbreviate"] = true,
	["NearColor"] = {217/255, 196/255, 92/255},
	["CastBarName"] = true,
	["Auras"] = false,
	["Width"] = 120,
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
	["Enable"] = true,
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
	["Recount"] = false,
	["Skada"] = false,
	["WeakAuras"] = false,
	["WorldMap"] = true,
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
	["ItemCount"] = false,
	["ItemIcon"] = false,
	["QualityBorder"] = false,
	["RaidIcon"] = false,
	["Rank"] = false,
	["SpellID"] = false,
	["Talents"] = false,
	["Target"] = true,
	["Title"] = true,
	["WhoTargetting"] = true,
}
-- Unitframe Options
C["Unitframe"] = {
	["ComboFrame"] = false,
	["AuraOffsetY"] = 3,
	["BetterPowerColors"] = false,
	["CastBarScale"] = 1.2,
	["ClassHealth"] = false,
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