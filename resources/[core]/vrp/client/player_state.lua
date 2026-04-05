-- periodic player state update

local state_ready = false

AddEventHandler("playerSpawned", function()
	state_ready = false
	Citizen.CreateThread(function()
		Citizen.Wait(30000)
		state_ready = true
	end)
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(30000)
		if not IsPlayerPlaying(PlayerId()) or not state_ready then goto continue end

		local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))
		vRPserver.ping({})
		vRPserver.updatePos({ x, y, z })
		vRPserver.updateHealth({ vRP.getHealth() })
		vRPserver.updateWeapons({ vRP.getWeapons() })
		vRPserver.updateCustomization({ vRP.getCustomization() })

		::continue::
	end
end)

-- WEAPONS

local weapon_types = {
	"GADGET_PARACHUTE", "WEAPON_ADVANCEDRIFLE", "WEAPON_AIRSTRIKE_ROCKET",
	"WEAPON_APPISTOL", "WEAPON_ASSAULTRIFLE", "WEAPON_ASSAULTRIFLE_MK2",
	"WEAPON_ASSAULTSHOTGUN", "WEAPON_ASSAULTSMG", "WEAPON_AUTOSHOTGUN",
	"WEAPON_BALL", "WEAPON_BAT", "WEAPON_BATTLEAXE", "WEAPON_BOTTLE",
	"WEAPON_BRIEFCASE", "WEAPON_BRIEFCASE_02", "WEAPON_BULLPUPRIFLE",
	"WEAPON_BULLPUPSHOTGUN", "WEAPON_BZGAS", "WEAPON_CARBINERIFLE",
	"WEAPON_CARBINERIFLE_MK2", "WEAPON_COMBATMG", "WEAPON_COMBATMG_MK2",
	"WEAPON_COMBATPDW", "WEAPON_COMBATPISTOL", "WEAPON_COMPACTLAUNCHER",
	"WEAPON_COMPACTRIFLE", "WEAPON_CROWBAR", "WEAPON_DAGGER", "WEAPON_DBSHOTGUN",
	"WEAPON_DIGISCANNER", "WEAPON_FIREEXTINGUISHER", "WEAPON_FIREWORK",
	"WEAPON_FLARE", "WEAPON_FLAREGUN", "WEAPON_FLASHLIGHT", "WEAPON_GOLFCLUB",
	"WEAPON_GRENADE", "WEAPON_GRENADELAUNCHER", "WEAPON_GRENADELAUNCHER_SMOKE",
	"WEAPON_GUSENBERG", "WEAPON_HAMMER", "WEAPON_HATCHET", "WEAPON_HEAVYPISTOL",
	"WEAPON_HEAVYSHOTGUN", "WEAPON_HEAVYSNIPER", "WEAPON_HEAVYSNIPER_MK2",
	"WEAPON_HOMINGLAUNCHER", "WEAPON_KNIFE", "WEAPON_KNUCKLE", "WEAPON_MACHETE",
	"WEAPON_MACHINEPISTOL", "WEAPON_MARKSMANPISTOL", "WEAPON_MARKSMANRIFLE",
	"WEAPON_MG", "WEAPON_MICROSMG", "WEAPON_MINIGUN", "WEAPON_MINISMG",
	"WEAPON_MOLOTOV", "WEAPON_MUSKET", "WEAPON_NIGHTSTICK", "WEAPON_PASSENGER_ROCKET",
	"WEAPON_PETROLCAN", "WEAPON_PIPEBOMB", "WEAPON_PISTOL", "WEAPON_PISTOL_MK2",
	"WEAPON_PISTOL50", "WEAPON_POOLCUE", "WEAPON_PROXMINE", "WEAPON_PUMPSHOTGUN",
	"WEAPON_RAILGUN", "WEAPON_REMOTESNIPER", "WEAPON_REVOLVER", "WEAPON_RPG",
	"WEAPON_SAWNOFFSHOTGUN", "WEAPON_SMG", "WEAPON_SMG_MK2", "WEAPON_SMOKEGRENADE",
	"WEAPON_SNIPERRIFLE", "WEAPON_SNOWBALL", "WEAPON_SNSPISTOL", "WEAPON_SPECIALCARBINE",
	"WEAPON_STICKYBOMB", "WEAPON_STINGER", "WEAPON_STUNGUN", "WEAPON_SWITCHBLADE",
	"WEAPON_VINTAGEPISTOL", "WEAPON_WRENCH",
}

