local cfg = vRP.module("cfg/player_state")
local lang = vRP.lang

-- Helper: generate random spawn position
local function randomSpawnPos()
	local x = cfg.spawn_position[1] + math.random() * cfg.spawn_radius * 2 - cfg.spawn_radius
	local y = cfg.spawn_position[2] + math.random() * cfg.spawn_radius * 2 - cfg.spawn_radius
	local z = cfg.spawn_position[3] + math.random() * cfg.spawn_radius * 2 - cfg.spawn_radius
	return { x = x, y = y, z = z }
end

-- Helper: load weapons and health
local function loadWeaponsAndHealth(source, data)
	if data.weapons == nil then return end
	vRPclient.giveWeapons(source, { data.weapons, true })
	if data.health ~= nil then
		vRPclient.setHealth(source, { data.health })
	end
end

-- client -> server events
AddEventHandler("vRP:playerSpawn", function(user_id, source, first_spawn)
	local data = vRP.getUserDataTable(user_id)
	local tmpdata = vRP.getUserTmpTable(user_id)

	if first_spawn then
		if data.customization == nil then
			data.customization = cfg.default_customization
		end
		if data.position == nil and cfg.spawn_enabled then
			data.position = randomSpawnPos()
		end

		if data.position ~= nil then
			vRPclient.teleport(source, { data.position.x, data.position.y, data.position.z })
		end

		if data.customization ~= nil then
			vRPclient.setCustomization(source, { data.customization }, function()
				loadWeaponsAndHealth(source, data)
			end)
		else
			loadWeaponsAndHealth(source, data)
		end

		SetTimeout(35000, function()
			vRP.notify(source, lang.common.welcome({ tmpdata.last_login }))
		end)
	else
		vRP.setHunger(user_id, 0)
		vRP.setThirst(user_id, 0)
		vRP.clearInventory(user_id)

		if cfg.lose_aptitudes_on_death then
			data.gaptitudes.physical = {}
		end

		vRP.setMoney(user_id, 0)
		vRPclient.setHandcuffed(source, { false })

		if cfg.spawn_enabled then
			data.position = randomSpawnPos()
			vRPclient.teleport(source, { data.position.x, data.position.y, data.position.z })
		end

		if data.customization ~= nil then
			vRPclient.setCustomization(source, { data.customization })
		end
	end
end)

-- death, clear position and weapons
AddEventHandler("vRP:playerDied", function()
	local user_id = vRP.getUserId(source)
	if user_id == nil then return end

	local data = vRP.getUserDataTable(user_id)
	local tmp = vRP.getUserTmpTable(user_id)
	if data ~= nil and (tmp == nil or tmp.home_stype == nil) then
		data.position = nil
		data.weapons = nil
	end
end)

-- updates
function tvRP.updatePos(x, y, z)
	local user_id = vRP.getUserId(source)
	if user_id == nil then return end

	local data = vRP.getUserDataTable(user_id)
	local tmp = vRP.getUserTmpTable(user_id)
	if data ~= nil and (tmp == nil or tmp.home_stype == nil) then
		data.position = { x = tonumber(x), y = tonumber(y), z = tonumber(z) }
	end
end

function tvRP.updateWeapons(weapons)
	local user_id = vRP.getUserId(source)
	if user_id == nil then return end
	local data = vRP.getUserDataTable(user_id)
	if data then data.weapons = weapons end
end

function tvRP.updateCustomization(customization)
	local user_id = vRP.getUserId(source)
	if user_id == nil then return end
	local data = vRP.getUserDataTable(user_id)
	if data then data.customization = customization end
end

function tvRP.updateHealth(health)
	local user_id = vRP.getUserId(source)
	if user_id == nil then return end
	local data = vRP.getUserDataTable(user_id)
	if data then data.health = health end
end
