local vRPc = {}
Tunnel.bindInterface(GetCurrentResourceName(), vRPc)

local open = cfg.start

vRPc.updateHud = function(data)
	SendNUIMessage({
		type = data.type,
		wallet = data.wallet,
		bank = data.bank,
		dirty_money = data.dirty_money,
		job = data.job,
		id = data.id,
	})
end

Citizen.CreateThread(function()
	while true do
		if open then
			TriggerServerEvent("V1N_InformationHUD:updateHud")
		end
		Citizen.Wait(2500)
	end
end)

RegisterCommand(cfg.command, function(source, args, rawCommand)
	if open then
		open = false
		SendNUIMessage({
			type = "close",
		})
	else
		TriggerServerEvent("V1N_InformationHUD:updateHud")
		open = true
	end
end)

--==Variables==--
local open = cfg.start
--===================================--

--==Functions==--
vRPc.updateHud = function(data)
	SendNUIMessage({
		type = data.type,
		wallet = data.wallet,
		bank = data.bank,
		dirty_money = data.dirty_money,
		job = data.job,
		id = data.id,
	})
end
--===================================--

--==Threads==--
Citizen.CreateThread(function()
	while true do
		if open then
			TriggerServerEvent("V1N_InformationHUD:updateHud")
		end
		Citizen.Wait(2500)
	end
end)
--===================================--

--==Commands==--
RegisterCommand(cfg.command, function(source, args, rawCommand)
	if open then
		open = not open
		SendNUIMessage({
			type = "close",
		})
	else
		TriggerServerEvent("V1N_InformationHUD:updateHud")
		open = not open
	end
end)
--===================================--
