local K, C, L, _ = select(2, ...):unpack()

-- WorldChildren: WorldFrame child scanner (ported 1:1 from FrostAtomUI Core/WorldChildren.lua)
-- 3.3.5: nameplates and chat bubbles are unnamed WorldFrame children; no event
-- announces them, so WorldFrame children are polled. Only the first region
-- tells them apart.

local WorldChildren = {}
K.WorldChildren = WorldChildren

local function SafeCall(func, ...)
	local ok, err = pcall(func, ...)
	if not ok and C.General and C.General.DeveloperMode then
		K.Print("WorldChildren handler error: " .. tostring(err))
	end
	return ok
end

-- FrostAtomUI exact-case texture map. 3.3.5 GetTexture() returns this exact case.
local KIND_BY_TEXTURE = {
	["Interface\\TargetingFrame\\UI-TargetingFrame-Flash"] = "NamePlate",
	["Interface\\Tooltips\\ChatBubble-Background"] = "ChatBubble",
}

-- Lowercase fallback: this very addon historically matched via strlower because
-- WoW can return texture paths lowercased. Keep as fallback so a case change
-- can never silently break bubble detection again.
local KIND_BY_TEXTURE_LOWER = {
	["interface\\targetingframe\\ui-targetingframe-flash"] = "NamePlate",
	["interface\\tooltips\\chatbubble-background"] = "ChatBubble",
	["interface\\tooltips\\chatbubble-backdrop"] = "ChatBubble",
}

local seen = {}
local frames = {}
local handlers = {}
local known = 0

local function identify(frame)
	if frame:GetName() or not frame.GetRegions then
		return
	end
	local region = frame:GetRegions()
	if not (region and region.GetTexture) then
		return
	end
	local ok, texture = pcall(region.GetTexture, region)
	if not ok or type(texture) ~= "string" then
		return
	end
	-- 1. Exact match first (FrostAtomUI parity).
	local kind = KIND_BY_TEXTURE[texture]
	if kind then
		return kind
	end
	-- 2. Lowercase fallback (original budsUI behavior).
	return KIND_BY_TEXTURE_LOWER[string.lower(texture)]
end

local function add(frame)
	if seen[frame] then
		return
	end
	seen[frame] = true
	local kind = identify(frame)
	if not kind then
		return
	end
	local list = frames[kind]
	if not list then
		list = {}
		frames[kind] = list
	end
	list[#list + 1] = frame
	local callbacks = handlers[kind]
	if callbacks then
		for i = 1, #callbacks do
			SafeCall(callbacks[i], frame)
		end
	end
end

local function addAll(frame, ...)
	if not frame then
		return
	end
	add(frame)
	return addAll(...)
end

local function scanNewChildren()
	local count = WorldFrame:GetNumChildren()
	if count == known then
		return
	end
	if count > known then
		addAll(select(known + 1, WorldFrame:GetChildren()))
	else
		addAll(WorldFrame:GetChildren())
	end
	known = count
end

function WorldChildren.Register(kind, handler)
	local callbacks = handlers[kind]
	if not callbacks then
		callbacks = {}
		handlers[kind] = callbacks
	end
	callbacks[#callbacks + 1] = handler
	local list = frames[kind]
	if list then
		for i = 1, #list do
			SafeCall(handler, list[i])
		end
	end
end

-- 3.3.5: no event announces a new nameplate or bubble, so WorldFrame children are polled
local scanner = CreateFrame("Frame")
scanner:SetScript("OnUpdate", K.SafeOnUpdate and K.SafeOnUpdate(scanNewChildren, "WorldChildren") or scanNewChildren)
