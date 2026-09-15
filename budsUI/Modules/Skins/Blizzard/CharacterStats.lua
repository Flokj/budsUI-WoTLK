--[[-----------------------------------------------------------------------------
Addon: budsUI
File: Modules/Skins/Blizzard/CharacterStats.lua
Purpose:
	Extended character stats panel (collapsible categories, item level /
	GearScore header, spec in the level line), sourced from ElvUI_Enhanced
	via the standalone EnhancedCharacterFrame addon. Disable the standalone
	version while this skin is on, or the right panel spawns twice.
-----------------------------------------------------------------------------]]

local K, C, L, _ = select(2, ...):unpack()
if not C["Skins"].CharacterStats then return end

local module = CreateFrame("Frame", "EnhancedCharacterFrameModule")
module.Initialized = false

local function Kill(frame)
	if not frame then return end
	frame:Hide()
	frame.Show = frame.Hide
	if frame.UnregisterAllEvents then frame:UnregisterAllEvents() end
end

local CATEGORY_TITLES = {
	["ITEM_LEVEL"] = "Item Level",
	["BASE_STATS"] = "Base Stats",
	["MELEE_COMBAT"] = "Melee",
	["RANGED_COMBAT"] = "Ranged",
	["SPELL_COMBAT"] = "Spell",
	["DEFENSES"] = DEFENSE or "Defense",
	["RESISTANCE"] = "Resistance"
}

local PAPERDOLL_STATINFO = {
	["ITEM_LEVEL"] = {
		updateFunc = function(statFrame, unit) module:ItemLevel(statFrame, unit) end
	},
	["STRENGTH"] = {
		updateFunc = function(statFrame, unit) module:SetStat(statFrame, unit, 1) end
	},
	["AGILITY"] = {
		updateFunc = function(statFrame, unit) module:SetStat(statFrame, unit, 2) end
	},
	["STAMINA"] = {
		updateFunc = function(statFrame, unit) module:SetStat(statFrame, unit, 3) end
	},
	["INTELLECT"] = {
		updateFunc = function(statFrame, unit) module:SetStat(statFrame, unit, 4) end
	},
	["SPIRIT"] = {
		updateFunc = function(statFrame, unit) module:SetStat(statFrame, unit, 5) end
	},
	["MELEE_DAMAGE"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetDamage(statFrame, unit) end,
		updateFunc2 = function(statFrame) if CharacterDamageFrame_OnEnter then CharacterDamageFrame_OnEnter(statFrame) end end
	},
	["MELEE_DPS"] = {
		updateFunc = function(statFrame, unit) module:SetMeleeDPS(statFrame, unit) end
	},
	["MELEE_AP"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetAttackPower(statFrame, unit) end
	},
	["MELEE_ATTACKSPEED"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetAttackSpeed(statFrame, unit) end
	},
	["HITCHANCE"] = {
		updateFunc = function(statFrame, unit) if unit ~= "player" then statFrame:Hide() return end PaperDollFrame_SetRating(statFrame, CR_HIT_MELEE) end
	},
	["CRITCHANCE"] = {
		updateFunc = function(statFrame, unit) module:SetMeleeCritChance(statFrame, unit) end
	},
	["EXPERTISE"] = {
		updateFunc = function(statFrame, unit) if unit ~= "player" then statFrame:Hide() return end PaperDollFrame_SetExpertise(statFrame, unit) end
	},
	["RANGED_COMBAT1"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetRangedDamage(statFrame, unit) end,
		updateFunc2 = function(statFrame) if CharacterRangedDamageFrame_OnEnter then CharacterRangedDamageFrame_OnEnter(statFrame) end end
	},
	["RANGED_COMBAT2"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetRangedAttackSpeed(statFrame, unit) end
	},
	["RANGED_COMBAT3"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetRangedAttackPower(statFrame, unit) end
	},
	["RANGED_COMBAT4"] = {
		updateFunc = function(statFrame) PaperDollFrame_SetRating(statFrame, CR_HIT_RANGED) end
	},
	["RANGED_COMBAT5"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetRangedCritChance(statFrame, unit) end
	},
	["SPELL_COMBAT1"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetSpellBonusDamage(statFrame, unit) end,
		updateFunc2 = function(statFrame) if CharacterSpellBonusDamage_OnEnter then CharacterSpellBonusDamage_OnEnter(statFrame) end end
	},
	["SPELL_COMBAT2"] = {
		updateFunc = function(statFrame, unit) if unit ~= "player" then statFrame:Hide() return end PaperDollFrame_SetSpellBonusHealing(statFrame, unit) end
	},
	["SPELL_COMBAT3"] = {
		updateFunc = function(statFrame, unit) if unit ~= "player" then statFrame:Hide() return end PaperDollFrame_SetRating(statFrame, CR_HIT_SPELL) end
	},
	["SPELL_COMBAT4"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetSpellCritChance(statFrame, unit) end,
		updateFunc2 = function(statFrame) if CharacterSpellCritChance_OnEnter then CharacterSpellCritChance_OnEnter(statFrame) end end
	},
	["SPELL_COMBAT5"] = {
		updateFunc = function(statFrame, unit) if unit ~= "player" then statFrame:Hide() return end PaperDollFrame_SetSpellHaste(statFrame, unit) end
	},
	["SPELL_COMBAT6"] = {
		updateFunc = function(statFrame, unit) if unit ~= "player" then statFrame:Hide() return end PaperDollFrame_SetManaRegen(statFrame, unit) end
	},
	["DEFENSES1"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetArmor(statFrame, unit) end
	},
	["DEFENSES2"] = {
		updateFunc = function(statFrame, unit) if unit ~= "player" then statFrame:Hide() return end PaperDollFrame_SetDefense(statFrame, unit) end
	},
	["DEFENSES3"] = {
		updateFunc = function(statFrame, unit) module:SetDodge(statFrame, unit) end
	},
	["DEFENSES4"] = {
		updateFunc = function(statFrame, unit) module:SetParry(statFrame, unit) end
	},
	["DEFENSES5"] = {
		updateFunc = function(statFrame, unit) module:SetBlock(statFrame, unit) end
	},
	["DEFENSES6"] = {
		updateFunc = function(statFrame, unit) module:SetResilience(statFrame, unit) end
	},
	["ARCANE"] = {
		updateFunc = function(statFrame, unit) module:SetResistance(statFrame, unit, 6) end
	},
	["FIRE"] = {
		updateFunc = function(statFrame, unit) module:SetResistance(statFrame, unit, 2) end
	},
	["FROST"] = {
		updateFunc = function(statFrame, unit) module:SetResistance(statFrame, unit, 4) end
	},
	["NATURE"] = {
		updateFunc = function(statFrame, unit) module:SetResistance(statFrame, unit, 3) end
	},
	["SHADOW"] = {
		updateFunc = function(statFrame, unit) module:SetResistance(statFrame, unit, 5) end
	}
}

