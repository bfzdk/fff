RegisterNetEvent("c_setSpike")
AddEventHandler("c_setSpike", function()
	SetSpikesOnGround()
end)

local spike_hash = GetHashKey("P_ld_stinger_s")

function SetSpikesOnGround()
	local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))

	RequestModel(spike_hash)
	while not HasModelLoaded(spike_hash) do
		Citizen.Wait(1)
	end

	local object = CreateObject(spike_hash, x + 1, y, z - 2, true, true, false)
	PlaceObjectOnGroundProperly(object)
end

local function burstAllTyres(veh)
	for i = 0, 7 do
		SetVehicleTyreBurst(veh, i, true, 1000.0)
	end
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local ped = GetPlayerPed(-1)
		local veh = GetVehiclePedIsIn(ped, false)
		if not IsPedInAnyVehicle(ped, false) then goto continue end

		local vehCoord = GetEntityCoords(veh)
		if DoesObjectOfTypeExistAtCoords(vehCoord.x, vehCoord.y, vehCoord.z, 0.9, spike_hash, true) then
			burstAllTyres(veh)
			RemoveSpike()
		end

		::continue::
	end
end)

function RemoveSpike()
	local ped = GetPlayerPed(-1)
	local veh = GetVehiclePedIsIn(ped, false)
	local vehCoord = GetEntityCoords(veh)

	if not DoesObjectOfTypeExistAtCoords(vehCoord.x, vehCoord.y, vehCoord.z, 0.9, spike_hash, true) then
		return
	end

	local spike_obj = GetClosestObjectOfType(vehCoord.x, vehCoord.y, vehCoord.z, 0.9, spike_hash, false, false, false)
	if spike_obj ~= 0 then
		SetEntityAsMissionEntity(spike_obj, true, true)
		DeleteObject(spike_obj)
	end
end
