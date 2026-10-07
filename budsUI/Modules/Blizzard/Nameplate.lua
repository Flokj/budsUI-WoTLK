local K, C, L, _ = select(2, ...):unpack()
if C.Nameplate.Enable ~= true then return end

local tonumber, pairs, select, unpack = tonumber, pairs, select, unpack
local match = string.match
local floor = math.floor
local find = string.find
local band = bit.band
local CreateFrame = CreateFrame
local UnitGUID = UnitGUID
local UnitName = UnitName
local UnitExists = UnitExists
local GetNumRaidMembers = GetNumRaidMembers
local GetNumPartyMembers = GetNumPartyMembers
local wipe = wipe
local InCombatLockdown = InCombatLockdown
local SetCVar = SetCVar
local GetUnitName = GetUnitName
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local WorldFrame = WorldFrame

local frames, numChildren, scanThrottle = {}, -1, 0
-- Persistent guid -> plate uniqueness table (FrostAtom Identity.lua setGUID model).
-- Declared up here so OnHide (below) can release bindings on plate hide.
local plateByGuid = {}
local goodR, goodG, goodB = unpack(C.Nameplate.GoodColor)
local badR, badG, badB = unpack(C.Nameplate.BadColor)
local transitionR, transitionG, transitionB = unpack(C.Nameplate.NearColor)

-- Target name cache to reduce API calls
local cachedTargetName = nil
local targetNameCache = 0

local function GetCachedTargetName()
	local now = GetTime()
	if (now - targetNameCache) > 0.1 then
		cachedTargetName = UnitExists("target") and GetUnitName("target") or nil
		targetNameCache = now
	end
	return cachedTargetName
end

local OVERLAY = [=[Interface\TargetingFrame\UI-TargetingFrame-Flash]=]

-- Based on dNameplates(by Dawn, editor Kkthnx)
local NamePlates = CreateFrame("Frame", nil, UIParent)
NamePlates:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

local function Abbrev(name)
	local newname = (string.len(name) > 18) and string.gsub(name, "%s?(.[\128-\191]*)%S+%s", "%1. ") or name
	return K.ShortenString(newname, 18, false)
end

local function QueueObject(frame, object)
	frame.queue = frame.queue or {}
	frame.queue[object] = true
end

local function HideObjects(frame)
	for object in pairs(frame.queue) do
		if object:GetObjectType() == "Texture" then
			object:SetTexture("")
		elseif object:GetObjectType() == "FontString" then
			object:SetWidth(0.001)
		elseif object:GetObjectType() == "StatusBar" then
			object:SetStatusBarTexture("")
		else
			object:Hide()
		end
	end
end

-- Create a fake backdrop frame using textures
local function CreateVirtualFrame(parent, point)
	if point == nil then point = parent end

	if point.backdrop then return end
	parent.backdrop = CreateFrame("Frame", nil , parent)
	parent.backdrop:SetAllPoints()
	parent.backdrop:SetBackdrop({
		bgFile = C.Media.Blank,
		edgeFile = C.Media.Glow,
		edgeSize = 3 * K.NoScaleMult,
		insets = {top = 3 * K.NoScaleMult, left = 3 * K.NoScaleMult, bottom = 3 * K.NoScaleMult, right = 3 * K.NoScaleMult}
	})
	parent.backdrop:SetPoint("TOPLEFT", point, -3 * K.NoScaleMult, 3 * K.NoScaleMult)
	parent.backdrop:SetPoint("BOTTOMRIGHT", point, 3 * K.NoScaleMult, -3 * K.NoScaleMult)
	parent.backdrop:SetBackdropColor(.05, .05, .05, .9)
	parent.backdrop:SetBackdropBorderColor(0, 0, 0, 1)

	if parent:GetFrameLevel() - 1 > 0 then
		parent.backdrop:SetFrameLevel(parent:GetFrameLevel() - 1)
	else
		parent.backdrop:SetFrameLevel(0)
	end
end

-- Aura icons are provided by the NamePlateAuras engine (Modules/Blizzard/NamePlateAuras.lua)

local function CastTextUpdate(frame, curValue)
	local _, maxValue = frame:GetMinMaxValues()
	local last = frame.last and frame.last or 0
	local finish = (curValue > last) and (maxValue - curValue) or curValue

	frame.time:SetFormattedText("%.1f ", finish)
	frame.last = curValue

	if frame.shield:IsShown() then
		frame:SetStatusBarColor(217/255, 69/255, 69/255)
		frame.bg:SetTexture(217/255, 69/255, 69/255, 0.2)
	else
		frame.bg:SetTexture(217/255, 196/255, 92/255, 0.2)
	end
end

local function HealthBar_ValueChanged(frame)
	frame = frame:GetParent()
	if not frame or not frame.hp or not frame.healthOriginal then return end
	frame.hp:SetMinMaxValues(frame.healthOriginal:GetMinMaxValues())
	frame.hp:SetValue(frame.healthOriginal:GetValue())
end

