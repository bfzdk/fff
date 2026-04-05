local Tunnel = vRP.module("lib/Tunnel")
local Lang = vRP.module("lib/Lang")

local config = vRP.module("cfg/base")

tvRP = Tunnel.createInterface("vRP")

-- load language
vRP.lang = Lang.new(vRP.module("cfg/lang/da"))

-- init
vRPclient = Tunnel.getInterface("vRP", "vRP") -- server -> client tunnel

vRP.users = {} -- will store logged users (id) by first identifier
vRP.rusers = {} -- store the opposite of users
vRP.user_tables = {} -- user data tables (logger storage, saved to database)
vRP.user_tmp_tables = {} -- user tmp data tables (logger storage, not saved)
vRP.user_sources = {} -- user sources

-- Helper: check if an identifier should be processed
local function isValidIdentifier(id)
	if config.ignore_ip_identifier and string.find(id, "ip:") then return false end
	if config.ignore_license_identifier and string.find(id, "license:") then return false end
	if config.ignore_xbox_identifier and string.find(id, "xbl:") then return false end
	if config.ignore_discord_identifier and string.find(id, "discord:") then return false end
	if config.ignore_live_identifier and string.find(id, "live:") then return false end
	return true
end

-- Helper: insert identifiers for a user
local function insertUserIdentifiers(user_id, identifiers)
	for _, identifier in ipairs(identifiers) do
		if isValidIdentifier(identifier) then
			MySQL.Async.execute(
				"INSERT INTO vrp_user_ids (identifier,user_id) VALUES(@identifier,@user_id)",
				{ user_id = user_id, identifier = identifier }
			)
		end
	end
end

function vRP.getUserIdByIdentifiers(ids, cbr)
	local task = Task(cbr)
	if ids == nil or #ids == 0 then
		task()
		return
	end

	local i = 0
	local valid_count = 0

	local function search()
		i = i + 1
		if i > #ids then
			-- No matching identifier found, create new user
			if valid_count == 0 then
				task()
				return
			end

			MySQL.Async.fetchAll("SELECT MAX(user_id) AS id FROM vrp_user_ids", {}, function(result)
				local next_id = (result[1].id == nil) and 1 or result[1].id + 1

				MySQL.Async.execute(
					"INSERT INTO vrp_users (id, whitelisted, banned) VALUES (@id, 0, 0)",
					{ id = next_id },
					function(rows, affected)
						if next_id then
							insertUserIdentifiers(next_id, ids)
							task({ next_id })
						else
							task()
						end
					end
				)
			end)
			return
		end

		if isValidIdentifier(ids[i]) then
			valid_count = valid_count + 1
			MySQL.Async.fetchAll(
				"SELECT user_id FROM vrp_user_ids WHERE identifier = @identifier",
				{ identifier = ids[i] },
				function(rows, affected)
					if #rows > 0 then
						task({ rows[1].user_id })
					else
						search()
					end
				end
			)
		else
			search()
		end
	end

	search()
end

function vRP.getSourceIdKey(source)
	local ids = GetPlayerIdentifiers(source)
	local idk = "idk_"
	for _, v in pairs(ids) do
		idk = idk .. v
	end
	return idk
end

function vRP.getPlayerEndpoint(player)
	return GetPlayerEndpoint(player) or 'No endpoint found'
end