local PAPERDOLL_STATCATEGORIES = {
	["ITEM_LEVEL"] = { id = 1, stats = { "ITEM_LEVEL" } },
	["BASE_STATS"] = { id = 2, stats = { "STRENGTH", "AGILITY", "STAMINA", "INTELLECT", "SPIRIT" } },
	["MELEE_COMBAT"] = { id = 3, stats = { "MELEE_DAMAGE", "MELEE_DPS", "MELEE_AP", "MELEE_ATTACKSPEED", "HITCHANCE", "CRITCHANCE", "EXPERTISE" } },
	["RANGED_COMBAT"] = { id = 4, stats = { "RANGED_COMBAT1", "RANGED_COMBAT2", "RANGED_COMBAT3", "RANGED_COMBAT4", "RANGED_COMBAT5" } },
	["SPELL_COMBAT"] = { id = 5, stats = { "SPELL_COMBAT1", "SPELL_COMBAT2", "SPELL_COMBAT3", "SPELL_COMBAT4", "SPELL_COMBAT5", "SPELL_COMBAT6" } },
	["DEFENSES"] = { id = 6, stats = { "DEFENSES1", "DEFENSES2", "DEFENSES3", "DEFENSES4", "DEFENSES5", "DEFENSES6" } },
	["RESISTANCE"] = { id = 7, stats = { "ARCANE", "FIRE", "FROST", "NATURE", "SHADOW" } }
}

local PAPERDOLL_STATCATEGORY_DEFAULTORDER = { "ITEM_LEVEL", "BASE_STATS", "MELEE_COMBAT", "RANGED_COMBAT", "SPELL_COMBAT", "DEFENSES", "RESISTANCE" }

-- Ordered frame list + drag state, like ElvUI_Enhanced.
local StatCategoryFrames = {}
local MOVING_STAT_CATEGORY = nil
local STATCATEGORY_MOVING_INDENT = 4

for _id, _name in ipairs(PAPERDOLL_STATCATEGORY_DEFAULTORDER) do
	PAPERDOLL_STATCATEGORIES[_name].id = _id
end

local function FindCategoryById(id)
	for categoryName, category in pairs(PAPERDOLL_STATCATEGORIES) do
		if category.id == id then
			return categoryName
		end
	end
end

-- Saved state per character, like E.private.enhanced.character in ElvUI_Enhanced:
-- collapsed/collapsed2 + order/order2 (one set per talent group), panelHidden.
-- Left-click header: toggle + autosave. Drag header: reorder (autosaved).
local function CharStatsData()
	if type(budsUIData) ~= "table" then budsUIData = {} end
	if type(budsUIData.CharacterData) ~= "table" then budsUIData.CharacterData = {} end
	local key = (K.Realm or GetRealmName()) .. "-" .. (K.Name or UnitName("player"))
	if type(budsUIData.CharacterData[key]) ~= "table" then budsUIData.CharacterData[key] = {} end
	local charData = budsUIData.CharacterData[key]
	if type(charData.CharStats) ~= "table" then charData.CharStats = {} end
	return charData.CharStats
end

local function ActiveSpec()
	if GetActiveTalentGroup and GetActiveTalentGroup() == 2 then return 2 end
	return 1
end

-- All categories expanded by default, like ElvUI_Enhanced Private.lua.

-- Collapsed table for the active spec. First run: all expanded.
-- Spec2 without data inherits spec1 (like ElvUI_Enhanced orderName2 init).
local function CollapsedStore()
	local data = CharStatsData()
	local key = ActiveSpec() == 2 and "collapsed2" or "collapsed"
	if type(data[key]) ~= "table" then
		data[key] = {}
		local source = (key == "collapsed2" and type(data.collapsed) == "table") and data.collapsed or nil
		for _, category in ipairs(PAPERDOLL_STATCATEGORY_DEFAULTORDER) do
			if source and source[category] ~= nil then
				data[key][category] = source[category]
			else
				data[key][category] = false
			end
		end
	else
		for _, category in ipairs(PAPERDOLL_STATCATEGORY_DEFAULTORDER) do
			if data[key][category] == nil then
				data[key][category] = false
			end
		end
	end
	return data[key]
end

local function GetOrderData()
	local data = CharStatsData()
	if ActiveSpec() == 2 then
		if data.order2 == nil and data.order ~= nil then data.order2 = data.order end
		return data.order2 or ""
	end
	return data.order or ""
end

local function SaveOrderData(orderString)
	local data = CharStatsData()
	if ActiveSpec() == 2 then data.order2 = orderString else data.order = orderString end
end

local function ShowStatTooltip(self)
	if self.tooltip then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.tooltip)
		if self.tooltip2 then
			GameTooltip:AddLine(self.tooltip2, 1, 0.82, 0, 1)
		end
		GameTooltip:Show()
	elseif PaperDollStatTooltip then
		PaperDollStatTooltip(self)
	end
end

local function CreateStatFrame(parent, name)
	local f = CreateFrame("Frame", name, parent)
	f:SetSize(165, 15)
	f:EnableMouse(true)

	local label = f:CreateFontString(name.."Label", "ARTWORK", "GameFontNormal")
	label:SetSize(110, 12)
	label:SetPoint("LEFT", f, "LEFT", 2, 0)
	label:SetJustifyH("LEFT")
	f.Label = label
	_G[name.."Label"] = label

	local val = f:CreateFontString(name.."StatText", "ARTWORK", "GameFontHighlight")
	val:SetPoint("RIGHT", f, "RIGHT", -2, 0)
	val:SetJustifyH("RIGHT")
	f.Value = val
	_G[name.."StatText"] = val

	return f
end

