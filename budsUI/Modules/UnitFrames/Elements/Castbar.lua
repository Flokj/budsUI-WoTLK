--[[-----------------------------------------------------------------------------
Addon: budsUI
File: Modules/UnitFrames/Elements/Castbar.lua
Purpose:
	Castbars. The player, target, and focus bars are detached and get their
	own mover, the way the original KkthnxUI placed them. Boss and group bars
	stay attached to their unit.

	Ported from KkthnxUI retail to WoW 3.3.5: classic oUF drives the progress
	with start/end arithmetic (no DurationObject, no secret booleans), so the
	callbacks take plain values. notInterruptible is a normal boolean. No
	empower stages exist here.
-----------------------------------------------------------------------------]]

local Engine = select(2, ...)
local K, C = Engine:unpack()
local Module = Engine.UnitFrames
local Build = Module.Build

local CreateFrame = CreateFrame

-- Blizzard's own cast colour language, tuned to sit in our palette: a warm
-- gold for a normal cast, silver grey for one you cannot interrupt (paired
-- with the shield), and red when a cast is interrupted or fails.
local CAST_COLOR = { 0.85, 0.65, 0.13 } -- normal (gold / yellow)
local NOINTERRUPT_COLOR = { 0.6, 0.6, 0.65 } -- cannot interrupt (silver)
local FAIL_COLOR = { 0.85, 0.25, 0.25 } -- interrupted / failed (red)

-- ---------------------------------------------------------------------------
-- Callbacks
-- ---------------------------------------------------------------------------

-- Colour the whole bar by interruptibility and drive the shield.
local function OnCastStart(self, unit)
	self.__failed = nil
	if self.notInterruptible then
		self:SetStatusBarColor(NOINTERRUPT_COLOR[1], NOINTERRUPT_COLOR[2], NOINTERRUPT_COLOR[3])
	else
		self:SetStatusBarColor(CAST_COLOR[1], CAST_COLOR[2], CAST_COLOR[3])
	end
	if self.Shield then
		if self.notInterruptible then
			self.Shield:Show()
		else
			self.Shield:Hide()
		end
	end
end

local function OnCastFail(self, unit)
	self:SetStatusBarColor(FAIL_COLOR[1], FAIL_COLOR[2], FAIL_COLOR[3])
	self.__failed = true
	if self.Shield then
		self.Shield:Hide()
	end
	-- Fill the bar so a stopped cast reads as stopped rather than frozen part
	-- way through, the same way the other UIs show an interrupt.
	self:SetMinMaxValues(0, 1)
	self:SetValue(1)
end

local function CustomTimeText(self, duration)
	if self.__failed then
		return
	end
	self.Time:SetFormattedText("%.1f", duration)
end

local function CustomDelayText(self, duration)
	if self.__failed then
		return
	end
	self.Time:SetFormattedText("%.1f|cffff5555%s%.1f|r", duration, self.channeling and "-" or "+", self.delay)
end

-- ---------------------------------------------------------------------------
-- Construction
-- ---------------------------------------------------------------------------

-- Parented to the bar rather than the holder so oUF hiding the bar takes the
-- icon with it. Sticking out past the bar's edge is fine, children are not
-- clipped to their parent.
local function AddIcon(cast, size, side)
	local holder = CreateFrame("Frame", nil, cast)
	holder:SetSize(size, size)
	if side == "right" then
		holder:SetPoint("LEFT", cast, "RIGHT", Module.GAP, 0)
	else
		holder:SetPoint("RIGHT", cast, "LEFT", -Module.GAP, 0)
	end
	K.CreateBackground(holder, 0.05, 0.05, 0.05, 0.9)
	K.CreateBorder(holder, 10)

	local icon = holder:CreateTexture(nil, "ARTWORK")
	icon:SetPoint("TOPLEFT", holder, "TOPLEFT", 1, -1)
	icon:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -1, 1)
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	cast.Icon = icon
	cast.IconHolder = holder
	return holder