-- We need to reset everything when a nameplate it hidden
local function OnHide(frame)
	-- Release ported aura icons (NamePlateAuras engine)
	if K.NamePlateAuras_Hide then
		K.NamePlateAuras_Hide(frame)
	end

	-- Release guid ownership so a hidden plate never blocks a new bind
	local g = frame.guid
	if g and plateByGuid[g] == frame then
		plateByGuid[g] = nil
	end

	-- Visual cleanup
	frame.hp:SetStatusBarColor(frame.hp.rcolor, frame.hp.gcolor, frame.hp.bcolor)
	frame.hp:SetScale(1)
	frame.overlay:Hide()
	frame.cb:Hide()
	frame.cb:SetScale(1)
	frame.unit = nil
	frame.guid = nil
	frame.boundName = nil
	frame.confirmedAt = 0
	frame.isClass = nil
	frame.isFriendly = nil
	frame.hp.rcolor = nil
	frame.hp.gcolor = nil
	frame.hp.bcolor = nil
	frame.blacklistChecked = nil -- Reset blacklist check flag
	frame:SetScript("OnUpdate", nil)
end

-- Color Nameplate
local function Colorize(frame)
	local r, g, b = frame.healthOriginal:GetStatusBarColor()
	local texcoord = {0, 0, 0, 0}
	frame.isClass = false

	for classToken, color in pairs(RAID_CLASS_COLORS) do
		-- Fix: use new naming to prevent leak and add tolerance to comparison
		if math.abs(color.r - r) < 0.02 and math.abs(color.g - g) < 0.02 and math.abs(color.b - b) < 0.02 then
			frame.isClass = true
			frame.isFriendly = false
			if C.Nameplate.ClassIcons == true then
				texcoord = CLASS_BUTTONS[classToken]
				frame.class.Glow:Show()
				frame.class:SetTexCoord(texcoord[1], texcoord[2], texcoord[3], texcoord[4])
			end
			frame.hp.name:SetTextColor(color.r, color.g, color.b)
			frame.hp:SetStatusBarColor(color.r, color.g, color.b)
			frame.hp.bg:SetTexture(color.r, color.g, color.b, 0.2)
			return classToken
		end
	end

	frame.isTapped = false

	if (r + g + b) == 1.59 then
		r, g, b = 153/255, 153/255, 153/255
		frame.isFriendly = false
		frame.isTapped = true
	elseif g + b == 0 then
		r, g, b = 217/255, 69/255, 69/255
		frame.isFriendly = false
	elseif r + b == 0 then
		r, g, b = 79/255, 115/255, 161/255
		frame.isFriendly = true
	elseif r + g > 1.95 then
		r, g, b = 217/255, 196/255, 92/255
		frame.isFriendly = false
	elseif r + g == 0 then
		r, g, b = 84/255, 150/255, 84/255
		frame.isFriendly = true
	else
		frame.isFriendly = false
	end

	if C.Nameplate.ClassIcons == true then
		if frame.isClass == true then
			frame.class.Glow:Show()
		else
			frame.class.Glow:Hide()
		end
		frame.class:SetTexCoord(texcoord[1], texcoord[2], texcoord[3], texcoord[4])
	end

	frame.hp:SetStatusBarColor(r, g, b)
	frame.hp.bg:SetTexture(r, g, b, 0.2)
	frame.hp.name:SetTextColor(r, g, b)
end

-- HealthBar OnShow, use this to set variables for the nameplate
local function UpdateObjects(frame)
	frame = frame:GetParent()

	-- Set scale
	while frame.hp:GetEffectiveScale() < 1 do
		frame.hp:SetScale(frame.hp:GetScale() + 0.01)
	end

	while frame.cb:GetEffectiveScale() < 1 do
		frame.cb:SetScale(frame.cb:GetScale() + 0.01)
	end

	-- Have to reposition this here so it doesnt resize after being hidden
	frame.hp:ClearAllPoints()
	frame.hp:SetSize(C.Nameplate.Width * K.NoScaleMult, C.Nameplate.Height * K.NoScaleMult)
	frame.hp:SetPoint("TOP", frame, "TOP", 0, -15)

	-- Match values
	HealthBar_ValueChanged(frame.hp)

	-- Colorize Plate
	Colorize(frame)
	frame.hp.rcolor, frame.hp.gcolor, frame.hp.bcolor = frame.hp:GetStatusBarColor()

	-- Set the name text
	if C.Nameplate.NameAbbreviate == true and C.Nameplate.Auras ~= true then
		frame.hp.name:SetText(Abbrev(frame.hp.oldname:GetText()))
	else
		frame.hp.name:SetText(frame.hp.oldname:GetText())
	end

	--[[ Setup level text
	local level, elite, mylevel = tonumber(frame.hp.oldlevel:GetText()), frame.hp.elite:IsShown(), K.Level
	frame.hp.level:ClearAllPoints()
	if C.Nameplate.ClassIcons == true and frame.isClass == true then
		frame.hp.level:SetPoint("RIGHT", frame.hp.name, "LEFT", -2, 0)
	else
		frame.hp.level:SetPoint("RIGHT", frame.hp, "LEFT", -2, 0)
	end
	frame.hp.level:SetTextColor(frame.hp.oldlevel:GetTextColor())
	if frame.hp.boss:IsShown() then
		frame.hp.level:SetText("??")
		frame.hp.level:SetTextColor(204/255, 13/255, 0/255)
		frame.hp.level:Show()
	elseif not elite and level == mylevel then
		frame.hp.level:Hide()
	else
		frame.hp.level:SetText(level..(elite and "+" or ""))
		frame.hp.level:Show()
	end]]

	frame.overlay:ClearAllPoints()
	frame.overlay:SetAllPoints(frame.hp)

	HideObjects(frame)
