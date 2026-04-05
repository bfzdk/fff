local htmlEntities = vRP.module("lib/htmlEntities")
local Tools = vRP.module("lib/Tools")
local lang = vRP.lang
local cfg = vRP.module("cfg/admin")
local webhook = vRP.module("cfg/webhooks")

local player_lists = {}
local special_perm_table = {
	[1] = true, --ID 1 kan ikke få ban
}

function vRP.getWarnings(user_id, cbr)
	local task = Task(cbr)

	MySQL.Async.fetchAll("SELECT * FROM vrp_users WHERE id = @user_id", { user_id = user_id }, function(rows, affected)
		if #rows > 0 and rows ~= nil then
			if rows[1].warnings == 0 or rows[1].warnings == nil then
				return 0
			else
				task({ rows[1].warnings })
			end
		end
	end)
end

local function ch_list(player, choice)
	local user_id = vRP.getUserId(player)
	if user_id ~= nil and vRP.hasPermission(user_id, "player.list") then
		if player_lists[player] then -- hide
			player_lists[player] = nil
			vRPclient.removeDiv(player, { "user_list" })
		else -- show
			local content = ""
			local count = 0
			for k, v in pairs(vRP.rusers) do
				count = count + 1
				local source = vRP.getUserSource(k)
				vRP.getUserIdentity(k, function(identity)
					if source ~= nil then
						if identity then
							content = content
								.. "["
								.. k
								.. '] <span class="pseudo">'
								.. vRP.getPlayerName(source)
								.. '</span> | <span class="name">'
								.. htmlEntities.encode(identity.firstname)
								.. " "
								.. htmlEntities.encode(identity.name)
								.. '</span> [CPR]: <span class="reg">'
								.. identity.registration
								.. '</span> [TLF]: <span class="phone">'
								.. identity.phone
								.. "</span><br>"
						end
					end

					-- check end
					count = count - 1
					if count == 0 then
						player_lists[player] = true
						local css = [[
			                    	.div_user_list{ 
			                    	  margin: auto; 
			                    	  padding: 8px; 
			                    	  width: 650px; 
			                    	  margin-top: 90px; 
			                    	  background: black; 
			                    	  color: white; 
			                    	  font-weight: bold; 
			                    	  font-size: 16px;
			                    	  font-family: arial;
			                    	} 
                                
			                    	.div_user_list .pseudo{ 
			                    	  color: rgb(255,255,255);
			                    	}
                                
			                    	.div_user_list .endpoint{ 
			                    	  color: rgb(255,255,255);
			                    	}
                                
			                    	.div_user_list .name{ 
			                    	  color: #309eff;
			                    	}
                                
			                    	.div_user_list .reg{ 
			                    	  color: rgb(255,255,255);
			                    	}
                                
			                    	.div_user_list .phone{ 
			                    	  color: rgb(255,255,255);
			                    	}
                                ]]
						vRPclient.setDiv(player, { "user_list", css, content })
					end
				end)
			end
		end
	end
end

local function ch_whitelist(player, choice)
	local user_id = vRP.getUserId(player)
	if user_id ~= nil and vRP.hasPermission(user_id, "player.whitelist") then
		vRP.prompt(player, "ID: ", "", function(player, id)
			id = parseInt(id)
			vRP.setWhitelisted(id, true)
			local dmessage = "```[ID: " .. tostring(user_id) .. "] Tilføjede whitelist til [ID: " .. tostring(id) .. "]```"
			PerformHttpRequest(
				webhook.Whitelist,
				function(err, text, headers) end,
				"POST",
				json.encode({ username = "FlaxHosting - Logs", content = dmessage }),
				{ ["Content-Type"] = "application/json" }
			)

			vRP.notify(user_id, "ID " .. id .. " blev whitelisted")
		end)
	end
end

