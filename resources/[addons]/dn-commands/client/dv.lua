local vRP = exports["vrp"]:getvRP()

RegisterNetEvent("wk:deleteVehicle", function()
	local ped = GetPlayerPed(-1)

	if DoesEntityExist(ped) and not IsEntityDead(ped) then
		if IsPedSittingInAnyVehicle(ped) then
			local vehicle = GetVehiclePedIsIn(ped, false)

			if GetPedInVehicleSeat(vehicle, -1) == ped then
				SetEntityAsMissionEntity(vehicle, true, true)
				DeleteVehicle(vehicle)

				vRP.notify(DoesEntityExist(vehicle) and "Kunne ikke fjerne køretøjet, prøv igen" or "Køretøj fjernet")
			else
				vRP.notify("Du skal være føreren af køretøjet for at kunne fjerne den")
			end
		else
			local vehicle = GetVehicleInDirection(
				GetEntityCoords(ped, true), -- spillerns koordinater
				GetOffsetFromEntityInWorldCoords(ped, 0.0, cfg.distance_to_check, 0.0) -- distancen for at tjekke efter køretøjer
			)

			if not DoesEntityExist(vehicle) then
				return vRP.notify("Der er ingen køretøjer i nærheden")
			end

			SetEntityAsMissionEntity(vehicle, true, true)
			DeleteVehicle(vehicle)

			if DoesEntityExist(vehicle) then
				vRP.notify("Kunen ikke fjerne Køretøjet, prøv igen")
			else
				vRP.notify("Køretøj fjernet")
			end
		end
	end
end)

function GetVehicleInDirection(coordFrom, coordTo)
	local rayHandle =
		CastRayPointToPoint(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10, GetPlayerPed(-1), 0)
	local _, _, _, _, vehicle = GetRaycastResult(rayHandle)
	return vehicle
end