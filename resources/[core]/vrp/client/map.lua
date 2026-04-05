-- BLIPS: see https://wiki.gtanet.work/index.php?title=Blips for blip id/color

-- TUNNEL CLIENT API

-- BLIP

function vRP.addBlip(x, y, z, idtype, idcolor, text)
	local blip = AddBlipForCoord(x + 0.001, y + 0.001, z + 0.001)
	SetBlipSprite(blip, idtype)
	SetBlipAsShortRange(blip, true)
	SetBlipColour(blip, idcolor)
	SetBlipScale(blip, 0.6)

	if text ~= nil then
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(text)
		EndTextCommandSetBlipName(blip)
	end

	return blip
end

function vRP.removeBlip(id)
	RemoveBlip(id)
end

local named_blips = {}

function vRP.setNamedBlip(name, x, y, z, idtype, idcolor, text)
	vRP.removeNamedBlip(name)
	named_blips[name] = vRP.addBlip(x, y, z, idtype, idcolor, text)
	return named_blips[name]
end

function vRP.removeNamedBlip(name)
	if named_blips[name] ~= nil then
		vRP.removeBlip(named_blips[name])
		named_blips[name] = nil
	end
end

-- GPS

function vRP.setGPS(x, y)
	SetNewWaypoint(x + 0.0001, y + 0.0001)
end

function vRP.setBlipRoute(id)
	SetBlipRoute(id, true)
end

-- MARKER

local markers = {}
local marker_ids = Tools.newIDGenerator()
local named_markers = {}

local marker_defaults = {
	sx = 2.0, sy = 2.0, sz = 0.7,
	r = 0, g = 155, b = 255, a = 200,
	visible_distance = 150,
}

function vRP.addMarker(x, y, z, sx, sy, sz, r, g, b, a, visible_distance)
	local marker = {
		x = x + 0.001, y = y + 0.001, z = z + 0.001,
		sx = (sx or marker_defaults.sx) + 0.001,
		sy = (sy or marker_defaults.sy) + 0.001,
		sz = (sz or marker_defaults.sz) + 0.001,
		r = r or marker_defaults.r,
		g = g or marker_defaults.g,
		b = b or marker_defaults.b,
		a = a or marker_defaults.a,
		visible_distance = visible_distance or marker_defaults.visible_distance,
	}

	local id = marker_ids:gen()
	markers[id] = marker
	return id
end

function vRP.removeMarker(id)
	if markers[id] ~= nil then
		markers[id] = nil
		marker_ids:free(id)
	end
end

function vRP.setNamedMarker(name, x, y, z, sx, sy, sz, r, g, b, a, visible_distance)
	vRP.removeNamedMarker(name)
	named_markers[name] = vRP.addMarker(x, y, z, sx, sy, sz, r, g, b, a, visible_distance)
	return named_markers[name]
end

function vRP.removeNamedMarker(name)
	if named_markers[name] ~= nil then
		vRP.removeMarker(named_markers[name])
		named_markers[name] = nil
	end
end

-- markers draw loop
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local px, py, pz = vRP.getPosition()

		for _, v in pairs(markers) do
			if GetDistanceBetweenCoords(v.x, v.y, v.z, px, py, pz, true) <= v.visible_distance then
				DrawMarker(27, v.x, v.y, v.z, 0, 0, 0, 0, 0, 0, v.sx, v.sy, v.sz, v.r, v.g, v.b, v.a, 0, 0, 0, 50)
			end
		end
	end
end)

-- AREA

local areas = {}

function vRP.setArea(name, x, y, z, radius, height)
	areas[name] = {
		x = x + 0.001, y = y + 0.001, z = z + 0.001,
		radius = radius,
		height = height or 6,
	}
end

function vRP.removeArea(name)
	areas[name] = nil
end

-- areas triggers detections
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(250)
		local px, py, pz = vRP.getPosition()

		for k, v in pairs(areas) do
			local player_in = (
				GetDistanceBetweenCoords(v.x, v.y, v.z, px, py, pz, true) <= v.radius
				and math.abs(pz - v.z) <= v.height
			)

			if v.player_in and not player_in then
				vRPserver.leaveArea({ k })
			elseif not v.player_in and player_in then
				vRPserver.enterArea({ k })
			end

			v.player_in = player_in
		end
	end
end)

-- DOOR

function vRP.setStateOfClosestDoor(doordef, locked, doorswing)
	local x, y, z = vRP.getPosition()
	local hash = doordef.modelhash or GetHashKey(doordef.model)
	SetStateOfClosestDoorOfType(hash, x, y, z, locked, doorswing + 0.0001)
end

function vRP.openClosestDoor(doordef)
	vRP.setStateOfClosestDoor(doordef, false, 0)
end

function vRP.closeClosestDoor(doordef)
	vRP.setStateOfClosestDoor(doordef, true, 0)
end
