-- budsUI_Config :: Pages/Profiles.lua
-- Profile management: switch / create / rename / save / delete / export / import.

local _, ns = ...

local function profileValues()
	local K = ns.Engine()
	local list = {}
	if _G["budsUIData"] and _G["budsUIData"].Profiles then
		for name in pairs(_G["budsUIData"].Profiles) do
			list[#list + 1] = { name, name }
		end
		table.sort(list, function(a, b)
			return a[1] < b[1]
		end)
	end
	return list
end

local function activeProfile()
	local K = ns.Engine()
	if K and K.GetActiveProfile then
		return K.GetActiveProfile()
	end
	return "Unknown"
end

ns.RegisterPage({
	key = "Profiles",
	name = L_GUI_PROFILES or "Profiles",
	order = 2,
	noReset = true,
	schema = {
		{ header = L_GUI_PROFILES or "Profiles" },
		{
			description = "Profiles store every budsUI setting. " ..
				"Switching, importing or deleting a profile reloads the UI.",
		},
		{
			label = L_GUI_PROFILES_ACTIVE or "Active Profile:",
			type = "select",
			width = 220,
			values = profileValues,
			get = activeProfile,
			set = function(name)
				local K = ns.Engine()
				if K and K.SetProfile and K.SetProfile(name) then
					ReloadUI()
				end
			end,
			noReset = true,
		},
		{
			label = L_GUI_PROFILES_CREATE or "Create New Profile",
			type = "input",
			width = 220,
			text = L_GUI_PROFILES_CREATE or "Create",
			noReset = true,
			validate = function(text)
				if not text or text == "" then
					return false, "Enter a profile name."
				end
				if _G["budsUIData"] and _G["budsUIData"].Profiles
						and _G["budsUIData"].Profiles[text] then
					return false, "A profile with this name already exists."
				end
				return true
			end,
			func = function(text)
				local K = ns.Engine()
				if K and K.CreateProfile and K.CreateProfile(text, activeProfile()) then
					K.SetProfile(text)
					ns.Print("|cff388bdb" .. text .. "|r created.")
					ReloadUI()
				end
			end,
		},
		{
			label = "Rename active profile",
			type = "input",
			width = 220,
			text = "Rename",
			noReset = true,
			validate = function(text)
				if not text or text == "" or text == activeProfile() then
					return false, "Enter a different name."
				end
				if _G["budsUIData"] and _G["budsUIData"].Profiles
						and _G["budsUIData"].Profiles[text] then
					return false, "A profile with this name already exists."
				end
				return true
			end,
			func = function(text)
				local K = ns.Engine()
				if K and K.RenameProfile and K.RenameProfile(activeProfile(), text) then
					ns.Print("Profile renamed to |cff388bdb" .. text .. "|r. Reloading...")
					ReloadUI()
				end
			end,
		},
		{
			label = "Save profile",
			type = "execute",
			text = "Save Profile",
			width = 220,
			noReset = true,
			desc = "Write all current live settings into the active profile.",
			func = function()
				local K = ns.Engine()
				if K and K.SaveProfile and K.SaveProfile() then
					ns.Print("|cff388bdb" .. activeProfile() .. "|r saved.")
				end
			end,
		},
		{
			label = L_GUI_PROFILES_DELETE or "Delete Profile",
			type = "execute",
			text = "Delete Profile",
			width = 220,
			noReset = true,
			confirm = function()
				return "Delete profile |cff388bdb" .. activeProfile()
					.. "|r? This cannot be undone."
			end,
			func = function()
				local count = 0
				if _G["budsUIData"] and _G["budsUIData"].Profiles then
					for _ in pairs(_G["budsUIData"].Profiles) do
						count = count + 1
					end
				end
				if count <= 1 then
					ns.Print("|cffff0000Cannot delete the last profile.|r")
					return
				end
				local K = ns.Engine()
				if K and K.DeleteProfile then
					local dead = activeProfile()
					K.DeleteProfile(dead)
					if _G["budsUIData"] and _G["budsUIData"].Profiles then
						for name in pairs(_G["budsUIData"].Profiles) do
							K.SetProfile(name)
							break
						end
					end
					ReloadUI()
				end
			end,
		},
		{ header = "Import / Export" },
		{
			label = "Export active profile",
			type = "execute",
			text = "Export",
			width = 220,
			noReset = true,
			desc = "Show the profile as copyable text (Ctrl+C).",
			func = function()
				local K = ns.Engine()
				if K and K.ExportProfile then
					local data = K.ExportProfile(activeProfile())
					if data then
						ns.ShowExport(data)
					end
				end
			end,
		},
		{
			label = "Import profile text",
			type = "custom",
			noReset = true,
			build = function(row)
				local box = CreateFrame("EditBox", nil, row)
				box:SetAutoFocus(false)
				box:SetMultiLine(true)
				box:SetFontObject(GameFontHighlightSmall)
				box:SetWidth(430)
				box:SetHeight(70)
				box:SetMaxLetters(0)
				box:SetTextInsets(5, 5, 5, 5)
				local K, C = ns.Engine()
				if K and K.Backdrop then
					box:SetBackdrop(K.Backdrop)
					box:SetBackdropColor(0, 0, 0, 0.5)
					if C and C.Media and C.Media.Border_Color then
						box:SetBackdropBorderColor(unpack(C.Media.Border_Color))
					end
				end
				box:SetPoint("LEFT", ns.CONTROL_X + 6, 0)
				box:SetScript("OnEscapePressed", function(self)
					self:ClearFocus()
				end)
				ns.BindRow(box, row)
				row.ioBox = box

				local import = ns.CreateButton(row, "Import", 100)
				import:SetPoint("LEFT", box, "RIGHT", 8, 0)
				ns.BindRow(import, row)
				import:SetScript("OnClick", function()
					local K2 = ns.Engine()
					local data = box:GetText()
					if not K2 or not data or data == "" then
						return
					end
					local name = activeProfile() .. " (Import)"
					local n = 2
					while _G["budsUIData"].Profiles[name] do
						name = activeProfile() .. " (Import " .. n .. ")"
						n = n + 1
					end
					if K2.ImportProfile and K2.ImportProfile(name, data) then
						K2.SetProfile(name)
						ns.Print("|cff388bdb" .. name .. "|r imported. Reloading...")
						ReloadUI()
					else
						ns.Print("|cffff0000Import failed.|r Invalid data.")
					end
				end)
				row:SetHeight(76)
			end,
			refresh = function(row)
			end,
			setEnabled = function(row, enabled)
				if row.ioBox then
					ns.SetEditBoxEnabled(row.ioBox, enabled)
				end
			end,
		},
	},
})
