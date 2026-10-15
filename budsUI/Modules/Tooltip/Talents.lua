local K, C, L, _ = select(2, ...):unpack()
if C.Tooltip.Enable ~= true or C.Tooltip.Talents ~= true then return end

-- Target Talents(TipTacTalents by Aezay)
-- Locals
local _G = _G
local ipairs = ipairs
local CreateFrame = CreateFrame
local GetTalentTabInfo = GetTalentTabInfo
local isInspect = isInspect
local GetText, GetMouseFocus, GetUnit = GetText, GetMouseFocus, GetUnit
local UnitIsPlayer, UnitLevel, UnitIsPlayer, UnitName, UnitIsUnit, UnitGUID = UnitIsPlayer, UnitLevel, UnitIsPlayer, UnitName, UnitIsUnit, UnitGUID
local CanInspect = CanInspect
local GatherTalents = GatherTalents
local InspectFrame = InspectFrame

local ttt = CreateFrame("Frame", "TipTacTalents")
local cache = {}
local current = {}
local TALENTS_PREFIX = TALENTS..":|cffffffff "
local CACHE_SIZE = 25	-- Change cache size here (Default 25)

-- Allow these to be accessed through other addons
ttt.cache = cache
ttt.current = current

-- Gather Talents
-- Target Talents(TipTacTalents by Aezay)
if C.Tooltip.Talents == true then
	local gtt = GameTooltip

	-- GatherTalents — parses talent data into `current`, refreshes the open
	-- tooltip and caches the entry. No "Loading" placeholder is printed: the
	-- line appears as soon as the inspect data lands, and cached entries are
	-- shown instantly (FrostAtomUI behaviour — no stuck "Loading").
	local function GatherTalents(isInspect)
		-- Inspect functions will always use the active spec when not inspecting
		local group = GetActiveTalentGroup(isInspect)
		-- Get points per tree, and set "maxTree" to the tree with most points
		local maxTree = 1
		for i = 1, 3 do
			_, _, current[i] = GetTalentTabInfo(i,isInspect,nil,group)
			if (current[i] > current[maxTree]) then
				maxTree = i
			end
		end
		current.tree = GetTalentTabInfo(maxTree,isInspect,nil,group)
		-- Customise output. Use TipTac setting if it exists, otherwise just use formatting style one.
		local talentFormat = (TipTac_Config and TipTac_Config.talentFormat or 1)
		if (current[maxTree] == 0) then
			current.format = L_TOOLTIP_NO_TALENT
		elseif (talentFormat == 1) then
			current.format = current.tree.." ("..current[1].."/"..current[2].."/"..current[3]..")"
		elseif (talentFormat == 2) then
			current.format = current.tree
		elseif (talentFormat == 3) then
			current.format = current[1].."/"..current[2].."/"..current[3]
		end
		-- Set the tips line output; for inspect, only touch the tooltip while it
		-- still shows the very unit whose data just arrived.
		local tipUnit = gtt:GetUnit()
		if (not isInspect) then
			gtt:AddLine(TALENTS_PREFIX..current.format)
		elseif (tipUnit and current.guid and UnitGUID(tipUnit) == current.guid) then
			local replaced = false
			for i = 2, gtt:NumLines() do
				local line = _G["GameTooltipTextLeft"..i]
				local text = line and line:GetText() or ""
				if (text:match("^"..TALENTS_PREFIX)) then
					line:SetFormattedText("%s%s",TALENTS_PREFIX,current.format)
					replaced = true
					break
				end
			end
			if (not replaced) then
				gtt:AddLine(TALENTS_PREFIX..current.format)
			end
			-- Do not call Show() if the tip is fading out, this only works with TipTac
			if (not gtt.fadeOut) then
				gtt:Show()
			end
		end
		-- Organise Cache (GUID-first, name fallback)
		local cacheSize = (TipTac_Config and TipTac_Config.talentCacheSize or CACHE_SIZE)
		for i = #cache, 1, -1 do
			if (current.guid and cache[i].guid and current.guid == cache[i].guid)
			or (not current.guid and current.name and cache[i].name == current.name) then
				tremove(cache,i)
				break
			end
		end
		if (#cache > cacheSize) then
			tremove(cache,1)
		end
		-- Cache the new entry
		if (cacheSize > 0) then
			cache[#cache + 1] = CopyTable(current)
		end
	end

	-- OnEvent: the inspect for the LAST requested unit landed. Update the open
	-- tooltip if it still shows that unit; otherwise just cache the data — the
	-- next hover shows it from the cache instead of a new "Loading" round.
	ttt:SetScript("OnEvent",function(self,event)
		self:UnregisterEvent("INSPECT_TALENT_READY")
		local requestGuid = self.requestGuid
		local requestName = self.requestName
		self.requestGuid = nil
		self.requestName = nil
		if (not requestGuid) then
			return
		end
		if (current.guid == requestGuid) then
			GatherTalents(1)
		else
			-- The tooltip switched to another unit: parse into a copy keyed by
			-- the requested unit and cache it, leaving `current` untouched.
			local cached = current
			current = { guid = requestGuid, name = requestName }
			GatherTalents(1)
			current = cached
		end
	end)

	-- HOOK: OnTooltipSetUnit
	gtt:HookScript("OnTooltipSetUnit",function(self,...)
		-- Get the unit -- Check the UnitFrame unit if this tip is from a concated unit, such as "targettarget".
		local _, unit = self:GetUnit()
		if (not unit) then
			local mFocus = GetMouseFocus()
			if (mFocus) and (mFocus.unit) then
				unit = mFocus.unit
			end
		end
		-- Only for players over level 9 -- Ignore PvP flagged people, unless they are friendly
		if (UnitIsPlayer(unit)) and (UnitLevel(unit) > 9 or UnitLevel(unit) == -1) and (CanInspect(unit)) then
			wipe(current)
			current.name = UnitName(unit)
			current.guid = UnitGUID(unit)
			current.unit = unit
			-- Player
			if (UnitIsUnit(unit,"player")) then
				GatherTalents()
				-- Others
			else
				local allowInspect = (not InspectFrame or not InspectFrame:IsShown()) and (not Examiner or not Examiner:IsShown())
				for _, entry in ipairs(cache) do
					if (current.guid and entry.guid and current.guid == entry.guid)
					or (not current.guid and current.name and entry.name == current.name) then
						self:AddLine(TALENTS_PREFIX..entry.format)
						current.tree = entry.tree
						current.format = entry.format
						current[1], current[2], current[3] = entry[1], entry[2], entry[3]
						current.guid = entry.guid
						return
					end
				end
				if (allowInspect) then
					-- No cache entry: request the inspect and remember WHO we
					-- asked for, so the data is cached even if the tooltip moves
					-- on before INSPECT_TALENT_READY fires.
					ttt.requestGuid = current.guid
					ttt.requestName = current.name
					ttt:RegisterEvent("INSPECT_TALENT_READY")
					NotifyInspect(unit)
				end
			end
		end
	end)
end