-- Helper: async fetch single row
local function fetchSingle(query, params, cbr, default)
	local task = Task(cbr, default)
	MySQL.Async.fetchAll(query, params, function(rows)
		task(#rows > 0 and { rows[1] } or nil)
	end)
end

function vRP.getUserData(user_id, cbr)
	fetchSingle("SELECT * FROM vrp_users WHERE id = @user_id", { user_id = user_id }, cbr, { false })
end

function vRP.isBanned(user_id, cbr)
	fetchSingle("SELECT banned FROM vrp_users WHERE id = @user_id", { user_id = user_id }, function(rows)
		cbr(rows and rows[1].banned or false)
	end, { false })
end

function vRP.getBannedReason(user_id, cbr)
	fetchSingle("SELECT ban_reason FROM vrp_users WHERE id = @user_id", { user_id = user_id }, function(rows)
		cbr(rows and rows[1].ban_reason or nil)
	end, { false })
end

function vRP.setBanned(user_id, banned)
	if banned ~= false then
		MySQL.Async.execute(
			"UPDATE vrp_users SET banned = @banned, ban_reason = @reason WHERE id = @user_id",
			{ user_id = user_id, reason = banned, banned = 1 }
		)
	else
		MySQL.Async.execute("UPDATE vrp_users SET banned = @banned WHERE id = @user_id", { user_id = user_id, banned = 0 })
	end
end

function vRP.isWhitelisted(user_id, cbr)
	fetchSingle("SELECT whitelisted FROM vrp_users WHERE id = @user_id", { user_id = user_id }, function(rows)
		cbr(rows and rows[1].whitelisted or false)
	end, { false })
end

function vRP.setWhitelisted(user_id, whitelisted)
	MySQL.Async.execute(
		"UPDATE vrp_users SET whitelisted = @whitelisted WHERE id = @user_id",
		{ user_id = user_id, whitelisted = whitelisted }
	)
end

function vRP.getLastLogin(user_id, cbr)
	fetchSingle("SELECT last_login FROM vrp_users WHERE id = @user_id", { user_id = user_id }, function(rows)
		cbr(rows and rows[1].last_login or "")
	end, { "" })
end

function vRP.getPlayerName(player)
	return GetPlayerName(player) or "INTET STEAMNAVN FUNDET"
end

function vRP.setUData(user_id, key, value)
	MySQL.Async.execute(
		"REPLACE INTO vrp_user_data(user_id,dkey,dvalue) VALUES(@user_id,@key,@value)",
		{ user_id = user_id, key = key, value = value }
	)
end

function vRP.getUData(user_id, key, cbr)
	local task = Task(cbr, { "" })

	MySQL.Async.fetchAll(
		"SELECT dvalue FROM vrp_user_data WHERE user_id = @user_id AND dkey = @key",
		{ user_id = user_id, key = key },
		function(rows, affected)
			if #rows > 0 then
				task({ rows[1].dvalue })
			else
				task()
			end
		end
	)
end

function vRP.setSData(key, value)
	MySQL.Async.execute("REPLACE INTO vrp_srv_data(dkey,dvalue) VALUES(@key,@value)", { key = key, value = value })
end

function vRP.getSData(key, cbr)
	local task = Task(cbr, { "" })

	MySQL.Async.fetchAll("SELECT dvalue FROM vrp_srv_data WHERE dkey = @key", { key = key }, function(rows, affected)
		if #rows > 0 then
			task({ rows[1].dvalue })
		else
			task()
		end
	end)
end

function vRP.getUserDataTable(user_id)
	return vRP.user_tables[user_id]
end

function vRP.getUserTmpTable(user_id)
	return vRP.user_tmp_tables[user_id]
end

function vRP.isConnected(user_id)
	return vRP.rusers[user_id] ~= nil
end

function vRP.isFirstSpawn(user_id)
	local tmp = vRP.getUserTmpTable(user_id)
	return tmp and tmp.spawns == 1
end

function vRP.getUserId(source)
	if source ~= nil then
		local ids = GetPlayerIdentifiers(source)
		if ids ~= nil and #ids > 0 then
			return vRP.users[ids[1]]
		end
	end
	return nil
end

function vRP.getUsers()
	local users = {}
	for k, v in pairs(vRP.user_sources) do
		users[k] = v
	end
	return users
end

function vRP.getUserSource(user_id)
	return vRP.user_sources[user_id]
end

function vRP.notify(user_id, msg)
	vRPclient.notify(vRP.getUserSource(user_id), msg)
end

function vRP.ban(user_id, reason)
	if user_id ~= nil then
		local player = vRP.getUserSource(user_id)
		vRP.setBanned(user_id, reason)
		if player ~= nil then
			vRP.kick(player, "[Udelukket] " .. reason)
		end
	end
end

function vRP.kick(source, reason)
	DropPlayer(source, reason)
end

-- tasks

function task_save_datatables()
	TriggerEvent("vRP:save")

	for k, v in pairs(vRP.user_tables) do
		vRP.setUData(k, "vRP:datatable", json.encode(v))
		TriggerEvent("htn_logging:saveUser", k)
	end

	SetTimeout(config.save_interval * 1000, task_save_datatables)
end
task_save_datatables()

local max_pings = math.ceil(config.ping_timeout * 120 / 60) + 2
function task_timeout() -- kick users not sending ping event in 3 minutes
	local users = vRP.getUsers()
	for k, v in pairs(users) do
		local tmpdata = vRP.getUserTmpTable(tonumber(k))
		if tmpdata.pings == nil then
			tmpdata.pings = 0
		end

		tmpdata.pings = tmpdata.pings + 1
		if tmpdata.pings >= max_pings then
			vRP.kick(v, "[FlaxHosting] Ping Timeout - Intet client svar i 3 minutter.")
		end
	end

	SetTimeout(60000, task_timeout)
end
task_timeout()

function tvRP.ping()
	local user_id = vRP.getUserId(source)
	if user_id ~= nil then
		local tmpdata = vRP.getUserTmpTable(user_id)
		tmpdata.pings = 0 -- reinit ping countdown
	end
end

-- handlers
local isStopped = false
function vRP.getServerStatus()
	return isStopped
end

function vRP.setServerStatus(reason)
	isStopped = reason
end

local antispam = {}

-- Helper: initialize a new user session
local function initUserSession(user_id, source, ids, name, deferrals)
	vRP.users[ids[1]] = user_id
	vRP.rusers[user_id] = ids[1]
	vRP.user_tables[user_id] = {}
	vRP.user_tmp_tables[user_id] = {}
	vRP.user_sources[user_id] = source

	deferrals.update("[FlaxHosting] Indlæser karakter.")
	vRP.getUData(user_id, "vRP:datatable", function(sdata)
		local data = json.decode(sdata)
		if type(data) == "table" then
			vRP.user_tables[user_id] = data
		end

		local tmpdata = vRP.getUserTmpTable(user_id)
		deferrals.update("[FlaxHosting] Indlæser karakter..")

		vRP.getLastLogin(user_id, function(last_login)
			tmpdata.last_login = last_login or ""
			tmpdata.spawns = 0

			local ep = vRP.getPlayerEndpoint(source)
			local last_login_stamp = ep .. " " .. os.date("%H:%M:%S %d/%m/%Y")

			MySQL.Async.execute(
				"UPDATE vrp_users SET last_login = @last_login WHERE id = @user_id",
				{ user_id = user_id, last_login = last_login_stamp }
			)

			print("[" .. user_id .. "] Forbinder til serveren")
			TriggerEvent("vRP:playerJoin", user_id, source, name, tmpdata.last_login)
			deferrals.done()
		end)
	end)
end

-- Helper: handle rejoin
local function handleRejoin(user_id, source, name, deferrals)
	print("[" .. user_id .. "] Rejoinede serveren")
	TriggerEvent("vRP:playerRejoin", user_id, source, name)

	local tmpdata = vRP.getUserTmpTable(user_id)
	tmpdata.spawns = 0
	deferrals.done()
end

-- Helper: reject connection
local function rejectConnection(name, source, reason, message)
	print("[" .. name .. "] " .. reason)
	deferrals.done(message)
end

AddEventHandler("playerConnecting", function(name, setMessage, deferrals)
	deferrals.defer()

	local source = source

	if isStopped ~= false then
		rejectConnection(
			name, source,
			"blev kicket for at joine imens serveren er igang med at " .. isStopped,
			"Serveren er igang med at " .. isStopped
		)
		return
	end

	local ids = GetPlayerIdentifiers(source)
	if antispam[ids and ids[1]] ~= nil then
		rejectConnection(
			name, source,
			"Forsøgte at joine for hurtigt igen",
			"Du prøvet at joine for hurtigt prøv igen om [" .. antispam[ids[1]] .. "] sekunder!"
		)
		return
	end

	if ids == nil or #ids == 0 then
		rejectConnection(
			name, source,
			"Afvist ingen identifiers fundet",
			"[FlaxHosting]: Serveren kunne ikke finde nogen identifiers tjek om du har steam åbent"
		)
		return
	end

	deferrals.update("[FlaxHosting] Indlæser karakter.")

	vRP.getUserIdByIdentifiers(ids, function(user_id)
		if user_id == nil then
			rejectConnection(
				name, source,
				"Afvist kunne ikke finde user_id",
				"[FlaxHosting]: Serveren kunne ikke finde dit ID kontakt venligst en fra developer teamet"
			)
			return
		end

		deferrals.update("[FlaxHosting] Indlæser karakter..")

		vRP.getUserData(user_id, function(userdata)
			if userdata.banned then
				local ban_reason = (type(userdata.ban_reason) == "table") and "Ingen grund sat" or userdata.ban_reason
				print("[" .. user_id .. "] Forsøgte og joine men er bandlyst med grunden (" .. ban_reason .. ")")
				rejectConnection(
					name, source,
					"Forsøgte og joine men er bandlyst med grunden (" .. ban_reason .. ")",
					"[FlaxHosting]: Du er bannet for: " .. ban_reason .. " [" .. user_id .. "]."
				)
				return
			end

			if config.whitelist and not userdata.whitelisted then
				print("[" .. user_id .. "]: Forsøgte og joine men er ikke whitelistet")
				rejectConnection(
					name, source,
					"Forsøgte og joine men er ikke whitelistet",
					"[FlaxHosting] Ikke whitelisted ansøg på Discord.gg/P7bj3ZXu [" .. user_id .. "]."
				)
				return
			end

			if vRP.rusers[user_id] == nil then
				initUserSession(user_id, source, ids, name, deferrals)
			else
				handleRejoin(user_id, source, name, deferrals)
			end
		end)
	end)
end)

CreateThread(function()
	while true do
		Wait(1000)
		for k, v in pairs(antispam) do
			if tonumber(v) > 1 then
				antispam[k] = tonumber(v) - 1
			else
				antispam[k] = nil
			end
		end
	end
end)

AddEventHandler("playerDropped", function(reason)
	local source = source

	vRPclient.removePlayer(-1, { source })

	local user_id = vRP.getUserId(source)

	if user_id ~= nil then
		TriggerEvent("vRP:playerLeave", user_id, source)

		-- save user data table
		vRP.setUData(user_id, "vRP:datatable", json.encode(vRP.getUserDataTable(user_id)))

		print("[" .. user_id .. "] Forlod serveren")
		vRP.users[vRP.rusers[user_id]] = nil
		vRP.rusers[user_id] = nil
		vRP.user_tables[user_id] = nil
		vRP.user_tmp_tables[user_id] = nil
		vRP.user_sources[user_id] = nil
	end
end)

RegisterServerEvent("vRPcli:playerSpawned")
AddEventHandler("vRPcli:playerSpawned", function()
	local user_id = vRP.getUserId(source)
	local player = source

	if user_id ~= nil then
		vRP.user_sources[user_id] = source
		local tmp = vRP.getUserTmpTable(user_id)
		tmp.spawns = tmp.spawns + 1
		local first_spawn = (tmp.spawns == 1)

		if first_spawn then
			for k, v in pairs(vRP.user_sources) do
				vRPclient.addPlayer(source, { v })
			end

			-- send new player to all players
			vRPclient.addPlayer(-1, { source })
		end

		Tunnel.setDestDelay(player, config.load_delay)

		SetTimeout(2000, function() -- trigger spawn event
			TriggerEvent("vRP:playerSpawn", user_id, player, first_spawn)
			TriggerClientEvent("dn_carplacer:place", player)
			SetTimeout(config.load_duration * 1000, function() -- set client delay to normal delay
				Tunnel.setDestDelay(player, config.global_delay)
				vRPclient.removeProgressBar(player, { "vRP:loading" })
				TriggerClientEvent("movebitch", player)
			end)
		end)
	end
end)

RegisterServerEvent("vRP:playerDied")