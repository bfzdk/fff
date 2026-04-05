Citizen.CreateThread(function()
	while true do
		Citizen.Wait(900000)
		TriggerServerEvent("paycheck:salary")
	end
end)
