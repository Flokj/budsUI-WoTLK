local K, C, L, _ = select(2, ...):unpack()
if C.Minimap.CDR ~= true then return end

local function fmttime(sec)
   local d, h, m, s = ChatFrame_TimeBreakDown(math.floor(sec))
   if d > 0 then
      return string.format("%dd %dh %dm", d, h, m)
   elseif h > 0 then
      return string.format("%dh %dm", h, m)
   else
      return string.format("%dm %ds", m, s)
   end
end

TimeManagerClockButton:SetScript("OnEnter", function(self)
   RequestRaidInfo()

   GameTooltip:SetOwner(Minimap, "ANCHOR_BOTTOM", 0, -5)
   GameTooltip:ClearAllPoints()
   GameTooltip:SetPoint("BOTTOM", self, "TOP", 0, 1)
   GameTooltip:ClearLines()

   local hasRaid = false
   for i = 1, GetNumSavedInstances() do
      local name, id, reset, difficulty, locked, extended, _, isRaid, maxPlayers = GetSavedInstanceInfo(i)

      if isRaid and (locked or extended) then
         if not hasRaid then
            GameTooltip:AddLine("Raid Cooldowns:", 1, 0.82, 0)
            hasRaid = true
         end

         local diff = (difficulty == 3 or difficulty == 4) and "|cffff5555Heroic|r" or "|cff888888Normal|r"
         local tr, tg, tb = 1, 1, 1
         if extended then 
            tr, tg, tb = 0.3, 1, 0.3 
         end

         local leftText = string.format("|cffffd200%2d|r | %s (%s) |cff555555#%s|r", maxPlayers, name, diff, id)
         local rightText = fmttime(reset)

         GameTooltip:AddDoubleLine(leftText, rightText, 1, 1, 1, tr, tg, tb)
      end
   end

   if hasRaid then
      GameTooltip:Show()
   end
end)

TimeManagerClockButton:SetScript("OnLeave", function()
   GameTooltip:Hide()
end)