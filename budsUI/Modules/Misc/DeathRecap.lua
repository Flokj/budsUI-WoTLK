local K, C, L, _ = select(2, ...):unpack()

local GetTime = GetTime
local GetSpellInfo = GetSpellInfo
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local UnitGUID = UnitGUID
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local IsInInstance = IsInInstance
local GameTooltip = GameTooltip
local FauxScrollFrame_Update = FauxScrollFrame_Update
local FauxScrollFrame_OnVerticalScroll = FauxScrollFrame_OnVerticalScroll
local FauxScrollFrame_GetOffset = FauxScrollFrame_GetOffset
local FauxScrollFrame_SetOffset = FauxScrollFrame_SetOffset
local floor, min, max = math.floor, math.min, math.max
local band = bit.band
local concat = table.concat
local format = string.format
local tostring = tostring
local tinsert = table.insert

local LINK_PREFIX = "budsrecap:"
-- K.Print already prefixes every message with the addon name.
local CHAT_LINE = "%s |cffff4d4d|H" .. LINK_PREFIX .. "%d|h[%s]|h|r"
local BURST_TEXT = "%s  |cffff3333%s|r"
local RECAPS_KEPT = 30
local BUFFER_SIZE = 80
local RECAP_WINDOW = 10
local BURST_WINDOW = 1.5
local WIDTH = 340
local PADDING = 12
local HEADER_HEIGHT = 26
local ROW_HEIGHT = 34
local ICON_SIZE = 26
local ICON_TRIM = 0.08
local AMOUNT_WIDTH = 80
local SCROLL_WIDTH = 20
local TOMBSTONE_SIZE = 16
local TOMBSTONE_ICON = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull"
local ENVIRONMENT_ICON = "Interface\\Icons\\Ability_Creature_Cursed_05"
local MELEE_SPELL = 6603
local NO_ENTRIES = {}

local FIXED_ICONS = {
	[MELEE_SPELL] = "Interface\\Icons\\Ability_MeleeDamage",
	[75] = "Interface\\Icons\\Ability_Marksmanship",
	[5019] = "Interface\\Icons\\Ability_ShootWand",
}

local DAMAGE_COLOR = { 0.75, 0.1, 0.1 }
local LARGEST_COLOR = { 1, 0.2, 0.2 }
local ABSORBED_COLOR = { 0.6, 0.6, 0.6 }
local CASTER_COLOR = { 0.6, 0.6, 0.6 }
local EXTRA_COLOR = { 0.7, 0.7, 0.7 }
local TIME_COLOR = { 1, 0.82, 0 }
local HEAL_COLOR = { 0.3, 0.9, 0.3 }

local HEAL_EVENTS = {
	SPELL_HEAL = true,
	SPELL_PERIODIC_HEAL = true,
}

local SPELL_DAMAGE_EVENTS = {
	SPELL_DAMAGE = true,
	SPELL_PERIODIC_DAMAGE = true,
	RANGE_DAMAGE = true,
	DAMAGE_SHIELD = true,
	DAMAGE_SPLIT = true,
}

local SPELL_MISSED_EVENTS = {
	SPELL_MISSED = true,
	SPELL_PERIODIC_MISSED = true,
	RANGE_MISSED = true,
	DAMAGE_SHIELD_MISSED = true,
}

local SCHOOLS = {
	{ 1, "Physical" },
	{ 2, "Holy" },
	{ 4, "Fire" },
	{ 8, "Nature" },
	{ 16, "Frost" },
	{ 32, "Shadow" },
	{ 64, "Arcane" },
}

local ENVIRONMENT = {
	FALLING = { "Falling", "Interface\\Icons\\Ability_Rogue_QuickRecovery" },
	DROWNING = { "Drowning", "Interface\\Icons\\Spell_Shadow_DemonBreath" },
	FATIGUE = { "Fatigue", ENVIRONMENT_ICON },
	FIRE = { "Fire", "Interface\\Icons\\Spell_Fire_Fire" },
	LAVA = { "Lava", "Interface\\Icons\\Spell_Fire_Fire" },
	SLIME = { "Slime", "Interface\\Icons\\INV_Misc_Slime_01" },
}