local function ch_unwhitelist(player, choice)
	local user_id = vRP.getUserId(player)
	if user_id ~= nil and vRP.hasPermission(user_id, "player.unwhitelist") then
		vRP.prompt(player, "ID: ", "", function(player, id)
			id = parseInt(id)
			vRP.setWhitelisted(id, false)
			local dmessage = "```[ID: " .. tostring(user_id) .. "] Fjernede whitelist Fra [ID: " .. tostring(id) .. " ]```"
			PerformHttpRequest(
				webhook.Unwhitelist,
				function(err, text, headers) end,
				"POST",
				json.encode({ username = "FlaxHosting - Logs", content = dmessage }),
				{ ["Content-Type"] = "application/json" }
			)

			vRP.notify(user_id, "ID " .. id .. " blev unwhitelisted")
		end)
	end
end

local function ch_addgroup_staff(player, choice)
	local user_id = vRP.getUserId(player)
	if user_id ~= nil and vRP.hasPermission(user_id, "player.group.add.staff") then
		vRP.prompt(player, "Spiller ID: ", "", function(player, id)
			id = parseInt(id)
			local checkid = vRP.getUserSource(tonumber(id))
			if checkid ~= nil then
				vRP.prompt(player, "Job: ", "", function(player, group)
					if group == " " or group == "" or group == nil or group == 0 or group == nil then
						vRP.notify(user_id, "Du angav ikke et job/rang.")
					else
						vRP.addUserGroup(id, group)

						local dmessage = "```"
							.. tostring(user_id)
							.. " tilføjede gruppe ["
							.. tostring(group)
							.. "] til "
							.. tostring(id)
							.. "```"
						PerformHttpRequest(
							webhook.AddGroup,
							function(err, text, headers) end,
							"POST",
							json.encode({ username = "FlaxHosting - Logs", content = dmessage }),
							{ ["Content-Type"] = "application/json" }
						)
						vRP.notify(user_id, id .. " blev ansat som " .. group)
					end
				end)
			else
				vRP.notify(user_id, "ID " .. id .. " er ugyldigt eller ikke online.")
			end
		end)
	end
end

local function ch_removegroup_staff(player, choice)
	local user_id = vRP.getUserId(player)
	if user_id ~= nil and vRP.hasPermission(user_id, "player.group.remove.staff") then
		vRP.prompt(player, "Spiller ID: ", "", function(player, id)
			id = parseInt(id)
			local checkid = vRP.getUserSource(tonumber(id))
			if checkid ~= nil then
				vRP.prompt(player, "Job: ", "", function(player, group)
					if group == " " or group == "" or group == nil or group == 0 or group == nil then
						vRP.notify(user_id, "Du angav ikke et job/rang.")
					else
						vRP.removeUserGroup(id, group)
						vRP.notify(user_id, id .. " blev fyret som " .. group)
					end
				end)
			else
				vRP.notify(user_id, "ID " .. id .. " er ugyldigt eller ikke online.")
			end
		end)
	end
end

local function ch_kick(player, choice)
	local user_id = vRP.getUserId(player)
	if user_id ~= nil and vRP.hasPermission(user_id, "player.kick") then
		vRP.prompt(player, "Spiller ID: ", "", function(player, id)
			id = parseInt(id)
			vRP.prompt(player, "Årsag: ", "", function(_, reason)
				local source = vRP.getUserSource(id)
				if source ~= nil then
					vRP.kick(source, reason)
					vRP.notify(user_id, "Du kickede " .. id)
				end
			end)
		end)
	end
end

local function ch_ban(player, choice)
	local user_id = vRP.getUserId(player)
	if user_id ~= nil and vRP.hasPermission(user_id, "player.ban") then
		vRP.prompt(player, "Spiller ID: ", "", function(player, id)
			id = parseInt(id)
			vRP.prompt(player, "Årsag: ", "", function(player, reason)
				vRP.ban(id, reason)
				vRP.notify(user_id, "Du bannede " .. id)
			end)
		end)
	end
end

