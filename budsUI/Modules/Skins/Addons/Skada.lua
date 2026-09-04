local K, C, L, _ = select(2, ...):unpack()
if C.Skins.Skada ~= true then return end

local function LoadSkadaSkin()
	if not IsAddOnLoaded("Skada") then return end

	local Skada = Skada
	if not Skada then return end

	local barSpacing = 1
	local barmod = Skada.displays["bar"]

	local function StripOptions(options)
		if options.baroptions then
			options.baroptions.args.barspacing = nil
			options.baroptions.args.barfont = nil
		end
		if options.titleoptions then
			options.titleoptions.args.texture = nil
			options.titleoptions.args.bordertexture = nil
			options.titleoptions.args.thickness = nil
			options.titleoptions.args.margin = nil
			options.titleoptions.args.color = nil
			options.titleoptions.args.font = nil
		end
	end

	barmod.AddDisplayOptions_ = barmod.AddDisplayOptions
	barmod.AddDisplayOptions = function(self, win, options)
		self:AddDisplayOptions_(win, options)
		StripOptions(options)
	end

	for _, options in pairs(Skada.options.args.windows.args) do
		if options.type == "group" then
			StripOptions(options.args)
		end
	end

	barmod.ApplySettings_ = barmod.ApplySettings
	barmod.ApplySettings = function(self, win)
		barmod.ApplySettings_(self, win)
		local window = win.bargroup
		if win.db.enabletitle then
			window.button:SetBackdrop(nil)
		end
		window:SetSpacing(barSpacing)
		window:SetFrameLevel(5)
		window.SetFrameLevel = K.Noop
		window:SetBackdrop(nil)
		window.borderFrame:StripTextures()

		if not window.bg then
			window.bg = CreateFrame("Frame", nil, window)
			window.bg:SetFrameLevel(1)
			
			if window.bg.CreateBackdrop then
				window.bg:CreateBackdrop()
			else
				window.bg:SetBackdrop({
					bgFile = (C.Media and C.Media.Blank) or "Interface\\Buttons\\WHITE8X8",
					edgeFile = (C.Media and C.Media.Glow) or "Interface\\Buttons\\WHITE8X8",
					tile = false, tileSize = 0, edgeSize = 1,
					insets = { left = 0, right = 0, top = 0, bottom = 0 }
				})
			end
		end

		if C.Media and C.Media.Backdrop_Color then
			window.bg:SetBackdropColor(unpack(C.Media.Backdrop_Color))
		else
			window.bg:SetBackdropColor(0.06, 0.06, 0.06, 0.9)
		end

		if C.Media and C.Media.Border_Color then
			window.bg:SetBackdropBorderColor(unpack(C.Media.Border_Color))
		end

		window.bg:ClearAllPoints()
		if win.db.enabletitle then
			window.bg:SetPoint("TOPLEFT", window.button, "TOPLEFT", -2, 2)
		else
			window.bg:SetPoint("TOPLEFT", window, "TOPLEFT", -2, 2)
		end
		window.bg:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", 2, -2)

		window.button:SetBackdropColor(1, 1, 1, 0)
		window.button:SetFrameStrata("MEDIUM")
		window.button:SetFrameLevel(10)
		window:SetFrameStrata("MEDIUM")

		if win.db.enabletitle and window.button then
			local children = { window.button:GetChildren() }
			for i = 1, #children do
				children[i]:SetFrameLevel(12)
			end
		end
	end

	local function EmbedWindow(window, width, barheight, height, ofsx, ofsy)
		window.db.barwidth = width
		window.db.barheight = barheight
		if window.db.enabletitle then
			height = height - barheight
		end
		window.db.background.height = height
		window.db.spark = false
		window.db.barslocked = true
		window.bargroup:ClearAllPoints()
		window.bargroup:SetPoint("TOPLEFT", UIParent, "TOPLEFT", ofsx, ofsy)
		barmod.ApplySettings(barmod, window)
	end

	local windows = {}
	local function EmbedSkada()
		if #windows == 1 then
			EmbedWindow(windows[1], 320, 18, 190, 20, -300)
		elseif #windows == 2 then
			EmbedWindow(windows[1], 320, 18, 190, 20, -300)
			EmbedWindow(windows[2], 260, 18, 150, 350, -300)
		end
	end

	for _, window in ipairs(Skada:GetWindows()) do
		window:UpdateDisplay()
	end

	if not Skada.CreateWindow_ then
		Skada.CreateWindow_ = Skada.CreateWindow
		function Skada:CreateWindow(name, db)
			Skada:CreateWindow_(name, db)
			wipe(windows)
			for _, window in ipairs(Skada:GetWindows()) do
				tinsert(windows, window)
			end
		end
	end

	if not Skada.DeleteWindow_ then
		Skada.DeleteWindow_ = Skada.DeleteWindow
		function Skada:DeleteWindow(name)
			Skada:DeleteWindow_(name)
			wipe(windows)
			for _, window in ipairs(Skada:GetWindows()) do
				tinsert(windows, window)
			end
		end
	end

	EmbedSkada()

	-- default config
	Skada.windowdefaults.bartexture = "Serenity"
	Skada.windowdefaults.classicons = false
	Skada.windowdefaults.title.fontsize = 12
	Skada.windowdefaults.title.color = {r=0, g=0, b=0, a=.3}
	Skada.windowdefaults.barfontsize = 12
	Skada.windowdefaults.barbgcolor = {r=0, g=0, b=0, a=0}

	if Skada.options.args.generaloptions.args.numberformat then
		Skada.options.args.generaloptions.args.numberformat = nil
	end

	function Skada:FormatNumber(number)
		if number then return K.ShortValue(number) end
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", LoadSkadaSkin)