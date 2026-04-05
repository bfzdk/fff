local vRP = exports["vrp"]:getvRP()

RegisterNetEvent("V1N_attachments:equipComponent", function(item)
	local components = cfg.attachments[item].components
	for _, v in pairs(components) do
		local hashKey = GetSelectedPedWeapon(GetPlayerPed(-1))
		if DoesWeaponTakeWeaponComponent(hashKey, GetHashKey(v)) then
			if not HasPedGotWeaponComponent(GetPlayerPed(-1), hashKey, GetHashKey(v)) then
				GiveWeaponComponentToPed(PlayerPedId(), hashKey, GetHashKey(v))
				vRP.notify(cfg.equip_text:format(item:lower()))
			else
				RemoveWeaponComponentFromPed(PlayerPedId(), hashKey, GetHashKey(v))
				vRP.notify(cfg.remove_text:format(item:lower()))
			end

			return
		end
	end

	vRP.notify({ "Du kan ikke sætte et " .. item:lower() .. " på dette våben!" })
end)