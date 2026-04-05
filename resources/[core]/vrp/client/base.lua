local Tunnel = vRP.module("vrp/lib/Tunnel")

cfg = vRP.module("cfg/client")

vRPserver = Tunnel.getInterface("vRP", "vRP")

local players = {} -- keep track of connected players (server id)

-- functions
function vRP.teleport(x, y, z)
	vRP.unjail() -- force unjail before a teleportation
	SetEntityCoords(GetPlayerPed(-1), x + 0.0001, y + 0.0001, z + 0.0001, true, false, false, true)
	vRPserver.updatePos({ x, y, z })
end

-- return x,y,z
function vRP.getPosition()
	local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))
	return x, y, z
end

-- return false if in exterior, true if inside a building
function vRP.isInside()
	local x, y, z = vRP.getPosition()
	return not (GetInteriorAtCoords(x, y, z) == 0)
end

-- return vx,vy,vz
function vRP.getSpeed()
	local vx, vy, vz = table.unpack(GetEntityVelocity(GetPlayerPed(-1)))
	return math.sqrt(vx * vx + vy * vy + vz * vz)
end

function vRP.getCamDirection()
	local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(GetPlayerPed(-1))
	local pitch = GetGameplayCamRelativePitch()

	local x = -math.sin(heading * math.pi / 180.0)
	local y = math.cos(heading * math.pi / 180.0)
	local z = math.sin(pitch * math.pi / 180.0)

	-- normalize
	local len = math.sqrt(x * x + y * y + z * z)
	if len ~= 0 then
		x = x / len
		y = y / len
		z = z / len
	end

	return x, y, z
end

function vRP.addPlayer(player)
	players[player] = true
end

function vRP.removePlayer(player)
	players[player] = nil
end

function vRP.getNearestPlayers(radius)
	local r = {}

	local pid = PlayerId()
	local px, py, pz = vRP.getPosition()

	for k, v in pairs(players) do
		local player = GetPlayerFromServerId(k)

		if v and player ~= pid and NetworkIsPlayerConnected(player) then
			local oped = GetPlayerPed(player)
			local x, y, z = table.unpack(GetEntityCoords(oped, true))
			local distance = GetDistanceBetweenCoords(x, y, z, px, py, pz, true)
			if distance <= radius then
				r[GetPlayerServerId(player)] = distance
			end
		end
	end

	return r
end

function vRP.getNearestPlayer(radius)
	local p = nil

	local players = vRP.getNearestPlayers(radius)
	local min = radius + 10.0
	for k, v in pairs(players) do
		if v < min then
			min = v
			p = k
		end
	end

	return p
end

function vRP.notify(msg)
	msg = string.gsub(msg, "~r~", "")
	msg = string.gsub(msg, "~g~", "")
	msg = string.gsub(msg, "~b~", "")
	msg = string.gsub(msg, "~s~", "")
	msg = string.gsub(msg, "~o~", "")
	msg = string.gsub(msg, "~n~", "")
	msg = string.gsub(msg, "~b~", "")
	msg = string.gsub(msg, "~y~", "")

	TriggerEvent("pNotify:SendNotification", {
		text = msg,
		type = "info",
		timeout = 3000,
		layout = "centerRight",
		theme = "gta",
	})
end

-- play a screen effect
-- name, see https://wiki.fivem.net/wiki/Screen_Effects
-- duration: in seconds, if -1, will play until stopScreenEffect is called
function vRP.playScreenEffect(name, duration)
	if duration < 0 then -- loop
		StartScreenEffect(name, 0, true)
	else
		StartScreenEffect(name, 0, true)

		Citizen.CreateThread(function() -- force stop the screen effect after duration+1 seconds
			Citizen.Wait(math.floor((duration + 1) * 1000))
			StopScreenEffect(name)
		end)
	end
end

-- stop a screen effect
-- name, see https://wiki.fivem.net/wiki/Screen_Effects
function vRP.stopScreenEffect(name)
	StopScreenEffect(name)
end

-- ANIM

-- animations dict and names: http://docs.ragepluginhook.net/html/62951c37-a440-478c-b389-c471230ddfc5.htm

local anims = {}
local anim_ids = Tools.newIDGenerator()

