-- FrostAtomUI-style nameplate cast feedback, scoped to budsUI's existing bar.
local K, C = select(2, ...):unpack()
if C.Nameplate.Enable ~= true then return end
local Feedback = {}
K.NamePlateCastEnhancements = Feedback
local PULSE_PERIOD = 2
local CASTBAR_TEXTURE = [=[Interface\Buttons\WHITE8x8]=]
local CASTBAR_BORDER_COLOR = { 1, 1, 1 }
local GLOW_CORNER = [=[Interface\AddOns\]=] .. K.Directory .. [=[\Media\Textures\CastGlowCorner.tga]=]
local IMPORTANT_COLOR = { 1, 0.85, 0.3 }
local IMPORTANT_CASTS = {
	118, -- Polymorph
	5782, -- Fear
	5484, -- Howl of Terror
	6358, -- Seduction
	33786, -- Cyclone
	51514, -- Hex
	605, -- Mind Control
	2637, -- Hibernate
	339, -- Entangling Roots
	1513, -- Scare Beast
	10326, -- Turn Evil
	8129, -- Mana Burn
	2060, -- Greater Heal
	2061, -- Flash Heal
	32546, -- Binding Heal
	596, -- Prayer of Healing
	47540, -- Penance
	64843, -- Divine Hymn
	635, -- Holy Light
	19750, -- Flash of Light
	5185, -- Healing Touch
	8936, -- Regrowth
	50464, -- Nourish
	740, -- Tranquility
	331, -- Healing Wave
	8004, -- Lesser Healing Wave
	1064, -- Chain Heal
	32375, -- Mass Dispel
}

local importantCasts = {}
for i = 1, #IMPORTANT_CASTS do
	local name = GetSpellInfo(IMPORTANT_CASTS[i])
	if name then importantCasts[name] = true end
end

local function CreateGlow(parent, anchor, size)
	local glow = CreateFrame("Frame", nil, parent)
	glow:SetFrameLevel(parent:GetFrameLevel())
	glow:EnableMouse(false)
	glow:Hide()

	local function edge(texture)
		local region = glow:CreateTexture(nil, "BACKGROUND")
		region:SetTexture(texture or C.Media.Blank)
		region:SetBlendMode("ADD")
		return region
	end

	local function corner(point, relativePoint, left, right, top, bottom)
		local region = edge(GLOW_CORNER)
		region:SetSize(size, size)
		region:SetPoint(point, anchor, relativePoint)
		region:SetTexCoord(left, right, top, bottom)
		return region
	end

	local top = edge()
	top:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT")
	top:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT")
	top:SetHeight(size)
	local bottom = edge()
	bottom:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT")
	bottom:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT")
	bottom:SetHeight(size)
	local left = edge()
	left:SetPoint("TOPRIGHT", anchor, "TOPLEFT")
	left:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMLEFT")
	left:SetWidth(size)
	local right = edge()
	right:SetPoint("TOPLEFT", anchor, "TOPRIGHT")
	right:SetPoint("BOTTOMLEFT", anchor, "BOTTOMRIGHT")
	right:SetWidth(size)

	glow.top, glow.bottom, glow.left, glow.right = top, bottom, left, right
	glow.corners = {
		corner("BOTTOMRIGHT", "TOPLEFT", 0, 0.5, 0, 0.5),
		corner("BOTTOMLEFT", "TOPRIGHT", 0.5, 1, 0, 0.5),
		corner("TOPRIGHT", "BOTTOMLEFT", 0, 0.5, 0.5, 1),
		corner("TOPLEFT", "BOTTOMRIGHT", 0.5, 1, 0.5, 1),
	}
	return glow
end

