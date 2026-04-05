local vehicles = {}

AddEventHandler("vrp_garages:setVehicle", function(vtype, vehicle)
	vehicles[vtype] = vehicle
end)

-- Helper: release vehicle entity from game
local function releaseVehicle(entity)
	if entity == nil or entity == 0 then return end
	SetVehicleHasBeenOwnedByPlayer(entity, false)
	Citizen.InvokeNative(0xAD738C3085FE7E11, entity, false, true)
	SetVehicleAsNoLongerNeeded(Citizen.PointerValueIntInitialized(entity))
	Citizen.InvokeNative(0xEA386986E786A54F, Citizen.PointerValueIntInitialized(entity))
end

-- Helper: find closest vehicle (tries all vehicle types)
local function findClosestVehicle(x, y, z, radius)
	local veh = GetClosestVehicle(x, y, z, radius, 0, 8192 + 4096 + 4 + 2 + 1)
	if not IsEntityAVehicle(veh) then
		veh = GetClosestVehicle(x, y, z, radius, 0, 4 + 2 + 1)
	end
	return veh
end

-- Helper: load model with timeout
local function loadModel(mhash, timeout)
	timeout = timeout or 10000
	local i = 0
	while not HasModelLoaded(mhash) and i < timeout do
		RequestModel(mhash)
		Citizen.Wait(10)
		i = i + 1
	end
	return HasModelLoaded(mhash)
end

-- Helper: get vehicle type display name
local function getVtypeLabel(vtype)
	local labels = { car = "bil", bike = "motorcykel", citybike = "cykel" }
	return labels[vtype] or vtype
end

-- Vehicle lock toggle cooldown
local lock_cooldown = false

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)
		if IsControlJustReleased(0, 182) then
			local ok, vtype = vRP.getNearestOwnedVehicle(20)
			if ok then
				vRP.vc_toggleLock(vtype)
			end
		end
	end
end)

function vRP.spawnGarageVehicle(vtype, name, pos)
	local vehicle = vehicles[vtype]

	-- Precheck: clean up undriveable vehicle
	if vehicle and not IsVehicleDriveable(vehicle[3], false) then
		releaseVehicle(vehicle[3])
		vehicles[vtype] = nil
		vehicle = nil
	end

	if vehicle ~= nil then
		vRP.notify("Du kan kun have én " .. getVtypeLabel(vtype) .. " ude")
		return
	end

	-- Load vehicle model
	local mhash = GetHashKey(name)
	if not loadModel(mhash) then return end

	-- Spawn vehicle
	local x, y, z = vRP.getPosition()
	if pos then
		x, y, z = table.unpack(pos)
	end

	local nveh = CreateVehicle(mhash, x, y, z + 0.5, 0.0, true, false)
	SetVehicleOnGroundProperly(nveh)
	SetEntityInvincible(nveh, false)
	SetPedIntoVehicle(GetPlayerPed(-1), nveh, -1)
	SetVehicleNumberPlateText(nveh, "P " .. vRP.getRegistrationNumber())

	if GetVehicleClass(nveh) == 18 then
		SetVehicleDirtLevel(nveh, 0.0)
		TriggerEvent("advancedFuel:setEssence", 100, GetVehicleNumberPlateText(nveh), GetDisplayNameFromVehicleModel(GetEntityModel(nveh)))
	end

	SetVehicleHasBeenOwnedByPlayer(nveh, true)
	local nid = NetworkGetNetworkIdFromEntity(nveh)
	SetNetworkIdCanMigrate(nid, true)

	vehicles[vtype] = { vtype, name, nveh }
	SetModelAsNoLongerNeeded(mhash)
end

function vRP.despawnGarageVehicle(vtype, max_range)
	local vehicle = vehicles[vtype]
	if vehicle == nil then return end

	local x, y, z = table.unpack(GetEntityCoords(vehicle[3], true))
	local px, py, pz = vRP.getPosition()

	if GetDistanceBetweenCoords(x, y, z, px, py, pz, true) >= max_range then
		vRP.notify("Du er for langt fra køretøjet.")
		return
	end

	releaseVehicle(vehicle[3])
	vehicles[vtype] = nil
	vRP.notify("Køretøj parkeret.")
end

function vRP.despawnNetVehicle(veh)
	if veh == nil then return end
	veh = NetToVeh(veh)
	releaseVehicle(veh)
end

function vRP.getNearestVehicle(radius)
	local x, y, z = vRP.getPosition()
	local ped = GetPlayerPed(-1)
	if IsPedSittingInAnyVehicle(ped) then
		return GetVehiclePedIsIn(ped, true)
	end
	return findClosestVehicle(x, y, z, radius)
end

