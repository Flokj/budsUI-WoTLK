local K, C, L, _ = select(2, ...):unpack()
if IsAddOnLoaded("Stuf") or IsAddOnLoaded("PitBull4") or IsAddOnLoaded("ShadowedUnitFrames") or IsAddOnLoaded("XPerl") then return end


if C.Unitframe.ClassHealth == false and C.Unitframe.PercentHealth == true then
	local function updateHealthColor(self, value, smooth)
		if not value then return end
		local r, g, b
		local vMin, vMax = self:GetMinMaxValues()
		if not vMin or not vMax then return end

		if value < vMin or value > vMax then return end

		if (vMax - vMin) > 0 then
			value = (value - vMin)/(vMax - vMin)
		else
			value = 0
		end
		if value > .5 then
			r = (1 - value)*2
			g = 1
		else
			r = 1
			g = value * 2
		end
		b = 0
		self:SetStatusBarColor(r, g, b)
	end
	
	-- OnUpdate delay to prevent taint during Blizzard's frame update chain
	local colorQueue = {}
	local colorFrame = CreateFrame("Frame")
	colorFrame.elapsed = 0
	colorFrame:SetScript("OnUpdate", function(self, elapsed)
		self.elapsed = self.elapsed + elapsed
		if self.elapsed > 0.05 then
			for statusBar, _ in pairs(colorQueue) do
				local value = statusBar:GetValue()
				updateHealthColor(statusBar, value)
				colorQueue[statusBar] = nil
			end
			self.elapsed = 0
		end
	end)
	
	-- TAINT FIX: Use event listeners instead of hooking protected health bar update functions
	-- Hooks on HealthBar_OnValueChanged / UnitFrameHealthBar_Update injected addon code
	-- into Blizzard's secure health bar update chain, causing guaranteed taint in combat.
	local unitToFrame = {
		["player"] = PlayerFrameHealthBar,
		["target"] = TargetFrameHealthBar,
		["focus"]  = FocusFrameHealthBar,
	}

	local healthColorWatcher = CreateFrame("Frame")
	healthColorWatcher:RegisterEvent("UNIT_HEALTH")
	healthColorWatcher:RegisterEvent("UNIT_MAXHEALTH")
	healthColorWatcher:RegisterEvent("PLAYER_TARGET_CHANGED")
	healthColorWatcher:RegisterEvent("PLAYER_FOCUS_CHANGED")
	healthColorWatcher:SetScript("OnEvent", function(self, event, unit)
		if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
			local bar = unitToFrame[unit]
			if bar then
				colorQueue[bar] = true
			end
		elseif event == "PLAYER_TARGET_CHANGED" then
			local bar = unitToFrame["target"]
			if bar then
				colorQueue[bar] = true
			end
		elseif event == "PLAYER_FOCUS_CHANGED" then
			local bar = unitToFrame["focus"]
			if bar then
				colorQueue[bar] = true
			end
		end
	end)
end