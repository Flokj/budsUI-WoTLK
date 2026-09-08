--[[-----------------------------------------------------------------------------
Addon: budsUI
File: Modules/UnitFrames/Elements/Auras.lua
Purpose:
	Buff and debuff displays for the unit frames, built on classic oUF's
	Buffs/Debuffs elements (UnitAura based).

	Ported from KkthnxUI retail to WoW 3.3.5: Blizzard's Midnight
	CustomAuraContainer does not exist here, so this is a full rewrite that
	keeps the same look and layout (debuffs above growing right then up,
	buffs below growing right then down, compact dispel rows beside group
	frames). Dispel filtering uses a CustomFilter against K.CanDispel because
	3.3.5 UnitAura has no RAID_DISPELLABLE filter token.
-----------------------------------------------------------------------------]]

local Engine = select(2, ...)
local K, C = Engine:unpack()
local Module = Engine.UnitFrames
local Build = Module.Build

local floor = math.floor
local max = math.max
local DebuffTypeColor = DebuffTypeColor
local UnitIsUnit = UnitIsUnit

-- Style a fresh aura button: cropped icon, thin border, cooldown swipe, stack
-- count. Runs once per button from PostCreateIcon. oUF calls it as
-- element:PostCreateIcon(button), so the button is the second argument;
-- taking it first would style the whole container instead of each icon.
local function StyleButton(_, button)
	if not button then
		return
	end
	local icon = button.icon
	if icon then
		icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end

	K.CreateBorder(button, 10)

	local cd = button.cd
	if cd then
		cd:SetReverse(true)
		K.StyleCooldownSwipe(cd)
	end

	local count = button.count
	if count then
		K.SetFont(count, 10, K.FontOutlineStyle())
		count:ClearAllPoints()
		count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, 0)
		count:SetJustifyH("RIGHT")
	end

	if button.overlay then
		button.overlay:Hide()
	end
end

-- Recolour the button border by dispel type so dispellable debuffs stand out.
local function PostUpdateIcon(element, unit, button, index, position, duration, expiration, debuffType, isStealable)
	if debuffType and button.SetBackdropBorderColor then
		local c = DebuffTypeColor[debuffType]
		if c then
			button:SetBackdropBorderColor(c.r, c.g, c.b)
			return
		end
	end
	if button.SetBackdropBorderColor then
		button:SetBackdropBorderColor()
	end
end

local function IsMine(caster)
	return caster and (UnitIsUnit(caster, "player") or UnitIsUnit(caster, "vehicle") or UnitIsUnit(caster, "pet"))
end

-- Debuffs sit above the frame and grow right then up, buffs below growing
-- right then down, filling the frame width.
function Build.Auras(self, cfg)
	local db = C.Unitframe.Auras
	local width = cfg.Width or 220
	local perRow = max(1, db.PerRow or 7)
	local spacing = db.Spacing or 6
	local size = max(8, floor((width - (perRow - 1) * spacing) / perRow))
	-- oUF derives its column count from the container width, so the panel
	-- must span a full row or every icon lands on its own line.
	local rowWidth = size * perRow + spacing * (perRow - 1)

	if cfg.Debuffs then
		local debuffs = CreateFrame("Frame", nil, self)
		-- Sit above the name gradient (the stack-up anchor) rather than the
		-- frame's top, so the debuffs clear the name cleanly.
		local anchorTo = self.__stackUp or self
		debuffs:SetPoint("BOTTOMLEFT", anchorTo, "TOPLEFT", 0, Module.GAP)
		debuffs:SetSize(rowWidth, size)
		debuffs.size = size
		debuffs.spacing = spacing
		debuffs.num = db.NumDebuffs or 8
		debuffs.onlyShowPlayer = db.OnlyPlayerDebuffs or false
		debuffs.initialAnchor = "BOTTOMLEFT"
		debuffs["growth-x"] = "RIGHT"
		debuffs["growth-y"] = "UP"
		debuffs.PostCreateIcon = StyleButton
		debuffs.PostUpdateIcon = PostUpdateIcon
		self.Debuffs = debuffs
	end

	if cfg.Buffs then
		local buffs = CreateFrame("Frame", nil, self)
		buffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -Module.GAP)
		buffs:SetSize(rowWidth, size)
		buffs.size = size
		buffs.spacing = spacing
		buffs.num = db.NumBuffs or 12
		buffs.initialAnchor = "TOPLEFT"
		buffs["growth-x"] = "RIGHT"
		buffs["growth-y"] = "DOWN"
		buffs.PostCreateIcon = StyleButton
		buffs.PostUpdateIcon = PostUpdateIcon
		self.Buffs = buffs
	end
end

-- Compact debuff row beside a group frame's health bar. side "right" clears
-- the party portrait, "left" is the default for the raid.
function Build.GroupDebuffs(self, count, size, side)
	local spacing = Module.GAP
	local debuffs = CreateFrame("Frame", nil, self)
	if side == "right" then
		debuffs:SetPoint("BOTTOMLEFT", self.Health, "RIGHT", spacing, 0)
		debuffs.initialAnchor = "BOTTOMLEFT"
		debuffs["growth-x"] = "RIGHT"
	else
		debuffs:SetPoint("BOTTOMRIGHT", self.Health, "LEFT", -spacing, 0)
		debuffs.initialAnchor = "BOTTOMRIGHT"
		debuffs["growth-x"] = "LEFT"
	end
	debuffs:SetSize(size * count + spacing * (count - 1), size)
	debuffs["growth-y"] = "UP"
	debuffs.size = size
	debuffs.spacing = spacing
	debuffs.num = count

	-- Healers usually only want debuffs they can act on, so default the group
	-- rows to the auras the player can dispel. Toggle off to show everything.
	if C.Unitframe.GroupDispelOnly then
		debuffs.CustomFilter = function(element, unit, button, name, rank, icon, count, debuffType)
			if debuffType and K.CanDispel and K.CanDispel[debuffType] then
				return true
			end
			return false
		end
	end

	debuffs.PostCreateIcon = StyleButton
	debuffs.PostUpdateIcon = PostUpdateIcon
	self.Debuffs = debuffs
	return debuffs
end