function module:PaperDollFrame_SetLevel()
	local myclass = select(2, UnitClass("player"))
	local myLocalizedClass = select(1, UnitClass("player"))
	local classColor = RAID_CLASS_COLORS[myclass] or {r=1, g=1, b=1}
	local classColorString = string.format("FF%02x%02x%02x", classColor.r*255, classColor.g*255, classColor.b*255)

	local specName = NONE
	local maxPoints = 0
	for i = 1, GetNumTalentTabs() do
		local name, _, pointsSpent = GetTalentTabInfo(i)
		if pointsSpent > maxPoints then
			maxPoints = pointsSpent
			specName = name
		end
	end

	if specName == NONE or not specName then
		CharacterLevelText:SetFormattedText("Level %s |c%s%s|r", UnitLevel("player"), classColorString, myLocalizedClass)
	else
		CharacterLevelText:SetFormattedText("Level %s |c%s%s %s|r", UnitLevel("player"), classColorString, specName, myLocalizedClass)
	end
end

function module:SetLabelAndText(statFrame, label, text, isPercentage)
	local labelText = _G[statFrame:GetName().."Label"] or statFrame.Label
	local valueText = _G[statFrame:GetName().."StatText"] or statFrame.Value
	if labelText then labelText:SetFormattedText(STAT_FORMAT or "%s:", label) end
	if valueText then
		if isPercentage then
			valueText:SetFormattedText("%.2F%%", text)
		else
			valueText:SetText(text)
		end
	end
end

function module:GetGearScore()
	local pName = UnitName("player")
	local pRealm = GetRealmName()
	
	if GearScore_GetScore then
		local score = GearScore_GetScore(pName, "player")
		if (not score or score == 0) and GS_Data and GS_Data[pRealm] and GS_Data[pRealm].Players and GS_Data[pRealm].Players[pName] then
			score = GS_Data[pRealm].Players[pName].GearScore
		end
		if score and score > 0 then
			local r, g, b = 1, 0.82, 0
			if GearScore_GetQuality then
				r, g, b = GearScore_GetQuality(score)
			end
			return score, r, g, b
		end
	end
	return nil
end

function module:ItemLevel(statFrame, unit)
	local score, r, g, b = module:GetGearScore()
	local labelText = _G[statFrame:GetName().."Label"] or statFrame.Label
	if score then
		if labelText then
			labelText:SetText(score)
			labelText:SetTextColor(r or 1, g or 0.82, b or 0)
		end
		return
	end

	local ilvl, items = 0, 16
	for slotID = 1, 18 do
		if slotID ~= 4 then
			local itemLink = GetInventoryItemLink("player", slotID)
			if itemLink then
				local lvl = select(4, GetItemInfo(itemLink))
				if lvl then ilvl = ilvl + lvl end
			end
		end
	end
	if labelText then
		labelText:SetFormattedText("%.1f", ilvl / items)
		labelText:SetTextColor(1, 0.82, 0)
	end
end

function module:SetStat(statFrame, unit, statIndex)
	local stat, effectiveStat, posBuff, negBuff = UnitStat(unit, statIndex)
	local statName = _G["SPELL_STAT"..statIndex.."_NAME"] or ""
	local labelText = _G[statFrame:GetName().."Label"] or statFrame.Label
	local valueText = _G[statFrame:GetName().."StatText"] or statFrame.Value

	if labelText then labelText:SetFormattedText(STAT_FORMAT or "%s:", statName) end

	local tooltipFormat = PAPERDOLLFRAME_TOOLTIP_FORMAT or "%s"
	local highlightCode = HIGHLIGHT_FONT_COLOR_CODE or "|cffffffff"
	local closeCode = FONT_COLOR_CODE_CLOSE or "|r"
	local greenCode = GREEN_FONT_COLOR_CODE or "|cff20ff20"
	local redCode = RED_FONT_COLOR_CODE or "|cffff2020"

	local tooltipText = highlightCode..string.format(tooltipFormat, statName).." "
	if posBuff == 0 and negBuff == 0 then
		if valueText then valueText:SetText(effectiveStat) end
		statFrame.tooltip = tooltipText..effectiveStat..closeCode
	else
		tooltipText = tooltipText..effectiveStat
		if posBuff > 0 or negBuff < 0 then
			tooltipText = tooltipText.." ("..(stat - posBuff - negBuff)..closeCode
		end
		if posBuff > 0 then
			tooltipText = tooltipText..closeCode..greenCode.."+"..posBuff..closeCode
		end
		if negBuff < 0 then
			tooltipText = tooltipText..redCode.." "..negBuff..closeCode
		end
		if posBuff > 0 or negBuff < 0 then
			tooltipText = tooltipText..highlightCode..")"..closeCode
		end
		statFrame.tooltip = tooltipText

		if valueText then
			if negBuff < 0 then
				valueText:SetText(redCode..effectiveStat..closeCode)
			else
				valueText:SetText(greenCode..effectiveStat..closeCode)
			end
		end
	end

	statFrame.tooltip2 = _G["DEFAULT_STAT"..statIndex.."_TOOLTIP"]

	if unit == "player" then
		local _, unitClass = UnitClass("player")
		if statIndex == 1 then
			local attackPower = GetAttackPowerForStat and GetAttackPowerForStat(statIndex, effectiveStat) or 0
			if statFrame.tooltip2 then
				statFrame.tooltip2 = string.format(statFrame.tooltip2, attackPower)
			end
			if unitClass == "WARRIOR" or unitClass == "SHAMAN" or unitClass == "PALADIN" then
				if statFrame.tooltip2 then
					local blockVal = math.max(0, effectiveStat * (BLOCK_PER_STRENGTH or 0.05) - 10)
					statFrame.tooltip2 = statFrame.tooltip2.."\n"..string.format(STAT_BLOCK_TOOLTIP or "Increases block value by %d.", blockVal)
				end
			end
		elseif statIndex == 3 then
			local baseStam = math.min(20, effectiveStat)
			local moreStam = effectiveStat - baseStam
			local hpMod = GetUnitMaxHealthModifier and GetUnitMaxHealthModifier("player") or 1
			local hpGain = (baseStam + (moreStam * (HEALTH_PER_STAMINA or 10))) * hpMod
			if statFrame.tooltip2 then
				statFrame.tooltip2 = string.format(statFrame.tooltip2, hpGain)
			end
			if ComputePetBonus then
				local petStam = ComputePetBonus("PET_BONUS_STAM", effectiveStat)
				if petStam > 0 and statFrame.tooltip2 then
					statFrame.tooltip2 = statFrame.tooltip2.."\n"..string.format(PET_BONUS_TOOLTIP_STAMINA or "", petStam)
				end
			end
		elseif statIndex == 2 then
			local attackPower = GetAttackPowerForStat and GetAttackPowerForStat(statIndex, effectiveStat) or 0
			local critFromAgi = GetCritChanceFromAgility and GetCritChanceFromAgility("player") or 0
			local armorPerAgi = ARMOR_PER_AGILITY or 2
			if attackPower > 0 then
				local apText = string.format(STAT_ATTACK_POWER or "Attack Power: %d", attackPower)
				if statFrame.tooltip2 then
					statFrame.tooltip2 = apText.."\n"..string.format(statFrame.tooltip2, critFromAgi, effectiveStat * armorPerAgi)
				end
			else
				if statFrame.tooltip2 then
					statFrame.tooltip2 = string.format(statFrame.tooltip2, critFromAgi, effectiveStat * armorPerAgi)
				end
			end
		elseif statIndex == 4 then
			local baseInt = math.min(20, effectiveStat)
			local moreInt = effectiveStat - baseInt
			if UnitHasMana and UnitHasMana("player") then
				local spellCrit = GetSpellCritChanceFromIntellect and GetSpellCritChanceFromIntellect("player") or 0
				local manaGain = baseInt + moreInt * (MANA_PER_INTELLECT or 15)
				if statFrame.tooltip2 then
					statFrame.tooltip2 = string.format(statFrame.tooltip2, manaGain, spellCrit)
				end
			else
				statFrame.tooltip2 = nil
			end
			if ComputePetBonus then
				local petInt = ComputePetBonus("PET_BONUS_INT", effectiveStat)
				if petInt > 0 then
					if not statFrame.tooltip2 then statFrame.tooltip2 = "" end
					statFrame.tooltip2 = statFrame.tooltip2.."\n"..string.format(PET_BONUS_TOOLTIP_INTELLECT or "", petInt)
				end
			end
		elseif statIndex == 5 then
			local hpRegen = GetUnitHealthRegenRateFromSpirit and GetUnitHealthRegenRateFromSpirit("player") or 0
			if statFrame.tooltip2 then
				statFrame.tooltip2 = string.format(statFrame.tooltip2, hpRegen)
			end
			if UnitHasMana and UnitHasMana("player") then
				local regen = GetUnitManaRegenRateFromSpirit and GetUnitManaRegenRateFromSpirit("player") or 0
				regen = math.floor(regen * 5.0)
				if statFrame.tooltip2 then
					statFrame.tooltip2 = statFrame.tooltip2.."\n"..string.format(MANA_REGEN_FROM_SPIRIT or "Mana Regen: %d", regen)
				end
			end
		end
	end
	statFrame:Show()
