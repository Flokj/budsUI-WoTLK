local K, C, L, _ = select(2, ...):unpack()
if C.PulseCD.Enable ~= true then return end

-- Based on Doom Cooldown Pulse(by Woffle of Dark Iron, editor Affli)
local GetTime = GetTime
local fadeInTime, fadeOutTime, maxAlpha, elapsed, runtimer = 0.5, 0.7, 1, 0, 0
local animScale, iconSize, holdTime, threshold = C.PulseCD.AnimationScale, C.PulseCD.Size, C.PulseCD.HoldTime, C.PulseCD.Threshold
local cooldowns, animating, watching = {}, {}, {}

local anchor = CreateFrame("Frame", "PulseCDAnchor", UIParent)
anchor:SetSize(C.PulseCD.Size, C.PulseCD.Size)
anchor:SetPoint(unpack(C.Position.PulseCooldown))

local frame = CreateFrame("Frame", "PulseCDFrame", anchor)
frame:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
frame:SetBackdrop({
	bgFile = C.Media.Blank,
	edgeFile = C.Media.Glow,
	edgeSize = 3 * K.NoScaleMult,
	insets = {top = 3 * K.NoScaleMult, left = 3 * K.NoScaleMult, bottom = 3 * K.NoScaleMult, right = 3 * K.NoScaleMult}
})
frame:SetBackdropColor(0, 0, 0, 0)
frame:SetBackdropBorderColor(0, 0, 0, 0.8)
frame:SetPoint("CENTER", anchor, "CENTER")

local icon = frame:CreateTexture(nil, "ARTWORK")
icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
icon:SetPoint("TOPLEFT", frame, "TOPLEFT", K.NoScaleMult * 2, -K.NoScaleMult * 2)
icon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -K.NoScaleMult * 2, K.NoScaleMult * 2)

-- Utility Functions
local function tcount(tab)
	local n = 0
	for _ in pairs(tab) do
		n = n + 1
	end
	return n
end

local function GetPetActionIndexByName(name)
	for i = 1, NUM_PET_ACTION_SLOTS, 1 do
		if GetPetActionInfo(i) == name then
			return i
		end
	end
	return nil
end

-- Cooldown/Animation
local function OnUpdate(_, update)
	elapsed = elapsed + update
	if elapsed > 0.05 then
		for i, v in pairs(watching) do
			if GetTime() >= v[1] + 0.5 + threshold then
				if K.pulse_ignored_spells[i] then
					watching[i] = nil
				else
					-- WoW 3.3.5 Compatibility: Cooldown functions return only 2 values (start, duration)
					-- The 3rd parameter (enabled) was added in Cataclysm 4.0
					local start, duration, texture, isPet
					if v[2] == "spell" then
						texture = GetSpellTexture(v[3])
						start, duration = GetSpellCooldown(v[3])
					elseif v[2] == "item" then
						texture = v[3]
						start, duration = GetItemCooldown(i)
					elseif v[2] == "pet" then
						texture = select(3, GetPetActionInfo(v[3]))
						start, duration = GetPetActionCooldown(v[3])
						isPet = true
					end
					-- In 3.3.5, if start > 0 the cooldown is active (no enabled flag needed)
					if start and start > 0 and duration and duration > threshold and texture then
						cooldowns[i] = {start, duration, texture, isPet}
					end
					-- Remove from watching if cooldown started or spell type
					if (start and start > 0) or v[2] == "spell" then
						watching[i] = nil
					end
				end
			end
		end
		for i, v in pairs(cooldowns) do
			local remaining = v[2] - (GetTime() - v[1])
			if remaining <= 0 then
				tinsert(animating, {v[3], v[4]})
				cooldowns[i] = nil
			end
		end

		elapsed = 0
		if #animating == 0 and tcount(watching) == 0 and tcount(cooldowns) == 0 then
			frame:SetScript("OnUpdate", nil)
			return
		end
	end

	if #animating > 0 then
		runtimer = runtimer + update
		if runtimer > (fadeInTime + holdTime + fadeOutTime) then
			tremove(animating, 1)
			runtimer = 0
			icon:SetTexture(nil)
			frame:SetBackdropBorderColor(0, 0, 0, 0)
			frame:SetBackdropColor(0, 0, 0, 0)
		else
			if not icon:GetTexture() then
				icon:SetTexture(animating[1][1])
				if C.PulseCD.Sound == true then
					PlaySoundFile(C.Media.Proc_Sound, "Master")
				end
			end
			local alpha = maxAlpha
			if runtimer < fadeInTime then
				alpha = maxAlpha * (runtimer / fadeInTime)
			elseif runtimer >= fadeInTime + holdTime then
				alpha = maxAlpha - (maxAlpha * ((runtimer - holdTime - fadeInTime) / fadeOutTime))
			end
			frame:SetAlpha(alpha)
			local scale = iconSize + (iconSize * ((animScale - 1) * (runtimer / (fadeInTime + holdTime + fadeOutTime))))
			frame:SetWidth(scale)
			frame:SetHeight(scale)
			frame:SetBackdropBorderColor(0, 0, 0, 0.8)
			frame:SetBackdropColor(unpack(C.Media.Backdrop_Color))
		end
	end
end

-- Event Handlers
function frame:ADDON_LOADED(addon)
	for _, v in pairs(K.pulse_ignored_spells) do
		K.pulse_ignored_spells[v] = true
	end
	self:UnregisterEvent("ADDON_LOADED")
end
frame:RegisterEvent("ADDON_LOADED")

function frame:UNIT_SPELLCAST_SUCCEEDED(unit, spell, rank)
	if unit == "player" then
		watching[spell] = {GetTime(), "spell", spell.."("..rank..")"}
		self:SetScript("OnUpdate", OnUpdate)
	elseif unit == "pet" then
		local name = spell
		local index = GetPetActionIndexByName(name)
		if index and not select(7, GetPetActionInfo(index)) then
			watching[name] = {GetTime(), "pet", index}
		elseif not index and name then
			watching[name] = {GetTime(), "spell", name.."("..rank..")"}
		else
			return
		end
		self:SetScript("OnUpdate", OnUpdate)
	end
end
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

function frame:PLAYER_ENTERING_WORLD()
	local _, instanceType = IsInInstance()
	if instanceType == "arena" then
		self:SetScript("OnUpdate", nil)
		wipe(cooldowns)
		wipe(watching)
	end
end
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

hooksecurefunc("UseAction", function(slot)
	local actionType, itemID = GetActionInfo(slot)
	if actionType == "item" then
		local texture = GetActionTexture(slot)
		watching[itemID] = {GetTime(), "item", texture}
	end
end)

hooksecurefunc("UseInventoryItem", function(slot)
	local itemID = GetInventoryItemID("player", slot)
	if itemID then
		local texture = GetInventoryItemTexture("player", slot)
		watching[itemID] = {GetTime(), "item", texture}
	end
end)

hooksecurefunc("UseContainerItem", function(bag, slot)
	local itemID = GetContainerItemID(bag, slot)
	if itemID then
		local texture = select(10, GetItemInfo(itemID))
		watching[itemID] = {GetTime(), "item", texture}
	end
end)

SlashCmdList.PulseCD = function()
	tinsert(animating, {GetSpellTexture(87214)})
	if C.PulseCD.Sound == true then
		PlaySoundFile(C.Media.Proc_Sound, "Master")
	end
	frame:SetScript("OnUpdate", OnUpdate)
end
SLASH_PulseCD1 = "/pulsecd"