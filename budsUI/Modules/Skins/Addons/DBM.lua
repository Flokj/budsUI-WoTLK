local K, C, L, _ = select(2, ...):unpack()
if C.Skins.DBM ~= true then return end

local _G = _G
local format = string.format
local find = string.find
local gsub = string.gsub
local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc

local croprwicons = true
local rwiconsize = 18
local BAR_HEIGHT = 23
local BOSS_HEIGHT = 19
local barBackdrop = {
	bgFile = C.Media.Blank,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
}

-- Reparent icon into a backdrop overlay, ElvUI-style.
-- Overlay is square (bar height), icon sits inside with cropped texcoords.
local function CreateIconOverlay(id, parent, size)
	local overlay = CreateFrame("Frame", "$parentIcon" .. id .. "Overlay", parent)
	overlay:SetWidth(size)
	overlay:SetHeight(size)
	if id == 1 then
		overlay:SetPoint("RIGHT", parent, "LEFT", -5 * K.Mult, 0)
	else
		overlay:SetPoint("LEFT", parent, "RIGHT", 5 * K.Mult, 0)
	end
	overlay:CreateBackdrop(2)
	return overlay
end

local function StyleIcon(icon, overlay)
	icon:SetParent(overlay)
	icon:ClearAllPoints()
	icon:SetInside()
	if icon.SetTexCoord then
		icon:SetTexCoord(unpack(K.TexCoords))
	end
end

local function ApplyBarStyle(bar)
	local frame = bar.frame
	if not frame then return end
	local frameName = frame:GetName()
	if not frameName then return end

	local tbar = _G[frameName .. "Bar"]
	local background = _G[frameName .. "BarBackground"]
	local spark = _G[frameName .. "BarSpark"]
	local texture = _G[frameName .. "BarTexture"]
	local icon1 = _G[frameName .. "BarIcon1"]
	local icon2 = _G[frameName .. "BarIcon2"]
	local name = _G[frameName .. "BarName"]
	local timer = _G[frameName .. "BarTimer"]
	if not tbar then return end

	local options = bar.owner and bar.owner.options
	local enlarged = bar.enlarged
	local scale = 1
	local width = 189
	if options then
		if enlarged then
			scale = options.HugeScale or options.Scale or 1
			width = options.HugeWidth or options.Width or width
		else
			scale = options.Scale or 1
			width = options.Width or width
		end
	end
	width = width * scale
	local height = BAR_HEIGHT * scale

	-- Icons (overlay hosts the icon, so Hide on overlay hides both)
	if icon1 then
		if not icon1.overlay then
			icon1.overlay = CreateIconOverlay(1, frame, height)
			StyleIcon(icon1, icon1.overlay)
		else
			icon1.overlay:SetWidth(height)
			icon1.overlay:SetHeight(height)
			if icon1:GetParent() ~= icon1.overlay then
				StyleIcon(icon1, icon1.overlay)
			end
		end
	end
	if icon2 then
		if not icon2.overlay then
			icon2.overlay = CreateIconOverlay(2, frame, height)
			StyleIcon(icon2, icon2.overlay)
		else
			icon2.overlay:SetWidth(height)
			icon2.overlay:SetHeight(height)
			if icon2:GetParent() ~= icon2.overlay then
				StyleIcon(icon2, icon2.overlay)
			end
		end
	end

	-- Frame + statusbar
	frame:SetScale(1)
	frame:SetWidth(width)
	frame:SetHeight(height)
	if not frame.styled then
		frame:CreateBackdrop(2)
		frame.styled = true
	end

	if background and not background.killed then
		background:SetTexture(nil)
		background:Hide()
		background.killed = true
	end

	if spark and not spark.killed then
		spark:SetTexture(nil)
		spark:Hide()
		spark.killed = true
	end

	if texture and not texture.styled then
		texture:SetTexture(C.Media.Texture)
		texture.styled = true
	end

	tbar:ClearAllPoints()
	tbar:SetInside(frame)
	if not tbar.budsBackdrop then
		tbar:SetBackdrop(barBackdrop)
		tbar:SetBackdropColor(unpack(C.Media.Backdrop_Color))
		tbar.budsBackdrop = true
	end

	if name then
		name:ClearAllPoints()
		name:SetPoint("LEFT", frame, "LEFT", 4 * K.Mult, 0)
		if timer then
			name:SetPoint("RIGHT", timer, "LEFT", -2, 0) -- truncation, ElvUI-style
		else
			name:SetWidth(width - 60)
		end
		name:SetHeight(8)
		name:SetJustifyH("LEFT")
		K.SkinFont(name)
	end

	if timer then
		timer:ClearAllPoints()
		timer:SetPoint("RIGHT", frame, "RIGHT", -4 * K.Mult, 0)
		timer:SetJustifyH("RIGHT")
		K.SkinFont(timer)
	end

	-- NOTE: no SetFont = K.Noop lock here on purpose:
	-- the hook re-applies our font after every DBM ApplyStyle,
	-- so user/UploadDBM font options keep working.

	if options then
		if icon1 and icon1.overlay then
			if options.IconLeft then icon1.overlay:Show() else icon1.overlay:Hide() end
		end
		if icon2 and icon2.overlay then
			if options.IconRight then icon2.overlay:Show() else icon2.overlay:Hide() end
		end
	end

	tbar:SetAlpha(1)
	frame:SetAlpha(1)
	if texture then texture:SetAlpha(1) end
	frame:Show()
	bar.injected = true
	if bar.Update then bar:Update(0) end