end

function module:SetResistance(statFrame, unit, resistanceIndex)
	local base, resistance, positive, negative = UnitResistance(unit, resistanceIndex)
	local resistanceNameShort = _G["SPELL_SCHOOL"..resistanceIndex.."_CAP"] or ""
	local resistanceName = _G["RESISTANCE"..resistanceIndex.."_NAME"] or ""
	local resistanceIconCode = "|TInterface\\PaperDollInfoFrame\\SpellSchoolIcon"..(resistanceIndex + 1)..":14:14:2:2:16:16:2:14:2:14|t"

	local labelText = _G[statFrame:GetName().."Label"] or statFrame.Label
	local valueText = _G[statFrame:GetName().."StatText"] or statFrame.Value

	if labelText then labelText:SetText(resistanceIconCode.." "..string.format(STAT_FORMAT or "%s:", resistanceNameShort)) end

	if PaperDollFormatStat then
		PaperDollFormatStat(resistanceName, base, positive, negative, statFrame, valueText)
	else
		if valueText then valueText:SetText(resistance) end
	end

	local highlightCode = HIGHLIGHT_FONT_COLOR_CODE or "|cffffffff"
	local closeCode = FONT_COLOR_CODE_CLOSE or "|r"
	local greenCode = GREEN_FONT_COLOR_CODE or "|cff20ff20"
	local redCode = RED_FONT_COLOR_CODE or "|cffff2020"

	statFrame.tooltip = resistanceIconCode.." "..highlightCode..string.format(PAPERDOLLFRAME_TOOLTIP_FORMAT or "%s", resistanceName).." "..resistance..closeCode

	if positive ~= 0 or negative ~= 0 then
		statFrame.tooltip = statFrame.tooltip.." ( "..highlightCode..base
		if positive > 0 then
			statFrame.tooltip = statFrame.tooltip..greenCode.." +"..positive
		end
		if negative < 0 then
			statFrame.tooltip = statFrame.tooltip.." "..redCode..negative
		end
		statFrame.tooltip = statFrame.tooltip..closeCode.." )"
	end

	local resistanceLevel
	local unitLevel = UnitLevel(unit)
	unitLevel = math.max(unitLevel, 20)

	local magicResistanceNumber = resistance / unitLevel
	if magicResistanceNumber > 5 then
		resistanceLevel = RESISTANCE_EXCELLENT
	elseif magicResistanceNumber > 3.75 then
		resistanceLevel = RESISTANCE_VERYGOOD
	elseif magicResistanceNumber > 2.5 then
		resistanceLevel = RESISTANCE_GOOD
	elseif magicResistanceNumber > 1.25 then
		resistanceLevel = RESISTANCE_FAIR
	elseif magicResistanceNumber > 0 then
		resistanceLevel = RESISTANCE_POOR
	else
		resistanceLevel = RESISTANCE_NONE
	end
	if RESISTANCE_TOOLTIP_SUBTEXT then
		statFrame.tooltip2 = string.format(RESISTANCE_TOOLTIP_SUBTEXT, _G["RESISTANCE_TYPE"..resistanceIndex] or "", unitLevel, resistanceLevel or "")
	end
	statFrame:Show()
end

