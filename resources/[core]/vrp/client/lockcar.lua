Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)
		local ped = GetPlayerPed(-1)
		if IsControlPressed(0, 182) then
			local nearest = vRP.getNearestOwnedVehicle(8)
			if nearest then
				vRP.vc_toggleLock(nearest.vtype)
				Citizen.Wait(2000)
			end
		end
		if IsControlPressed(0, 167) then
			if vRP.getNearestOwnedVehicle(5) then
				if IsPedInAnyVehicle(ped, true) then
					local nearest = vRP.getNearestOwnedVehicle(5)
					if nearest then
						vRP.vc_NeonToggle(nearest.vtype)
					end
					Citizen.Wait(1000)
				else
					Citizen.Wait(500)
				end
			end
		end
	end
end)