end

local function SkinBars(self)
	if not self.GetBarIterator then return end
	-- GetBarIterator returns nil while self.bars is not initialized yet
	local iterator, tbl, state = self:GetBarIterator()
	if not iterator then return end
	for bar in iterator, tbl, state do
		if not bar.injected then
			-- Direct override, not hooksecurefunc: old DBM bar objects
			-- don't expose hookable Update/ApplyStyle methods (nil call error).
			bar.ApplyStyle = function()
				ApplyBarStyle(bar)
			end
			bar:ApplyStyle()
		end
	end
end

local function SkinBossTitle()
	if not DBMBossHealthDropdown then return end
	local anchor = DBMBossHealthDropdown:GetParent()
	if not anchor or anchor.styled then return end
	local header = {anchor:GetRegions()}
	if header[1] and header[1].IsObjectType and header[1]:IsObjectType("FontString") then
		K.SkinFont(header[1])
		header[1]:SetTextColor(1, 1, 1, 1)
		anchor.styled = true
	end
end

local function SkinBoss()
	local count = 1
	local bar = _G[format("DBM_BossHealth_Bar_%d", count)]
	while bar do
		local barName = bar:GetName()
		local background = _G[barName .. "BarBorder"]
		local progress = _G[barName .. "Bar"]
		local name = _G[barName .. "BarName"]
		local timer = _G[barName .. "BarTimer"]
		local prev = _G[format("DBM_BossHealth_Bar_%d", count - 1)]
		if not progress then return end

		local growUp = DBM and DBM.Options and DBM.Options.HealthFrameGrowUp
		bar:ClearAllPoints()
		if count == 1 then
			local _, anch = bar:GetPoint()
			if growUp then
				if anch then bar:SetPoint("BOTTOM", anch, "TOP", 0, 8 * K.Mult) end
			else
				if anch then bar:SetPoint("TOP", anch, "BOTTOM", 0, -3 * K.Mult) end
			end
		else
			if prev then
				if growUp then
					bar:SetPoint("BOTTOMLEFT", prev, "TOPLEFT", 0, 4 * K.Mult)
				else
					bar:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -3 * K.Mult)
				end
			end
		end

		if not bar.styled then
			bar:SetScale(1)
			bar:SetHeight(BOSS_HEIGHT)
			bar:CreateBackdrop(2)
			if background and background.SetNormalTexture then
				background:SetNormalTexture(nil)
			end
			bar.styled = true
		end

		progress:SetStatusBarTexture(C.Media.Texture)
		progress:ClearAllPoints()
		progress:SetInside(bar)
		if not progress.budsBackdrop then
			progress:SetBackdrop(barBackdrop)
			progress:SetBackdropColor(unpack(C.Media.Backdrop_Color))
			progress.budsBackdrop = true
		end

		if name then
			name:ClearAllPoints()
			name:SetPoint("LEFT", bar, "LEFT", 4 * K.Mult, 0)
			if timer then
				name:SetPoint("RIGHT", timer, "LEFT", -2, 0)
			end
			name:SetJustifyH("LEFT")
			K.SkinFont(name)
		end

		if timer then
			timer:ClearAllPoints()
			timer:SetPoint("RIGHT", bar, "RIGHT", -4 * K.Mult, 0)
			timer:SetJustifyH("RIGHT")
			K.SkinFont(timer)
		end

		count = count + 1
		bar = _G[format("DBM_BossHealth_Bar_%d", count)]
	end