local function StartGlow(glow, color)
	local r, g, b = color[1], color[2], color[3]
	if r ~= glow.r or g ~= glow.g or b ~= glow.b then
		glow.r, glow.g, glow.b = r, g, b
		glow.top:SetGradientAlpha("VERTICAL", r, g, b, 1, r, g, b, 0)
		glow.bottom:SetGradientAlpha("VERTICAL", r, g, b, 0, r, g, b, 1)
		glow.left:SetGradientAlpha("HORIZONTAL", r, g, b, 0, r, g, b, 1)
		glow.right:SetGradientAlpha("HORIZONTAL", r, g, b, 1, r, g, b, 0)
		for i = 1, 4 do
			glow.corners[i]:SetVertexColor(r, g, b)
		end
	end
	glow.elapsed = 0
	glow:SetAlpha(0)
	glow:Show()
end

local function pulseCastGlow(glow, elapsed)
	local t = (glow.elapsed + elapsed) % PULSE_PERIOD
	glow.elapsed = t
	glow:SetAlpha(t < 1 and t or PULSE_PERIOD - t)
end



-- Same immunity rules as FrostAtomUI Core/Auras.lua. Match localized names
-- as well as IDs because UnitAura slot 11 is missing on some 3.3.5 clients.
local immunityIDs = { [642] = true, [45438] = true, [31224] = true, [54748] = true }
local immunityNames = {}
for id in pairs(immunityIDs) do
	local name = GetSpellInfo(id)
	if name then immunityNames[name] = true end
end
local masteryName, concentrationName = GetSpellInfo(31821), GetSpellInfo(19746)
local function HasImmunity(bar, unit)
	if not unit then return false end
	local guid, now = UnitGUID(unit), GetTime()
	if guid == bar.immunityGUID and now < (bar.immunityNextScan or 0) then
		return bar.castImmune
	end
	local mastery, concentration, immune = false, false, false
	for i = 1, 40 do
		local name, _, _, _, _, _, _, _, _, _, id = UnitAura(unit, i, "HELPFUL")
		if not name then break end
		if immunityIDs[id] or immunityNames[name] then immune = true; break end
		if id == 31821 or name == masteryName then mastery = true end
		if id == 19746 or name == concentrationName then concentration = true end
	end
	bar.immunityGUID, bar.immunityNextScan = guid, now + 0.2
	bar.castImmune = immune or (mastery and concentration)
	return bar.castImmune
end

local bars = setmetatable({}, { __mode = "k" })
local LATE_INTERRUPT = 0.3
local INTERRUPT_HOLD = 1
local FADE_TIME = 0.3
local INTERRUPT_COLOR = { 0.8, 0.1, 0.1 }

local function sameCast(record, guid, spell, startTime)
	return record and record.guid == guid and record.spell == spell and record.startTime == startTime
end

local function HideResult(bar)
	if bar.interruptResult then bar.interruptResult:Hide() end
end

local function resultUpdate(result)
	local bar, now = result.bar, GetTime()
	local plate = bar:GetParent()
	local name = plate.hp.oldname and plate.hp.oldname:GetText()
	if not plate:IsShown() or plate.hide or name ~= result.plateName
		or (plate.guid and plate.guid ~= result.guid) or now >= result.expires then
		result:Hide()
		return
	end
	result:SetAlpha(math.min(1, (result.expires - now) / FADE_TIME))
end

