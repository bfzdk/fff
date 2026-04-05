local salary = {
	["Rigspolitichef"] = { salary = 50000, perm = "politiledelse.paycheck" },
	["Vicerigspolitichef"] = { salary = 42000, perm = "Vicerigspolitichef.paycheck" },
	["Politidirektør"] = { salary = 40000, perm = "policedirector.paycheck" },
	["Chefpolitiinspektør"] = { salary = 38000, perm = "Chefpolitiinspekteer.paycheck" },
	["Politiinspektør"] = { salary = 36000, perm = "Politiinspekteer.paycheck" },
	["Vicepolitiinspektør"] = { salary = 34000, perm = "Vicepolitiinspekteer.paycheck" },
	["PolitiKommissær"] = { salary = 27000, perm = "PolitiKommisseer.paycheck" },
	["Indsatsleder"] = { salary = 28000, perm = "Indsatsleder.paycheck" },
	["Politiassistent af 1. grad"] = { salary = 25000, perm = "Politiassistent_af_1_grad.paycheck" },
	["Politiassistent"] = { salary = 23500, perm = "Politiassistent.paycheck" },
	["Politibetjent"] = { salary = 17500, perm = "Politibetjent.paycheck" },
	["Politielev"] = { salary = 12000, perm = "Politielev.paycheck" },

	["DBE Chef"] = { salary = 25000, perm = "dbechef.paycheck" },
	["DBE"] = { salary = 20000, perm = "dbe.paycheck" },

	["Dommer"] = { salary = 25000, perm = "dommer.paycheck" },

	["Regionschef"] = { salary = 50000, perm = "regionschef.paycheck" },
	["Viceregionschef"] = { salary = 45000, perm = "viceregionschef.paycheck" },
	["Stationsleder"] = { salary = 40000, perm = "stationsleder.paycheck" },
	["Overlæge"] = { salary = 35000, perm = "overlaege.paycheck" },
	["Paramedeciner"] = { salary = 30000, perm = "paramedeciner.paycheck" },
	["Akutlæge"] = { salary = 25000, perm = "akutlaege.paycheck" },
	["Ambulanceredder"] = { salary = 20000, perm = "ambulanceredder.paycheck" },
	["AmbulanceElev"] = { salary = 15000, perm = "ambulanceelev.paycheck" },

	["Mekaniker Chef"] = { salary = 16500, perm = "mekanikerchef.paycheck" },
	["Mekaniker"] = { salary = 12500, perm = "mekaniker.paycheck" },

	["Advokat Chef"] = { salary = 20000, perm = "advokatchef.paycheck" },
	["Advokat"] = { salary = 27500, perm = "advokat.paycheck" },

	["Sikkerhedsvagt Chef"] = { salary = 15000, perm = "sikkerhedsvagtchef.paycheck" },
	["Sikkerhedsvagt"] = { salary = 13500, perm = "sikkerhedsvagt.paycheck" },

	["Journalist Chef"] = { salary = 12500, perm = "journalistchef.paycheck" },
	["Journalist"] = { salary = 11000, perm = "journalist.paycheck" },

	["Bilforhandler"] = { salary = 12000, perm = "bilforhandler.paycheck" },
	["Auto Genbrug"] = { salary = 25000, perm = "auto.paycheck" },

	["Taxa"] = { salary = 5500, perm = "taxi.paycheck" },

	["Våbendealer"] = { salary = 5500, perm = "weapondealer.paycheck" },

	["Pizzabud"] = { salary = 8000, perm = "delivery.paycheck" },

	["Burgershot Medarbejder"] = { salary = 8000, perm = "burger.paycheck" },

	["Lastbil Chauffør"] = { salary = 8000, perm = "trucker.paycheck" },
	["Psykolog"] = { salary = 17500, perm = "psyko.paycheck" },
	["Miner"] = { salary = 8000, perm = "miner.paycheck" },
	["Arbejdsløs"] = { salary = 6000, perm = "nojob.paycheck" },
	["Devo Vagt Service"] = { salary = 8500, perm = "dvs.paycheck" },
}

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1800000)
		for user_id, source in pairs(vRP.getUsers()) do
			for k, v in pairs(salary) do
				if vRP.hasPermission(user_id, v.perm) then
					local amount = tonumber(v.salary)
					vRP.giveBankMoney(user_id, amount)
					vRP.notify(user_id, "Lønudbetaling: " .. format_thousands(math.floor(amount)) .. " DKK. Erhverv: " .. k .. ".")
					break
				end
			end
		end
	end
end)
