-- Proxy system
-- Når du laver et interface, laver den et event for dit project, det event kan så kaldes og dine funktioner kan blive kaldt via events
-- Get interface giver blot personen en "fake" version af dit project, men hvis gang du kalder en funktion i det, så kalder den dit events og resultatet sendes tilbage

local Proxy = {}

local isServer = IsDuplicityVersion()


local proxy_rdata = {}
local function proxy_callback(rvalues) -- save returned values, TriggerEvent is synchronous
	proxy_rdata = rvalues
end

local function proxy_resolve(itable, key)
	local iname = getmetatable(itable).name

	-- generate access function
	local fcall = function(args, callback)
		if args == nil then
			args = {}
		end

		TriggerEvent(iname .. ":proxy", key, args, proxy_callback)
		return table.unpack(proxy_rdata) -- returns
	end

	itable[key] = fcall -- add generated call to table (optimization)
	return fcall
end

function Proxy.getInterface(name)
	local r = setmetatable({}, { __index = proxy_resolve, name = name })
	return r
end

function Proxy.createInterface(name)
	name = name or GetCurrentResourceName()
	local itable = {}

	AddEventHandler(name .. ":proxy", function(member, args, callback)
		if source > 0 and isServer then -- prevent client -> server calls
			return print("error: proxy call from client to server without tunnel " .. name .. ":" .. member)
		end

		local f = itable[member]

		if type(f) == "function" then -- hvis den kan finde vrp funktion ved navn
			callback({ f(table.unpack(args)) }) -- kalder vrp funktionen og retuner resultatet
		else
			print("error: proxy call " .. name .. ":" .. member .. " not found")
		end
	end)

	return itable
end

return Proxy