local function ch_unban(player, choice)
	local user_id = vRP.getUserId(player)
	if user_id ~= nil and vRP.hasPermission(user_id, "player.unban") then
		vRP.prompt(player, "User id to unban: ", "", function(player, id)
			id = parseInt(id)
			vRP.setBanned(id, false)
			vRP.notify(user_id, "un-banned user " .. id)
			local dmessage = "```ID " .. tostring(user_id) .. " unbannede ID " .. tostring(id) .. "```"
			PerformHttpRequest(
				webhook.Unban,
				function(err, text, headers) end,
				"POST",
				json.encode({ username = "FlaxHosting - Logs", content = dmessage }),
				{ ["Content-Type"] = "application/json" }
			)
		end)
	end
end

local function ch_revivePlayer(player, choice)
	local nuser_id = vRP.getUserId(player)
	vRP.prompt(player, "Spiller ID:", "", function(player, user_id)
		local deadplayer = vRP.getUserSource(tonumber(user_id))
		if deadplayer == nil then
			vRP.notify(nuser_id, "Ugyldigt eller manglende ID")
		else
			vRP.notify(nuser_id, "Du genoplivede spilleren med ID " .. user_id)
			vRPclient.varyHealth(deadplayer, { 100 })
			vRP.setHunger(tonumber(user_id), 0)
			vRP.setThirst(tonumber(user_id), 0)

			local dmessage = "```"
				.. tostring(nuser_id)
				.. " genoplivet "
				.. tostring(user_id)
				.. " ("
				.. os.date("%H:%M:%S %d/%m/%Y")
				.. ")```"
			PerformHttpRequest(
				webhook.Revive,
				function(err, text, headers) end,
				"POST",
				json.encode({ username = "FlaxHosting - Logs", content = dmessage }),
				{ ["Content-Type"] = "application/json" }
			)
		end
	end)
end

local function ch_changeplate(player, choice)
	vRPclient.changeNummerPlate(player, { 5 })
end

local function ch_repairVehicle(player, name, choice)
	vRPclient.fixeNearestVehicleAdmin(player, { 3 })
	local user_id = vRP.getUserId(player)

	local dmessage = "**Reparer køretøj** \n```\nAdmin ID: " .. tostring(user_id) .. "\n```"
	PerformHttpRequest(
		webhook.Repair,
		function(err, text, headers) end,
		"POST",
		json.encode({ username = "FlaxHosting - Logs", content = dmessage }),
		{ ["Content-Type"] = "application/json" }
	)
end

local function ch_coords(player, choice)
	vRPclient.getPosition(player, {}, function(x, y, z)
		vRP.prompt(player, "Kopier koordinaterne med CTRL-A CTRL-C", x .. "," .. y .. "," .. z, function(player, choice) end)
	end)
end

local function ch_tptome(player, choice)
	vRPclient.getPosition(player, {}, function(x, y, z)
		vRP.prompt(player, "Spiller ID:", "", function(player, user_id)
			local tplayer = vRP.getUserSource(tonumber(user_id))
			if tplayer ~= nil then
				vRPclient.teleport(tplayer, { x, y, z })
				local admin_user_id = vRP.getUserId(player)

				local dmessage = "**TP Person til mig** \n```\nAdmin ID: " .. tostring(admin_user_id) .. "\n```"
				PerformHttpRequest(
					webhook.TpToMe,
					function(err, text, headers) end,
					"POST",
					json.encode({ username = "FlaxHosting - Logs", content = dmessage }),
					{ ["Content-Type"] = "application/json" }
				)
			end
		end)
	end)
end

local function ch_tpto(player, choice)
	vRP.prompt(player, "Spiller ID:", "", function(player, user_id)
		local tplayer = vRP.getUserSource(tonumber(user_id))
		if tplayer ~= nil then
			vRPclient.getPosition(tplayer, {}, function(x, y, z)
				vRPclient.teleport(player, { x, y, z })
				local admin_user_id = vRP.getUserId(player)

				local dmessage = "**TP til person** \n```\nAdmin ID: " .. tostring(admin_user_id) .. "\n```"
				PerformHttpRequest(
					webhook.TpTo,
					function(err, text, headers) end,
					"POST",
					json.encode({ username = "FlaxHosting - Logs", content = dmessage }),
					{ ["Content-Type"] = "application/json" }
				)
			end)
		end
	end)
end

