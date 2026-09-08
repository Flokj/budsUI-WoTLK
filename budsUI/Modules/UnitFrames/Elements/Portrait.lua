--[[-----------------------------------------------------------------------------
Addon: budsUI
File: Modules/UnitFrames/Elements/Portrait.lua
Purpose:
	The detached portrait box. It sits beside the unit and spans the whole
	frame height (health, gap, power), squared by the spawn pass.

	Three styles: a 3D model, the flat 2D face texture, or a class icon.

	Ported from KkthnxUI retail to WoW 3.3.5: SetPortraitTexture has no atlas
	path here, so the crop is applied unconditionally for 2D portraits and
	class icons use CLASS_ICON_TCOORDS.
-----------------------------------------------------------------------------]]

local Engine = select(2, ...)
local K, C = Engine:unpack()
local Module = Engine.UnitFrames
local Build = Module.Build

local CreateFrame = CreateFrame

-- SetPortraitTexture resets texcoords on every update, so the crop that
-- trims the transparent frame baked into the face art is reapplied after.
local function CropPortrait(element)
	element:SetTexCoord(0.15, 0.85, 0.15, 0.85)
end

-- side is "left" or "right", relative to the unit frame. Standalone units get
-- their square width set later from the real frame height, header children
-- (party) have no such pass, so they pass an explicit width here.
function Build.Portrait(self, side, width)
	if not C.Unitframe.Portrait then
		return
	end

	local holder = CreateFrame("Frame", nil, self)
	holder:SetPoint("TOP", self, "TOP", 0, 0)
	holder:SetPoint("BOTTOM", self, "BOTTOM", 0, 0)
	if side == "right" then
		holder:SetPoint("LEFT", self, "RIGHT", Module.GAP, 0)
	else
		holder:SetPoint("RIGHT", self, "LEFT", -Module.GAP, 0)
	end
	if width then
		holder:SetWidth(width)
	end
	K.CreateBackground(holder, 0.05, 0.05, 0.05, 0.9)

	local style = C.Unitframe.PortraitStyle
	local portrait

	if style == "3D" then
		portrait = CreateFrame("PlayerModel", nil, holder)
		portrait:SetPoint("TOPLEFT", holder, "TOPLEFT", 1, -1)
		portrait:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -1, 1)

		-- A 3D model draws over textures on the same frame, so the border has
		-- to live on an overlay frame stacked above the model.
		local overlay = CreateFrame("Frame", nil, holder)
		overlay:SetAllPoints()
		overlay:SetFrameLevel(portrait:GetFrameLevel() + 2)
		K.CreateBorder(overlay)
		holder.Overlay = overlay
	elseif style == "Class" then
		portrait = holder:CreateTexture(nil, "ARTWORK")
		portrait:SetPoint("TOPLEFT", holder, "TOPLEFT", 1, -1)
		portrait:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -1, 1)
		portrait.PostUpdate = function(element, unit)
			local _, class = UnitClass(unit)
			if class then
				local coords = CLASS_ICON_TCOORDS[class]
				if coords then
					element:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
					element:SetTexCoord(unpack(coords))
					return
				end
			end
			SetPortraitTexture(element, unit)
			CropPortrait(element)
		end
		K.CreateBorder(holder)
	else
		portrait = holder:CreateTexture(nil, "ARTWORK")
		portrait:SetPoint("TOPLEFT", holder, "TOPLEFT", 1, -1)
		portrait:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -1, 1)
		portrait.PostUpdate = CropPortrait
		K.CreateBorder(holder)
	end

	self.Portrait = portrait
	self.PortraitHolder = holder
	return holder
end

-- Level text on the portrait, so the name above the health bar stays clean.
function Build.PortraitLevel(self)
	local holder = self.PortraitHolder
	if not holder then
		return
	end

	local level = Module.GradientLabel(self, holder, 12)
	self:Tag(level, "[difficulty][buds:level]")
	self.LevelText = level
	return level
end