local ENTRY_FIELDS = {
	"time", "kind", "source", "spellId", "spellName", "environment",
	"amount", "overkill", "school", "resisted", "blocked", "absorbed",
	"critical", "health", "healthMax",
}

local playerGUID
local buffer = { head = 0 }
local recaps = {}
local lastRecapId = 0
local shownId
local deathTime = 0
local frame

local function recordHit(sourceName, spellId, spellName, environment, amount, overkill, school, resisted, blocked, absorbed, critical)
	local head = buffer.head % BUFFER_SIZE + 1
	buffer.head = head
	local entry = buffer[head]
	if not entry then
		entry = {}
		buffer[head] = entry
	end
	entry.time = GetTime()
	entry.kind = nil
	entry.source = sourceName
	entry.spellId = spellId
	entry.spellName = spellName
	entry.environment = environment
	entry.amount = amount or 0
	entry.overkill = overkill or 0
	entry.school = school
	entry.resisted = resisted or 0
	entry.blocked = blocked or 0
	entry.absorbed = absorbed or 0
	entry.critical = critical
	entry.health = UnitHealth("player")
	entry.healthMax = UnitHealthMax("player")
end

local function recordOther(kind, sourceName, spellId, spellName, amount)
	recordHit(sourceName, spellId, spellName, nil, amount)
	buffer[buffer.head].kind = kind
end