local function ch_tptocoords(player, choice)
	vRP.prompt(player, "Koordinater x,y,z:", "", function(player, fcoords)
		local coords = {}
		for coord in string.gmatch(fcoords or "0,0,0", "[^,]+") do
			table.insert(coords, tonumber(coord))
		end

		local x = coords[1] or 0
		local y = coords[2] or 0
		local z = coords[3] or 0

		if x == 0 and y == 0 and z == 0 then
			vRP.notify(vRP.getUserId(player), "Ugyldige koordinater.")
		else
			vRPclient.teleport(player, { x, y, z })
		end
	end)
end

-- teleport waypoint
local function ch_tptowaypoint(player, choice)
	TriggerClientEvent("TpToWaypoint", player)
end

local function ch_givemoney(player, choice)
	local user_id = vRP.getUserId(player)
	if user_id ~= nil then
		vRP.getUserIdentity(user_id, function(identity)
			if identity then
				local steamname = GetPlayerName(player)
				vRP.prompt(player, "Beløb:", "", function(player, amount)
					vRP.prompt(player, "Formål ved spawn af penge:", "", function(player, reason)
						if string.len(reason) > 100 then
							vRP.notify(user_id, "Tror du selv du skal skrive så meget?")
						else
							if reason == " " or reason == "" or reason == null or reason == 0 or reason == nil then
								reason = "Ingen kommentar..."
							end
							amount = parseInt(amount)
							if amount == " " or amount == "" or amount == null or amount == 0 or amount == nil then
								vRP.notify(user_id, "Ugyldigt pengebeløb.")
							else
								vRP.giveMoney(user_id, amount)
								vRP.notify(user_id, "Du spawnede " .. amount .. "DKK")

								PerformHttpRequest(
									webhook.SpawnMoney,
									function(err, text, headers) end,
									"POST",
									json.encode({
										username = "FlaxHosting - Logs",
										content = "**ID: "
											.. user_id
											.. " ("
											.. identity.firstname
											.. " "
											.. identity.name
											.. ")** spawnede **"
											.. amount
											.. " DKK** - Kommentar: *"
											.. reason
											.. "*",
									}),
									{ ["Content-Type"] = "application/json" }
								)
							end
						end
					end)
				end)
			end
		end)
	end
end

local function ch_giveitem(player, choice)
	local user_id = vRP.getUserId(player)
	if user_id ~= nil then
		vRP.getUserIdentity(user_id, function(identity)
			if identity then
				local steamname = GetPlayerName(player)
				vRP.prompt(player, "Tingens ID:", "", function(player, idname)
					idname = idname
					if idname == " " or idname == "" or idname == null or idname == nil then
						vRP.notify(user_id, "Ugyldigt ID.")
					else
						vRP.prompt(player, "Antal:", "", function(player, amount)
							if amount == " " or amount == "" or amount == null or amount == nil then
								vRP.notify(user_id, "Ugyldigt antal.")
							else
								amount = parseInt(amount)
								vRP.giveInventoryItem(user_id, idname, amount, true)

								PerformHttpRequest(
									webhook.SpawnItem,
									function(err, text, headers) end,
									"POST",
									json.encode({
										username = "FlaxHosting - Logs",
										content = "```ID: " .. user_id .. " spawnede " .. amount .. " stk. " .. idname .. "```",
									}),
									{ ["Content-Type"] = "application/json" }
								)
							end
						end)
					end
				end)
			end
		end)
	end
end