end

-- This is where we create most "Static" objects for the nameplate
local function SkinObjects(frame, nameFrame)
	local hp, cb = frame:GetChildren()
	local threat, hpborder, cbshield, cbborder, cbicon, overlay, oldname, oldlevel, bossicon, raidicon, elite = frame:GetRegions()

	-- Health Bar
	frame.healthOriginal = hp
	hp:SetStatusBarTexture(C.Media.Texture)
	CreateVirtualFrame(hp)

	-- Create Level
	hp.level = hp:CreateFontString(nil, "OVERLAY")
	hp.level:SetFont(C.Media.Font, C.Media.Font_Size * K.NoScaleMult, C.Media.Font_Style)
	hp.level:SetShadowOffset((0), -(0))
	hp.level:SetTextColor(255/255, 255/255, 255/255)
	hp.oldlevel = oldlevel
	hp.boss = bossicon
	hp.elite = elite

	-- Create Health Text
	if C.Nameplate.HealthValue == true then
		hp.value = hp:CreateFontString(nil, "OVERLAY")
		hp.value:SetFont(C.Media.Font, C.Media.Font_Size * K.NoScaleMult - 1, C.Media.Font_Style)
		hp.value:SetShadowOffset((0), -(0))
		hp.value:SetPoint("CENTER", hp, "CENTER", 0, 0)
		hp.value:SetTextColor(255/255, 255/255, 255/255)
	end

	-- Create Name Text
	hp.name = hp:CreateFontString(nil, "OVERLAY")
	hp.name:SetPoint("BOTTOMLEFT", hp, "TOPLEFT", -3, 4)
	hp.name:SetPoint("BOTTOMRIGHT", hp, "TOPRIGHT", 3, 4)
	hp.name:SetFont(C.Media.Font, C.Media.Font_Size * K.NoScaleMult, C.Media.Font_Style)
	hp.name:SetShadowOffset((0), -(0))
	hp.oldname = oldname

	hp.bg = hp:CreateTexture(nil, "BORDER")
	hp.bg:SetAllPoints(hp)
	hp.bg:SetTexture(255/255, 255/255, 255/255, 0.2)

	hp:HookScript("OnShow", UpdateObjects)
	frame.hp = hp

	if not frame.threat then
		frame.threat = threat
	end

	-- Create Cast Bar
	cb:ClearAllPoints()
	cb:SetPoint("TOPRIGHT", hp, "BOTTOMRIGHT", 0, -8)
	cb:SetPoint("BOTTOMLEFT", hp, "BOTTOMLEFT", 0, -8-(C.Nameplate.Height * K.NoScaleMult))
	cb:SetStatusBarTexture(C.Media.Texture)
	CreateVirtualFrame(cb)

	cb.bg = cb:CreateTexture(nil, "BORDER")
	cb.bg:SetAllPoints(cb)
	cb.bg:SetTexture(217/255, 196/255, 92/255, 0.2)

	-- Create Cast Time Text
	cb.time = cb:CreateFontString(nil, "ARTWORK")
	cb.time:SetPoint("RIGHT", cb, "RIGHT", 3, 0)
	cb.time:SetFont(C.Media.Font, C.Media.Font_Size * K.NoScaleMult, C.Media.Font_Style)
	cb.time:SetShadowOffset((0), -(0))
	cb.time:SetTextColor(255/255, 255/255, 255/255)

	-- Create Cast Name Text
	cb.name = cb:CreateFontString(nil, "ARTWORK")
	if C.Nameplate.CastBarName == true then
		cb.name:SetPoint("LEFT", cb, "LEFT", 3, 0)
		cb.name:SetFont(C.Media.Font, C.Media.Font_Size * K.NoScaleMult, C.Media.Font_Style)
		cb.name:SetShadowOffset((0), -(0))
		cb.name:SetTextColor(255/255, 255/255, 255/255)
	end

	-- Create Class Icon
	if C.Nameplate.ClassIcons == true then
		local cIconTex = hp:CreateTexture(nil, "OVERLAY")
		cIconTex:SetPoint("TOPRIGHT", hp, "TOPLEFT", -8, K.NoScaleMult * 2)
		cIconTex:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
		cIconTex:SetSize((C.Nameplate.Height * 2 * K.NoScaleMult) + 11, (C.Nameplate.Height * 2 * K.NoScaleMult) + 11)
		frame.class = cIconTex

		frame.class.Glow = CreateFrame("Frame", nil, frame)
		frame.class.Glow:SetBackdrop({
			bgFile = C.Media.Blank,
			edgeFile = C.Media.Glow,
			edgeSize = 3 * K.NoScaleMult,
			insets = {
				top = 3 * K.NoScaleMult, left = 3 * K.NoScaleMult, bottom = 3 * K.NoScaleMult, right = 3 * K.NoScaleMult
			}
		})
		frame.class.Glow:SetPoint("TOPLEFT", frame.class, -3 * K.NoScaleMult, 3 * K.NoScaleMult)
		frame.class.Glow:SetPoint("BOTTOMRIGHT", frame.class, 3 * K.NoScaleMult, -3 * K.NoScaleMult)
		frame.class.Glow:SetBackdropColor(.05, .05, .05, .9)
		frame.class.Glow:SetBackdropBorderColor(0, 0, 0, 1)
		frame.class.Glow:SetScale(K.NoScaleMult)
		frame.class.Glow:SetFrameLevel(hp:GetFrameLevel() -1 > 0 and hp:GetFrameLevel() -1 or 0)
		frame.class.Glow:Hide()
	end

	-- Create CastBar Icon
	cbicon:ClearAllPoints()
	cbicon:SetPoint("TOPRIGHT", hp, "TOPLEFT", -6, 0)
	cbicon:SetSize((C.Nameplate.Height * 2 * K.NoScaleMult) + 8, (C.Nameplate.Height * 2 * K.NoScaleMult) + 8)
	cbicon:SetTexCoord(unpack(K.TexCoords))
	cbicon:SetDrawLayer("OVERLAY")
	cb.icon = cbicon
	CreateVirtualFrame(cb, cb.icon)

	cb.shield = cbshield
	cb:HookScript("OnValueChanged", CastTextUpdate)
	frame.cb = cb

	-- Aura icons are owned by the NamePlateAuras engine and bound once per
	-- update pass by ResolvePlateAuras (one plate per guid).

	-- Highlight texture
	if not frame.overlay then
		overlay:SetTexture(255/255, 255/255, 255/255, 0.15)
		overlay:SetAllPoints(frame.hp)
		frame.overlay = overlay
	end

	-- Raid icon
	if not frame.raidicon then
		raidicon:ClearAllPoints()
		raidicon:SetPoint("BOTTOM", hp, "TOP", 0, C.Nameplate.Auras == true and 38 or 16)
		raidicon:SetSize((C.Nameplate.Height * 2) + 8, (C.Nameplate.Height * 2) + 8)
		frame.raidicon = raidicon
	end

	-- Hide Old Stuff
	QueueObject(frame, oldlevel)
	QueueObject(frame, threat)
	QueueObject(frame, hpborder)
	QueueObject(frame, cbshield)
	QueueObject(frame, cbborder)
	QueueObject(frame, oldname)
	QueueObject(frame, bossicon)
	QueueObject(frame, elite)

	UpdateObjects(hp)

	--frame.hp:HookScript("OnShow", UpdateObjects)
	frame:HookScript("OnHide", OnHide)
	frames[frame] = true
