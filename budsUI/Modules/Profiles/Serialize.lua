local K, C, L, _ = select(2, ...):unpack()

local floor, strbyte, strchar, strsub, concat = math.floor, string.byte, string.char, string.sub, table.concat
local tonumber, tostring, type, pairs, ipairs = tonumber, tostring, type, pairs, ipairs

-- ---------------------------------------------------------------------------
-- ZeroMQ Base85 (Z85) Encoding
-- ---------------------------------------------------------------------------
local Z85 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-:+=^!/*?&<>()[]{}@%$#"
local Z85_INDEX = {}
for i = 1, 85 do
	Z85_INDEX[strbyte(Z85, i)] = i - 1
end

local function toZ85(bytes)
	local pad = (4 - #bytes % 4) % 4
	bytes = bytes .. strchar(0):rep(pad)
	local out = { tostring(pad) }
	local chunk = {}
	for i = 1, #bytes, 4 do
		local b1, b2, b3, b4 = strbyte(bytes, i, i + 3)
		local value = ((b1 * 256 + b2) * 256 + b3) * 256 + b4
		for j = 5, 1, -1 do
			local index = value % 85
			chunk[j] = strsub(Z85, index + 1, index + 1)
			value = (value - index) / 85
		end
		out[#out + 1] = concat(chunk)
	end
	return concat(out)
end

local function fromZ85(text)
	local pad = tonumber(strsub(text, 1, 1))
	if not pad or pad > 3 or (#text - 1) % 5 ~= 0 then
		return nil
	end
	local out = {}
	for i = 2, #text, 5 do
		local value = 0
		for j = i, i + 4 do
			local index = Z85_INDEX[strbyte(text, j)]
			if not index then
				return nil
			end
			value = value * 85 + index
		end
		if value >= 2 ^ 32 then
			return nil
		end
		local b4 = value % 256
		value = (value - b4) / 256
		local b3 = value % 256
		value = (value - b3) / 256
		local b2 = value % 256
		out[#out + 1] = strchar((value - b2) / 256, b2, b3, b4)
	end
	local bytes = concat(out)
	return strsub(bytes, 1, #bytes - pad)
end

-- ---------------------------------------------------------------------------
-- LZW Compression
-- ---------------------------------------------------------------------------
local MIN_WIDTH = 9
local MAX_WIDTH = 16
local MAX_CODES = 2 ^ MAX_WIDTH

local function widthFor(emission)
	local width = MIN_WIDTH
	local highest = 256 + emission - 2
	while width < MAX_WIDTH and highest >= 2 ^ width do
		width = width + 1
	end
	return width
end

local function compress(text)
	local dict, nextCode = {}, 256
	for i = 0, 255 do
		dict[strchar(i)] = i
	end
	local out, acc, nbits, emission = {}, 0, 0, 0
	local function emit(code)
		emission = emission + 1
		local width = widthFor(emission)
		acc = acc * 2 ^ width + code
		nbits = nbits + width
		while nbits >= 8 do
			local shift = 2 ^ (nbits - 8)
			local byte = floor(acc / shift)
			out[#out + 1] = strchar(byte)
			acc = acc - byte * shift
			nbits = nbits - 8
		end
	end
	local w = ""
	for i = 1, #text do
		local c = strsub(text, i, i)
		local wc = w .. c
		if dict[wc] then
			w = wc
		else
			emit(dict[w])
			if nextCode < MAX_CODES then
				dict[wc] = nextCode
				nextCode = nextCode + 1
			end
			w = c
		end
	end
	if w ~= "" then
		emit(dict[w])
	end
	if nbits > 0 then
		out[#out + 1] = strchar(acc * 2 ^ (8 - nbits))
	end
	return concat(out)
end

local function decompress(data)
	local dict, nextCode = {}, 256
	for i = 0, 255 do
		dict[i] = strchar(i)
	end
	local out, acc, nbits, pos, emission = {}, 0, 0, 1, 0
	local total = #data
	local prev
	while true do
		emission = emission + 1
		local width = widthFor(emission)
		while nbits < width and pos <= total do
			acc = acc * 256 + strbyte(data, pos)
			nbits = nbits + 8
			pos = pos + 1
		end
		if nbits < width then
			break
		end
		local shift = 2 ^ (nbits - width)
		local code = floor(acc / shift)
		acc = acc - code * shift
		nbits = nbits - width
		local entry = dict[code]
		if not entry then
			if code ~= nextCode or not prev then
				return nil
			end
			entry = prev .. strsub(prev, 1, 1)
		end
		out[#out + 1] = entry
		if prev and nextCode < MAX_CODES then
			dict[nextCode] = prev .. strsub(entry, 1, 1)
			nextCode = nextCode + 1
		end
		prev = entry
	end
	return concat(out)
end

-- ---------------------------------------------------------------------------
-- Adler-32 Checksum
-- ---------------------------------------------------------------------------
local function adler32(text)
	local a, b = 1, 0
	for i = 1, #text do
		a = (a + strbyte(text, i)) % 65521
		b = (b + a) % 65521
	end
	return b * 65536 + a
end

function K.Encode(text)
	local sum = adler32(text)
	local header = strchar(floor(sum / 16777216) % 256, floor(sum / 65536) % 256, floor(sum / 256) % 256, sum % 256)
	return toZ85(header .. compress(text))
end

function K.Decode(encoded)
	if not encoded or encoded == "" then
		return nil, "empty string"
	end
	local bytes = fromZ85((encoded:gsub("%s", "")))
	if not bytes or #bytes < 4 then
		return nil, "malformed string"
	end
	local b1, b2, b3, b4 = strbyte(bytes, 1, 4)
	local text = decompress(strsub(bytes, 5))
	if not text then
		return nil, "corrupted data"
	end
	if adler32(text) ~= ((b1 * 256 + b2) * 256 + b3) * 256 + b4 then
		return nil, "checksum mismatch"
	end
	return text
end

-- ---------------------------------------------------------------------------
-- Deterministic Safe Table Serializer / Parser (No loadstring)
-- ---------------------------------------------------------------------------
local function formatNumber(value)
	if value ~= value then
		return "0"
	elseif value == math.huge then
		return "1e999"
	elseif value == -math.huge then
		return "-1e999"
	end
	local text = ("%.14g"):format(value)
	if tonumber(text) ~= value then
		text = ("%.17g"):format(value)
	end
	return text
end

local function serialize(value, out)
	local kind = type(value)
	if kind == "table" then
		out[#out + 1] = "{"
		local count = 0
		while value[count + 1] ~= nil do
			count = count + 1
		end
		for i = 1, count do
			serialize(value[i], out)
			out[#out + 1] = ","
		end
		-- Associative keys: sort for deterministic output
		local keys = {}
		for key in pairs(value) do
			if not (type(key) == "number" and key >= 1 and key <= count and key % 1 == 0) then
				keys[#keys + 1] = key
			end
		end
		table.sort(keys, function(a, b)
			if type(a) == type(b) then return tostring(a) < tostring(b) end
			return type(a) < type(b)
		end)
		for _, key in ipairs(keys) do
			out[#out + 1] = "["
			serialize(key, out)
			out[#out + 1] = "]="
			serialize(value[key], out)
			out[#out + 1] = ","
		end
		out[#out + 1] = "}"
	elseif kind == "string" then
		out[#out + 1] = ("%q"):format(value)
	elseif kind == "number" then
		out[#out + 1] = formatNumber(value)
	elseif kind == "boolean" then
		out[#out + 1] = tostring(value)
	end
end

local ESCAPES = { n = "\n", r = "\r", t = "\t", ["\n"] = "\n" }

local function unescape(body)
	local out, i = {}, 1
	while i <= #body do
		local char = body:sub(i, i)
		if char == "\\" then
			local digits = body:match("^%d%d?%d?", i + 1)
			if digits then
				out[#out + 1] = strchar(tonumber(digits))
				i = i + 1 + #digits
			else
				local escaped = body:sub(i + 1, i + 1)
				out[#out + 1] = ESCAPES[escaped] or escaped
				i = i + 2
			end
		else
			out[#out + 1] = char
			i = i + 1
		end
	end
	return concat(out)
end

local parseValue

local function parseTable(text, pos)
	local result, index = {}, 1
	pos = pos + 1
	while true do
		local char = text:sub(pos, pos)
		if char == "}" then
			return result, pos + 1
		elseif char == "" then
			return nil
		end
		local key, value
		if char == "[" then
			key, pos = parseValue(text, pos + 1)
			if not key or text:sub(pos, pos) ~= "]" or text:sub(pos + 1, pos + 1) ~= "=" then
				return nil
			end
			pos = pos + 2
		else
			key, index = index, index + 1
		end
		value, pos = parseValue(text, pos)
		if value == nil then
			return nil
		end
		result[key] = value
		if text:sub(pos, pos) == "," then
			pos = pos + 1
		end
	end
end

function parseValue(text, pos)
	local char = text:sub(pos, pos)
	if char == "{" then
		return parseTable(text, pos)
	elseif char == '"' then
		local stop = pos
		repeat
			stop = text:find('"', stop + 1, true)
			if not stop then
				return nil
			end
			local backslashes = #text:sub(pos + 1, stop - 1):match("\\*$")
		until backslashes % 2 == 0
		return unescape(text:sub(pos + 1, stop - 1)), stop + 1
	elseif text:sub(pos, pos + 3) == "true" then
		return true, pos + 4
	elseif text:sub(pos, pos + 4) == "false" then
		return false, pos + 5
	end
	local number = text:match("^-?%d+%.?%d*[eE]?[-+]?%d*", pos)
	if number and number ~= "" and tonumber(number) then
		return tonumber(number), pos + #number
	end
	return nil
end

function K.Serialize(value)
	local out = {}
	serialize(value, out)
	return concat(out)
end

function K.Deserialize(text)
	if not text or text == "" then return nil end
	local value, pos = parseValue(text, 1)
	if value == nil or pos ~= #text + 1 then
		return nil
	end
	return value
end