function vRP.getWeaponTypes()
	return weapon_types
end

function vRP.getWeapons()
	local player = GetPlayerPed(-1)
	local ammo_types = {}
	local weapons = {}

	for _, wname in ipairs(weapon_types) do
		local hash = GetHashKey(wname)
		if HasPedGotWeapon(player, hash) then
			local atype = Citizen.InvokeNative(0x7FEAD38B326B9F74, player, hash)
			local ammo = 0
			if ammo_types[atype] == nil then
				ammo_types[atype] = true
				ammo = GetAmmoInPedWeapon(player, hash)
			end
			weapons[wname] = { ammo = ammo }
		end
	end

	return weapons
end

function vRP.replaceWeapons(weapons)
	local old_weapons = vRP.getWeapons()
	vRP.giveWeapons(weapons, true)
	return old_weapons
end

function vRP.giveWeapons(weapons, clear_before)
	local player = GetPlayerPed(-1)
	if clear_before then
		RemoveAllPedWeapons(player, true)
	end
	for wname, weapon in pairs(weapons) do
		GiveWeaponToPed(player, GetHashKey(wname), weapon.ammo or 0, false)
	end
end

function vRP.removeWeapons(weapons)
	local player = GetPlayerPed(-1)
	for wname in pairs(weapons) do
		RemoveWeaponFromPed(player, GetHashKey(wname))
	end
end

-- PLAYER CUSTOMIZATION

local function parse_part(key)
	if type(key) == "string" and string.sub(key, 1, 1) == "p" then
		return true, tonumber(string.sub(key, 2))
	end
	return false, tonumber(key)
end

-- Helper: load model with timeout
local function loadModel(mhash, timeout)
	timeout = timeout or 10000
	local i = 0
	while not HasModelLoaded(mhash) and i < timeout do
		RequestModel(mhash)
		Citizen.Wait(10)
		i = i + 1
	end
	return HasModelLoaded(mhash)
end

function vRP.getDrawables(part)
	local ped = GetPlayerPed(-1)
	local isprop, index = parse_part(part)
	return isprop
		and GetNumberOfPedPropDrawableVariations(ped, index)
		or GetNumberOfPedDrawableVariations(ped, index)
end

function vRP.getDrawableTextures(part, drawable)
	local ped = GetPlayerPed(-1)
	local isprop, index = parse_part(part)
	return isprop
		and GetNumberOfPedPropTextureVariations(ped, index, drawable)
		or GetNumberOfPedTextureVariations(ped, index, drawable)
end

function vRP.getCustomization()
	local ped = GetPlayerPed(-1)
	local custom = { modelhash = GetEntityModel(ped) }

	for i = 0, 20 do
		custom[i] = { GetPedDrawableVariation(ped, i), GetPedTextureVariation(ped, i), GetPedPaletteVariation(ped, i) }
	end
	for i = 0, 10 do
		custom["p" .. i] = { GetPedPropIndex(ped, i), math.max(GetPedPropTextureIndex(ped, i), 0) }
	end

	return custom
end

function vRP.setCustomization(custom)
	local exit = TUNNEL_DELAYED()

	Citizen.CreateThread(function()
		if custom == nil then
			exit({})
			return
		end

		local ped = GetPlayerPed(-1)
		local mhash = custom.modelhash or (custom.model and GetHashKey(custom.model))

		if mhash ~= nil then
			if loadModel(mhash) then
				local weapons = vRP.getWeapons()
				SetPlayerModel(PlayerId(), mhash)
				vRP.giveWeapons(weapons, true)
				SetModelAsNoLongerNeeded(mhash)
			end
		end

		ped = GetPlayerPed(-1)

		for k, v in pairs(custom) do
			if k ~= "model" and k ~= "modelhash" then
				local isprop, index = parse_part(k)
				if isprop then
					if v[1] < 0 then
						ClearPedProp(ped, index)
					else
						SetPedPropIndex(ped, index, v[1], v[2], v[3] or 2)
					end
				else
					SetPedComponentVariation(ped, index, v[1], v[2], v[3] or 2)
				end
			end
		end

		exit({})
	end)
end
