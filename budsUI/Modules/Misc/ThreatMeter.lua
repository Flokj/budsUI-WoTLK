local K, C, L, _ = select(2, ...):unpack()
if C.ThreatMeter.Enable ~= true then return end

-- budsUI Threat Meter (ported from the standalone Threath addon).
-- Shows the top threat holders on your current attackable target.
-- Styled with the budsUI panel look (backdrop + border) and moved
-- through the budsUI mover ("Threat Meter"). Runs on PLAYER_LOGIN so
-- Core (Movers/Border) is fully loaded (Misc modules load before it).

local tinsert, wipe = table.insert, wipe
local select, pairs = select, pairs
local CreateFrame, UIParent = CreateFrame, UIParent
local UnitExists, UnitIsDead, UnitIsPlayer, UnitIsVisible = UnitExists, UnitIsDead, UnitIsPlayer, UnitIsVisible
local UnitCanAttack, UnitName, UnitGUID, UnitClass = UnitCanAttack, UnitName, UnitGUID, UnitClass
local UnitDetailedThreatSituation = UnitDetailedThreatSituation
local GetNumRaidMembers, GetNumPartyMembers = GetNumRaidMembers, GetNumPartyMembers

local PET_COLOR = { r = 0, g = 0.7, b = 0 }

local function Threat_Init()
	local width = C.ThreatMeter.Width
	local height = C.ThreatMeter.Height
	local spacing = C.ThreatMeter.Spacing
	local maxBars = C.ThreatMeter.MaxBars
	local fontSize = C.ThreatMeter.FontSize

	--------------------------------------------------
	-- HOLDER (anchored to the budsUI mover)
	--------------------------------------------------

	local holder = CreateFrame("Frame", "budsUIThreatMeter", UIParent)
	holder:SetSize(width, (height + spacing) * maxBars)
	holder:SetClampedToScreen(true)

	K.CreateMover(holder, "ThreatMeter", "Threat Meter",
		{ "TOPLEFT", UIParent, "BOTTOMRIGHT", -565, 113 },
		width, (height + spacing) * maxBars)

	--------------------------------------------------
	-- DATA
	--------------------------------------------------

	local bars, tList, barList = {}, {}, {}
	local targeted = false

	local function Truncate(value)
		if value >= 1e6 then
			return string.format("%.2fm", value / 1e6)
		elseif value >= 1e4 then
			return string.format("%.1fk", value / 1e3)
		else
			return string.format("%.0f", value)
		end
	end

	local function AddUnit(unit)
		local threatpct, _, threatval = select(3, UnitDetailedThreatSituation(unit, "target"))

		-- 3.3.5 returns threat as signed 32-bit, fix the overflow
		if threatval and threatval < 0 then
			threatval = threatval + 410065408
		end

		local guid = UnitGUID(unit)
		if not guid then return end

		if not tList[guid] then
			tinsert(barList, guid)
			tList[guid] = {
				name = UnitName(unit),
				class = UnitIsPlayer(unit) and select(2, UnitClass(unit)) or "PET",
			}
		end

		tList[guid].pct = threatpct or 0
		tList[guid].val = threatval or 0
	end

	local function CheckUnit(unit)
		if UnitExists(unit) and UnitIsVisible(unit) then
			AddUnit(unit)
			if UnitExists(unit .. "pet") then
				AddUnit(unit .. "pet")
			end
		end
	end

	--------------------------------------------------
	-- BAR CREATION (budsUI style: backdrop + border)
	--------------------------------------------------

	local function CreateBar(index)
		local bar = CreateFrame("StatusBar", nil, holder)
		bar:SetSize(width, height)
		bar:SetStatusBarTexture(C.Media.Texture)
		bar:SetMinMaxValues(0, 100)
		bar:SetBackdrop(K.Backdrop)
		bar:SetBackdropColor(unpack(C.Media.Backdrop_Color))
		bar:SetBackdropBorderColor(unpack(C.Media.Border_Color))
		K.CreateBorder(bar)
		bar:EnableMouse(false)

		bar.left = bar:CreateFontString(nil, "OVERLAY")
		bar.left:SetFont(C.Media.Font, fontSize, C.Media.Font_Style)
		bar.left:SetPoint("LEFT", 2, 0)
		bar.left:SetJustifyH("LEFT")
		bar.left:SetShadowColor(0, 0, 0)
		bar.left:SetShadowOffset(1, -1)

		bar.right = bar:CreateFontString(nil, "OVERLAY")
		bar.right:SetFont(C.Media.Font, fontSize, C.Media.Font_Style)
		bar.right:SetPoint("RIGHT", -2, 0)
		bar.right:SetJustifyH("RIGHT")
		bar.right:SetShadowColor(0, 0, 0)
		bar.right:SetShadowOffset(1, -1)

		bar:SetPoint("TOP", holder, "TOP", 0, -(height + spacing) * (index - 1))
		bar:Hide()

		return bar
	end

	--------------------------------------------------
	-- UPDATES
	--------------------------------------------------

	local function SortMethod(a, b)
		local ta, tb = tList[a], tList[b]
		if not ta then return false end
		if not tb then return true end
		return tb.pct < ta.pct
	end

	local function UpdateBars()
		for _, v in pairs(bars) do
			v:Hide()
		end

		table.sort(barList, SortMethod)

		if #barList == 0 then return end

		local maxThreat = tList[barList[1]]
		if not maxThreat then return end

		for i = 1, #barList do
			local cur = tList[barList[i]]
			if i > maxBars or not cur or cur.pct == 0 then break end

			if not bars[i] then
				bars[i] = CreateBar(i)
			end

			local value = 0
			if maxThreat.pct and maxThreat.pct > 0 then
				value = 100 * cur.pct / maxThreat.pct
			end
			bars[i]:SetValue(value)

			-- Empty part of the bar: dark class color on the backdrop
			-- (a separate tint texture mislayers on 3.3.5 and shows white).
			local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[cur.class] or (cur.class == "PET" and PET_COLOR)
			if color then
				bars[i]:SetStatusBarColor(color.r, color.g, color.b)
				bars[i]:SetBackdropColor(color.r * 0.22, color.g * 0.22, color.b * 0.22, 0.9)
			else
				bars[i]:SetBackdropColor(unpack(C.Media.Backdrop_Color))
			end

			bars[i].left:SetText(cur.name)
			bars[i].right:SetText(string.format("%s (%d%%)", Truncate(cur.val / 100), cur.pct))
			bars[i]:Show()
		end
	end

	local function UpdateThreat()
		if not targeted then return end

		if GetNumRaidMembers() > 0 then
			for i = 1, GetNumRaidMembers() do
				CheckUnit("raid" .. i)
			end
		elseif GetNumPartyMembers() > 0 then
			for i = 1, GetNumPartyMembers() do
				CheckUnit("party" .. i)
			end
		end

		CheckUnit("targettarget")
		CheckUnit("player")

		UpdateBars()
	end

	local function Reset()
		wipe(tList)
		wipe(barList)
		UpdateBars()
	end

	--------------------------------------------------
	-- EVENTS
	--------------------------------------------------

	local addon = CreateFrame("Frame")
	addon:SetScript("OnEvent", function(_, event)
		if event == "PLAYER_TARGET_CHANGED" then
			if UnitExists("target") and not UnitIsDead("target")
				and not UnitIsPlayer("target") and UnitCanAttack("player", "target") then
				targeted = true
			else
				targeted = false
			end
			Reset()
		elseif event == "UNIT_THREAT_LIST_UPDATE" then
			UpdateThreat()
		elseif event == "PLAYER_REGEN_ENABLED" then
			Reset()
		end
	end)
	addon:RegisterEvent("PLAYER_TARGET_CHANGED")
	addon:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
	addon:RegisterEvent("PLAYER_REGEN_ENABLED")

	-- Preview: /bthreat fills the meter with fake data (KkthnxUI /kkthreat)
	SlashCmdList["BUDS_THREAT"] = function()
		for i = 1, maxBars do
			tList[i] = {
				name = UnitName("player"),
				class = select(2, UnitClass("player")),
				pct = i / maxBars * 100,
				val = i * 10000,
			}
			tinsert(barList, i)
		end
		UpdateBars()
		wipe(tList)
		wipe(barList)
	end
	SLASH_BUDS_THREAT1 = "/bthreat"
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN")
	Threat_Init()
end)