function vRP.getNearestVehicleHealth(radius)
	local x, y, z = vRP.getPosition()
	local ped = GetPlayerPed(-1)
	if IsPedSittingInAnyVehicle(ped) then
		local veh = GetVehiclePedIsIn(ped, true)
		return { veh = veh, health = GetVehicleEngineHealth(veh) }
	end
	local veh = findClosestVehicle(x, y, z, radius)
	if not IsEntityAVehicle(veh) then return nil end
	return { veh = veh, health = GetVehicleEngineHealth(veh) }
end

function vRP.fixeNearestVehicle(radius)
	local veh = vRP.getNearestVehicle(radius)
	if IsEntityAVehicle(veh) then
		SetVehicleFixed(veh)
	end
end

function vRP.lowfixNearestVehicle(veh)
	if IsEntityAVehicle(veh) then
		SetVehicleEngineHealth(veh, 200.0)
	end
end

function vRP.fixeNearestVehicleAdmin(radius)
	local veh = vRP.getNearestVehicle(radius)
	if not IsEntityAVehicle(veh) then
		vRP.notify("Køretøj blev ikke fundet.")
		return
	end
	if IsPedSittingInAnyVehicle(GetPlayerPed(-1)) then
		vRP.notify("Du må ikke sidde i køretøjet, mens du reparerer det.")
		return
	end
	SetVehicleFixed(veh)
	vRP.notify("Nærmeste køretøj repareret.")
end

function vRP.changeNummerPlate(radius)
	local veh = vRP.getNearestVehicle(radius)
	if not IsEntityAVehicle(veh) then
		vRP.notify("Køretøj blev ikke fundet.")
		return
	end

	local number = vRP.generateStringNumber("DLDLDL")
	SetVehicleNumberPlateText(veh, "P " .. number)
end

function vRP.fixeNearestVehicleMidlertidigt(radius)
	local veh = vRP.getNearestVehicle(radius)
	if not IsEntityAVehicle(veh) then
		vRP.notify("Køretøj blev ikke fundet.")
		return
	end
	if IsPedSittingInAnyVehicle(GetPlayerPed(-1)) then
		vRP.notify("Du må ikke sidde i køretøjet, mens du reparerer det.")
		return
	end
	SetVehicleEngineHealth(veh, 300.0)
	vRP.notify("Nærmeste køretøj er midlertidigt repareret.")
end

function vRP.vehicleUnlockMekaniker()
	local veh = vRP.getNearestVehicle(4)
	if not IsEntityAVehicle(veh) then
		vRP.notify("Intet køretøj fundet.")
		return
	end

	local ped = GetPlayerPed(-1)
	SetVehicleDoorsLockedForAllPlayers(veh, false)
	SetVehicleDoorsLocked(veh, 1)
	SetVehicleDoorsLockedForPlayer(veh, ped, false)
	vRP.notify("Vent seks sekunder før køretøjet er låst op!")

	Citizen.CreateThread(function()
		Citizen.Wait(6000)
		vRP.notify("Nærmeste køretøj låst op.")
	end)
end

function vRP.fixCurrentVehicle()
	local veh = GetVehiclePedIsIn(GetPlayerPed(-1), false)
	if IsEntityAVehicle(veh) then
		SetVehicleFixed(veh)
	else
		vRP.notify("Køretøj blev ikke fundet.")
	end
end

function vRP.replaceNearestVehicle(radius)
	local veh = vRP.getNearestVehicle(radius)
	if not IsEntityAVehicle(veh) then return end
	if IsPedSittingInAnyVehicle(GetPlayerPed(-1)) then return end

	local roll = GetEntityRoll(veh)
	if roll <= 75.0 and roll >= -75.0 then return end
	if GetEntitySpeed(veh) >= 2 then return end

	local heading = GetEntityHeading(veh)
	SetEntityRotation(veh, 0, 0, 0, 0, 0)
	SetVehicleOnGroundProperly(veh)
	SetEntityHeading(veh, heading)
	vRP.notify("Køretøjet blev vendt om.")
end

function vRP.getVehicleAtPosition(x, y, z)
	local ray = CastRayPointToPoint(x, y, z, x, y, z + 4, 10, GetPlayerPed(-1), 0)
	local a, b, c, d, ent = GetRaycastResult(ray)
	return ent
end

function vRP.getNearestOwnedVehicle(radius)
	local px, py, pz = vRP.getPosition()
	for k, v in pairs(vehicles) do
		local x, y, z = table.unpack(GetEntityCoords(v[3], true))
		if GetDistanceBetweenCoords(x, y, z, px, py, pz, true) <= radius then
			return true, v[1], v[2]
		end
	end
	return false, "", ""
end

function vRP.getAnyOwnedVehiclePosition()
	for k, v in pairs(vehicles) do
		if IsEntityAVehicle(v[3]) then
			local x, y, z = table.unpack(GetEntityCoords(v[3], true))
			return true, x, y, z
		end
	end
	return false, 0, 0, 0