local function CreateResult(bar)
	local plate = bar:GetParent()
	local result = CreateFrame("Frame", nil, plate)
	result:Hide()
	result:EnableMouse(false)
	result:SetFrameLevel(bar:GetFrameLevel() + 2)
	result:SetPoint("TOPLEFT", bar, "TOPLEFT", -3, 3)
	result:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 3, -3)
	result:SetBackdrop({ bgFile = C.Media.Blank, edgeFile = C.Media.Glow,
		edgeSize = 3 * K.NoScaleMult, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
	result:SetBackdropColor(0, 0, 0, 0.6)
	result:SetBackdropBorderColor(CASTBAR_BORDER_COLOR[1], CASTBAR_BORDER_COLOR[2], CASTBAR_BORDER_COLOR[3], 1)
	local fill = result:CreateTexture(nil, "BORDER")
	fill:SetAllPoints(bar)
	fill:SetTexture(CASTBAR_TEXTURE)
	fill:SetVertexColor(unpack(INTERRUPT_COLOR))
	local text = result:CreateFontString(nil, "OVERLAY")
	text:SetPoint("LEFT", bar, "LEFT", 3, 0)
	text:SetPoint("RIGHT", bar, "RIGHT", -3, 0)
	text:SetJustifyH("LEFT")
	text:SetWordWrap(false)
	text:SetFont(C.Media.Font, C.Media.Font_Size * K.NoScaleMult, C.Media.Font_Style)
	text:SetTextColor(1, 1, 1)
	result.text = text
	local icon = result:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints(bar.icon)
	icon:SetTexCoord(unpack(K.TexCoords))
	result.icon = icon
	result.bar = bar
	result:SetScript("OnUpdate", resultUpdate)
	bar.interruptResult = result
	return result
end

local function InterruptedBy(sourceGUID, sourceName, sourceFlags)
	if not sourceName then return INTERRUPTED or "Interrupted" end
	local color
	if sourceGUID and sourceFlags and bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_PLAYER or 0x400) > 0
		and GetPlayerInfoByGUID then
		local ok, _, class = pcall(GetPlayerInfoByGUID, sourceGUID)
		if ok and class then color = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class]) or RAID_CLASS_COLORS[class] end
	end
	color = color or { r = 1, g = 1, b = 1 }
	local name = string.format("|cff%02x%02x%02x%s|r", math.floor(color.r * 255), math.floor(color.g * 255), math.floor(color.b * 255), sourceName)
	local formatText = GetLocale and GetLocale() == "ruRU" and "Прервано: %s" or "Interrupted by %s"
	return string.format(formatText, name)
end

local function ShowInterrupted(bar, record, text)
	local result = bar.interruptResult or CreateResult(bar)
	result.guid = record.guid
	result.plateName = bar:GetParent().hp.oldname:GetText()
	result.text:SetText(text)
	result.icon:SetTexture(record.texture)
	result.expires = GetTime() + INTERRUPT_HOLD + FADE_TIME
	result:SetAlpha(1)
	result:Show()
	bar.suppressedCast = record
	bar.stoppedCast = record
	bar.stoppedAt = GetTime()
	bar.activeCast = nil
	if bar.importantGlow then bar.importantGlow:Hide() end
	bar.targetingYou = nil
	if bar.castHolder then bar.castHolder:SetBackdropBorderColor(CASTBAR_BORDER_COLOR[1], CASTBAR_BORDER_COLOR[2], CASTBAR_BORDER_COLOR[3], 1) end
end

local function Candidate(bar, guid, now)
	local plate = bar:GetParent()
	if not plate:IsShown() or plate.hide then return end
	local record = bar.activeCast or bar.stoppedCast
	if not record or record.guid ~= guid then return end
	if plate.guid and plate.guid ~= guid then return end
	local name = plate.hp.oldname and plate.hp.oldname:GetText()
	if name ~= record.plateName then return end
	if bar.activeCast then
		if record.endTime and now > record.endTime + LATE_INTERRUPT then return end
	elseif now - (bar.stoppedAt or 0) > LATE_INTERRUPT then
		return
	end
	return record
end

local function OnInterrupt(timestamp, subevent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags,
	spellID, spellName, spellSchool, interruptedID, interruptedName)
	if subevent ~= "SPELL_INTERRUPT" then return end
	local now = GetTime()
	for bar in pairs(bars) do
		local record = Candidate(bar, destGUID, now)
		if record and (not interruptedName or interruptedName == record.spell) then
			ShowInterrupted(bar, record, InterruptedBy(sourceGUID, sourceName, sourceFlags))
		end
	end
end