local function ch_calladmin(player, choice)
	local user_id = vRP.getUserId(player)
	if user_id ~= nil then
		vRP.prompt(player, "Beskriv dit problem. Minimun 10 tegn:", "", function(player, desc)
			desc = desc or ""

			local answered = false
			local players = {}
			for k, v in pairs(vRP.rusers) do
				local player = vRP.getUserSource(tonumber(k))
				-- check user
				if vRP.hasPermission(k, "admin.tickets") and player ~= nil then
					table.insert(players, player)
				end
			end

			-- send notify and alert to all listening players
			if string.len(desc) > 10 and string.len(desc) < 1000 then
				for k, v in pairs(players) do
					vRP.request(v, "[" .. user_id .. "]: " .. htmlEntities.encode(desc), 60, function(v, ok)
						if ok then -- take the call
							if not answered then
								local steamname = GetPlayerName(v)
								PerformHttpRequest(
									webhook.AdminCall,
									function(err, text, headers) end,
									"POST",
									json.encode({
										username = "FlaxHosting - Logs",
										content = "```\n"
											.. steamname
											.. "\nTog et admin call fra ID "
											.. user_id
											.. ".\nIndhold: "
											.. desc
											.. ".```",
									}),
									{ ["Content-Type"] = "application/json" }
								) -- answer the call
								vRP.notify(user_id, "En staff har taget din case!")
								vRPclient.getPosition(player, {}, function(x, y, z)
									vRPclient.teleport(v, { x, y, z })
								end)
								answered = true
							else
								vRP.notify(v, "Allerede taget!")
							end
						end
					end)
				end
			end
		end)
	end
end

local function choice_bilforhandler(player, choice)
	local user_id = vRP.getUserId(player)
	if user_id ~= nil then
		local usrList = ""
		vRPclient.getNearestPlayers(player, { 5 }, function(nplayer)
			for k, v in pairs(nplayer) do
				usrList = usrList .. " | " .. "[" .. vRP.getUserId(k) .. "]" .. GetPlayerName(k)
			end
			if usrList ~= "" then
				vRP.prompt(player, "Nærmeste spiller(e): " .. usrList .. "", "", function(player, nuser_id)
					if nuser_id ~= nil and nuser_id ~= "" then
						local target = vRP.getUserSource(tonumber(nuser_id))
						if target ~= nil then
							vRP.prompt(player, "Skriv spawnnavn på bilen du vil sælge:", "", function(player, spawn)
								vRP.prompt(player, "Type? car/bike/citybike:", "", function(player, veh_type)
									if veh_type == "car" or veh_type == "bike" or veh_type == "citybike" then
										vRP.prompt(player, "Hvad skal den koste?", "", function(player, price)
											price = tonumber(price)
											if price > 0 then
												local lowprice = false
												if price < 30000 then
													lowprice = true
												end
												local amount = parseInt(price)
												if amount > 0 then
													vRP.prompt(
														player,
														"Bekræft: " .. spawn .. " sælges til " .. nuser_id .. " for " .. format_thousands(tonumber(price)),
														"",
														function(player, bool)
															if string.lower(bool) == "bekræft" then
																if vRP.tryFullPayment(tonumber(nuser_id), tonumber(price)) then
																	vRP.getUserIdentity(tonumber(nuser_id), function(identity)
																		local pp = math.floor(tonumber(price) / 100 * 5)
																		vRP.giveBankMoney(user_id, tonumber(pp))

																		MySQL.Async.execute(
																			"INSERT IGNORE INTO vrp_user_vehicles(user_id,vehicle,vehicle_plate,veh_type) VALUES(@user_id,@vehicle,@vehicle_plate,@veh_type)",
																			{
																				user_id = tonumber(nuser_id),
																				vehicle = spawn,
																				vehicle_plate = "P " .. identity.registration,
																				veh_type = veh_type,
																			}
																		)

																		vRP.notify(user_id, identity.firstname
																			.. " "
																			.. identity.name
																			.. " har modtaget "
																			.. spawn
																			.. " for "
																			.. format_thousands(tonumber(price))
																			.. " DKK. Du modtog "
																			.. format_thousands(tonumber(pp))
																			.. " for handlen!")
																	end)
																	local message = "**"
																		.. user_id
																		.. "** solgte en **"
																		.. spawn
																		.. "** til **"
																		.. nuser_id
																		.. "** for **"
																		.. format_thousands(tonumber(price))
																		.. " DKK**"
																	if lowprice then
																		message = message .. " @everyone"
																	end
																	PerformHttpRequest(
																		webhook.SellCar,
																		function(err, text, headers) end,
																		"POST",
																		json.encode({ username = "FlaxHosting - Logs", content = message }),
																		{ ["Content-Type"] = "application/json" }
																	)

																	vRP.notify(nuser_id, "Tillykke med din " .. spawn .. "!")
																else
																	vRP.notify(user_id, "Personen har ikke nok penge")
																end
															else
																vRP.notify(user_id, "Du har annulleret")
															end
														end
													)
												else
														vRP.notify(user_id, "Beløbet skal være over 0!")
												end
											end
										end)
									else
										vRP.notify(user_id, "Typen: " .. veh_type .. " findes ikke")
									end
								end)
							end)
						else
							vRP.notify(user_id, "Dette ID ser ud til ikke at eksistere")
						end
					else
						vRP.notify(user_id, "Intet ID valgt")
					end
				end)
			else
				vRP.notify(user_id, "Ingen spiller i nærheden")
			end
		end)
	end
