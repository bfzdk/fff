local Tools = module("lib/Tools")

local Tunnel = {}
local isServer = IsDuplicityVersion()

if isServer then
	Tunnel.delays = {}

	function Tunnel.setDestDelay(dest, delay)
		Tunnel.delays[dest] = { delay, 0 }
	end
end

local function tunnel_resolve(itable, key)
	local mtable     = getmetatable(itable)
	local iname      = mtable.name
	local ids        = mtable.tunnel_ids
	local callbacks  = mtable.tunnel_callbacks
	local identifier = mtable.identifier

	local fcall

	if isServer then
		fcall = function(dest, args, callback)
			args = args or {}

			local delay_data = Tunnel.delays[dest]
			if delay_data == nil then delay_data = { 0, 0 } end

			local add_delay = delay_data[1]
			delay_data[2] = delay_data[2] + add_delay

			local function doTrigger()
				if type(callback) == "function" then
					local rid = ids:gen()
					callbacks[rid] = callback
					TriggerClientEvent(iname .. ":tunnel_req", dest, key, args, identifier, rid)
				else
					TriggerClientEvent(iname .. ":tunnel_req", dest, key, args, "", -1)
				end
			end

			if delay_data[2] > 0 then
				SetTimeout(delay_data[2], function()
					delay_data[2] = delay_data[2] - add_delay
					doTrigger()
				end)
			else
				doTrigger()
			end
		end
	else
		fcall = function(args, callback)
			args = args or {}

			if type(callback) == "function" then
				local rid = ids:gen()
				callbacks[rid] = callback
				TriggerServerEvent(iname .. ":tunnel_req", key, args, identifier, rid)
			else
				TriggerServerEvent(iname .. ":tunnel_req", key, args, "", -1)
			end
		end
	end

	itable[key] = fcall
	return fcall
end

function Tunnel.createInterface(name)
	name = name or GetCurrentResourceName()

	local interface = {}

	if isServer then
		RegisterServerEvent(name .. ":tunnel_req")
		AddEventHandler(name .. ":tunnel_req", function(member, args, identifier, rid)
			local source  = source
			local delayed = false
			local f       = interface[member]
			local rets    = {}

			if type(f) == "function" then
				TUNNEL_DELAYED = function()
					delayed = true
					return function(r)
						r = r or {}
						if rid >= 0 then
							TriggerClientEvent(name .. ":" .. identifier .. ":tunnel_res", source, rid, r)
						end
					end
				end
				rets = { f(table.unpack(args)) }
			end

			if not delayed and rid >= 0 then
				TriggerClientEvent(name .. ":" .. identifier .. ":tunnel_res", source, rid, rets)
			end
		end)
	else
		RegisterNetEvent(name .. ":tunnel_req")
		AddEventHandler(name .. ":tunnel_req", function(member, args, identifier, rid)
			local delayed = false
			local f       = interface[member]
			local rets    = {}

			if type(f) == "function" then
				TUNNEL_DELAYED = function()
					delayed = true
					return function(r)
						r = r or {}
						if rid >= 0 then
							TriggerServerEvent(name .. ":" .. identifier .. ":tunnel_res", rid, r)
						end
					end
				end
				rets = { f(table.unpack(args)) }
			end

			if not delayed and rid >= 0 then
				TriggerServerEvent(name .. ":" .. identifier .. ":tunnel_res", rid, rets)
			end
		end)
	end

	return interface
end

function Tunnel.getInterface(name, identifier)
	local ids       = Tools.newIDGenerator()
	local callbacks = {}

	local r = setmetatable(
		{},
		{
			__index        = tunnel_resolve,
			name           = name,
			tunnel_ids     = ids,
			tunnel_callbacks = callbacks,
			identifier     = identifier,
		}
	)

	(isServer and RegisterServerEvent or RegisterNetEvent)(name .. ":" .. identifier .. ":tunnel_res")
	AddEventHandler(name .. ":" .. identifier .. ":tunnel_res", function(rid, args)
		local callback = callbacks[rid]
		if callback then
			ids:free(rid)
			callbacks[rid] = nil
			callback(table.unpack(args))
		end
	end)

	return r
end

return Tunnel