end

function vRP.getOwnedVehiclePosition(vtype)
	local vehicle = vehicles[vtype]
	if vehicle then
		return table.unpack(GetEntityCoords(vehicle[3], true))
	end
	return 0, 0, 0
end

function vRP.getOwnedVehicleId(vtype)
	local vehicle = vehicles[vtype]
	if vehicle then
		return true, NetworkGetNetworkIdFromEntity(vehicle[3])
	end
	return false, 0
end

function vRP.ejectVehicle()
	local ped = GetPlayerPed(-1)
	if IsPedSittingInAnyVehicle(ped) then
		TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 4160)
	end
end

-- Door state tracking (single shared state)
local door_state = false

function vRP.vc_toggleDoor(vtype, door_index)
	local vehicle = vehicles[vtype]
	if vehicle == nil then return end
	if door_state then
		SetVehicleDoorOpen(vehicle[3], door_index, 0, false)
	else
		SetVehicleDoorShut(vehicle[3], door_index, 0, false)
	end
	door_state = not door_state
end

function vRP.vc_openDoor(vtype, door_index)
	local vehicle = vehicles[vtype]
	if vehicle == nil then return end
	if door_state then
		SetVehicleDoorShut(vehicle[3], door_index, 0, false)
	else
		SetVehicleDoorOpen(vehicle[3], door_index)
	end
	door_state = not door_state
end

function vRP.vc_closeDoor(vtype, door_index)
	local vehicle = vehicles[vtype]
	if vehicle == nil then return end
	SetVehicleDoorShut(vehicle[3], door_index)
end

-- Neon state tracking
local neon_state = false

function vRP.vc_NeonToggle(vtype)
	local vehicle = vehicles[vtype]
	if vehicle == nil then return end

	neon_state = not neon_state
	for i = 0, 3 do
		SetVehicleNeonLightEnabled(vehicle[3], i, neon_state)
	end
end

function vRP.vc_detachTrailer(vtype)
	local vehicle = vehicles[vtype]
	if vehicle then DetachVehicleFromTrailer(vehicle[3]) end
end

function vRP.vc_detachTowTruck(vtype)
	local vehicle = vehicles[vtype]
	if vehicle == nil then return end
	local ent = GetEntityAttachedToTowTruck(vehicle[3])
	if IsEntityAVehicle(ent) then
		DetachVehicleFromTowTruck(vehicle[3], ent)
	end
end

function vRP.vc_detachCargobob(vtype)
	local vehicle = vehicles[vtype]
	if vehicle == nil then return end
	local ent = GetVehicleAttachedToCargobob(vehicle[3])
	if IsEntityAVehicle(ent) then
		DetachVehicleFromCargobob(vehicle[3], ent)
	end
end

function vRP.vc_toggleEngine(vtype)
	local vehicle = vehicles[vtype]
	if vehicle == nil then return end

	local running = Citizen.InvokeNative(0xAE31E7DF9B5B132E, vehicle[3])
	SetVehicleEngineOn(vehicle[3], not running, true, true)
	SetVehicleUndriveable(vehicle[3], running)
end

function vRP.vc_toggleLock(vtype)
	local vehicle = vehicles[vtype]
	if vehicle == nil then return end
	if lock_cooldown then return end

	local ped = GetPlayerPed(-1)
	local veh = vehicle[3]
	local lveh = GetVehiclePedIsUsing(ped)

	TriggerEvent("ftn:carkeys")
	local locked = GetVehicleDoorLockStatus(veh) >= 2

	if locked then
		SetVehicleDoorsLockedForAllPlayers(veh, false)
		SetVehicleDoorsLocked(veh, 1)
		SetVehicleDoorsLockedForPlayer(veh, ped, false)
		vRP.notify("Køretøj laast op")
	else
		SetVehicleDoorsLocked(veh, 2)
		SetVehicleDoorsLockedForAllPlayers(veh, true)
		vRP.notify("Køretøj laast")
	end

	if not DoesEntityExist(lveh) or lveh ~= veh then
		TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 0.5, "lock", 0.3)
		SetVehicleEngineOn(veh, true, true, false)
		SetVehicleIndicatorLights(veh, 0, true)
		SetVehicleIndicatorLights(veh, 1, true)

		lock_cooldown = true
		Citizen.CreateThread(function()
			Wait(3000)
			SetVehicleIndicatorLights(veh, 0, false)
			SetVehicleIndicatorLights(veh, 1, false)
			if not DoesEntityExist(GetVehiclePedIsUsing(ped)) or GetVehiclePedIsUsing(ped) ~= veh then
				SetVehicleEngineOn(veh, false, true, false)
			end
			lock_cooldown = false
		end)
	else
		local sound = locked and "pressunlock" or "presslock"
		TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 2, sound, 0.4)
	end
end
