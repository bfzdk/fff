-- this vRP.module describe the group/permission system

-- group functions are used on connected players only
-- multiple groups can be set to the same player, but the gtype config option can be used to set some groups as unique

-- api

local cfg = vRP.module("cfg/groups")
local groups = cfg.groups
local users = cfg.users
local selectors = cfg.selectors

-- get groups keys of a connected user
function vRP.getUserGroups(user_id)
	local data = vRP.getUserDataTable(user_id)
	if data == nil then return {} end
	if data.groups == nil then data.groups = {} end
	return data.groups
end

-- add a group to a connected user
function vRP.addUserGroup(user_id, group)
	if not vRP.hasGroup(user_id, group) then
		local user_groups = vRP.getUserGroups(user_id)
		local ngroup = groups[group]
		if ngroup then
			if ngroup._config and ngroup._config.gtype ~= nil then
				-- copy group list to prevent iteration while removing
				local _user_groups = {}
				for k, v in pairs(user_groups) do
					_user_groups[k] = v
				end

				for k, v in pairs(_user_groups) do -- remove all groups with the same gtype
					local kgroup = groups[k]
					if kgroup and kgroup._config and ngroup._config and kgroup._config.gtype == ngroup._config.gtype then
						vRP.removeUserGroup(user_id, k)
					end
				end
			end

			-- add group
			user_groups[group] = true
			local player = vRP.getUserSource(user_id)
			if ngroup._config and ngroup._config.onjoin and player ~= nil then
				ngroup._config.onjoin(player) -- call join callback
			end

			-- trigger join event
			local gtype = nil
			if ngroup._config then
				gtype = ngroup._config.gtype
			end
			TriggerEvent("vRP:playerJoinGroup", user_id, group, gtype)
		end
	end
end

-- get user group by type
-- return group name or an empty string
function vRP.getUserGroupByType(user_id, gtype)
	local user_groups = vRP.getUserGroups(user_id)
	for k in pairs(user_groups) do
		local kgroup = groups[k]
		if kgroup and kgroup._config and kgroup._config.gtype == gtype then
			return k
		end
	end
	return ""
end

-- return list of connected users by group
function vRP.getUsersByGroup(group)
	local users = {}

	for k, v in pairs(vRP.rusers) do
		if vRP.hasGroup(tonumber(k), group) then
			table.insert(users, tonumber(k))
		end
	end

	return users
end

-- return list of connected users by permission
function vRP.getUsersByPermission(perm)
	local users = {}

	for k, v in pairs(vRP.rusers) do
		if vRP.hasPermission(tonumber(k), perm) then
			table.insert(users, tonumber(k))
		end
	end

	return users
end

-- remove a group from a connected user
function vRP.removeUserGroup(user_id, group)
	local user_groups = vRP.getUserGroups(user_id)
	local groupdef = groups[group]
	if groupdef and groupdef._config and groupdef._config.onleave then
		local source = vRP.getUserSource(user_id)
		if source ~= nil then
			groupdef._config.onleave(source) -- call leave callback
		end
	end

	-- trigger leave event
	if group ~= nil then
		local gtype = nil
		if groupdef._config then
			gtype = groupdef._config.gtype
		end

		TriggerEvent("vRP:playerLeaveGroup", user_id, group, gtype)

		user_groups[group] = nil -- remove reference
	else
		print("[vRP]: Fejl forsøg på at fjerne group der ikke findes")
	end
end

-- check if the user has a specific group
function vRP.hasGroup(user_id, group)
	local user_groups = vRP.getUserGroups(user_id)
	return (user_groups[group] ~= nil)
end