-- play animation (new version)
-- upper: true, only upper body, false, full animation
-- seq: list of animations as {dict,anim_name,loops} (loops is the number of loops, default 1) or a task def (properties: task, play_exit)
-- looping: if true, will infinitely loop the first element of the sequence until stopAnim is called
function vRP.playAnim(upper, seq, looping)
	if seq.task ~= nil then -- is a task (cf https://github.com/ImagicTheCat/vRP/pull/118)
		vRP.stopAnim(true)

		local ped = GetPlayerPed(-1)
		if seq.task == "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER" then -- special case, sit in a chair
			local x, y, z = vRP.getPosition()
			TaskStartScenarioAtPosition(ped, seq.task, x, y, z - 1, GetEntityHeading(ped), 0, false, false)
		else
			TaskStartScenarioInPlace(ped, seq.task, 0, not seq.play_exit)
		end
	else -- a regular animation sequence
		vRP.stopAnim(upper)

		local flags = 0
		if upper then
			flags = flags + 48
		end
		if looping then
			flags = flags + 1
		end

		Citizen.CreateThread(function()
			-- prepare unique id to stop sequence when needed
			local id = anim_ids:gen()
			anims[id] = true

			for k, v in pairs(seq) do
				local dict = v[1]
				local name = v[2]
				local loops = v[3] or 1

				for i = 1, loops do
					if anims[id] then -- check animation working
						local first = (k == 1 and i == 1)
						local last = (k == #seq and i == loops)

						-- request anim dict
						RequestAnimDict(dict)
						local i = 0
						while not HasAnimDictLoaded(dict) and i < 1000 do -- max time, 10 seconds
							Citizen.Wait(10)
							RequestAnimDict(dict)
							i = i + 1
						end

						-- play anim
						if HasAnimDictLoaded(dict) and anims[id] then
							local inspeed = 8.0001
							local outspeed = -8.0001
							if not first then
								inspeed = 2.0001
							end
							if not last then
								outspeed = 2.0001
							end

							TaskPlayAnim(GetPlayerPed(-1), dict, name, inspeed, outspeed, -1, flags, 0, false, false, false)
						end

						Citizen.Wait(0)
						while
							GetEntityAnimCurrentTime(GetPlayerPed(-1), dict, name) <= 0.95
							and IsEntityPlayingAnim(GetPlayerPed(-1), dict, name, 3)
							and anims[id]
						do
							Citizen.Wait(0)
						end
					end
				end
			end

			-- free id
			anim_ids:free(id)
			anims[id] = nil
		end)
	end
end

-- stop animation (new version)
-- upper: true, stop the upper animation, false, stop full animations
function vRP.stopAnim(upper)
	anims = {} -- stop all sequences
	if upper then
		ClearPedSecondaryTask(GetPlayerPed(-1))
	else
		ClearPedTasks(GetPlayerPed(-1))
	end
end

-- SOUND
-- some lists:
-- pastebin.com/A8Ny8AHZ
-- https://wiki.gtanet.work/index.php?title=FrontEndSoundlist

-- play sound at a specific position
function vRP.playSpatializedSound(dict, name, x, y, z, range)
	PlaySoundFromCoord(-1, name, x + 0.0001, y + 0.0001, z + 0.0001, dict, false, range + 0.0001, false)
end

-- play sound
function vRP.playSound(dict, name)
	PlaySound(-1, name, dict, false, false, true)
end

-- events

AddEventHandler("playerSpawned", function()
	TriggerServerEvent("vRPcli:playerSpawned")
end)

AddEventHandler("onPlayerDied", function(player, reason)
	TriggerServerEvent("vRPcli:playerDied")
end)

AddEventHandler("onPlayerKilled", function(player, killer, reason)
	TriggerServerEvent("vRPcli:playerDied")
end)

-- voice proximity computation
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(500)
		local ped = GetPlayerPed(-1)
		local proximity = cfg.voice_proximity

		if IsPedSittingInAnyVehicle(ped) then
			local veh = GetVehiclePedIsIn(ped, false)
			local hash = GetEntityModel(veh)
			-- make open vehicles (bike,etc) use the default proximity
			if IsThisModelACar(hash) or IsThisModelAHeli(hash) or IsThisModelAPlane(hash) then
				proximity = cfg.voice_proximity_vehicle
			end
		elseif vRP.isInside() then
			proximity = cfg.voice_proximity_inside
		end

		NetworkSetTalkerProximity(proximity + 0.0001)
	end
end)
