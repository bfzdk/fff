local cfg = vRP.module("cfg/survival")
local lang = vRP.lang

-- api
function vRP.getHunger(user_id)
	local data = vRP.getUserDataTable(user_id)
	return data and data.hunger or 0
end

function vRP.getThirst(user_id)
	local data = vRP.getUserDataTable(user_id)
	return data and data.thirst or 0
end

-- Helper: clamp and update progress bar
local function clampAndNotify(user_id, key, value)
	if value < 0 then value = 0
	elseif value > 100 then value = 100 end

	local source = vRP.getUserSource(user_id)
	if source then
		vRPclient.setProgressBarValue(source, { key, value })
	end
	return value
end

function vRP.setHunger(user_id, value)
	local data = vRP.getUserDataTable(user_id)
	if data then
		data.hunger = clampAndNotify(user_id, "hunger", value)
	end
end

function vRP.setThirst(user_id, value)
	local data = vRP.getUserDataTable(user_id)
	if data then
		data.thirst = clampAndNotify(user_id, "thirst", value)
	end
end

-- Helper: vary survival stat
local function varyStat(user_id, stat, variation, bar_text)
	local data = vRP.getUserDataTable(user_id)
	if not data then return end

	data[stat] = data[stat] + variation
	local overflow = data[stat] - 100
	if overflow > 0 then
		vRPclient.varyHealth(vRP.getUserSource(user_id), { -overflow * cfg.overflow_damage_factor })
	end

	data[stat] = (data[stat] < 0) and 0 or (data[stat] > 100 and 100 or data[stat])

	local source = vRP.getUserSource(user_id)
	if source then
		vRPclient.setProgressBarText(source, { bar_text, data[stat] })
	end
end

function vRP.varyHunger(user_id, variation)
	varyStat(user_id, "hunger", variation, "hunger")
end

function vRP.varyThirst(user_id, variation)
	varyStat(user_id, "thirst", variation, "thirst")
end

-- tunnel api
function tvRP.varyHunger(variation)
	local user_id = vRP.getUserId(source)
	if user_id then vRP.varyHunger(user_id, variation) end
end

function tvRP.varyThirst(variation)
	local user_id = vRP.getUserId(source)
	if user_id then vRP.varyThirst(user_id, variation) end
end

-- tasks
function task_update()
	for _, user_id in pairs(vRP.users) do
		vRP.varyHunger(user_id, cfg.hunger_per_minute)
		vRP.varyThirst(user_id, cfg.thirst_per_minute)
	end
	SetTimeout(60000, task_update)
end
task_update()

-- handlers
AddEventHandler("vRP:playerJoin", function(user_id, source, name, last_login)
	local data = vRP.getUserDataTable(user_id)
	if data.hunger == nil then
		data.hunger = 0
		data.thirst = 0
	end
end)

-- add survival progress bars on spawn
AddEventHandler("vRP:playerSpawn", function(user_id, source, first_spawn)
	local data = vRP.getUserDataTable(user_id)
	vRPclient.setPolice(source, { cfg.police })
	vRPclient.setFriendlyFire(source, { cfg.pvp })

	vRPclient.setProgressBar(source, { "vRP:hunger", "minimap", htxt, 255, 153, 0, 0 })
	vRPclient.setProgressBar(source, { "vRP:thirst", "minimap", ttxt, 0, 125, 255, 0 })
	vRP.setHunger(user_id, data.hunger)
	vRP.setThirst(user_id, data.thirst)
end)

-- EMERGENCY
local revive_seq = {
	{ "amb@medic@standing@tendtodead@enter", "enter", 1 },
	{ "amb@medic@standing@tendtodead@idle_a", "idle_a", 1 },
	{ "amb@medic@standing@tendtodead@exit", "exit", 1 },
}

local choice_revive = {
	function(player, choice)
		local user_id = vRP.getUserId(player)
		if user_id == nil then return end

		vRPclient.getNearestPlayer(player, { 10 }, function(nplayer)
			if nplayer == nil then
				vRP.notify(user_id, "Ingen spiller nær dig!")
				return
			end

			local nuser_id = vRP.getUserId(nplayer)
			if nuser_id == nil then
				vRP.notify(user_id, "Ingen spiller nær dig!")
				return
			end

			vRPclient.isInComa(nplayer, {}, function(in_coma)
				if not in_coma then
					vRP.notify(user_id, "Ikke i koma!")
					return
				end
				if vRP.tryGetInventoryItem(user_id, "medkit", 1, true) then
					vRPclient.playAnim(player, { false, revive_seq, false })
					SetTimeout(15000, function()
						vRPclient.varyHealth(nplayer, { 50 })
					end)
				end
			end)
		end)
	end,
	lang.emergency.menu.revive.description(),
}

vRP.registerMenuBuilder("main", function(add, data)
	local user_id = vRP.getUserId(data.player)
	if user_id == nil then return end

	local choices = {}
	if vRP.hasPermission(user_id, "emergency.revive") then
		choices[lang.emergency.menu.revive.title()] = choice_revive
	end
	add(choices)
end)