function module:SetDodge(statFrame, unit)
	if unit ~= "player" then statFrame:Hide() return end
	local chance = GetDodgeChance()
	module:SetLabelAndText(statFrame, STAT_DODGE or "Dodge", chance, 1)
	local highlightCode = HIGHLIGHT_FONT_COLOR_CODE or "|cffffffff"
	local closeCode = FONT_COLOR_CODE_CLOSE or "|r"
	statFrame.tooltip = highlightCode..string.format(PAPERDOLLFRAME_TOOLTIP_FORMAT or "%s", STAT_DODGE or "Dodge").." "..string.format("%.02f", chance).."%"..closeCode
	if CR_DODGE and CR_DODGE_TOOLTIP then
		statFrame.tooltip2 = string.format(CR_DODGE_TOOLTIP, GetCombatRating(CR_DODGE), GetCombatRatingBonus(CR_DODGE))
	end
	statFrame:Show()
end

function module:SetBlock(statFrame, unit)
	if unit ~= "player" then statFrame:Hide() return end
	local chance = GetBlockChance()
	module:SetLabelAndText(statFrame, STAT_BLOCK or "Block", chance, 1)
	local highlightCode = HIGHLIGHT_FONT_COLOR_CODE or "|cffffffff"
	local closeCode = FONT_COLOR_CODE_CLOSE or "|r"
	statFrame.tooltip = highlightCode..string.format(PAPERDOLLFRAME_TOOLTIP_FORMAT or "%s", STAT_BLOCK or "Block").." "..string.format("%.02f", chance).."%"..closeCode
	if CR_BLOCK and CR_BLOCK_TOOLTIP then
		statFrame.tooltip2 = string.format(CR_BLOCK_TOOLTIP, GetCombatRating(CR_BLOCK), GetCombatRatingBonus(CR_BLOCK), GetShieldBlock and GetShieldBlock() or 0)
	end
	statFrame:Show()
end

function module:SetParry(statFrame, unit)
	if unit ~= "player" then statFrame:Hide() return end
	local chance = GetParryChance()
	module:SetLabelAndText(statFrame, STAT_PARRY or "Parry", chance, 1)
	local highlightCode = HIGHLIGHT_FONT_COLOR_CODE or "|cffffffff"
	local closeCode = FONT_COLOR_CODE_CLOSE or "|r"
	statFrame.tooltip = highlightCode..string.format(PAPERDOLLFRAME_TOOLTIP_FORMAT or "%s", STAT_PARRY or "Parry").." "..string.format("%.02f", chance).."%"..closeCode
	if CR_PARRY and CR_PARRY_TOOLTIP then
		statFrame.tooltip2 = string.format(CR_PARRY_TOOLTIP, GetCombatRating(CR_PARRY), GetCombatRatingBonus(CR_PARRY))
	end
	statFrame:Show()
end

function module:SetResilience(statFrame, unit)
	if unit ~= "player" then statFrame:Hide() return end
	local melee = GetCombatRating(CR_CRIT_TAKEN_MELEE or 14)
	local ranged = GetCombatRating(CR_CRIT_TAKEN_RANGED or 15)
	local spell = GetCombatRating(CR_CRIT_TAKEN_SPELL or 16)
	local minResilience = math.min(melee, math.min(ranged, spell))

	local lowestRating = CR_CRIT_TAKEN_MELEE or 14
	if minResilience == ranged then lowestRating = CR_CRIT_TAKEN_RANGED or 15
	elseif minResilience == spell then lowestRating = CR_CRIT_TAKEN_SPELL or 16 end

	local maxRatingBonus = GetMaxCombatRatingBonus and GetMaxCombatRatingBonus(lowestRating) or 0
	local lowestRatingBonus = GetCombatRatingBonus and GetCombatRatingBonus(lowestRating) or 0

	module:SetLabelAndText(statFrame, STAT_RESILIENCE or "Resilience", minResilience)
	local highlightCode = HIGHLIGHT_FONT_COLOR_CODE or "|cffffffff"
	local closeCode = FONT_COLOR_CODE_CLOSE or "|r"
	statFrame.tooltip = highlightCode..string.format(PAPERDOLLFRAME_TOOLTIP_FORMAT or "%s", STAT_RESILIENCE or "Resilience").." "..minResilience..closeCode
	if RESILIENCE_TOOLTIP then
		local mult1 = RESILIENCE_CRIT_CHANCE_TO_DAMAGE_REDUCTION_MULTIPLIER or 1
		local mult2 = RESILIENCE_CRIT_CHANCE_TO_CONSTANT_DAMAGE_REDUCTION_MULTIPLIER or 2
		statFrame.tooltip2 = string.format(RESILIENCE_TOOLTIP, lowestRatingBonus, math.min(lowestRatingBonus * mult1, maxRatingBonus), lowestRatingBonus * mult2)
	end
	statFrame:Show()
end

function module:SetMeleeDPS(statFrame, unit)
	local labelText = _G[statFrame:GetName().."Label"] or statFrame.Label
	local valueText = _G[statFrame:GetName().."StatText"] or statFrame.Value
	if labelText then labelText:SetFormattedText(STAT_FORMAT or "%s:", "Damage Per Second") end
	local speed = UnitAttackSpeed(unit) or 1
	local minDamage, maxDamage = UnitDamage(unit)
	local dps = ((minDamage or 0) + (maxDamage or 0)) / 2 / speed
	if valueText then valueText:SetText(string.format("%.1F", dps)) end
	
	local highlightCode = HIGHLIGHT_FONT_COLOR_CODE or "|cffffffff"
	local closeCode = FONT_COLOR_CODE_CLOSE or "|r"
	statFrame.tooltip = highlightCode..(DAMAGE_PER_SECOND or "Damage Per Second")..closeCode
	statFrame.tooltip2 = nil
	statFrame:Show()
end

function module:SetMeleeCritChance(statFrame, unit)
	if unit ~= "player" then statFrame:Hide() return end
	local labelText = _G[statFrame:GetName().."Label"] or statFrame.Label
	local valueText = _G[statFrame:GetName().."StatText"] or statFrame.Value
	local critChance = GetCritChance()
	if labelText then labelText:SetFormattedText(STAT_FORMAT or "%s:", MELEE_CRIT_CHANCE or "Crit Chance") end
	if valueText then valueText:SetFormattedText("%.2F%%", critChance) end

	local highlightCode = HIGHLIGHT_FONT_COLOR_CODE or "|cffffffff"
	local closeCode = FONT_COLOR_CODE_CLOSE or "|r"
	statFrame.tooltip = highlightCode..string.format(PAPERDOLLFRAME_TOOLTIP_FORMAT or "%s", MELEE_CRIT_CHANCE or "Crit Chance").." "..string.format("%.2F%%", critChance)..closeCode
	if CR_CRIT_MELEE and CR_CRIT_MELEE_TOOLTIP then
		statFrame.tooltip2 = string.format(CR_CRIT_MELEE_TOOLTIP, GetCombatRating(CR_CRIT_MELEE), GetCombatRatingBonus(CR_CRIT_MELEE))
	end
	statFrame:Show()
