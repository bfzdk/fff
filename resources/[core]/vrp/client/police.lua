-- this vRP.module define some police tools and functions

local handcuffed = false
local cop = false

-- Helper: load animation dict
local function loadAnimDict(dict)
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		Citizen.Wait(10)
	end
end

-- set player as cop (true or false)
function vRP.setCop(flag)
	cop = flag
	SetPedAsCop(GetPlayerPed(-1), flag)
end

-- HANDCUFF

function vRP.toggleHandcuff()
	handcuffed = not handcuffed
	SetEnableHandcuffs(GetPlayerPed(-1), handcuffed)
	if handcuffed then
		vRP.playAnim(true, { { "mp_arresting", "idle", 1 } }, true)
		TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 2, "handcuff", 0.4)
	else
		vRP.stopAnim(true)
	end
end

function vRP.setHandcuffed(flag)
	if handcuffed ~= flag then
		vRP.toggleHandcuff()
	end
end

function vRP.isInComa()
	return vRP.isInComa()
end

function vRP.isHandcuffed()
	return handcuffed
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)
		if IsControlJustReleased(1, 170) then
			TriggerServerEvent("handcuff:checkjob")
			Citizen.Wait(1500)
		end
	end
end)

RegisterNetEvent("cuff")
AddEventHandler("cuff", function()
	if not vRP.isInComa() and not vRP.isHandcuffed() then
		if IsPedInAnyVehicle(PlayerPedId(), true) then
			vRP.notify("Du kan ikke give håndjern på fra et køretøj.")
		else
			TriggerServerEvent("handcuff:cuffHim")
		end
	end
end)

function vRP.spawnspikes()
	TriggerEvent("c_setSpike")
end

-- DRAG SYSTEM

local drag_state = {
	other = nil,
	active = false,
	playerAttached = false,
	version = 1,
}

RegisterNetEvent("dr:drag")
AddEventHandler("dr:drag", function(pl)
	drag_state.other = pl
	drag_state.active = not drag_state.active
	drag_state.version = 1
end)

RegisterNetEvent("dr:drag2")
AddEventHandler("dr:drag2", function(pl)
	drag_state.other = pl
	drag_state.active = not drag_state.active
	drag_state.version = 2
end)

local function clearDragState()
	drag_state.active = false
	drag_state.other = nil
	if drag_state.playerAttached then
		DetachEntity(GetPlayerPed(-1), true, false)
		drag_state.playerAttached = false
	end
end

RegisterNetEvent("dr:undrag")
AddEventHandler("dr:undrag", clearDragState)

RegisterNetEvent("dr:undrag2")
AddEventHandler("dr:undrag2", function()
	clearDragState()
	ClearPedTasksImmediately(GetPlayerPed(-1))
end)

Citizen.CreateThread(function()
	while true do
		if drag_state.active and drag_state.other ~= nil then
			local ped = GetPlayerPed(GetPlayerFromServerId(drag_state.other))
			local myped = GetPlayerPed(-1)
			if drag_state.version == 1 then
				AttachEntityToEntity(myped, ped, 9816, 0.015, 0.38, 0.11, 0.9, 0.30, 90.0, false, false, false, false, 2, false)
			else
				AttachEntityToEntity(myped, ped, 0, 0.27, 0.15, 0.63, 0.5, 0.5, 0.0, false, false, false, false, 2, false)
			end
			drag_state.playerAttached = true
		elseif drag_state.playerAttached then
			DetachEntity(GetPlayerPed(-1), true, false)
			drag_state.playerAttached = false
		end
		Citizen.Wait(0)
	end
end)

-- VEHICLE HELPERS

-- Helper: find first free passenger seat
local function findPassengerSeat(veh)
	local ped = GetPlayerPed(-1)
	for i = 1, GetVehicleMaxNumberOfPassengers(veh) do
		if IsVehicleSeatFree(veh, i) then
			DetachEntity(ped, true, false)
			SetPedIntoVehicle(ped, veh, i)
			return true
		end
	end
	return false
end

function vRP.putInNearestVehicleAsPassenger(radius)
	local veh = vRP.getNearestVehicle(radius)
	if not IsEntityAVehicle(veh) then return false end
	return findPassengerSeat(veh)
end

function vRP.putInNetVehicleAsPassenger(net_veh)
	local veh = NetworkGetEntityFromNetworkId(net_veh)
	if not IsEntityAVehicle(veh) then return false end
	return findPassengerSeat(veh)
end

function vRP.putInVehiclePositionAsPassenger(x, y, z)
	local veh = vRP.getVehicleAtPosition(x, y, z)
	if not IsEntityAVehicle(veh) then return false end
	return findPassengerSeat(veh)
end

-- keep handcuffed animation
CreateThread(function()
	while true do
		Citizen.Wait(5000)
		if handcuffed then
			vRP.playAnim(true, { { "mp_arresting", "idle", 1 } }, true)
		end
	end
end)