end

local function UpdateThreat(frame, elapsed)
	Colorize(frame)

	if frame.isClass then return end

	if C.Nameplate.EnhanceThreat ~= true then

	else

		if not frame.threat:IsShown() then
			if InCombatLockdown() and frame.isFriendly ~= true then
				-- No Threat
				if K.Role == "Tank" then
					frame.hp:SetStatusBarColor(badR, badG, badB)
					frame.hp.bg:SetTexture(badR, badG, badB, 0.2)
				else
					frame.hp:SetStatusBarColor(goodR, goodG, goodB)
					frame.hp.bg:SetTexture(goodR, goodG, goodB, 0.2)
				end
			end
		else
			-- Ok we either have threat or we"re losing/gaining it
			local r, g, b = frame.threat:GetVertexColor()
			if g + b == 0 then
				-- Have Threat
				if K.Role == "Tank" then
					frame.hp:SetStatusBarColor(goodR, goodG, goodB)
					frame.hp.bg:SetTexture(goodR, goodG, goodB, 0.2)
				else
					frame.hp:SetStatusBarColor(badR, badG, badB)
					frame.hp.bg:SetTexture(badR, badG, badB, 0.2)
				end
			else
				-- Losing/Gaining Threat
				frame.hp:SetStatusBarColor(transitionR, transitionG, transitionB)
				frame.hp.bg:SetTexture(transitionR, transitionG, transitionB, 0.2)
			end
		end
	end
end

-- Create our blacklist for nameplates
-- Matches the full, un-abbreviated unit name (oldname), so the blacklist
-- keeps working even with NameAbbreviate enabled (mirroring FrostAtomUI,
-- which hides by the full unit name).
local function CheckBlacklist(frame, ...)
	local name = frame.hp and (frame.hp.oldname and frame.hp.oldname:GetText() or frame.hp.name and frame.hp.name:GetText())
	if name and K.PlateBlacklist[name] then
		frame:SetScript("OnUpdate", function() end)
		frame.hp:SetAlpha(0)
		frame.cb:Hide()
		frame.overlay:Hide()
		frame.hp.oldlevel:Hide()
		frame.hide = true
	elseif frame.hide then
		frame.hp:SetAlpha(1)
		frame.hide = false
	end
end

-- Force the name text of a nameplate to be behind other nameplates unless it is our target
local function AdjustNameLevel(frame, ...)
	local targetName = GetCachedTargetName()
	if targetName and frame.hp.name:GetText() == targetName and frame:GetParent():GetAlpha() == 1 then
		frame.hp.name:SetDrawLayer("OVERLAY")
	else
		frame.hp.name:SetDrawLayer("BORDER")
	end