end

function module:PaperDollFrame_UpdateStatCategory(categoryFrame)
	if not categoryFrame or not categoryFrame.Category then return end

	local category = categoryFrame.Category
	local categoryInfo = PAPERDOLL_STATCATEGORIES[category]

	local title = CATEGORY_TITLES[category] or category
	if category == "ITEM_LEVEL" and module:GetGearScore() then
		title = "Gear Score"
	end

	if categoryFrame.collapsed then
		if categoryFrame.NameText then
			categoryFrame.NameText:SetText(title .. "  [+]")
		end
		for i = 1, #categoryFrame.Stats do
			categoryFrame.Stats[i]:Hide()
		end
		categoryFrame:SetHeight(20)
		return
	else
		if categoryFrame.NameText then
			categoryFrame.NameText:SetText(title)
		end
	end

	local totalHeight = 20
	local numVisible = 0
	if categoryInfo then
		local prevStatFrame = nil
		for _, stat in ipairs(categoryInfo.stats) do
			local statInfo = PAPERDOLL_STATINFO[stat]
			if statInfo then
				local statFrame = categoryFrame.Stats[numVisible + 1]
				if not statFrame then
					statFrame = CreateStatFrame(categoryFrame, categoryFrame:GetName().."Stat"..(numVisible + 1))
					categoryFrame.Stats[numVisible + 1] = statFrame
				end

				statFrame:ClearAllPoints()
				if prevStatFrame then
					statFrame:SetPoint("TOPLEFT", prevStatFrame, "BOTTOMLEFT", 0, -2)
					statFrame:SetPoint("TOPRIGHT", prevStatFrame, "BOTTOMRIGHT", 0, -2)
				else
					statFrame:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", 0, -20)
					statFrame:SetPoint("TOPRIGHT", categoryFrame, "TOPRIGHT", 0, -20)
				end

				statFrame:Show()

				local labelText = _G[statFrame:GetName().."Label"] or statFrame.Label
				local valueText = _G[statFrame:GetName().."StatText"] or statFrame.Value

				if stat == "ITEM_LEVEL" then
					statFrame:SetHeight(26)
					if labelText then
						labelText:SetWidth(165)
						labelText:ClearAllPoints()
						labelText:SetPoint("CENTER", statFrame, "CENTER", 0, 0)
						labelText:SetJustifyH("CENTER")
						labelText:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")
					end
					if valueText then valueText:SetText("") end
				else
					statFrame:SetHeight(15)
					if labelText then
						labelText:SetWidth(110)
						labelText:ClearAllPoints()
						labelText:SetPoint("LEFT", statFrame, "LEFT", 2, 0)
						labelText:SetJustifyH("LEFT")
						labelText:SetFont(STANDARD_TEXT_FONT, 12, "")
					end
				end

				statFrame.tooltip = nil
				statFrame.tooltip2 = nil

				if statInfo.updateFunc2 then
					statFrame:SetScript("OnEnter", function(self)
						statInfo.updateFunc2(self)
					end)
				else
					statFrame:SetScript("OnEnter", function(self)
						ShowStatTooltip(self)
					end)
				end

				statFrame:SetScript("OnLeave", function()
					GameTooltip:Hide()
				end)

				statInfo.updateFunc(statFrame, "player")

				if statFrame:IsShown() then
					numVisible = numVisible + 1
					totalHeight = totalHeight + statFrame:GetHeight() + 2
					prevStatFrame = statFrame
				end
			end
		end
	end

	local index = numVisible + 1
	while categoryFrame.Stats[index] do
		categoryFrame.Stats[index]:Hide()
		index = index + 1
	end

	categoryFrame:SetHeight(totalHeight)
end

function module:PaperDoll_UpdateCategoryPositions()
	if not CharacterStatsPane or not CharacterStatsPane.Categories then return end
	if #StatCategoryFrames == 0 then
		local prevFrame = nil
		for index = 1, #PAPERDOLL_STATCATEGORY_DEFAULTORDER do
			local frame = CharacterStatsPane.Categories[index]
			if frame and frame:IsShown() then
				frame:ClearAllPoints()
				if prevFrame then
					frame:SetPoint("TOPLEFT", prevFrame, "BOTTOMLEFT", 0, -4)
				else
					frame:SetPoint("TOPLEFT", CharacterStatsPaneScrollChild, "TOPLEFT", 1, -4)
				end
				prevFrame = frame
			end
		end
		return
	end
	local prevFrame = nil
	for index = 1, #StatCategoryFrames do
		local frame = StatCategoryFrames[index]
		if frame and frame:IsShown() then
			local xOffset = 0
			if frame == MOVING_STAT_CATEGORY then
				xOffset = STATCATEGORY_MOVING_INDENT
			elseif prevFrame and prevFrame == MOVING_STAT_CATEGORY then
				xOffset = -STATCATEGORY_MOVING_INDENT
			end
			frame:ClearAllPoints()
			if prevFrame then
				frame:SetPoint("TOPLEFT", prevFrame, "BOTTOMLEFT", xOffset, -4)
			else
				frame:SetPoint("TOPLEFT", CharacterStatsPaneScrollChild, "TOPLEFT", 1 + xOffset, -4)
			end
			prevFrame = frame
		end
	end
end

function module:PaperDollFrame_UpdateStats()
	if not CharacterStatsPane or not CharacterStatsPane.Categories then return end
	local index = 1
	while CharacterStatsPane.Categories[index] do
		self:PaperDollFrame_UpdateStatCategory(CharacterStatsPane.Categories[index])
		index = index + 1
	end
	self:PaperDoll_UpdateCategoryPositions()
	self:PaperDollFrame_UpdateStatScrollChildHeight()
end

