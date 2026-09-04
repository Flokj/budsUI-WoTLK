local K, C, L, _ = select(2, ...):unpack()

if C.PowerBar.Maelstrom ~= true then return end

local MAELSTROM_SPELL_ID = 1153817 -- Ascension
local MAELSTROM_SPELL_WOTLK = 53817 -- WotLK
local IMAGE_PATH = [[Interface\AddOns\]] .. K.Directory .. [[\Media\Maelstrom\maelstrom]]

local killList = {
    [1153817] = true,
    [53817] = true,
    [344179] = true,
    [187881] = true,
    [467442] = true,
    [170586] = true,
    [170587] = true,
    [170588] = true,
    [187890] = true,
    [170585] = true,
}

local MaelstromAnchor = CreateFrame("Frame", "budsUIMaelstromAnchor", UIParent)
local size = C.PowerBar.MaelstromSize or 256
MaelstromAnchor:SetSize(size, size / 2)
MaelstromAnchor:SetPoint("CENTER", UIParent, "CENTER", 0, 180)

local f = CreateFrame("Frame", "budsUIMaelstromFrame", UIParent)
f:SetSize(size, size / 2)
f:SetPoint("CENTER", MaelstromAnchor, "CENTER", 0, 0)
f:SetFrameStrata("HIGH")
f:SetScale(1.0)
f:Hide()

-- Textures
f.textures = {}
for i = 1, 10 do
    f.textures[i] = f:CreateTexture(nil, "OVERLAY")
    f.textures[i]:SetAllPoints(f)
    f.textures[i]:SetTexture(IMAGE_PATH .. i .. ".blp")
    f.textures[i]:Hide()
end

local function ShowOnlyStackTexture(stacks)
    for i = 1, 10 do
        if i == stacks then
            f.textures[i]:Show()
        else
            f.textures[i]:Hide()
        end
    end
end

local lastStacks = 0
local pulseTimer = 0
local popTimer = 0

-- Manual Animation Loop (Mathematically stable, hard-capped at 1.3x)
-- Avoids buggy AnimationGroup scaling in older clients
f:SetScript("OnUpdate", function(self, elapsed)
    local targetScale = 1.0
    
    -- 1. Handle "Pop" effect (stack increase - 0.5s duration)
    if popTimer > 0 then
        popTimer = popTimer - elapsed
        if popTimer > 0.4 then
            -- Initial surge (0.1s fast grow)
            targetScale = 1.0 + (1.15 - 1.0) * ( (0.5 - popTimer) / 0.1 )
        else
            -- Shrink back (0.4s slow smooth return)
            targetScale = 1.15 - (1.15 - 1.0) * ( (0.4 - popTimer) / 0.4 )
        end
    end

    -- 2. Handle "Pulse" effect (at threshold, e.g. 5+ stacks)
    local pulseThreshold = C.PowerBar.MaelstromPulseAt or 5
    if C.PowerBar.MaelstromPulse and lastStacks >= pulseThreshold then
        pulseTimer = pulseTimer + elapsed
        -- Smooth sine wave pulse: 1.0 to 1.25 range
        local pulseScale = 1.0 + (math.sin(pulseTimer * 12) * 0.125 + 0.125)
        
        -- Use the larger of the two scales if popping while pulsing
        if pulseScale > targetScale then
            targetScale = pulseScale
        end
    else
        pulseTimer = 0
    end

    -- Clamp for absolute safety (prevents "giant icon" bugs)
    if targetScale < 1.0 then targetScale = 1.0 end
    if targetScale > 1.3 then targetScale = 1.3 end

    self:SetScale(targetScale)
end)

local function UpdateStacks()
    local stacks = 0
    -- Real-time size sync
    local size = C.PowerBar.MaelstromSize or 256
    MaelstromAnchor:SetSize(size, size / 2)
    f:SetSize(size, size / 2)

    -- WoW 3.3.5 Compatibility: UnitBuff returns only 10 values, not 11 (no spellID)
    -- We need to match by spell name instead of ID
    for i = 1, 40 do
        local name, _, _, count = UnitBuff("player", i)
        if not name then break end
        -- Check if this buff name matches any of our Maelstrom weapon buffs
        -- In 3.3.5 we need to use spell names, not IDs
        if name == "Maelstrom Weapon" or name == GetSpellInfo(53817) then
            stacks = count or 1
            break
        end
    end

    if stacks > 0 then
        if not f:IsShown() then
            f:Show()
            f:SetScale(1.0)
        end
        f:SetAlpha(1.0)
        ShowOnlyStackTexture(stacks)
        
        -- Trigger "Pop" effect on increase
        if stacks > lastStacks then
            popTimer = 0.5 
        end
    else
        f:Hide()
        popTimer = 0
        pulseTimer = 0
    end

    lastStacks = stacks
end

-- Suppress server-side overlays
local function ApplySurgicalFix()
    local frame = _G["SpellActivationOverlayFrame"]
    if not frame then return end

    if not frame.__budsUIMaelstromHooked then
        if frame.ShowOverlay then
            local originalShow = frame.ShowOverlay
            frame.ShowOverlay = function(self, spellID, ...)
                if killList[spellID] then
                    if self.HideOverlays then self:HideOverlays(spellID) end
                    return
                end
                return originalShow(self, spellID, ...)
            end
        end
        frame.__budsUIMaelstromHooked = true
    end

    if frame.HideOverlays then
        for id in pairs(killList) do
            frame:HideOverlays(id)
        end
    end
end

f:RegisterEvent("UNIT_AURA")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_LOGIN")

f:SetScript("OnEvent", function(self, event, arg1)
    ApplySurgicalFix()
    UpdateStacks()
end)

if K.Movers then
    table.insert(K.Movers, MaelstromAnchor)
end