end

local function CropRaidIcons(textString)
	if type(textString) == "string" and find(textString, " |T") then
		textString = gsub(textString, "(:12:12)", ":" .. rwiconsize .. ":" .. rwiconsize .. ":0:0:64:64:5:59:5:59")
	end
	return textString
end

local function InitCoreSkin()
	if DBT and DBT.CreateBar and not DBT.budsHooked then
		hooksecurefunc(DBT, "CreateBar", SkinBars)
		-- Style bars created before our hook attached.
		-- NOTE: DBT is only the class; live bars live on the DBM.Bars instance.
		if DBM and DBM.Bars and DBM.Bars.GetBarIterator then
			SkinBars(DBM.Bars)
		end
		DBT.budsHooked = true
	end
	if DBM and DBM.BossHealth and not DBM.BossHealth.budsHooked then
		if DBM.BossHealth.Show then
			hooksecurefunc(DBM.BossHealth, "Show", SkinBossTitle)
		end
		if DBM.BossHealth.AddBoss then
			hooksecurefunc(DBM.BossHealth, "AddBoss", SkinBoss)
		end
		if DBM.BossHealth.UpdateSettings then
			hooksecurefunc(DBM.BossHealth, "UpdateSettings", SkinBoss)
		end
		DBM.BossHealth.budsHooked = true
	end

	if croprwicons and RaidNotice_AddMessage and not _G.BudsRWIconHooked then
		local old = RaidNotice_AddMessage
		_G.RaidNotice_AddMessage = function(noticeFrame, textString, colorInfo)
			return old(noticeFrame, CropRaidIcons(textString), colorInfo)
		end
		_G.BudsRWIconHooked = true
	end
end

-- Loader: ADDON_LOADED covers late-loaded DBM, PLAYER_LOGIN covers already-loaded
local Loader = CreateFrame("Frame")
Loader:RegisterEvent("ADDON_LOADED")
Loader:RegisterEvent("PLAYER_LOGIN")
Loader:SetScript("OnEvent", function(_, event, addon)
	if event == "ADDON_LOADED" then
		if addon == "DBM-Core" then
			InitCoreSkin()
		end
	elseif event == "PLAYER_LOGIN" then
		if IsAddOnLoaded("DBM-Core") then
			InitCoreSkin()
		end
	end
end)