end

-- Health Text, also border coloring for certain plates depending on health
local function ShowHealth(frame, ...)
	-- Match values
	HealthBar_ValueChanged(frame.hp)

	-- Show current health value
	local _, maxHealth = frame.healthOriginal:GetMinMaxValues()
	local valueHealth = frame.healthOriginal:GetValue()
	local percent = (valueHealth / maxHealth) * 100

	if C.Nameplate.HealthValue == true then
		frame.hp.value:SetFormattedText(K.ShortValue(valueHealth).." - ".."%d%%", percent)
	end

	-- Use cached target name
	local targetName = GetCachedTargetName()
	if targetName and frame.hp.name:GetText() == targetName and frame:GetParent():GetAlpha() == 1 then
		frame.hp:SetSize((C.Nameplate.Width + C.Nameplate.AdditionalWidth) * K.NoScaleMult, (C.Nameplate.Height + C.Nameplate.AdditionalHeight) * K.NoScaleMult)
		frame.cb:SetPoint("BOTTOMLEFT", frame.hp, "BOTTOMLEFT", 0, -8-((C.Nameplate.Height + C.Nameplate.AdditionalHeight) * K.NoScaleMult))
		frame.cb.icon:SetSize(((C.Nameplate.Height + C.Nameplate.AdditionalHeight) * 2 * K.NoScaleMult) + 8, ((C.Nameplate.Height + C.Nameplate.AdditionalHeight) * 2 * K.NoScaleMult) + 8)
	else
		frame.hp:SetSize(C.Nameplate.Width * K.NoScaleMult, C.Nameplate.Height * K.NoScaleMult)
		frame.cb:SetPoint("BOTTOMLEFT", frame.hp, "BOTTOMLEFT", 0, -8-(C.Nameplate.Height * K.NoScaleMult))
		frame.cb.icon:SetSize((C.Nameplate.Height * 2 * K.NoScaleMult) + 8, (C.Nameplate.Height * 2 * K.NoScaleMult) + 8)
	end
end

-- Unit resolution for aura coverage (FrostAtomUI Identity.lua philosophy):
-- Blizzard recycles stock nameplate frames and 3.3.5 exposes no plate->unit
-- token, so each update pass re-resolves from EVERY unit token the client can
-- resolve (target/focus/mouseover/boss/arena/pet/party/raid targets) and binds
-- exactly ONE plate per guid. Same-name duplicate plates are disambiguated by
-- health fraction; a plate keeps its sticky guid (frame.guid) until it is
-- explicitly rebound, stolen, hidden, or recycled, so a mob that was once
-- target/mouseover keeps showing ITS OWN cached auras instead of leaking a
-- neighbor's.
local HEALTH_TOLERANCE = 0.02
local CONFIRM_HOLD = 1
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsPlayer = UnitIsPlayer
local GetTime = GetTime

local nameIndex = {} -- plate name -> single visible plate, or false on duplicates
local claims = {} -- plate -> guid resolved this pass
local owners = {} -- guid -> plate resolved this pass
local claimUnit = {} -- plate -> unit token resolved this pass
local resolveUnits = {} -- ordered unit tokens for this pass (priority order)

local function GetPlateName(frame)
	local hp = frame.hp
	if not hp then return nil end
	if hp.oldname then
		local n = hp.oldname:GetText()
		if n then return n end
	end
	if hp.name then
		return hp.name:GetText()
	end
	return nil
end

local function HealthMatches(frame, unit)
	local hb = frame.healthOriginal
	if not hb or not hb.GetMinMaxValues then return false end
	local _, max = hb:GetMinMaxValues()
	local cur = hb:GetValue()
	if not max or max <= 0 then return false end
	local uMax = UnitHealthMax(unit)
	if not uMax or uMax <= 0 then return false end
	local uCur = UnitHealth(unit)
	if not uCur then return false end
	local d = (cur / max) - (uCur / uMax)
	if d < 0 then d = -d end
	return d <= HEALTH_TOLERANCE
end

local function IsCandidate(frame, guid, now)
	local claimed = claims[frame]
	if claimed then
		return claimed == guid
	end
	return frame.guid == nil or frame.guid == guid or (now - (frame.confirmedAt or 0)) > CONFIRM_HOLD
end

local function KnownPlate(guid, name)
	local plate = plateByGuid[guid]
	if plate and plate:IsShown() and not plate.hide and GetPlateName(plate) == name then
		return plate
	end
	return nil
end

local function TargetPlate(name)
	if not UnitExists("target") then return nil end
	local found = nil
	for frame in pairs(frames) do
		if frame:IsShown() and not frame.hide and GetPlateName(frame) == name and HealthMatches(frame, "target") then
			if found then return nil end
			found = frame
		end
	end
	return found
end

local function MouseoverPlate(name)
	if not UnitExists("mouseover") then return nil end
	local found = nil
	for frame in pairs(frames) do
		if frame:IsShown() and not frame.hide and GetPlateName(frame) == name and HealthMatches(frame, "mouseover") then
			if found then return nil end
			found = frame
		end
	end
	return found
