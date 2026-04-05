for k in pairs(cfg.attachments) do
	vRP.defInventoryItem(
		cfg.attachments[k].item,
		cfg.attachments[k].itemName,
		cfg.attachments[k].description,
		function()
			local choice = {}
			choice["> Af / På"] = {
				function(player)
					local user_id = vRP.getUserId(player)
					if user_id ~= nil then
						TriggerClientEvent("V1N_attachments:equipComponent", player, cfg.attachments[k].itemName)
						vRP.closeMenu(player)
					end
				end,
				"Sæt en " .. cfg.attachments[k].itemName:lower() .. " på dit våben",
			}
			return choice
		end,
		cfg.attachments[k].weight
	)
end