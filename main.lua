local input = io.open("input.lua","rb"):read("*all")

local precompiled = string.dump(loadstring(input))

local function convert(s)
	local converted = {}
	return s:gsub(".",function(a)
		local dec = a:byte()
		table.insert(converted,string.format("%x",dec))
	end)
	return converted
end