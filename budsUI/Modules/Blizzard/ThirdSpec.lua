-- budsUI :: Modules/Blizzard/ThirdSpec.lua
-- Third talent set served by the realm (WowCircle ".spec 2 / .spec 3" chat
-- command). The 3.3.5 client only knows two talent groups, so the server swaps
-- the third set into group 2. Group 2's exact rank layout is the only client
-- side witness of which set is mounted, so the machine here turns
-- PLAYER_TALENT_UPDATE into a state transition (pending -> finish, or late).

local K, C = select(2, ...):unpack()
if C.Blizzard.TalentFrame ~= true then return end

local tostring = tostring
local CreateFrame = CreateFrame
local GetNumTalentTabs, GetNumTalents, GetTalentInfo, GetNumTalentGroups, GetTime =
	GetNumTalentTabs, GetNumTalents, GetTalentInfo, GetNumTalentGroups, GetTime
local GetRealmName, UnitName, SendChatMessage, PlaySound, InCombatLockdown =
	GetRealmName, UnitName, SendChatMessage, PlaySound, InCombatLockdown
local tconcat = table.concat

local WAIT_SECONDS = 6
local LATE_SECONDS = 20
local STR_THIRD_COMBAT = "Not available in combat"

local thirdPending, thirdLate

-- Rank signature of the talents mounted in a group: one rank digit per talent,
-- tabs joined with "-". Two different builds never share a signature.
local function ranksSig(group)
	local trees = {}
	for tab = 1, GetNumTalentTabs(false, false) or 0 do
		local digits = {}
		for i = 1, GetNumTalents(tab, false, false) or 0 do
			local name, _, _, _, rank = GetTalentInfo(tab, i, false, false, group or 2)
			if name then
				digits[#digits + 1] = tostring(rank or 0)
			end
		end
		trees[tab] = tconcat(digits)
	end
	return tconcat(trees, "-")
end

-- Per-character storage for the third-spec machine (budsUIData SavedVariables).
local function thirdSpecStore()
	if type(budsUIData) ~= "table" then
		budsUIData = {}
	end
	if type(budsUIData.CharacterData) ~= "table" then
		budsUIData.CharacterData = {}
	end
	local key = (K.Realm or GetRealmName()) .. "-" .. (K.Name or UnitName("player"))
	if type(budsUIData.CharacterData[key]) ~= "table" then
		budsUIData.CharacterData[key] = {}
	end
	if type(budsUIData.CharacterData[key].ThirdSpec) ~= "table" then
		budsUIData.CharacterData[key].ThirdSpec = {}
	end
	return budsUIData.CharacterData[key].ThirdSpec
end

-- First run or the legacy intent-only store: assume the second set is mounted
-- until events prove otherwise, and learn its signature.
local function thirdEnsure()
	if GetNumTalentGroups(false, false) < 2 then
		return false
	end
	local store = thirdSpecStore()
	if type(store.sig) ~= "table" then
		store.sig = {}
	end
	if store.loaded ~= 2 and store.loaded ~= 3 then
		store.loaded = (store.onThird and true or false) and 3 or 2
	end
	if not store.sig[store.loaded] then
		store.sig[store.loaded] = ranksSig(2)
	end
	return true
end

-- Group 2 changed to a build we do not hold: either the other known set got
-- mounted out-of-band or the current build was edited in place.
local function thirdRecognize(cur)
	local store = thirdSpecStore()
	local loaded = store.loaded or 2
	if cur == store.sig[loaded] then
		return
	end
	local other = loaded == 2 and 3 or 2
	if store.sig[other] and cur == store.sig[other] then
		store.loaded = other
	else
		store.sig[loaded] = cur
	end
end

local function thirdFinish(ok, cur)
	local p = thirdPending
	thirdPending = nil
	if not ok then
		thirdLate = { want = p.want, before = p.before, till = GetTime() + LATE_SECONDS }
		return
	end
	local store = thirdSpecStore()
	store.loaded = p.want
	store.sig[p.want] = cur or ranksSig(2)
end

-- Watchdog: the realm acknowledges the command with PLAYER_TALENT_UPDATE. If it
-- never arrives, set the late window so a delayed swap is still recognized.
local thirdClock = CreateFrame("Frame")
thirdClock:Hide()
thirdClock:SetScript("OnUpdate", function(self)
	local p = thirdPending
	if not p then
		self:Hide()
		return
	end
	if GetTime() - p.at > WAIT_SECONDS then
		thirdFinish(p.seen and true or false)
	end
end)

local function thirdOnEvent(event)
	if event == "PLAYER_LEAVING_WORLD" then
		thirdPending, thirdLate = nil, nil
		return
	end
	if not thirdEnsure() then
		return
	end
	if event ~= "PLAYER_TALENT_UPDATE" then
		return
	end
	local store = thirdSpecStore()
	local cur = ranksSig(2)
	if thirdPending then
		if cur ~= thirdPending.before then
			thirdFinish(true, cur)
		else
			thirdPending.seen = true
		end
		return
	end
	if thirdLate then
		if GetTime() > thirdLate.till then
			thirdLate = nil
		elseif cur ~= thirdLate.before and not store.sig[thirdLate.want] and store.loaded ~= thirdLate.want then
			store.loaded = thirdLate.want
			store.sig[thirdLate.want] = cur
			thirdLate = nil
			return
		end
	end
	thirdRecognize(cur)
end

local function activateThirdSpec()
	if not thirdEnsure() then
		return
	end
	if thirdPending then
		return
	end
	if InCombatLockdown() then
		UIErrorsFrame:AddMessage(STR_THIRD_COMBAT, 1, 0.1, 0.1)
		return
	end
	local store = thirdSpecStore()
	local cur = ranksSig(2)
	local loaded = store.loaded or 2
	store.sig[loaded] = cur
	local want = loaded == 3 and 2 or 3
	thirdPending = { want = want, before = cur, seen = false, at = GetTime() }
	SendChatMessage(".spec " .. want, "WHISPER", nil, UnitName("player"))
	PlaySound("igCharacterInfoTab")
	thirdClock:Show()
end

local watch = CreateFrame("Frame")
watch:RegisterEvent("PLAYER_TALENT_UPDATE")
watch:RegisterEvent("PLAYER_LEAVING_WORLD")
watch:SetScript("OnEvent", function(_, event)
	thirdOnEvent(event)
end)

K.ThirdSpec = {
	Click = activateThirdSpec,
	OnEvent = thirdOnEvent,
	Loaded = function()
		if not thirdEnsure() then
			return nil
		end
		local store = thirdSpecStore()
		return store.loaded
	end,
}

-- Test hook: drive the machine from the Lua 5.1 harness under the stub.
if Test then
	Test.BudsThird = {
		Click = activateThirdSpec,
		OnEvent = thirdOnEvent,
		Sig = ranksSig,
		Store = thirdSpecStore,
		Clock = thirdClock,
		Loaded = function()
			local store = thirdSpecStore()
			return store.loaded
		end,
		Pending = function()
			return thirdPending ~= nil
		end,
	}
end