end

function format_thousands(v)
	local s = string.format("%d", math.floor(v))
	local pos = string.len(s) % 3
	if pos == 0 then
		pos = 3
	end
	return string.sub(s, 1, pos) .. string.gsub(string.sub(s, pos + 1), "(...)", ".%1")
end

local player_customs = {}

local function ch_display_custom(player, choice)
	vRPclient.getCustomization(player, {}, function(custom)
		if player_customs[player] then -- hide
			player_customs[player] = nil
			vRPclient.removeDiv(player, { "customization" })
		else -- show
			local content = ""
			for k, v in pairs(custom) do
				content = content .. k .. " => " .. json.encode(v) .. "<br />"
			end

			player_customs[player] = true
			vRPclient.setDiv(
				player,
				{
					"customization",
					".div_customization{ margin: auto; padding: 8px; width: 500px; margin-top: 80px; background: black; color: white; font-weight: bold; ",
					content,
				}
			)
		end
	end)
end

local function ch_noclip(player, choice)
	local user_id = vRP.getUserId(player)
	vRPclient.toggleNoclip(player, {})
end

local function ch_warn(player, choice)
	local user_id = vRP.getUserId(player)
	if user_id ~= nil and vRP.hasPermission(user_id, "admin.tickets") then
		vRP.prompt(player, "Bruger ID: ", "", function(player, tar_id)
			tar_id = parseInt(tar_id)
			if tar_id ~= nil then
				local source = vRP.getUserSource(tar_id)
				if source ~= nil then
					vRP.prompt(player, "Antal Advarsler: ", "", function(player, warnings)
						warnings = parseInt(warnings) or 0
						vRP.prompt(player, "Hvad er grunden til advarsel:", "", function(player, grund)
							if grund ~= nil and warnings > 0 then
								vRP.getWarnings(tar_id, function(curwarnings)
									cuwarnings = curwarnings or 0
									local newwarn = math.floor(warnings + curwarnings)
									MySQL.Async.execute(
										"UPDATE vrp_users SET warnings = @warnings WHERE id = @user_id",
										{ user_id = tar_id, warnings = newwarn },
										function(rows, affected)
											local warn_text = warnings > 1 and "advarsler" or "advarsel"
											vRP.notify(tar_id, "Du har fået " .. warnings .. " " .. warn_text .. "! med grund: " .. grund .. " Du har I alt " .. newwarn .. " advarsler! Sendt af id: " .. user_id)
											vRP.notify(user_id, "Du har givet " .. warnings .. " " .. warn_text .. " til ID: " .. tar_id)

											if newwarn >= 3 and source ~= nil then
												vRP.ban(tar_id, "Du har fået 3 advarsler!", source)
												vRP.kick(source, "Du har fået 3 advarsler!")
											end
										end
									)
								end)
							end
						end)
					end)
				else
					vRP.notify(user_id, "Spilleren er ikke på!")
				end
			end
		end)
	end
end