function module:PaperDollFrame_UpdateStatScrollChildHeight()
	if not CharacterStatsPane or not CharacterStatsPane.Categories then return end
	local index = 1
	local totalHeight = 0
	while CharacterStatsPane.Categories[index] do
		if CharacterStatsPane.Categories[index]:IsShown() then
			totalHeight = totalHeight + CharacterStatsPane.Categories[index]:GetHeight() + 4
		end
		index = index + 1
	end
	if CharacterStatsPaneScrollChild then
		CharacterStatsPaneScrollChild:SetHeight(totalHeight + 10)
	end
end

function module:CollapseStatCategory(categoryFrame)
	if not categoryFrame or not categoryFrame.Category then return end
	if not categoryFrame.collapsed then
		categoryFrame.collapsed = true
		if categoryFrame.Toolbar then categoryFrame.Toolbar:SetAlpha(0.4) end
		self:PaperDollFrame_UpdateStatCategory(categoryFrame)
		self:PaperDollFrame_UpdateStatScrollChildHeight()
	end
end

function module:ExpandStatCategory(categoryFrame)
	if not categoryFrame or not categoryFrame.Category then return end
	if categoryFrame.collapsed then
		categoryFrame.collapsed = false
		if categoryFrame.Toolbar then categoryFrame.Toolbar:SetAlpha(1) end
		self:PaperDollFrame_UpdateStatCategory(categoryFrame)
		self:PaperDollFrame_UpdateStatScrollChildHeight()
	end
end

function module:PaperDoll_InitStatCategories()
	if not CharacterStatsPane or not CharacterStatsPane.Categories then return end
	local defaultOrder = PAPERDOLL_STATCATEGORY_DEFAULTORDER
	local orderData = GetOrderData()
	local collapsedData = CollapsedStore()

	local order = defaultOrder
	if orderData and orderData ~= "" then
		local savedOrder = {}
		for i in string.gmatch(orderData, "(%d+),?") do
			i = tonumber(i)
			if i then
				local categoryName = FindCategoryById(i)
				if categoryName then table.insert(savedOrder, categoryName) end
			end
		end
		local valid = true
		if #savedOrder == #defaultOrder then
			for _, category1 in ipairs(defaultOrder) do
				local found = false
				for _, category2 in ipairs(savedOrder) do
					if category1 == category2 then found = true break end
				end
				if not found then valid = false break end
			end
		else
			valid = false
		end
		if valid then
			order = savedOrder
		else
			SaveOrderData("")
		end
	end

	table.wipe(StatCategoryFrames)
	for index = 1, #order do
		local frame = CharacterStatsPane.Categories[index]
		if frame then
			table.insert(StatCategoryFrames, frame)
			frame.Category = order[index]
			frame:Show()
			if collapsedData[frame.Category] then
				frame.collapsed = true
				if frame.Toolbar then frame.Toolbar:SetAlpha(0.4) end
			else
				frame.collapsed = false
				if frame.Toolbar then frame.Toolbar:SetAlpha(1) end
			end
		end
	end

	local index = #order + 1
	while CharacterStatsPane.Categories[index] do
		CharacterStatsPane.Categories[index]:Hide()
		CharacterStatsPane.Categories[index].Category = nil
		index = index + 1
	end

	CharacterStatsPane.defaultOrder = defaultOrder
	CharacterStatsPane.collapsedData = collapsedData
	CharacterStatsPane.unit = "player"

	self:PaperDoll_UpdateCategoryPositions()
	self:PaperDollFrame_UpdateStats()
end

function module:SaveCollapsed(category, collapsed)
	if CharacterStatsPane and CharacterStatsPane.collapsedData then
		CharacterStatsPane.collapsedData[category] = collapsed
	else
		local ok, store = pcall(CollapsedStore)
		if ok and store then store[category] = collapsed end
	end
end

local function PaperDoll_SaveStatCategoryOrder()
	if not (CharacterStatsPane and CharacterStatsPane.defaultOrder) then return end
	if #StatCategoryFrames ~= #CharacterStatsPane.defaultOrder then return end
	local same = true
	for index = 1, #StatCategoryFrames do
		if StatCategoryFrames[index].Category ~= CharacterStatsPane.defaultOrder[index] then
			same = false
			break
		end
	end
	if same then SaveOrderData("") return end
	local order = {}
	for index = 1, #StatCategoryFrames do
		order[index] = PAPERDOLL_STATCATEGORIES[StatCategoryFrames[index].Category].id
	end
	SaveOrderData(table.concat(order, ","))
end