-- check if the user has a specific permission
function vRP.hasPermission(user_id, perm)
	local user_groups = vRP.getUserGroups(user_id)
	local fchar = string.sub(perm, 1, 1)

	if fchar == "@" then -- special aptitude permission
		local _perm = string.sub(perm, 2)
		local parts = splitString(_perm, ".")
		if #parts ~= 3 then return false end

		local group, aptitude, op = parts[1], parts[2], parts[3]
		local alvl = math.floor(vRP.expToLevel(vRP.getExp(user_id, group, aptitude)))
		local fop = string.sub(op, 1, 1)
		local lvl = parseInt(fop == "<" or fop == ">" and string.sub(op, 2) or op)

		if fop == "<" then return alvl < lvl
		elseif fop == ">" then return alvl > lvl
		else return alvl == lvl end

	elseif fchar == "#" then -- special item permission
		local _perm = string.sub(perm, 2)
		local parts = splitString(_perm, ".")
		if #parts ~= 2 then return false end

		local item, op = parts[1], parts[2]
		local amount = vRP.getInventoryItemAmount(user_id, item)
		local fop = string.sub(op, 1, 1)
		local n = parseInt(fop == "<" or fop == ">" and string.sub(op, 2) or op)

		if fop == "<" then return amount < n
		elseif fop == ">" then return amount > n
		else return amount == n end
	end

	-- regular permission: precheck negative
	local nperm = "-" .. perm
	for k in pairs(user_groups) do
		local group = groups[k]
		if group then
			for l, w in pairs(group) do
				if l ~= "_config" and w == nperm then return false end
			end
		end
	end

	-- check if permission exists
	for k in pairs(user_groups) do
		local group = groups[k]
		if group then
			for l, w in pairs(group) do
				if l ~= "_config" and w == perm then return true end
			end
		end
	end

	return false
end

-- check if the user has a specific list of permissions (all of them)
function vRP.hasPermissions(user_id, perms)
	for k, v in pairs(perms) do
		if not vRP.hasPermission(user_id, v) then
			return false
		end
	end

	return true
end

-- GROUP SELECTORS

local function ch_select(player, choice)
	local user_id = vRP.getUserId(player)
	if user_id ~= nil then
		vRP.addUserGroup(user_id, choice)
		vRP.closeMenu(player)
	end
end

-- build menus
local selector_menus = {}
for k, v in pairs(selectors) do
	local menu = { name = k, css = { top = "75px", header_color = "rgba(255,154,24,0.75)" } }
	for l, w in pairs(v) do
		if l ~= "_config" then
			menu[w] = { ch_select }
		end
	end

	selector_menus[k] = menu
end

local function build_client_selectors(source)
	local user_id = vRP.getUserId(source)
	if user_id == nil then return end

	for k, v in pairs(selectors) do
		local gcfg = v._config
		local menu = selector_menus[k]
		if gcfg == nil or menu == nil then return end

		local x, y, z = gcfg.x, gcfg.y, gcfg.z

		local function selector_enter()
			local uid = vRP.getUserId(source)
			if uid ~= nil and vRP.hasPermissions(uid, gcfg.permissions or {}) then
				vRP.openMenu(source, menu)
			end
		end

		local function selector_leave()
			vRP.closeMenu(source)
		end

		vRPclient.addBlip(source, { x, y, z, gcfg.blipid, gcfg.blipcolor, k })
		vRPclient.addMarker(source, { x, y, z - 0.87, 0.7, 0.7, 0.5, 255, 154, 24, 125, 150 })
		vRP.setArea(source, "vRP:gselector:" .. k, x, y, z, 1, 1.5, selector_enter, selector_leave)
	end
end

-- events

-- player spawn
AddEventHandler("vRP:playerSpawn", function(user_id, source, first_spawn)
	-- first spawn
	if first_spawn then
		-- add selectors
		build_client_selectors(source)

		-- add groups on user join
		local user = users[user_id]
		if user ~= nil then
			for k, v in pairs(user) do
				vRP.addUserGroup(user_id, v)
			end
		end

		-- add default group user
		vRP.addUserGroup(user_id, "user")
	end

	-- call group onspawn callback at spawn
	local user_groups = vRP.getUserGroups(user_id)
	for k, v in pairs(user_groups) do
		local group = groups[k]
		if group and group._config and group._config.onspawn then
			group._config.onspawn(source)
		end
	end
end)