local function ch_getwarn(player, choice)
	local user_id = vRP.getUserId(player)
	if user_id ~= nil and vRP.hasPermission(user_id, "admin.tickets") then
		vRP.prompt(player, "Bruger ID: ", "", function(player, tar_id)
			tar_id = parseInt(tar_id)
			if tar_id ~= nil then
				vRP.getWarnings(tar_id, function(curwarnings)
					if curwarnings == nil then
						curwarnings = 0
					end
					if curwarnings == 0 then
						vRP.notify(user_id, "ID: " .. tar_id .. " har ingen advarsler!")
					else
						vRP.notify(user_id, "ID: " .. tar_id .. " har " .. curwarnings .. " advarsler!")
						--  vRPclient.notify(player,{"ID: ".. tar_id.. " har ".. curwarnings.. " advarsler!"})
					end
				end)
			end
		end)
	end
end

local function ch_checkwarn(player)
	local user_id = vRP.getUserId(player)
	if user_id ~= nil then
		vRP.notify(user_id, "Tjekker advarsler!")
		vRP.getWarnings(user_id, function(curwarnings)
			if curwarnings == nil then
				curwarnings = 0
			end
			if curwarnings == 0 then
				vRP.notify(user_id, "Du har ingen advarsler!")
			else
				vRP.notify(user_id, "Du har " .. curwarnings .. " advarsler!")
				--  vRPclient.notify(player,{"ID: ".. tar_id.. " har ".. curwarnings.. " advarsler!"})
			end
		end)
	end
end

local function ch_clearwarn(player, choice)
	local user_id = vRP.getUserId(player)
	if user_id ~= nil and vRP.hasPermission(user_id, "player.unban") then
		vRP.prompt(player, "Bruger ID: ", "", function(player, tar_id)
			tar_id = parseInt(tar_id)
			if tar_id ~= nil then
				vRP.prompt(player, "Hvad er grunden til fjernelse?:", "", function(player, grund)
					if grund ~= nil then
						MySQL.Async.execute(
							"UPDATE vrp_users SET warnings = @warnings WHERE id = @user_id",
							{ user_id = tar_id, warnings = 0 },
							function(rows, affected)
								vRP.notify(user_id, "Du fjernede Id: " .. tar_id .. "'s advarelser")
							end
						)
					end
				end)
			end
		end)
	end
end

local function ch_freezeplayer(player, choice)
	local user_id = vRP.getUserId(player)
	vRP.prompt(player, "Spiller ID:", "", function(player, user_id)
		id = parseInt(user_id)
		special_perm_table[id] = special_perm_table[id] or false
		if special_perm_table[id] then
			vRP.kick(player, "Du har forsøgt at kicke en staff med immunitet")
		end
		local frozenplayer = vRP.getUserSource(tonumber(user_id))
		if frozenplayer == nil then
			vRP.notify(user_id, "Ugyldigt eller manglende ID")
		else
			vRP.notify(user_id, "Du frøs/optøede spilleren med ID " .. user_id)
			vRPclient.toggleFreeze(frozenplayer, {})
		end
	end)
end

local function ch_spawnvehicle(player, choice)
	local user_id = vRP.getUserId(player)
	vRP.prompt(player, "Bilen's modelnavn f.eks. police3:", "", function(player, veh)
		if veh ~= "" then
			TriggerClientEvent("hp:spawnvehicle", player, veh)
		end
	end)
end

local function ch_deletevehicle(player, choice)
	TriggerClientEvent("hp:deletevehicle", player)
end

local function ch_unlockvehicle(player, choice)
	vRPclient.vehicleUnlockAdmin(player)
end

local function ch_blips(player, choice)
	TriggerClientEvent("showBlips", player)
end

local function ch_spectate(player, choice)
	vRP.prompt(player, "ID: ", "", function(player, id)
		id = parseInt(id)
		if id ~= nil then
			TriggerEvent("vRPAdmin:SpectatePlr", id)
		else
			print("mangler id")
		end
	end)
end