end

local function MatchPlate(unit, guid, name, now)
	local candidate = nameIndex[name]
	if candidate == nil then return nil end
	if candidate then
		-- Uniquely-named plate: still require health agreement for mobs so a
		-- same-name mob elsewhere can never steal the bind; players skip it.
		if IsCandidate(candidate, guid, now) and (UnitIsPlayer(unit) or HealthMatches(candidate, unit)) then
			return candidate
		end
		return nil
	end
	-- Duplicate name (nameIndex == false): scan every same-named plate and
	-- require a health-fraction match; ambiguous (>1 match) binds nothing.
	local found = nil
	for frame in pairs(frames) do
		if frame:IsShown() and not frame.hide and GetPlateName(frame) == name and IsCandidate(frame, guid, now) and HealthMatches(frame, unit) then
			if found then return nil end
			found = frame
		end
	end
	return found
end

local function ResolveUnit(unit, now)
	if not UnitExists(unit) then return nil end
	local guid = UnitGUID(unit)
	if not guid then return nil end
	if owners[guid] then return owners[guid] end
	local name = UnitName(unit)
	if not name then return nil end
	local plate = nil
	if unit == "target" then
		plate = TargetPlate(name) or KnownPlate(guid, name)
	elseif unit == "mouseover" then
		plate = MouseoverPlate(name) or KnownPlate(guid, name)
	else
		plate = KnownPlate(guid, name) or MatchPlate(unit, guid, name, now)
	end
	if not plate or claims[plate] then return nil end
	owners[guid] = plate
	claims[plate] = guid
	claimUnit[plate] = unit
	return plate
end

-- Priority matches FrostAtom FIXED_UNITS spirit adapted to budsUI tokens:
-- target -> focus -> mouseover -> boss1-4 -> arena1-5 -> pet -> group targets.
local function BuildResolveUnits()
	wipe(resolveUnits)
	local n = 0
	local function push(u)
		if UnitExists(u) then
			n = n + 1
			resolveUnits[n] = u
		end
	end
	push("target")
	push("focus")
	push("mouseover")
	for i = 1, 4 do push("boss" .. i) end
	for i = 1, 5 do push("arena" .. i) end
	push("pet")
	push("pettarget")
	if GetNumRaidMembers and GetNumRaidMembers() > 0 then
		for i = 1, GetNumRaidMembers() do push("raid" .. i .. "target") end
		for i = 1, GetNumRaidMembers() do push("raid" .. i) end
	elseif GetNumPartyMembers then
		for i = 1, GetNumPartyMembers() do push("party" .. i .. "target") end
		for i = 1, GetNumPartyMembers() do push("party" .. i) end
	end
	return resolveUnits
end

-- Combat-log name -> guid map for token-less enemy plates (FrostAtomUI
-- Identity.lua rememberEnemy/bindEnemyPlayers pattern). Blizzard nameplates
-- for enemy players in the world/BGs have no unit token on 3.3.5, so we learn
-- hostile PLAYER guids from combat-log traffic and bind visible plates by
-- (realm-stripped) name. Mobs with duplicate names are deliberately NOT
-- learned (one guid per name would misattribute auras); they stay token-only.
local enemyGuidByName = {}
local BAND_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER or 0x00000400
local BAND_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE or 0x00000040

local COMBATLOG_NAME_EVENTS = {
	SWING_DAMAGE = true,
	RANGE_DAMAGE = true,
	SPELL_DAMAGE = true,
	SPELL_PERIODIC_DAMAGE = true,
	SPELL_HEAL = true,
	SPELL_PERIODIC_HEAL = true,
	SPELL_CAST_SUCCESS = true,
	SPELL_CAST_START = true,
	SPELL_AURA_APPLIED = true,
	SPELL_AURA_REFRESH = true,
	SPELL_MISSED = true,
}

local function StripBaseName(name)
	if not name then return nil end
	return match(name, "^[^%-]+") or name
end

local function RememberEnemyGuid(guid, name, flags)
	if not guid or not name or not flags then return end
	if band(flags, BAND_TYPE_PLAYER) == 0 then return end
	if band(flags, BAND_REACTION_HOSTILE) == 0 then return end
	enemyGuidByName[StripBaseName(name)] = guid
end