-- DBM settings(by ALZA and help from Affli)
function K.UploadDBM()
	if IsAddOnLoaded("DBM-Core") then
		DBM_UseDualProfile = false

		if DBM_SavedOptions then
			DBM_SavedOptions.enabled = true
			DBM_SavedOptions.ShowMinimapButton = C.Skins.MinimapButtons and true or false
			DBM_SavedOptions.WarningIconLeft = false
			DBM_SavedOptions.WarningIconRight = false
			DBM_SavedOptions.WarningColors = {
				{["b"] = K.Color.b, ["g"] = K.Color.g, ["r"] = K.Color.r,},
				{["b"] = K.Color.b, ["g"] = K.Color.g, ["r"] = K.Color.r,},
				{["b"] = K.Color.b, ["g"] = K.Color.g, ["r"] = K.Color.r,},
				{["b"] = K.Color.b, ["g"] = K.Color.g, ["r"] = K.Color.r,},
			}
			DBM_SavedOptions.HealthFrameGrowUp = false
			DBM_SavedOptions.HealthFrameWidth = 218
			DBM_SavedOptions.HPFrameX = 100
			DBM_SavedOptions.HPFramePoint = "LEFT"
			DBM_SavedOptions.RangeFrameX = 244
			DBM_SavedOptions.RangeFramePoint = "LEFT"
			DBM_SavedOptions.ShowSpecialWarnings = true
			DBM_SavedOptions.SpecialWarningFont = C.Media.Font
			DBM_SavedOptions.SpecialWarningFontSize = 50
			DBM_SavedOptions.SpecialWarningX = 0
			DBM_SavedOptions.SpecialWarningY = 75
		end

		if DBT_SavedOptions and DBT_SavedOptions["DBM"] then
			DBT_SavedOptions["DBM"].StartColorR = K.Color.r
			DBT_SavedOptions["DBM"].StartColorG = K.Color.g
			DBT_SavedOptions["DBM"].StartColorB = K.Color.b
			DBT_SavedOptions["DBM"].EndColorR = K.Color.r
			DBT_SavedOptions["DBM"].EndColorG = K.Color.g
			DBT_SavedOptions["DBM"].EndColorB = K.Color.b
			DBT_SavedOptions["DBM"].Scale = 1
			DBT_SavedOptions["DBM"].HugeScale = 1
			DBT_SavedOptions["DBM"].BarXOffset = 0
			DBT_SavedOptions["DBM"].BarYOffset = 10
			DBT_SavedOptions["DBM"].Font = C.Media.Font
			DBT_SavedOptions["DBM"].FontSize = C.Media.Font_Size
			DBT_SavedOptions["DBM"].Width = 189
			DBT_SavedOptions["DBM"].TimerX = -468.500244140625
			DBT_SavedOptions["DBM"].TimerPoint = "CENTER"
			DBT_SavedOptions["DBM"].FillUpBars = true
			DBT_SavedOptions["DBM"].IconLeft = true
			DBT_SavedOptions["DBM"].ExpandUpwards = true
			DBT_SavedOptions["DBM"].Texture = C.Media.Texture
			DBT_SavedOptions["DBM"].IconRight = false
			DBT_SavedOptions["DBM"].HugeBarXOffset = 0
			DBT_SavedOptions["DBM"].HugeBarsEnabled = false
			DBT_SavedOptions["DBM"].HugeWidth = 189
			DBT_SavedOptions["DBM"].HugeTimerX = 6
			DBT_SavedOptions["DBM"].HugeTimerPoint = "CENTER"
			DBT_SavedOptions["DBM"].HugeBarYOffset = 10
		end

		if C.ActionBar.BottomBars == 1 then
			if DBM_SavedOptions then
				DBM_SavedOptions.HPFrameY = 126
				DBM_SavedOptions.RangeFrameY = 101
			end
			if DBT_SavedOptions and DBT_SavedOptions["DBM"] then
				DBT_SavedOptions["DBM"].TimerY = 139
				DBT_SavedOptions["DBM"].HugeTimerY = -136
			end
		elseif C.ActionBar.BottomBars == 2 then
			if DBM_SavedOptions then
				DBM_SavedOptions.HPFrameY = 154
				DBM_SavedOptions.RangeFrameY = 129
			end
			if DBT_SavedOptions and DBT_SavedOptions["DBM"] then
				DBT_SavedOptions["DBM"].TimerY = 167
				DBT_SavedOptions["DBM"].HugeTimerY = -108
			end
		elseif C.ActionBar.BottomBars == 3 then
			if DBM_SavedOptions then
				DBM_SavedOptions.HPFrameY = 182
				DBM_SavedOptions.RangeFrameY = 157
			end
			if DBT_SavedOptions and DBT_SavedOptions["DBM"] then
				DBT_SavedOptions["DBM"].TimerY = 195
				DBT_SavedOptions["DBM"].HugeTimerY = -80
			end
		end

		if DBM_SavedOptions then
			DBM_SavedOptions.InstalledBars = C.ActionBar.BottomBars
		end
	end
end

StaticPopupDialogs.SETTINGS_DBM = {
	text = L_POPUP_SETTINGS_DBM,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function() K.UploadDBM() ReloadUI() end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = true,
	preferredIndex = 3,
}

-- On logon function
local OnLogon = CreateFrame("Frame")
OnLogon:RegisterEvent("PLAYER_ENTERING_WORLD")
OnLogon:SetScript("OnEvent", function(self, event)
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")

	if IsAddOnLoaded("DBM-Core") then
		if DBM_SavedOptions and DBM_SavedOptions.InstalledBars ~= C.ActionBar.BottomBars then
			StaticPopup_Show("SETTINGS_DBM")
		end
	end
end)