-- Normalized 3.3.5 CLEU payload (no frame/event prefix or hideCaster slot).
local function onCombatLogEvent(timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
	if destGUID ~= playerGUID then
		return
	end

	if HEAL_EVENTS[event] then
		local healed = (a4 or 0) - (a5 or 0)
		if healed > 0 and C.Misc and C.Misc.DeathRecapHeals ~= false then
			recordOther("heal", sourceName, a1, a2, healed)
		end
		return
	end

	if event == "SWING_DAMAGE" then
		recordHit(sourceName, MELEE_SPELL, nil, nil, a1, a2, a3, a4, a5, a6, a7)
	elseif SPELL_DAMAGE_EVENTS[event] then
		recordHit(sourceName, a1, a2, nil, a4, a5, a6, a7, a8, a9, a10)
	elseif event == "ENVIRONMENTAL_DAMAGE" then
		recordHit(nil, nil, nil, a1, a2, a3, a4, a5, a6, a7, a8)
	elseif event == "SWING_MISSED" then
		if a1 == "ABSORB" then
			recordHit(sourceName, MELEE_SPELL, nil, nil, 0, 0, 1, 0, 0, a2, nil)
		end
	elseif SPELL_MISSED_EVENTS[event] then
		if a4 == "ABSORB" then
			recordHit(sourceName, a1, a2, nil, 0, 0, a3, 0, 0, a5, nil)
		end
	end
end

local schoolNames = {}
local schoolParts = {}

local function schoolName(school)
	if not school or school == 0 then return end
	local name = schoolNames[school]
	if not name then
		wipe(schoolParts)
		for i = 1, #SCHOOLS do
			if band(school, SCHOOLS[i][1]) ~= 0 then
				schoolParts[#schoolParts + 1] = ((L_RECAP_SCHOOLS and L_RECAP_SCHOOLS[SCHOOLS[i][1]]) or SCHOOLS[i][2])
			end
		end
		name = concat(schoolParts, "/")
		schoolNames[school] = name
	end
	return name
end

local function shortAmount(value)
	if not value then return "0" end
	if value < 1e3 then
		return tostring(value)
	elseif value < 1e6 then
		return format("%.1fk", value / 1e3)
	end
	return format("%.2fm", value / 1e6)
end

local function resolveNameAndIcon(entry)
	local environment = entry.environment
	if environment then
		local info = ENVIRONMENT[environment]
		entry.name = info and ((L_RECAP_ENVIRONMENT and L_RECAP_ENVIRONMENT[environment]) or info[1]) or environment
		entry.icon = info and info[2] or ENVIRONMENT_ICON
		return
	end
	local spellId = entry.spellId
	local name, _, icon = GetSpellInfo(spellId)
	if spellId == MELEE_SPELL then
		entry.name = L_RECAP_MELEE or "Melee"
	else
		entry.name = entry.spellName or name or UNKNOWN or "Unknown"
	end
	entry.icon = FIXED_ICONS[spellId] or icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function burstDamage(lastHit)
	local total = 0
	local index = buffer.head
	for _ = 1, BUFFER_SIZE do
		local entry = buffer[index]
		if not entry or not entry.time or lastHit - entry.time > BURST_WINDOW then
			break
		end
		if not entry.kind then
			total = total + entry.amount
		end
		index = (index - 2) % BUFFER_SIZE + 1
	end
	return total
end

local function freezeRecap()
	local now = GetTime()
	local entries = {}
	local index = buffer.head
	for _ = 1, BUFFER_SIZE do
		local entry = buffer[index]
		if not entry or not entry.time or now - entry.time > RECAP_WINDOW then
			break
		end
		local target = {}
		for i = 1, #ENTRY_FIELDS do
			local field = ENTRY_FIELDS[i]
			target[field] = entry[field]
		end
		entries[#entries + 1] = target
		index = (index - 2) % BUFFER_SIZE + 1
	end

	local killIndex
	for i = 1, #entries do
		if not entries[i].kind then
			killIndex = i
			break
		end
	end

	local burst = killIndex and burstDamage(entries[killIndex].time)
	for i = 1, #buffer do
		buffer[i].time = nil
	end
	if not burst then return end

	local largest, largestAmount = nil, 0
	for i = 1, #entries do
		local entry = entries[i]
		resolveNameAndIcon(entry)
		if not entry.kind and entry.amount > largestAmount then
			largest, largestAmount = entry, entry.amount
		end
	end
	if largest then
		largest.largest = true
	end

	lastRecapId = lastRecapId + 1
	recaps[lastRecapId] = {
		entries = entries,
		deathTime = entries[killIndex].time,
		burst = burst,
		killIndex = killIndex,
	}
	recaps[lastRecapId - RECAPS_KEPT] = nil
	return lastRecapId
end

local function addTooltipLine(text, color)
	if color then
		GameTooltip:AddLine(text, color[1], color[2], color[3])
	else
		GameTooltip:AddLine(text)
	end
end

local function addExtra(template, value)
	if value and value > 0 then
		addTooltipLine(format(template, value), EXTRA_COLOR)
	end
end

local function onRowEnter(self)
	local entry = self.entry
	if not entry then return end
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	local school = schoolName(entry.school)
	if entry.kind == "heal" then
		addTooltipLine(format(L_RECAP_HEAL or "%d healing", entry.amount), HEAL_COLOR)
	elseif school then
		addTooltipLine(format(L_RECAP_DAMAGE_SCHOOL or "%d %s damage", entry.amount, school), LARGEST_COLOR)
	else
		addTooltipLine(format(L_RECAP_DAMAGE or "%d damage", entry.amount), LARGEST_COLOR)
	end
	if entry.critical then
		addTooltipLine(L_RECAP_CRITICAL or "Critical hit", EXTRA_COLOR)
	end
	addExtra(L_RECAP_OVERKILL or "%d overkill", entry.overkill)
	addExtra(L_RECAP_ABSORBED or "%d absorbed", entry.absorbed)
	addExtra(L_RECAP_RESISTED or "%d resisted", entry.resisted)
	addExtra(L_RECAP_BLOCKED or "%d blocked", entry.blocked)

	if entry.source then
		GameTooltip:AddLine(format(L_RECAP_SOURCE or "%s by %s", entry.name, entry.source), 1, 1, 1, true)
	else
		GameTooltip:AddLine(entry.name, 1, 1, 1, true)
	end

	if entry.healthMax and entry.healthMax > 0 then
		local percent = floor(entry.health / entry.healthMax * 100)
		if self.index == frame.killIndex then
			addTooltipLine(format(L_RECAP_KILLING_BLOW or "Killing blow at %d%% health", percent), TIME_COLOR)
		else
			addTooltipLine(format(L_RECAP_BEFORE_DEATH or "%.1fs before death at %d%% health", deathTime - entry.time, percent), TIME_COLOR)
		end
	end
	GameTooltip:Show()
end

local function onIconEnter(self)
	local spellId = self.row.entry and self.row.entry.spellId
	if not spellId or FIXED_ICONS[spellId] then
		onRowEnter(self.row)
		return
	end
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetHyperlink("spell:" .. spellId)
	GameTooltip:Show()
end

local function createRow(index)
	local list = frame.list
	local top = -(index - 1) * ROW_HEIGHT
	local row = CreateFrame("Button", nil, list)
	row:SetHeight(ROW_HEIGHT)
	row:SetPoint("TOPLEFT", list, "TOPLEFT", 0, top)
	row:SetPoint("TOPRIGHT", list, "TOPRIGHT", 0, top)
	row:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight")
	row:GetHighlightTexture():SetAlpha(0.2)
	row:SetScript("OnEnter", onRowEnter)
	row:SetScript("OnLeave", function() GameTooltip:Hide() end)

	local icon = row:CreateTexture(nil, "ARTWORK")
	icon:SetSize(ICON_SIZE, ICON_SIZE)
	icon:SetPoint("LEFT", 4, 0)
	icon:SetTexCoord(ICON_TRIM, 1 - ICON_TRIM, ICON_TRIM, 1 - ICON_TRIM)
	row.icon = icon

	local iconHover = CreateFrame("Frame", nil, row)
	iconHover:SetAllPoints(icon)
	iconHover:EnableMouse(true)
	iconHover.row = row
	iconHover:SetScript("OnEnter", onIconEnter)
	iconHover:SetScript("OnLeave", function() GameTooltip:Hide() end)

	local name = row:CreateFontString(nil, "OVERLAY")
	name:SetFont(C.Media.Font, 12, C.Media.Font_Style)
	name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, 0)
	name:SetPoint("TOPRIGHT", -(AMOUNT_WIDTH + 8), -(ROW_HEIGHT - ICON_SIZE) / 2)
	name:SetHeight(14)
	name:SetJustifyH("LEFT")
	row.name = name

	local caster = row:CreateFontString(nil, "OVERLAY")
	caster:SetFont(C.Media.Font, 11, C.Media.Font_Style)
	caster:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -1)
	caster:SetPoint("TOPRIGHT", name, "BOTTOMRIGHT", 0, -1)
	caster:SetHeight(12)
	caster:SetJustifyH("LEFT")
	caster:SetTextColor(CASTER_COLOR[1], CASTER_COLOR[2], CASTER_COLOR[3])
	row.caster = caster

	local amount = row:CreateFontString(nil, "OVERLAY")
	amount:SetFont(C.Media.Font, 13, "OUTLINE")
	amount:SetPoint("RIGHT", -4, 0)
	row.amount = amount

	local amountLarge = row:CreateFontString(nil, "OVERLAY")
	amountLarge:SetFont(C.Media.Font, 16, "OUTLINE")
	amountLarge:SetPoint("RIGHT", -4, 0)
	row.amountLarge = amountLarge

	local tombstone = row:CreateTexture(nil, "OVERLAY")
	tombstone:SetSize(TOMBSTONE_SIZE, TOMBSTONE_SIZE)
	tombstone:SetTexture(TOMBSTONE_ICON)
	row.tombstone = tombstone

	frame.rows[index] = row
	return row
end

local function fillRow(row, entry, index)
	row.entry = entry
	row.index = index
	row.icon:SetTexture(entry.icon)
	row.name:SetText(entry.name)
	row.caster:SetText(entry.source or "")

	local text, other = row.amount, row.amountLarge
	local color = DAMAGE_COLOR
	if entry.largest then
		text, other = other, text
		color = LARGEST_COLOR
	end
	other:Hide()
	text:Show()
	if entry.kind == "heal" then
		text:SetText("+" .. shortAmount(entry.amount))
		color = HEAL_COLOR
	elseif entry.amount > 0 then
		text:SetText("-" .. shortAmount(entry.amount))
	else
		text:SetText("0")
		color = ABSORBED_COLOR
	end
	text:SetTextColor(color[1], color[2], color[3])

	if index == frame.killIndex then
		row.tombstone:ClearAllPoints()
		row.tombstone:SetPoint("RIGHT", text, "LEFT", -4, 0)
		row.tombstone:Show()
	else
		row.tombstone:Hide()
	end
end

local function refreshRows()
	local entries = frame.entries
	local visible = frame.visibleRows
	local offset = FauxScrollFrame_GetOffset(frame.scroll)
	local rows = frame.rows
	for i = 1, visible do
		local index = i + offset
		local entry = entries[index]
		local row = rows[i] or createRow(i)
		if entry then
			fillRow(row, entry, index)
			row:Show()
		else
			row:Hide()
		end
	end
	for i = visible + 1, #rows do
		rows[i]:Hide()
	end
	FauxScrollFrame_Update(frame.scroll, #entries, visible, ROW_HEIGHT)
end

local function refresh()
	if not frame or not frame:IsShown() then
		return
	end
	local recap = recaps[shownId]
	local entries = recap and recap.entries or NO_ENTRIES
	local count = #entries
	local maxVisible = (C.Misc and C.Misc.DeathRecapEntries) or 5
	local visible = min(count, maxVisible)
	deathTime = recap and recap.deathTime or 0
	frame.killIndex = recap and recap.killIndex or 1

	local title = L_RECAP_TITLE or "Death recap"
	if recap and recap.burst > 0 then
		title = format(BURST_TEXT, title, format(L_RECAP_BURST or "-%s in %.1fs", shortAmount(recap.burst), BURST_WINDOW))
	end
	frame.title:SetText(title)
	frame.entries = entries
	frame.visibleRows = visible
	local height = max(visible, 1) * ROW_HEIGHT
	local right = count > visible and PADDING + SCROLL_WIDTH or PADDING
	frame.list:SetPoint("TOPRIGHT", -right, -(PADDING + HEADER_HEIGHT))
	frame.list:SetHeight(height)
	refreshRows()
	if frame.empty then
		if count == 0 then frame.empty:Show() else frame.empty:Hide() end
	end
	frame:SetHeight(PADDING * 2 + HEADER_HEIGHT + height)
end

local function createFrame()
	frame = CreateFrame("Frame", "budsUI_DeathRecap", UIParent)
	frame:SetSize(WIDTH, 200)
	frame:Hide()
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
	frame:SetFrameStrata("DIALOG")
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
	frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	frame:SetBackdrop(K.Backdrop)
	if K.CreateBorder then K.CreateBorder(frame) end
	-- CreateBorder re-applies SetBackdrop, which resets the background tint.
	frame:SetBackdropColor(unpack(C.Media.Backdrop_Color))
	frame:SetBackdropBorderColor(unpack(C.Media.Border_Color))
	tinsert(UISpecialFrames, "budsUI_DeathRecap")

	frame:SetScript("OnShow", refresh)
	frame.rows = {}
	frame.entries = NO_ENTRIES
	frame.visibleRows = 0

	local title = frame:CreateFontString(nil, "OVERLAY")
	title:SetFont(C.Media.Font, 12, C.Media.Font_Style)
	title:SetPoint("TOPLEFT", 12, -8)
	title:SetPoint("TOPRIGHT", -26, -8)
	title:SetJustifyH("LEFT")
	frame.title = title

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
	close:SetScript("OnClick", function() frame:Hide() end)

	local list = CreateFrame("Frame", nil, frame)
	list:SetPoint("TOPLEFT", PADDING, -(PADDING + HEADER_HEIGHT))
	list:SetPoint("TOPRIGHT", -PADDING, -(PADDING + HEADER_HEIGHT))
	frame.list = list

	local scroll = CreateFrame("ScrollFrame", "budsUI_DeathRecapScroll", list, "FauxScrollFrameTemplate")
	scroll:SetAllPoints()
	scroll:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, refreshRows)
	end)
	frame.scroll = scroll

	local empty = frame:CreateFontString(nil, "OVERLAY")
	empty:SetFont(C.Media.Font, 13, C.Media.Font_Style)
	empty:SetTextColor(0.5, 0.5, 0.5)
	empty:SetPoint("TOP", 0, -(PADDING + HEADER_HEIGHT + ROW_HEIGHT / 2 - 7))
	empty:SetText(L_RECAP_EMPTY or "No death recorded yet")
	frame.empty = empty

	K.CreateMover(frame, "DeathRecap", L_RECAP_TITLE or "Death recap", { "CENTER", UIParent, "CENTER", 0, 100 }, WIDTH, 200)