end

-- opts:
--   width, height   bar size
--   iconSide        "left" (default) or "right"
--   latency         show the latency safe zone (player only)
--   parent          frame the bar lives on, defaults to the unit frame
local function CreateBar(self, opts)
	local db = C.Unitframe.Castbar
	local parent = opts.parent or self

	local cast = CreateFrame("StatusBar", nil, parent)
	cast:SetStatusBarTexture(Module.Texture())
	cast:SetStatusBarColor(CAST_COLOR[1], CAST_COLOR[2], CAST_COLOR[3])
	cast:SetHeight(opts.height)
	K.CreateGradientBackground(cast, 0.9)
	K.CreateBorder(cast)

	cast.timeToHold = db.TimeToHold
	cast.PostCastStart = OnCastStart
	cast.PostCastInterruptible = OnCastStart
	cast.PostCastFail = OnCastFail
	cast.PostCastInterrupted = OnCastFail

	local shield = cast:CreateTexture(nil, "OVERLAY")
	shield:SetTexture("Interface\\CastingBar\\UI-CastingBar-Small-Shield")
	shield:SetSize(opts.height, opts.height)
	shield:SetPoint("CENTER", cast, "CENTER", 0, 0)
	shield:Hide()
	cast.Shield = shield

	if db.ShowSpark then
		local spark = cast:CreateTexture(nil, "OVERLAY")
		spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
		spark:SetBlendMode("ADD")
		spark:SetSize(12, opts.height + 8)
		spark:SetPoint("CENTER", cast:GetStatusBarTexture(), "RIGHT", 0, 0)
		cast.Spark = spark
	end

	local name = Module.NewText(cast, opts.height >= 24 and 12 or 11)
	name:SetPoint("LEFT", cast, "LEFT", 4, 0)
	name:SetJustifyH("LEFT")
	cast.Text = name

	if db.ShowTimer then
		local time = Module.NewText(cast, opts.height >= 24 and 12 or 11)
		time:SetPoint("RIGHT", cast, "RIGHT", -4, 0)
		time:SetJustifyH("RIGHT")
		cast.Time = time
		cast.CustomTimeText = CustomTimeText
		cast.CustomDelayText = CustomDelayText

		-- Keep the spell name from running under the timer.
		name:SetPoint("RIGHT", time, "LEFT", -6, 0)
	else
		name:SetPoint("RIGHT", cast, "RIGHT", -4, 0)
	end

	if db.ShowIcon then
		AddIcon(cast, opts.height, opts.iconSide)
	end

	if opts.latency and db.ShowLatency then
		local safe = cast:CreateTexture(nil, "OVERLAY")
		safe:SetTexture(FAIL_COLOR[1], FAIL_COLOR[2], FAIL_COLOR[3], 0.6)
		cast.SafeZone = safe
	end

	self.Castbar = cast
	return cast
end

-- A free floating castbar: the bar and its icon live inside a holder parented
-- to UIParent, which is what the mover grabs. Detaching from the unit frame
-- also means the bar keeps its own alpha and visibility.
function Build.DetachedCastbar(self, key, label, width, height, point, iconSide)
	local db = C.Unitframe.Castbar
	if not db.Enable then
		return
	end

	local holder = CreateFrame("Frame", nil, UIParent)
	local totalWidth = db.ShowIcon and (width + height + Module.GAP) or width
	holder:SetSize(totalWidth, height)

	local cast = CreateBar(self, {
		width = width,
		height = height,
		iconSide = iconSide or "left",
		latency = self.unit == "player",
		parent = holder,
	})
	cast:SetWidth(width)
	if (iconSide or "left") == "left" and db.ShowIcon then
		cast:SetPoint("RIGHT", holder, "RIGHT", 0, 0)
	else
		cast:SetPoint("LEFT", holder, "LEFT", 0, 0)
	end

	cast.Holder = holder

	-- Drop a target mid cast and no stop event ever arrives, because the unit
	-- is simply gone rather than finishing or being interrupted. The bar's
	-- OnUpdate would keep running with the cast still flagged in progress, and
	-- a detached bar sits on UIParent where nothing hides it, ticking forever.
	-- Hiding the bar stops that OnUpdate dead; the next cast start shows it
	-- again.
	self:HookScript("OnHide", function()
		cast:Hide()
	end)

	K.CreateMover(holder, key, label, point, totalWidth, height)
	return cast