vRP.registerMenuBuilder("main", function(add, data)
	local user_id = vRP.getUserId(data.player)
	if user_id == nil then return end

	local menu_items = {
		{ perm = "player.list", label = ">Brugerliste", fn = ch_list, desc = "Vis/Gem" },
		{ perm = "player.group.add.staff", label = "Tilføj Rank", fn = ch_addgroup_staff },
		{ perm = "player.group.remove.staff", label = "Fjern Rank", fn = ch_removegroup_staff },
		{ perm = "player.kick", label = "Kick", fn = ch_kick },
		{ perm = "player.kick", label = ">Giv Advarseler", fn = ch_warn },
		{ perm = "player.kick", label = "Antal Advarsler", fn = ch_getwarn },
		{ perm = "player.calladmin", label = "Tjek mine advarsler", fn = ch_checkwarn },
		{ perm = "player.unban", label = "Fjern Advarsler", fn = ch_clearwarn },
		{ perm = "player.kick", label = "Blips", fn = ch_blips },
		{ perm = "player.ban", label = "Ban", fn = ch_ban },
		{ perm = "player.unban", label = "Unban", fn = ch_unban },
		{ perm = "player.freeze", label = "Frys/optø spiller", fn = ch_freezeplayer },
		{ perm = "admin.revive", label = "Genopliv spiller", fn = ch_revivePlayer },
		{ perm = "player.repairvehicle", label = "Reparer køretøj", fn = ch_repairVehicle },
		{ perm = "developer.permission", label = ">Udskift nummerplade", fn = ch_changeplate },
		{ perm = "player.noclip", label = ">Noclip", fn = ch_noclip },
		{ perm = "player.spawnvehicle", label = "Spawn køretøj", fn = ch_spawnvehicle },
		{ perm = "player.deletevehicle", label = "Fjern køretøj", fn = ch_deletevehicle },
		{ perm = "player.unlockvehicle", label = "Lås køretøj op", fn = ch_unlockvehicle },
		{ perm = "player.coords", label = "Koordinater", fn = ch_coords },
		{ perm = "player.tptome", label = "TP person til mig", fn = ch_tptome },
		{ perm = "player.tpto", label = "TP til person", fn = ch_tpto },
		{ perm = "developer.permission", label = "TP til koordinater", fn = ch_tptocoords },
		{ perm = "player.tptowaypoint", label = "TP til waypoint", fn = ch_tptowaypoint },
		{ perm = "player.givemoney", label = "Spawn penge", fn = ch_givemoney },
		{ perm = "player.giveitem", label = "Spawn ting", fn = ch_giveitem },
		{ perm = "player.calladmin", label = "Tilkald staff", fn = ch_calladmin },
		{ perm = "admin.bilforhandler", label = "Sælg bil", fn = choice_bilforhandler },
		{ perm = "player.whitelist", label = "Whitelist", fn = ch_whitelist },
		{ perm = "player.unwhitelist", label = "Unwhitelist", fn = ch_unwhitelist },
		{ perm = "player.spectate", label = "Spectate", fn = ch_spectate },
	}

	local choices = {}
	choices["> Admin"] = {
		function(player, choice)
			local menu = { name = "FlaxHosting", css = { top = "75px", header_color = "rgb(153, 136, 59)" } }
			menu.onclose = function(player)
				vRP.openMainMenu(player)
			end

			for _, item in ipairs(menu_items) do
				if vRP.hasPermission(user_id, item.perm) then
					menu[item.label] = item.desc and { item.fn, item.desc } or { item.fn }
				end
			end

			vRP.openMenu(player, menu)
		end,
	}

	add(choices)
end)

RegisterNetEvent("vRPAdmin:SpectatePlr")
AddEventHandler("vRPAdmin:SpectatePlr", function(id)
	local source = source
	local SelectedPlrSource = vRP.getUserSource(tonumber(id))

	print(id)
	if SelectedPlrSource then
		if onesync ~= "off" then
			local ped = GetPlayerPed(SelectedPlrSource)
			local pedCoords = GetEntityCoords(ped)
			print(pedCoords)
			TriggerClientEvent("vRPAdmin:Spectate", source, SelectedPlrSource, pedCoords)
		else
			TriggerClientEvent("vRPAdmin:Spectate", source, SelectedPlrSource)
		end
	else
		vRP.notify(source, "This player may have left the game.")
	end
end)