-- force stealth movement while handcuffed
local handcuff_disabled_controls = {
	{0, 21}, {0, 22}, {0, 23}, {0, 24}, {0, 25}, {0, 29},
	{0, 47}, {0, 58}, {0, 73}, {0, 75}, {27, 75},
	{0, 140}, {0, 141}, {0, 142}, {0, 143}, {0, 257}, {0, 263}, {0, 264},
	{0, 311}, {0, 323}, {0, 244},
}

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if handcuffed then
			SetPedStealthMovement(GetPlayerPed(-1), true, "")
			for _, ctrl in ipairs(handcuff_disabled_controls) do
				DisableControlAction(ctrl[1], ctrl[2], true)
			end
		end
	end
end)

-- JAIL

local jail = nil

function vRP.jail(x, y, z, radius)
	vRP.teleport(x, y, z)
	jail = { x + 0.0001, y + 0.0001, z + 0.0001, radius + 0.0001 }
end

function vRP.unjail()
	jail = nil
end

function vRP.isJailed()
	return jail ~= nil
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(5)
		if jail == nil then goto continue end

		local x, y, z = vRP.getPosition()
		local dx = x - jail[1]
		local dy = y - jail[2]
		local dist = math.sqrt(dx * dx + dy * dy)

		if dist >= jail[4] then
			local ped = GetPlayerPed(-1)
			SetEntityVelocity(ped, 0.0001, 0.0001, 0.0001)
			dx = dx / dist * jail[4] + jail[1]
			dy = dy / dist * jail[4] + jail[2]
			SetEntityCoordsNoOffset(ped, dx, dy, z, true, true, true)
		end

		::continue::
	end
end)

-- WANTED

function vRP.applyWantedLevel(new_wanted)
	Citizen.CreateThread(function()
		local old_wanted = GetPlayerWantedLevel(PlayerId())
		local wanted = math.max(old_wanted, new_wanted)
		ClearPlayerWantedLevel(PlayerId())
		SetPlayerWantedLevelNow(PlayerId(), false)
		Citizen.Wait(10)
		SetPlayerWantedLevel(PlayerId(), wanted, false)
		SetPlayerWantedLevelNow(PlayerId(), false)
	end)
end

-- update wanted level
Citizen.CreateThread(function()
	local last_wanted = 0
	while true do
		Citizen.Wait(2000)
		if cop then
			ClearPlayerWantedLevel(PlayerId())
			SetPlayerWantedLevelNow(PlayerId(), false)
		end
		local cur_wanted = GetPlayerWantedLevel(PlayerId())
		if cur_wanted ~= last_wanted then
			last_wanted = cur_wanted
			vRPserver.updateWantedLevel({ cur_wanted })
		end
	end
end)

-- HANDCUFF ANIM EVENTS

RegisterNetEvent("vRPpolice-handcuff:Target")
AddEventHandler("vRPpolice-handcuff:Target", function(source)
	local playerPed = GetPlayerPed(-1)
	local targetPed = GetPlayerPed(GetPlayerFromServerId(source))
	loadAnimDict("mp_arrest_paired")
	AttachEntityToEntity(playerPed, targetPed, 11816, -0.1, 0.45, 0.0, 0.0, 0.0, 20.0, false, false, false, false, 20, false)
	TaskPlayAnim(playerPed, "mp_arrest_paired", "crook_p2_back_left", 8.0, -8.0, 5500, 33, 0, false, false, false)
	Citizen.Wait(950)
	DetachEntity(playerPed, true, false)
end)

RegisterNetEvent("vRPpolice-handcuff:Player")
AddEventHandler("vRPpolice-handcuff:Player", function()
	local playerPed = GetPlayerPed(-1)
	loadAnimDict("mp_arrest_paired")
	TaskPlayAnim(playerPed, "mp_arrest_paired", "cop_p2_back_left", 8.0, -8.0, 5500, 33, 0, false, false, false)
end)

RegisterNetEvent("vRPpolice-unhandcuff:Target")
AddEventHandler("vRPpolice-unhandcuff:Target", function(source)
	local playerPed = GetPlayerPed(-1)
	local targetPed = GetPlayerPed(GetPlayerFromServerId(source))
	loadAnimDict("mp_arresting")
	AttachEntityToEntity(playerPed, targetPed, 11816, -0.1, 0.45, 0.0, 0.0, 0.0, 20.0, false, false, false, false, 20, false)
	TaskPlayAnim(playerPed, "mp_arresting", "b_uncuff", 8.0, -8.0, 5500, 33, 0, false, false, false)
	Citizen.Wait(5500)
	DetachEntity(playerPed, true, false)
	ClearPedTasks(playerPed)
end)

RegisterNetEvent("vRPpolice-unhandcuff:Player")
AddEventHandler("vRPpolice-unhandcuff:Player", function()
	local playerPed = GetPlayerPed(-1)
	loadAnimDict("mp_arresting")
	TaskPlayAnim(playerPed, "mp_arresting", "a_uncuff", 8.0, -8.0, 5500, 33, 0, false, false, false)
end)
