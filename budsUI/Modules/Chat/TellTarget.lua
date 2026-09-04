local K, C, L, _ = select(2, ...):unpack()
if C.Chat.Enable ~= true then return end

local _G = _G
local len = string.len
local sub = string.sub
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS
local SendChatMessage = SendChatMessage
local GetUnitName = GetUnitName

-- Tell Target
for i = 1, NUM_CHAT_WINDOWS do
	local editbox = _G["ChatFrame"..i.."EditBox"]
	editbox:HookScript("OnTextChanged", function(self)
		local text = self:GetText()
		-- T26: Use localized len/sub upvalues for consistency (avoid method call overhead)
		if len(text) < 7 then
			if sub(text, 1, 4) == "/tt " or sub(text, 1, 6) == "/ее " then
				if UnitCanCooperate("player", "target") then
					ChatFrame_SendTell((GetUnitName("target", true)), ChatFrame1)
				end
			end
		end
	end)
end

-- Slash command
-- T25: Fixed SendChatMessage call to include target name argument (was missing, causing silent failure)
SLASH_TELLTARGET1 = "/tt"
SlashCmdList.TELLTARGET = function(msg)
	local target = GetUnitName("target", true)
	if target then
		SendChatMessage(msg, "WHISPER", nil, target)
	else
		K.Print("No target selected.")
	end
end