vRP = {}

local modules = {}
function vRP.module(rsc, path)
	if not path then
		path = rsc
		rsc = GetCurrentResourceName()
	end

	local key = rsc .. path

	if modules[key] then -- cached module
		return table.unpack(modules[key])
	end

	local f, err = load(LoadResourceFile(rsc, path .. ".lua"))
	if not f then
		return print("[vRP] error parsing module " .. rsc .. "/" .. path .. ":" .. err)
	end

	local ar = { pcall(f) }
	if not ar[1] then
		modules[key] = nil
		return print("[vRP] error loading module " .. rsc .. "/" .. path .. ":" .. ar[2])
	end

	table.remove(ar, 1)
	modules[key] = ar
	return table.unpack(ar)
end

exports('getSharedObject', function()
    return vRP
end)