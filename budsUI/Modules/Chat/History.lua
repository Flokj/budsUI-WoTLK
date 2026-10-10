local K, C, L, _ = select(2, ...):unpack()
if C.Chat.Enable ~= true then return end

--[[ budsUI Chat History (ported from FrostAtom History.lua)
	- Keeps chat window content across /reload: the last N lines per frame are
	  re-added on login with a dimmed "messages before the reload" separator.
	- Persists the edit-box COMMAND history (Up/Down recall) across /reload.
	- No copy-chat dialog here: budsUI already ships CopyChat.lua (/copychat).

	Storage shape (per character, created on demand):
		budsUIData.CharacterData["Realm-Name"].ChatHistory = {
			lines    = { ["ChatFrame1"] = { { text, r, g, b }, ... }, ... },
			commands = { mostRecent, ..., oldest },
		}

	Load-order note: this file is listed BEFORE ChatFrames.lua in budsUI.xml,
	so our AddMessage wrappers capture the ORIGINAL Blizzard AddMessage and
	ChatFrames.lua then wraps OUR wrapper with its formatting layer:
		live message:  ChatFrames.Format -> capture -> Blizzard original
		restored line: Blizzard original (raw path, no double timestamps)
	Restored lines are still run through the same raw path with dimmed colors
	(FrostAtom RESTORED_DIM), while the undimmed text is kept in memory so a
	follow-up /reload saves the true colors again.
]]

local _G = _G
local type, pairs, ipairs = type, pairs, ipairs
local tinsert, tremove = table.insert, table.remove
local find = string.find
local max, min = math.max, math.min
local hooksecurefunc = hooksecurefunc
local CreateFrame = CreateFrame

local RESTORED_DIM = 0.6
local SEPARATOR_R, SEPARATOR_G, SEPARATOR_B = 0.5, 0.5, 0.5
local SEPARATOR_TEXT = L_CHAT_HISTORY_SEPARATOR or "— messages before the reload —"
local PRINT_NEEDLE = "budsUI|r:" -- matches K.Print("|cff388bdbbudsUI|r:", ...) output

local function SavedHistoryLines()
	local n = C.Chat.SavedHistoryLines
	if type(n) ~= "number" then return 100 end
	return n
end

local function SavedCommands()
	local n = C.Chat.SavedCommands
	if type(n) ~= "number" then return 50 end
	return n
end

local function isOwnPrint(text)
	return type(text) == "string" and find(text, PRINT_NEEDLE, 1, true) ~= nil
end

-- origs[frame] = Blizzard-original AddMessage (see load-order note above).
local origs = {}
-- buffers[name] = array of { text, r, g, b } (undimmed), oldest -> newest.
local buffers = {}
-- commandHistory[1] = most recently typed command.
local commandHistory = {}
local isRestoring = false