local function StatCategory_OnDragUpdate(self)
	if #StatCategoryFrames == 0 then return end
	local _, cursorY = GetCursorPosition()
	cursorY = cursorY / (UIParent:GetEffectiveScale() or 1)
	local myIndex, insertIndex, closestPos
	for index = 1, #StatCategoryFrames + 1 do
		if StatCategoryFrames[index] == self then myIndex = index end
		local frameY
		if index <= #StatCategoryFrames then
			frameY = StatCategoryFrames[index]:GetTop()
		else
			frameY = StatCategoryFrames[#StatCategoryFrames]:GetBottom()
		end
		if not frameY then return end
		frameY = frameY - 8
		if myIndex and index > myIndex then frameY = frameY + self:GetHeight() end
		if not closestPos or math.abs(cursorY - frameY) < closestPos then
			insertIndex = index
			closestPos = math.abs(cursorY - frameY)
		end
	end
	if not myIndex or not insertIndex then return end
	if insertIndex > myIndex then insertIndex = insertIndex - 1 end
	if myIndex ~= insertIndex then
		table.remove(StatCategoryFrames, myIndex)
		table.insert(StatCategoryFrames, insertIndex, self)
		module:PaperDoll_UpdateCategoryPositions()
	end
end

local function PaperDollStatCategory_OnDragStart(self)
	MOVING_STAT_CATEGORY = self
	module:PaperDoll_UpdateCategoryPositions()
	GameTooltip:Hide()
	self:SetScript("OnUpdate", StatCategory_OnDragUpdate)
	for _, frame in next, StatCategoryFrames do
		if frame ~= self then frame:SetAlpha(0.6) end
	end
end

local function PaperDollStatCategory_OnDragStop(self)
	MOVING_STAT_CATEGORY = nil
	module:PaperDoll_UpdateCategoryPositions()
	self:SetScript("OnUpdate", nil)
	for _, frame in next, StatCategoryFrames do
		if frame ~= self then frame:SetAlpha(1) end
	end
	PaperDoll_SaveStatCategoryOrder()
end

function module:Initialize()
	Kill(CharacterAttributesFrame)
	Kill(CharacterResistanceFrame)

	if PersonalGearScore then Kill(PersonalGearScore) end
	if GearScore2 then Kill(GearScore2) end

	CharacterModelFrame:ClearAllPoints()
	CharacterModelFrame:SetSize(231, 320)
	CharacterModelFrame:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 66, -78)

	local RightPanel = CreateFrame("Frame", "EnhancedCharRightPanel", CharacterFrame, "UIPanelDialogTemplate")
	RightPanel:SetSize(210, 424)
	RightPanel:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 350, -12)

	local expandButton = CreateFrame("Button", "EnhancedCharExpandButton", PaperDollFrame, "UIPanelButtonTemplate")
	expandButton:SetSize(50, 20)
	expandButton:SetPoint("BOTTOMRIGHT", -43, 86)
	expandButton:SetText("Stats")

	local isExpanded = true
	local function TogglePanel(expand)
		if expand == nil then expand = not isExpanded end
		isExpanded = expand
		local ok, data = pcall(CharStatsData)
		if ok and data then data.panelHidden = not isExpanded end
		if isExpanded then
			RightPanel:Show()
			PlaySound("igCharacterInfoOpen")
		else
			RightPanel:Hide()
			PlaySound("igCharacterInfoClose")
		end
	end

	local closeButton = _G["EnhancedCharRightPanelClose"]
	if closeButton then
		closeButton:SetScript("OnClick", function()
			TogglePanel(false)
		end)
	end

	expandButton:SetScript("OnClick", function()
		TogglePanel()
	end)

	local statsPane = CreateFrame("ScrollFrame", "CharacterStatsPane", RightPanel, "UIPanelScrollFrameTemplate")
	statsPane:SetSize(168, 380)
	statsPane:SetPoint("TOPLEFT", RightPanel, "TOPLEFT", 10, -32)
	statsPane.Categories = {}

	local statsPaneScrollChild = CreateFrame("Frame", "CharacterStatsPaneScrollChild", statsPane)
	statsPaneScrollChild:SetSize(168, 1)
	statsPane:SetScrollChild(statsPaneScrollChild)

	for i = 1, 7 do
		local button = CreateFrame("Frame", "CharacterStatsPaneCategory"..i, statsPaneScrollChild)
		button:SetSize(168, 20)

		local toolbar = CreateFrame("Button", nil, button)
		toolbar:SetSize(165, 18)
		toolbar:SetPoint("TOP", button, "TOP", 0, 0)
		toolbar:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8X8",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 10,
			insets = { left = 1, right = 1, top = 1, bottom = 1 }
		})
		toolbar:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
		toolbar:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
		toolbar:RegisterForDrag("LeftButton")

		local nameText = toolbar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		nameText:SetPoint("CENTER", toolbar, "CENTER", 0, 0)
		button.NameText = nameText
		button.Toolbar = toolbar

		toolbar:SetScript("OnClick", function(self)
			local categoryFrame = self:GetParent()
			if categoryFrame.collapsed then
				module:ExpandStatCategory(categoryFrame)
				if CharacterStatsPane and CharacterStatsPane.collapsedData and categoryFrame.Category then
					CharacterStatsPane.collapsedData[categoryFrame.Category] = false
				end
			else
				module:CollapseStatCategory(categoryFrame)
				if CharacterStatsPane and CharacterStatsPane.collapsedData and categoryFrame.Category then
					CharacterStatsPane.collapsedData[categoryFrame.Category] = true
				end
			end
			module:PaperDoll_UpdateCategoryPositions()
			module:PaperDollFrame_UpdateStatScrollChildHeight()
		end)
		toolbar:SetScript("OnDragStart", function(self)
			PaperDollStatCategory_OnDragStart(self:GetParent())
		end)
		toolbar:SetScript("OnDragStop", function(self)
			PaperDollStatCategory_OnDragStop(self:GetParent())
		end)

		toolbar:SetScript("OnEnter", function(self)
			self:SetBackdropBorderColor(1, 0.82, 0, 1)
		end)
		toolbar:SetScript("OnLeave", function(self)
			self:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
		end)

		button.Stats = {}
		statsPane.Categories[i] = button
	end

	PaperDollFrame:HookScript("OnShow", function()
		local hidden = false
		local ok, data = pcall(CharStatsData)
		if ok and data then hidden = data.panelHidden end
		TogglePanel(not hidden)
		module:PaperDollFrame_SetLevel()
		module:PaperDoll_InitStatCategories()
	end)

	PaperDollFrame:HookScript("OnHide", function()
		RightPanel:Hide()
	end)

	self.Initialized = true
end

module:RegisterEvent("PLAYER_LOGIN")
module:SetScript("OnEvent", function(self, event, unit)
	if event == "PLAYER_LOGIN" then
		self:UnregisterEvent("PLAYER_LOGIN")
		self:Initialize()

		self:RegisterEvent("UNIT_RESISTANCES")
		self:RegisterEvent("UNIT_STATS")
		self:RegisterEvent("UNIT_DAMAGE")
		self:RegisterEvent("UNIT_ATTACK_SPEED")
		self:RegisterEvent("UNIT_ATTACK_POWER")
		self:RegisterEvent("UNIT_RANGEDDAMAGE")
		self:RegisterEvent("UNIT_RANGED_ATTACK_POWER")
		self:RegisterEvent("COMBAT_RATING_UPDATE")
		self:RegisterEvent("UNIT_LEVEL")
		self:RegisterEvent("PLAYER_TALENT_UPDATE")
		self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
		self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
		return
	end

	if event == "ACTIVE_TALENT_GROUP_CHANGED" then
		if PaperDollFrame and PaperDollFrame:IsVisible() then
			self:PaperDoll_InitStatCategories()
		end
		return
	end

	if PaperDollFrame and PaperDollFrame:IsVisible() then
		if unit == nil or unit == "player" then
			if event == "UNIT_LEVEL" or event == "PLAYER_TALENT_UPDATE" then
				self:PaperDollFrame_SetLevel()
			end
			self:PaperDollFrame_UpdateStats()
		end
	end
end)