end

local function show(id)
	if not frame then
		createFrame()
	end
	shownId = id or lastRecapId
	FauxScrollFrame_SetOffset(frame.scroll, 0)
	if frame.scroll.scrollBar then
		frame.scroll.scrollBar:SetValue(0)
	end
	if frame:IsShown() then
		refresh()
	else
		frame:Show()
	end
end
K.OpenDeathRecap = show

local function onPlayerDead()
	if not C.Misc or C.Misc.DeathRecap ~= true then return end
	local id = freezeRecap()
	if not id then return end
	K.Print(format(CHAT_LINE, L_RECAP_YOU_DIED or "You died.", id, L_RECAP_TITLE or "Death recap"))
	if C.Misc and C.Misc.DeathRecapAutoOpen then
		local _, instanceType = IsInInstance()
		if instanceType == "arena" or instanceType == "pvp" then
			show(id)
		end
	end
end

local listener = CreateFrame("Frame")

local function applyConfig()
	playerGUID = UnitGUID("player")
	if C.Misc and C.Misc.DeathRecap == true then
		listener:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		listener:RegisterEvent("PLAYER_DEAD")
	else
		listener:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		listener:UnregisterEvent("PLAYER_DEAD")
		for i = 1, #buffer do buffer[i].time = nil end
		if frame then frame:Hide() end
	end
	refresh()