local function HistoryFrames()
	local frames = {}
	if type(NUM_CHAT_WINDOWS) ~= "number" then return frames end
	for i = 1, NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame" .. i]
		if frame and frame ~= ChatFrame2 and frame:GetID() ~= 2 then
			frames[#frames + 1] = frame
		end
	end
	return frames
end

local function PushLine(name, text, r, g, b)
	local limit = SavedHistoryLines()
	if limit <= 0 then return end
	local buf = buffers[name]
	if type(buf) ~= "table" then
		buf = {}
		buffers[name] = buf
	end
	buf[#buf + 1] = { text, r, g, b }
	while #buf > limit do
		tremove(buf, 1)
	end
end

local function HookFrame(frame)
	if not frame or origs[frame] then return end
	if frame == ChatFrame2 then return end
	if frame.GetID and frame:GetID() == 2 then return end
	local name = frame.GetName and frame:GetName()
	if type(name) ~= "string" then return end
	local orig = frame.AddMessage
	if type(orig) ~= "function" then return end
	origs[frame] = orig
	if type(buffers[name]) ~= "table" then
		buffers[name] = {}
	end
	frame.AddMessage = function(self, text, r, g, b, ...)
		if type(text) == "string" and not isRestoring and not isOwnPrint(text) then
			PushLine(name, text, r, g, b)
		end
		return orig(self, text, r, g, b, ...)
	end
end

-- Per-character storage slot, created on the fly.
local function GetCharData()
	if type(budsUIData) ~= "table" then return nil end
	if type(budsUIData.CharacterData) ~= "table" then
		budsUIData.CharacterData = {}
	end
	local key = K.Realm .. "-" .. K.Name
	if type(budsUIData.CharacterData[key]) ~= "table" then
		budsUIData.CharacterData[key] = {}
	end
	return budsUIData.CharacterData[key]
end

local function GetHistorySlot(create)
	local charData = GetCharData()
	if not charData then return nil end
	if type(charData.ChatHistory) ~= "table" then
		if not create then return nil end
		charData.ChatHistory = {}
	end
	local slot = charData.ChatHistory
	if create then
		if type(slot.lines) ~= "table" then slot.lines = {} end
		if type(slot.commands) ~= "table" then slot.commands = {} end
	end
	return slot
end

local function SaveHistory()
	local slot = GetHistorySlot(true)
	if not slot then return end
	local limit = SavedHistoryLines()
	local savedLines = {}
	if limit > 0 then
		for name, buf in pairs(buffers) do
			if type(buf) == "table" and #buf > 0 then
				local out = {}
				local start = max(1, #buf - limit + 1)
				for i = start, #buf do
					local line = buf[i]
					if type(line) == "table" and type(line[1]) == "string" and not isOwnPrint(line[1]) then
						out[#out + 1] = { line[1], line[2], line[3], line[4] }
					end
				end
				if #out > 0 then
					savedLines[name] = out
				end
			end
		end
	end
	slot.lines = savedLines
	local cmdLimit = SavedCommands()
	local savedCmds = {}
	if cmdLimit > 0 then
		for i = 1, min(#commandHistory, cmdLimit) do
			if type(commandHistory[i]) == "string" then
				savedCmds[#savedCmds + 1] = commandHistory[i]
			end
		end
	end
	slot.commands = savedCmds
end

local function RestoreFrame(frame, saved)
	local name = frame.GetName and frame:GetName()
	local orig = origs[frame]
	if type(name) ~= "string" or type(orig) ~= "function" then return end
	if type(saved) ~= "table" or #saved == 0 then return end
	if SavedHistoryLines() <= 0 then return end
	isRestoring = true
	-- Guard against double timestamps if this file ever loads AFTER the
	-- ChatFrames.lua formatting hook (then orig would be the formatter).
	local savedFmt = C.Chat.TimestampFormat
	C.Chat.TimestampFormat = 1
	local restored = false
	for i = 1, #saved do
		local line = saved[i]
		if type(line) == "table" and type(line[1]) == "string" and not isOwnPrint(line[1]) then
			local r, g, b = line[2], line[3], line[4]
			PushLine(name, line[1], r, g, b)
			if type(r) == "number" and type(g) == "number" and type(b) == "number" then
				orig(frame, line[1], r * RESTORED_DIM, g * RESTORED_DIM, b * RESTORED_DIM)
			else
				orig(frame, line[1], r, g, b)
			end
			restored = true
		end
	end
	if restored then
		orig(frame, SEPARATOR_TEXT, SEPARATOR_R, SEPARATOR_G, SEPARATOR_B)
	end
	C.Chat.TimestampFormat = savedFmt
	isRestoring = false
end

local function tDeleteItem(tbl, item)
	for i = #tbl, 1, -1 do
		if tbl[i] == item then
			tremove(tbl, i)
		end
	end
end

-- Rebuilds the full slash text (e.g. "/w Target msg", "/2 msg") from the
-- edit-box attributes, mirroring FrostAtom editBoxCommand().
local function EditBoxCommand(editBox)
	local text = editBox.GetText and editBox:GetText()
	if type(text) ~= "string" or text == "" then return nil end
	local chatType = editBox.GetAttribute and editBox:GetAttribute("chatType")
	local header = (type(chatType) == "string" and _G["SLASH_" .. chatType .. "1"]) or ""
	if chatType == "WHISPER" then
		header = header .. " " .. (editBox:GetAttribute("tellTarget") or "")
	elseif chatType == "CHANNEL" then
		header = "/" .. (editBox:GetAttribute("channelTarget") or "")
	end
	if header == "" then return text end
	return header .. " " .. text
end

local function OnHistoryLine(editBox)
	if isRestoring then return end
	if SavedCommands() <= 0 then return end
	local command = EditBoxCommand(editBox)
	if not command then return end
	tDeleteItem(commandHistory, command)
	tinsert(commandHistory, 1, command)
	local limit = SavedCommands()
	while #commandHistory > limit do
		tremove(commandHistory)
	end
end

local function RestoreHistory()
	local slot = GetHistorySlot(false)
	if type(slot) ~= "table" then return end
	if type(slot.lines) == "table" then
		for _, frame in ipairs(HistoryFrames()) do
			local lines = slot.lines[frame:GetName()]
			if type(lines) == "table" then
				RestoreFrame(frame, lines)
			end
		end
	end
	if type(slot.commands) == "table" and SavedCommands() > 0 then
		for i = 1, #slot.commands do
			if type(slot.commands[i]) == "string" and slot.commands[i] ~= "" then
				commandHistory[#commandHistory + 1] = slot.commands[i]
			end
		end
		local limit = SavedCommands()
		while #commandHistory > limit do
			tremove(commandHistory)
		end
		local editBox = ChatFrame1EditBox
		if editBox and type(editBox.AddHistoryLine) == "function" then
			isRestoring = true
			for i = #commandHistory, 1, -1 do
				pcall(editBox.AddHistoryLine, editBox, commandHistory[i])
			end
			isRestoring = false
		end
	end
end

-- Hook persistent frames at load (before ChatFrames.lua wraps AddMessage).
for _, frame in ipairs(HistoryFrames()) do
	HookFrame(frame)
end

-- Hook temporary chat windows the same way ChatFrames.lua skins them.
if type(FCF_OpenTemporaryWindow) == "function" then
	hooksecurefunc("FCF_OpenTemporaryWindow", function()
		local frame = FCF_GetCurrentChatFrame and FCF_GetCurrentChatFrame()
		if frame then
			HookFrame(frame)
		end
	end)
end

-- Persistent edit-box command history.
if ChatFrame1EditBox and type(ChatFrame1EditBox.AddHistoryLine) == "function" then
	hooksecurefunc(ChatFrame1EditBox, "AddHistoryLine", OnHistoryLine)
end

local HistoryEvents = CreateFrame("Frame")
HistoryEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
HistoryEvents:RegisterEvent("PLAYER_LOGOUT")
HistoryEvents:RegisterEvent("PLAYER_LEAVING_WORLD")
HistoryEvents:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		RestoreHistory()
	else
		SaveHistory()
	end
end)
