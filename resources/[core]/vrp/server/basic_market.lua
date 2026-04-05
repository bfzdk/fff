-- a basic market implementation

local lang = vRP.lang
local cfg = vRP.module("cfg/markets")
local market_types = cfg.market_types
local markets = cfg.markets

local market_menus = {}

-- build market menus
local function build_market_menus()
	for gtype, mitems in pairs(market_types) do
		local market_menu = {
			name = lang.market.title({ gtype }),
			css = { top = "75px", header_color = "rgba(0,255,125,0.75)" },
		}

		-- build market items
		local kitems = {}

		-- item choice
		local market_choice = function(player, choice)
			local idname = kitems[choice][1]
			local item = vRP.items[idname]
			local price = kitems[choice][2]
			if item == nil then return end

			local user_id = vRP.getUserId(player)
			if user_id == nil then return end

			vRP.prompt(player, lang.market.prompt({ item.name }), "", function(player, amount)
				amount = parseInt(amount)
				if amount <= 0 then
					vRP.notify(player, lang.common.invalid_value())
					return
				end

				local new_weight = vRP.getInventoryWeight(user_id) + vRP.getItemWeight(idname) * amount
				if new_weight > vRP.getInventoryMaxWeight(user_id) then
					vRP.notify(player, lang.inventory.full())
					return
				end

				if vRP.tryFullPayment(user_id, amount * price) then
					vRP.giveInventoryItem(user_id, idname, amount, true)
					vRP.notify(player, lang.money.paid({ amount * price }))
				else
					vRP.notify(player, lang.money.not_enough())
				end
			end)
		end

		-- add item options
		for k, v in pairs(mitems) do
			local item = vRP.items[k]
			if item then
				kitems[item.name] = { k, math.max(v, 0) } -- idname/price
				market_menu[item.name] =
					{ market_choice, lang.market.info({ v, item.description .. "\n\n" .. item.weight .. " kg" }) }
			end
		end

		market_menus[gtype] = market_menu
	end
end

local function build_client_markets(source)
	if first_build then
		build_market_menus()
		first_build = false
	end

	local user_id = vRP.getUserId(source)
	if user_id == nil then return end

	for k, v in pairs(markets) do
		local gtype, x, y, z, hidden = table.unpack(v)
		local group = market_types[gtype]
		local menu = market_menus[gtype]
		if group == nil or menu == nil then return end

		local gcfg = group._config

		local function market_enter()
			local uid = vRP.getUserId(source)
			if uid ~= nil and vRP.hasPermissions(uid, gcfg.permissions or {}) then
				vRP.openMenu(source, menu)
			end
		end

		local function market_leave()
			vRP.closeMenu(source)
		end

		if hidden ~= true then
			vRPclient.addBlip(source, { x, y, z, gcfg.blipid, gcfg.blipcolor, lang.market.title({ gtype }) })
		end
		vRPclient.addMarker(source, { x, y, z - 0.87, 0.7, 0.7, 0.5, 0, 255, 125, 125, 150 })
		vRP.setArea(source, "vRP:market" .. k, x, y, z, 1, 1.5, market_enter, market_leave)
	end
end

AddEventHandler("vRP:playerSpawn", function(user_id, source, first_spawn)
	if first_spawn then
		build_client_markets(source)
	end
end)