end

-- An attached castbar, pushed onto the frame's downward stack.
function Build.Castbar(self, height, iconSide)
	local db = C.Unitframe.Castbar
	if not db.Enable then
		return
	end

	local cast = CreateBar(self, {
		height = height,
		iconSide = iconSide or "left",
	})
	Module.StackDown(self, cast, height)
	return cast
end

-- A castbar that sits above the frame, spanning the full width (portrait
-- included) so a compact frame keeps its own bar without a hanging icon.
function Build.TopCastbar(self, height, side)
	local db = C.Unitframe.Castbar
	if not db.Enable then
		return
	end
	local health = self.Health
	if not health then
		return
	end
	height = height or 16
	local rightSide = side == "right"

	local cast = CreateFrame("StatusBar", nil, self)
	cast:SetStatusBarTexture(Module.Texture())
	cast:SetStatusBarColor(CAST_COLOR[1], CAST_COLOR[2], CAST_COLOR[3])
	cast:SetHeight(height)
	local outer = self.PortraitHolder or self
	if rightSide then
		cast:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, Module.GAP)
		cast:SetPoint("BOTTOMRIGHT", outer, "TOPRIGHT", -(height + Module.GAP), Module.GAP)
	else
		cast:SetPoint("BOTTOMLEFT", outer, "TOPLEFT", height + Module.GAP, Module.GAP)
		cast:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, Module.GAP)
	end
	K.CreateGradientBackground(cast, 0.9)
	K.CreateBorder(cast)

	cast.PostCastStart = OnCastStart
	cast.PostCastInterruptible = OnCastStart
	cast.PostCastFail = OnCastFail
	cast.PostCastInterrupted = OnCastFail

	local holder = CreateFrame("Frame", nil, cast)
	holder:SetSize(height, height)
	if rightSide then
		holder:SetPoint("LEFT", cast, "RIGHT", Module.GAP, 0)
	else
		holder:SetPoint("RIGHT", cast, "LEFT", -Module.GAP, 0)
	end
	K.CreateGradientBackground(holder, 0.9)
	K.CreateBorder(holder, 10)
	local icon = holder:CreateTexture(nil, "ARTWORK")
	icon:SetPoint("TOPLEFT", holder, "TOPLEFT", 1, -1)
	icon:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -1, 1)
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	cast.Icon = icon
	cast.IconHolder = holder

	if db.ShowSpark then
		local spark = cast:CreateTexture(nil, "OVERLAY")
		spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
		spark:SetBlendMode("ADD")
		spark:SetSize(12, height + 4)
		spark:SetPoint("CENTER", cast:GetStatusBarTexture(), "RIGHT", 0, 0)
		cast.Spark = spark
	end

	local name = Module.NewText(cast, 10)
	name:SetPoint("LEFT", cast, "LEFT", 4, 0)
	name:SetJustifyH("LEFT")
	cast.Text = name

	if db.ShowTimer then
		local time = Module.NewText(cast, 10)
		time:SetPoint("RIGHT", cast, "RIGHT", -4, 0)
		time:SetJustifyH("RIGHT")
		cast.Time = time
		cast.CustomTimeText = CustomTimeText
		cast.CustomDelayText = CustomDelayText
		name:SetPoint("RIGHT", time, "LEFT", -4, 0)
	else
		name:SetPoint("RIGHT", cast, "RIGHT", -4, 0)
	end

	self.Castbar = cast
	return cast
end
