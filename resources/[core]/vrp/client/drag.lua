-- Standalone drag system (only use if police.lua drag is not active)
-- This file conflicts with police.lua drag system - do NOT load both

local drag_state = {
	other = nil,
	active = false,
	playerAttached = false,
}

RegisterNetEvent("dr:drag")
AddEventHandler("dr:drag", function(pl)
	drag_state.other = pl
	drag_state.active = not drag_state.active
end)

RegisterNetEvent("dr:undrag")
AddEventHandler("dr:undrag", function()
	drag_state.active = false
	if drag_state.playerAttached then
		DetachEntity(GetPlayerPed(-1), true, false)
		drag_state.playerAttached = false
	end
end)

Citizen.CreateThread(function()
	while true do
		if drag_state.active and drag_state.other ~= nil then
			local ped = GetPlayerPed(GetPlayerFromServerId(drag_state.other))
			local myped = GetPlayerPed(-1)
			AttachEntityToEntity(myped, ped, 4103, 11816, 0.54, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
			drag_state.playerAttached = true
		elseif drag_state.playerAttached then
			DetachEntity(GetPlayerPed(-1), true, false)
			drag_state.playerAttached = false
		end
		Citizen.Wait(0)
	end
end)