local events = CreateFrame("Frame")
events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
events:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(_, event, ...)
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		-- Normalize both legacy sourceGUID-third payloads (used by the donor)
		-- and payloads with a boolean hideCaster before sourceGUID.
		local timestamp, subevent, third = ...
		if type(third) == "boolean" then OnInterrupt(timestamp, subevent, select(4, ...))
		else OnInterrupt(timestamp, subevent, select(3, ...)) end
	elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
		local unit, spell = ...
		local guid, now = UnitGUID(unit), GetTime()
		for bar in pairs(bars) do
			local record = Candidate(bar, guid, now)
			if record and (not spell or spell == record.spell) then
				-- Do not replace a named combat-log result with the generic fallback.
				if not (bar.interruptResult and bar.interruptResult:IsShown()) then
					ShowInterrupted(bar, record, INTERRUPTED or "Interrupted")
				end
			end
		end
	else
		for bar in pairs(bars) do Feedback.Reset(bar) end
	end
end)

function Feedback.Setup(bar)
	if bars[bar] then return end
	bars[bar] = true
	bar:GetParent():HookScript("OnHide", function() Feedback.Reset(bar) end)
	bar:HookScript("OnUpdate", function(self, elapsed)
		local glow = self.importantGlow
		if glow and glow:IsShown() then pulseCastGlow(glow, elapsed) end
	end)
end

function Feedback.Update(bar, unit, spell, texture, startTime, endTime)
	local guid = unit and UnitGUID(unit)
	if spell and guid then
		if sameCast(bar.suppressedCast, guid, spell, startTime) then return false end
		if not sameCast(bar.activeCast, guid, spell, startTime) then
			HideResult(bar)
			bar.suppressedCast, bar.stoppedCast, bar.stoppedAt = nil, nil, nil
			bar.activeCast = { guid = guid, spell = spell, texture = texture,
				startTime = startTime, endTime = endTime and endTime / 1000,
				plateName = bar:GetParent().hp.oldname:GetText() }
		else
			-- Delayed casts/channel updates can move the native finish time.
			bar.activeCast.endTime = endTime and endTime / 1000
		end
	elseif bar.suppressedCast then
		return false
	elseif unit and bar.activeCast then
		-- The spell can disappear before Blizzard hides the stock bar.
		bar.stoppedCast, bar.stoppedAt = bar.activeCast, GetTime()
		bar.activeCast = nil
	end
	if spell and unit then
		bar.castLocked = bar.castLocked or HasImmunity(bar, unit) or false
	end
	local targetingYou = spell and unit and UnitIsUnit(unit .. "target", "player")
		and UnitCanAttack("player", unit) or false
	if targetingYou ~= bar.targetingYou then
		bar.targetingYou = targetingYou
		local holder = bar.castHolder
		if holder then
			if targetingYou then holder:SetBackdropBorderColor(1, 0.2, 0.1, 1)
			else holder:SetBackdropBorderColor(CASTBAR_BORDER_COLOR[1], CASTBAR_BORDER_COLOR[2], CASTBAR_BORDER_COLOR[3], 1) end
		end
	end
	local important = spell and importantCasts[spell]
	if important then
		local glow = bar.importantGlow
		if not glow then
			glow = CreateGlow(bar, bar.castHolder or bar, 4)
			bar.importantGlow = glow
		end
		if not glow:IsShown() then StartGlow(glow, IMPORTANT_COLOR) end
	elseif bar.importantGlow then
		bar.importantGlow:Hide()
	end
end

function Feedback.Hide(bar)
	if bar.activeCast then
		bar.stoppedCast, bar.stoppedAt = bar.activeCast, GetTime()
		bar.activeCast = nil
	end
	bar.immunityGUID, bar.immunityNextScan, bar.castImmune = nil, nil, nil
	bar.targetingYou = nil
	if bar.castHolder then bar.castHolder:SetBackdropBorderColor(CASTBAR_BORDER_COLOR[1], CASTBAR_BORDER_COLOR[2], CASTBAR_BORDER_COLOR[3], 1) end
	if bar.importantGlow then bar.importantGlow:Hide() end
end

function Feedback.Reset(bar)
	bar.activeCast, bar.stoppedCast, bar.suppressedCast, bar.stoppedAt = nil, nil, nil, nil
	Feedback.Hide(bar)
	HideResult(bar)
end

