local noclip = false
local noclip_speed = 1.0
local noclip_fspeed = 2.0
local frozen = false
local spectating = false
local last_coords = nil

function vRP.toggleNoclip()
	local ped = GetPlayerPed(-1)
	noclip = not noclip
	if noclip then -- set
		SetEntityInvincible(ped, true)
		SetEntityVisible(ped, false, false)
	else -- unset
		SetEntityInvincible(ped, false)
		SetEntityVisible(ped, true, false)
	end
	local coords = GetEntityCoords(ped)
	return { coords = { coords["x"], coords["y"], coords["z"] }, noclip = noclip }
end

function vRP.isNoclip()
	return noclip
end

function vRP.toggleFreeze()
	local ped = GetPlayerPed(-1)
	frozen = not frozen
	FreezeEntityPosition(ped, frozen)
	if frozen then
		vRP.notify("Du blev frosset af en admin.")
	else
		vRP.notify("~g~Du blev unfrosset.")
	end
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local ped = GetPlayerPed(-1)
		if frozen then
			DisableControlAction(0, 23, true)
			DisableControlAction(0, 24, true)
			DisableControlAction(0, 25, true)
			DisableControlAction(0, 37, true)
			DisableControlAction(0, 44, true)
			DisableControlAction(0, 45, true)
			DisableControlAction(0, 75, true)
			DisableControlAction(0, 140, true)
			DisableControlAction(0, 141, true)
			DisableControlAction(0, 142, true)
			DisablePlayerFiring(ped, true)
			FreezeEntityPosition(ped, true)
			local currentvehicle = GetVehiclePedIsIn(ped, false)
			if currentvehicle ~= 0 then
				FreezeEntityPosition(currentvehicle, true)
				SetVehicleUndriveable(currentvehicle, true)
				SetVehicleEngineOn(currentvehicle, false, false, false)
			end
		end
	end
end)

function vRP.setVehicleDoors(veh, doors)
	SetVehicleDoorsLocked(veh, doors)
end

function vRP.vehicleUnlockAdmin()
	local ped = GetPlayerPed(-1)
	local veh = vRP.getNearestVehicle(4)
	local plate = GetVehicleNumberPlateText(veh)

	SetVehicleDoorsLockedForAllPlayers(veh, false)
	SetVehicleDoorsLocked(veh, 1)
	SetVehicleDoorsLockedForPlayer(veh, ped, false)

	vRP.notify("~g~Du låste op for køretøjet med nummerpladen: ~b~" .. plate)
end

Citizen.CreateThread(function()
	while true do
		if noclip then
			local ped = GetPlayerPed(-1)
			local x, y, z = vRP.getPosition()
			local dx, dy, dz = vRP.getCamDirection()
			local speed = noclip_speed
			local fspeed = noclip_fspeed

			SetEntityVelocity(ped, 0.0001, 0.0001, 0.0001)

			if IsControlPressed(0, 32) then
				x = x + speed * dx
				y = y + speed * dy
				z = z + speed * dz
			end

			if IsControlPressed(0, 21) and IsControlPressed(0, 32) then
				x = x + fspeed * dx
				y = y + fspeed * dy
				z = z + fspeed * dz
			end

			if IsControlPressed(0, 269) then
				x = x - speed * dx
				y = y - speed * dy
				z = z - speed * dz
			end

			SetEntityCoordsNoOffset(ped, x, y, z, true, true, true)
			Citizen.Wait(0)
		else
			Citizen.Wait(500)
		end
	end
end)

local function teleportToWaypoint()
	local targetPed = GetPlayerPed(-1)
	local targetVeh = GetVehiclePedIsUsing(targetPed)
	if IsPedInAnyVehicle(targetPed, true) then
		targetPed = targetVeh
	end

	if not IsWaypointActive() then
		vRP.notify("~r~Du skal sætte et waypoint først.")
		return
	end

	local waypointBlip = GetFirstBlipInfoId(8) -- 8 = waypoint Id
	local x, y, z = table.unpack(Citizen.InvokeNative(0xFA7C7F0AADF25D09, waypointBlip, Citizen.ResultAsVector()))

	-- ensure entity teleports above the ground
	local ground
	local groundFound = false
	local groundCheckHeights =
		{ 100.0, 150.0, 50.0, 0.0, 200.0, 250.0, 300.0, 350.0, 400.0, 450.0, 500.0, 550.0, 600.0, 650.0, 700.0, 750.0, 800.0 }

	for i, height in ipairs(groundCheckHeights) do
		SetEntityCoordsNoOffset(targetPed, x, y, height, 0, 0, 1)
		Wait(10)

		ground, z = GetGroundZFor_3dCoord(x, y, height)
		if ground then
			z = z + 3
			groundFound = true
			break
		end
	end

	if not groundFound then
		z = 1000
		GiveDelayedWeaponToPed(PlayerPedId(), 0xFBAB5776, 1, 0) -- parachute
	end

	SetEntityCoordsNoOffset(targetPed, x, y, z, 0, 0, 1)
	vRP.notify("Teleporteret til waypoint")
end
RegisterNetEvent("TpToWaypoint")
AddEventHandler("TpToWaypoint", teleportToWaypoint)

RegisterNetEvent("vRPAdmin:Spectate")
AddEventHandler("vRPAdmin:Spectate", function(plr, tpcoords)
	local playerPed = PlayerPedId()
	local targetPed = GetPlayerPed(GetPlayerFromServerId(plr))

	if not spectating then
		last_coords = GetEntityCoords(playerPed)
		if tpcoords then
			SetEntityCoords(playerPed, tpcoords.x - 10.0, tpcoords.y, tpcoords.z)
		end
		Wait(300)
		targetPed = GetPlayerPed(GetPlayerFromServerId(plr))
		if targetPed == playerPed then
			vRP.notify("~r~Du kan ikke spectate dig selv.")
			return
		end
		NetworkSetInSpectatorMode(true, targetPed)
		SetEntityCollision(playerPed, false, false)
		SetEntityVisible(playerPed, false, 0)
		SetEveryoneIgnorePlayer(playerPed, true)
		SetEntityInvincible(playerPed, true)
		spectating = true
		vRP.notify("~g~Spectating Player.")
	else
		NetworkSetInSpectatorMode(false, targetPed)
		SetEntityVisible(playerPed, true, 0)
		SetEveryoneIgnorePlayer(playerPed, false)
		SetEntityInvincible(playerPed, false)
		SetEntityCollision(playerPed, true, true)
		spectating = false
		SetEntityCoords(playerPed, last_coords)
		vRP.notify("~r~Stopped Spectating Player.")
	end
end)
