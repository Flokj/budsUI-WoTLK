-- budsUI_Config :: Pages/Movers.lua
-- Management and individual reset of movable frames.
-- Lua 5.1 / WoW 3.3.5a safe.

local _, ns = ...

local function getMoverSchema()
	local K = ns.Engine()
	local schema = {
		{ header = "Mover Controls" },
		{
			description = "Toggle mover mode to drag frames across the screen, display alignment grid, or reset frame positions.",
		},
		{
			label = "Move Mode",
			type = "execute",
			text = "Toggle Move Mode",
			func = function()
				local K = ns.Engine()
				if K and K.ToggleMovers then
					K.ToggleMovers()
				end
			end,
			noReset = true,
		},
		{
			label = "Alignment Grid",
			type = "execute",
			text = "Toggle Grid",
			func = function()
				local K = ns.Engine()
				if K and K.ToggleMoverGrid then
					K.ToggleMoverGrid()
				end
			end,
			noReset = true,
		},
		{
			label = "Reset All Movers",
			type = "execute",
			text = "Reset All Positions",
			confirm = "Reset all frame positions to their defaults?",
			func = function()
				local K = ns.Engine()
				if K and K.ResetMovers then
					K.ResetMovers()
					if ns.RefreshPage then
						ns.RefreshPage()
					end
				end
			end,
			noReset = true,
		},
		{ header = "Individual Frames" },
	}

	if K and K.GetMoverList then
		local list = K.GetMoverList()
		for _, mover in ipairs(list) do
			local moverKey = mover.key
			local moverLabel = mover.label or moverKey
			schema[#schema + 1] = {
				label = moverLabel,
				type = "custom",
				height = 24,
				noReset = true,
				build = function(row)
					local flashBtn = ns.CreateButton(row, "Highlight", 70, true, 18)
					flashBtn:SetPoint("RIGHT", -74, 0)
					flashBtn:SetScript("OnClick", function()
						local K = ns.Engine()
						if K and K.FlashMover then
							K.FlashMover(moverKey)
						end
					end)

					local resetBtn = ns.CreateButton(row, "Reset", 65, true, 18)
					resetBtn:SetPoint("RIGHT", -4, 0)
					resetBtn:SetScript("OnClick", function()
						local K = ns.Engine()
						if K and K.ResetMover then
							K.ResetMover(moverKey)
							PlaySound("igMainMenuOptionCheckBoxOff")
						end
					end)
				end,
			}
		end
	end

	return schema
end

ns.RegisterPage({
	key = "Movers",
	name = "Movers",
	order = 23,
	noReset = true,
	schema = getMoverSchema,
})