function NamePlates:COMBAT_LOG_EVENT_UNFILTERED(timestamp, event, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	if not COMBATLOG_NAME_EVENTS[event] then return end
	if srcName then RememberEnemyGuid(srcGUID, srcName, srcFlags) end
	if dstName then RememberEnemyGuid(dstGUID, dstName, dstFlags) end
end

-- Plate-name skips for the guid (token-less) path. The engine still applies
-- the donor UnitCreatureType/name skips on the token path; this mirrors them
-- where no token exists to query (totems have no token, so match by suffix).
local PLATE_AURA_SKIPS = {
	["Viper"] = true,
	["Venomous Snake"] = true,
	["Army of the Dead Ghoul"] = true,
}

local function PlateNameSkipped(base)
	if not base then return true end
	if PLATE_AURA_SKIPS[base] then return true end
	if base:sub(-5) == "Totem" then return true end
	return false
end

-- One-guid-per-plate bind helpers (FrostAtom Identity.lua setGUID spirit).
-- plateByGuid is the single uniqueness table: a guid is never owned by two
-- plates at once. Evicting the previous owner always hides its icons first so
-- no stale aura row lingers on the wrong plate.
local function ReleasePlate(frame, hideIcons)
	if not frame then return end
	local g = frame.guid
	if g and plateByGuid[g] == frame then
		plateByGuid[g] = nil
	end
	frame.guid = nil
	frame.unit = nil
	frame.boundName = nil
	frame.confirmedAt = 0
	if hideIcons ~= false and K.NamePlateAuras_Hide then
		K.NamePlateAuras_Hide(frame)
	end
end

local function BindPlateToUnit(frame, unit, guid, now)
	local other = plateByGuid[guid]
	if other and other ~= frame then
		if K.NamePlateAuras_Hide then
			K.NamePlateAuras_Hide(other)
		end
		other.guid = nil
		other.unit = nil
		other.boundName = nil
		other.confirmedAt = 0
	end
	local old = frame.guid
	if old and old ~= guid and plateByGuid[old] == frame then
		plateByGuid[old] = nil
	end
	frame.guid = guid
	frame.unit = unit
	frame.boundName = GetPlateName(frame)
	frame.confirmedAt = now
	plateByGuid[guid] = frame
	K.NamePlateAuras_Update(frame, unit)
end

local function BindPlateToGuid(frame, guid, now)
	local other = plateByGuid[guid]
	if other and other ~= frame then
		return false
	end
	local old = frame.guid
	if old and old ~= guid and plateByGuid[old] == frame then
		plateByGuid[old] = nil
	end
	frame.guid = guid
	frame.unit = nil
	frame.boundName = GetPlateName(frame)
	frame.confirmedAt = now
	plateByGuid[guid] = frame
	owners[guid] = frame
	K.NamePlateAuras_Update(frame, guid)
	return true
end

-- Per-pass aura resolution (runs ONCE per 0.2s ticker, not once per plate):
-- 1. rebuild nameIndex (unique plate, or false on duplicate names);
-- 2. resolve every unit token in priority order to exactly one plate;
-- 3. bind claimed plates via the token path (exact UnitAura scan);
-- 4. for unclaimed plates: keep the sticky guid alive (redraw from the
--    combat-log cache), bind token-less enemy PLAYERS by unique name, or
--    release. Sticky guids + health disambiguation are what keep two
--    same-named mobs on their own aura rows.
local function ResolvePlateAuras(now)
	if C.Nameplate.Auras ~= true or not K.NamePlateAuras_Update then return end
	now = now or GetTime()
	wipe(nameIndex)
	wipe(claims)
	wipe(owners)
	wipe(claimUnit)
	for frame in pairs(frames) do
		if frame:IsShown() and not frame.hide then
			local pname = GetPlateName(frame)
			if pname then
				local cur = nameIndex[pname]
				if cur == nil then
					nameIndex[pname] = frame
				elseif cur ~= frame then
					nameIndex[pname] = false
				end
			end
		end
	end
	BuildResolveUnits()
	for i = 1, #resolveUnits do
		ResolveUnit(resolveUnits[i], now)
	end
	for plate, guid in pairs(claims) do
		local unit = claimUnit[plate]
		if plate:IsShown() and not plate.hide and unit and UnitExists(unit) then
			local base = StripBaseName(GetPlateName(plate))
			if base and not PlateNameSkipped(base) then
				BindPlateToUnit(plate, unit, guid, now)
			else
				ReleasePlate(plate, true)
			end
		end
	end
	for frame in pairs(frames) do
		if frame:IsShown() and not claims[frame] then
			if frame.hide then
				if frame.unit ~= nil or frame.guid ~= nil then
					ReleasePlate(frame, true)
				end
			else
				local pname = GetPlateName(frame)
				local sticky = frame.guid
				-- Recycled stock frame showing a new name: drop the old bind.
				if sticky and frame.boundName and pname ~= frame.boundName then
					ReleasePlate(frame, true)
					sticky = nil
				end
				-- Guid stolen by a claimed plate this pass: drop it.
				if sticky and plateByGuid[sticky] and plateByGuid[sticky] ~= frame then
					ReleasePlate(frame, true)
					sticky = nil
				end
				if sticky and owners[sticky] and owners[sticky] ~= frame then
					ReleasePlate(frame, true)
					sticky = nil
				end
				if sticky then
					if not plateByGuid[sticky] then
						plateByGuid[sticky] = frame
					end
					local base = pname and StripBaseName(pname) or nil
					if base and not PlateNameSkipped(base) then
						K.NamePlateAuras_Update(frame, sticky)
					else
						ReleasePlate(frame, true)
					end
				else
					-- Token-less enemy PLAYER bind: unique visible name only,
					-- guid not taken by any claimed/sticky plate this pass.
					local done = false
					local base = pname and StripBaseName(pname) or nil
					if base and not PlateNameSkipped(base) and nameIndex[pname] == frame then
						local eGuid = enemyGuidByName[base]
						if eGuid and not owners[eGuid] and (not plateByGuid[eGuid] or plateByGuid[eGuid] == frame) then
							done = BindPlateToGuid(frame, eGuid, now)
						end
					end
					if not done and frame.unit ~= nil then
						ReleasePlate(frame, true)
					end
				end
			end
		end
	end
end

-- Legacy per-plate entry kept for compatibility; the ticker now calls
-- ResolvePlateAuras once per pass, so this is a no-op shim.
local function CheckUnit_Guid(frame, ...)
	return
end

-- Run a function for all visible nameplates, we use this for the blacklist, to check unitguid, and to hide drunken text
local function ForEachPlate(functionToRun, ...)
	local count = 0
	for frame in pairs(frames) do
		if frame:IsShown() then
			local success, err = pcall(functionToRun, frame, ...)
			if not success and C.General.DeveloperMode then
				K.Print("ForEachPlate error:", err)
			end
			count = count + 1
		end
	end
	return count
end

-- Optimized version with batch-processing
local visiblePlates = {}
local function UpdateVisiblePlates()
	wipe(visiblePlates)
	for frame in pairs(frames) do
		if frame:IsShown() then
			table.insert(visiblePlates, frame)
		end
	end
end

local function ForEachVisiblePlate(functionToRun, ...)
	for i = 1, #visiblePlates do
		local success, err = pcall(functionToRun, visiblePlates[i], ...)
		if not success and C.General.DeveloperMode then
			K.Print("ForEachVisiblePlate error:", err)
		end
	end
end

-- Check if the frames default overlay texture matches blizzards nameplates default overlay texture
local select = select
local function HookFrames(...)
	for index = 1, select("#", ...) do
		local frame = select(index, ...)
		local region = frame:GetRegions()

		if (not frames[frame] and not (frame:GetName() and (frame:GetName():find("NamePlate%d") or frame:GetName():find("NamePlateDriverFrame"))) and not frame.UnitFrame and not frame._unit and region and region:GetObjectType() == "Texture" and region:GetTexture() == OVERLAY) then
			SkinObjects(frame)
			frame.region = region
		end
	end
end


-- Consolidated update throttle
local updateThrottle = 0
local UPDATE_INTERVAL = 0.2

-- Core right here, scan for any possible nameplate frames that are Children of the WorldFrame
NamePlates:SetScript("OnUpdate", K.SafeOnUpdate(function(self, elapsed)
	-- Scan for new nameplates (faster check, 0.1s interval)
	scanThrottle = scanThrottle + elapsed
	if scanThrottle > 0.1 then
		if WorldFrame:GetNumChildren() ~= numChildren then
			numChildren = WorldFrame:GetNumChildren()
			HookFrames(WorldFrame:GetChildren())
		end
		scanThrottle = 0
	end
	
	-- Consolidated update for all nameplate functions (0.2s interval)
	updateThrottle = updateThrottle + elapsed
	if updateThrottle >= UPDATE_INTERVAL then
		-- Update visible plates cache once
		UpdateVisiblePlates()

		-- Resolve aura bindings ONCE per pass (one plate per guid), then paint.
		if C.Nameplate.Auras then
			local ok, err = pcall(ResolvePlateAuras, GetTime())
			if not ok and C.General.DeveloperMode then
				K.Print("ResolvePlateAuras error:", err)
			end
		end
		
		-- Batch-update all functions in a single loop
		for i = 1, #visiblePlates do
			local frame = visiblePlates[i]
			
			-- Threat update (only when in combat and threat system active)
			if C.Nameplate.EnhanceThreat and InCombatLockdown() then
				UpdateThreat(frame, updateThrottle)
			end
			
			-- Health update
			ShowHealth(frame)
			
			-- Name level adjust (only when target exists)
			if UnitExists("target") then
				AdjustNameLevel(frame)
			end
			
			-- Blacklist check (only once per frame)
			if not frame.blacklistChecked then
				CheckBlacklist(frame)
				frame.blacklistChecked = true
			end
		end
		
		updateThrottle = 0
	end
end, "NamePlates"))

-- Only show nameplates when in combat
-- WoW 3.3.5 Compatibility: CVar "nameplateShowEnemies" doesn't exist in 3.3.5
-- It was added in Legion 7.0. In 3.3.5 we use "ShowNameplates" instead
if C.Nameplate.Combat == true then
	NamePlates:RegisterEvent("PLAYER_REGEN_ENABLED")
	NamePlates:RegisterEvent("PLAYER_REGEN_DISABLED")

	function NamePlates:PLAYER_REGEN_ENABLED()
		SetCVar("ShowNameplates", 0)
	end

	function NamePlates:PLAYER_REGEN_DISABLED()
		SetCVar("ShowNameplates", 1)
	end
end

NamePlates:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
NamePlates:RegisterEvent("PLAYER_ENTERING_WORLD")
function NamePlates:PLAYER_ENTERING_WORLD()
	wipe(enemyGuidByName)
	wipe(plateByGuid)
	wipe(nameIndex)
	wipe(claims)
	wipe(owners)
	wipe(claimUnit)
	if C.Nameplate.Combat == true then
		if InCombatLockdown() then
			SetCVar("ShowNameplates", 1)
		else
			SetCVar("ShowNameplates", 0)
		end
	end
end