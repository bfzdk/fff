local isUiOpen = false
local speedBuffer = {}
local velBuffer = {}
local beltOn = false
local wasInCar = false

local function IsCar(veh)
	local vc = GetVehicleClass(veh)
	return (vc >= 0 and vc <= 7) or (vc >= 9 and vc <= 12) or (vc >= 17 and vc <= 20)
end

local function GetForwardVector(entity)
	local hr = (GetEntityHeading(entity) + 90.0) * 0.0174533
	return { x = math.cos(hr) * 2.0, y = math.sin(hr) * 2.0 }
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		local ped = GetPlayerPed(-1)
		local car = GetVehiclePedIsIn(ped)

		if car == 0 or (not wasInCar and not IsCar(car)) then
			if wasInCar then
				wasInCar = false
				beltOn = false
				speedBuffer[1], speedBuffer[2] = 0.0, 0.0
				if isUiOpen and not IsPlayerDead(PlayerId()) then
					SendNUIMessage({ displayWindow = "false" })
					isUiOpen = false
				end
			end
			goto continue
		end

		wasInCar = true

		if not isUiOpen and not IsPlayerDead(PlayerId()) then
			SendNUIMessage({ displayWindow = "true" })
			isUiOpen = true
		end

		if beltOn then
			DisableControlAction(0, 75)
		end

		speedBuffer[2] = speedBuffer[1]
		speedBuffer[1] = GetEntitySpeed(car)

		if speedBuffer[2] ~= nil
			and not beltOn
			and GetEntitySpeedVector(car, true).y > 1.0
			and speedBuffer[1] > 19.25
			and (speedBuffer[2] - speedBuffer[1]) > (speedBuffer[1] * 0.255)
		then
			local co = GetEntityCoords(ped)
			local fw = GetForwardVector(ped)
			SetEntityCoords(ped, co.x + fw.x, co.y + fw.y, co.z - 0.47, true, true, true)
			SetEntityVelocity(ped, velBuffer[2].x, velBuffer[2].y, velBuffer[2].z)
			Citizen.Wait(1)
			SetPedToRagdoll(ped, 1000, 1000, 0, 0, 0, 0)
		end

		velBuffer[2] = velBuffer[1]
		velBuffer[1] = GetEntityVelocity(car)

		if IsControlJustReleased(0, 48) and GetLastInputMethod(0) then
			beltOn = not beltOn

			if beltOn then
				TriggerEvent("pNotify:SendNotification", {
					text = "✅ Sikkerhedssele <b style='color: #5DB6E5'>spændt</b>.",
					type = "success",
					timeout = 1400,
					layout = "bottomCenter",
				})
				TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 0.1, "buckle", 0.3)
				SendNUIMessage({ displayWindow = "false" })
			else
				TriggerEvent("pNotify:SendNotification", {
					text = "⛔️ Sikkerhedssele <b style='color: #DB4646'>løsnet</b>.",
					type = "error",
					timeout = 1400,
					layout = "bottomCenter",
				})
				TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 0.1, "unbuckle", 0.3)
				SendNUIMessage({ displayWindow = "true" })
			end
			isUiOpen = true
		end

		::continue::
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(100)
		if IsPlayerDead(PlayerId()) and isUiOpen then
			SendNUIMessage({ displayWindow = "false" })
			isUiOpen = false
		end
	end
end)