end
K.UpdateDeathRecapConfig = applyConfig

listener:RegisterEvent("PLAYER_LOGIN")
listener:RegisterEvent("PLAYER_ENTERING_WORLD")
listener:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
		if event == "PLAYER_LOGIN" then self:UnregisterEvent(event) end
		applyConfig()
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		-- Private clients may add boolean hideCaster after the subevent.
		-- Strip it at the boundary without copying the hot-path tuple.
		local timestamp, subevent, third = ...
		if type(third) == "boolean" then
			onCombatLogEvent(timestamp, subevent, select(4, ...))
		else
			onCombatLogEvent(...)
		end
	elseif event == "PLAYER_DEAD" then
		onPlayerDead()
	end
end)

-- The recap owns its link handler; it must also work with C.Chat.Enable off.
-- Keep the previous handler for items, spells and other addons' links.
local function handleRecapLink(link)
	if type(link) ~= "string" or link:sub(1, #LINK_PREFIX) ~= LINK_PREFIX then
		return false
	end
	local value = link:sub(#LINK_PREFIX + 1)
	local id = value:match("^%d+$") and tonumber(value)
	if id then K.OpenDeathRecap(id) end
	return true
end

local previousSetItemRef = SetItemRef
function _G.SetItemRef(link, ...)
	if handleRecapLink(link) then return end
	return previousSetItemRef(link, ...)
end

local previousSetHyperlink = ItemRefTooltip.SetHyperlink
function ItemRefTooltip:SetHyperlink(link, ...)
	if handleRecapLink(link) then return end
	return previousSetHyperlink(self, link, ...)
end

SLASH_RECAP1 = "/recap"
SLASH_RECAP2 = "/deathrecap"
SlashCmdList["RECAP"] = function()
	show()
end
