local htmlEntities = vRP.module("lib/htmlEntities")

local cfg = vRP.module("cfg/identity")
local lang = vRP.lang
local sanitizes = vRP.module("cfg/sanitizes")

-- wallet/bank amount (aliases to money module)
function vRP.getWalletAmount(user_id)
	return vRP.getMoney(user_id)
end

function vRP.getBankAmount(user_id)
	return vRP.getBankMoney(user_id)
end

-- cbreturn driverlicense status
function vRP.getDriverLicense(user_id, cbr)
	local task = Task(cbr)
	MySQL.Async.fetchAll("SELECT * FROM vrp_users WHERE id = @user_id", { user_id = user_id }, function(rows)
		task(#rows > 0 and { rows[1] } or nil)
	end)
end

-- cbreturn user identity
function vRP.getUserIdentity(user_id, cbr)
	if user_id == nil or cbr == nil then return end
	local task = Task(cbr)
	MySQL.Async.fetchAll(
		"SELECT * FROM vrp_user_identities WHERE user_id = @user_id",
		{ user_id = user_id },
		function(rows)
			task(#rows > 0 and { rows[1] } or nil)
		end
	)
end

-- cbreturn user_id by registration or nil
function vRP.getUserByRegistration(registration, cbr)
	local task = Task(cbr)
	MySQL.Async.fetchAll(
		"SELECT user_id FROM vrp_user_identities WHERE registration = @registration",
		{ registration = registration or "" },
		function(rows)
			task(#rows > 0 and { rows[1].user_id } or nil)
		end
	)
end

-- cbreturn user_id by phone or nil
function vRP.getUserByPhone(phone, cbr)
	local task = Task(cbr)
	MySQL.Async.fetchAll(
		"SELECT user_id FROM vrp_user_identities WHERE phone = @phone",
		{ phone = phone or "" },
		function(rows)
			task(#rows > 0 and { rows[1].user_id } or nil)
		end
	)
end

function vRP.generateStringNumber(format)
	local abyte = string.byte("A")
	local zbyte = string.byte("0")
	local number = ""
	for i = 1, #format do
		local char = string.sub(format, i, i)
		if char == "D" then
			number = number .. string.char(zbyte + math.random(0, 9))
		elseif char == "L" then
			number = number .. string.char(abyte + math.random(0, 25))
		else
			number = number .. char
		end
	end
	return number
end

-- cbreturn a unique registration number
function vRP.generateRegistrationNumber(cbr)
	local task = Task(cbr)
	local function search()
		local registration = vRP.generateStringNumber("DDDDDD")
		vRP.getUserByRegistration(registration, function(user_id)
			if user_id ~= nil then
				search()
			else
				task({ registration })
			end
		end)
	end
	search()
end

-- cbreturn a unique phone number
function vRP.generatePhoneNumber(cbr)
	local task = Task(cbr)
	local function search()
		local phone = vRP.generateStringNumber(cfg.phone_format)
		vRP.getUserByPhone(phone, function(user_id)
			if user_id ~= nil then
				search()
			else
				task({ phone })
			end
		end)
	end
	search()
end

-- events, init user identity at connection
AddEventHandler("vRP:playerJoin", function(user_id, source, name, last_login)
	vRP.getUserIdentity(user_id, function(identity)
		if identity ~= nil then return end

		vRP.generateRegistrationNumber(function(registration)
			if registration == nil then return end

			vRP.generatePhoneNumber(function(phone)
				if phone == nil then return end

				MySQL.Async.execute(
					"INSERT IGNORE INTO vrp_user_identities(user_id,registration,phone,firstname,name,age) VALUES(@user_id,@registration,@phone,@firstname,@name,@age)",
					{
						user_id = user_id,
						registration = registration,
						phone = phone,
						firstname = cfg.random_first_names[math.random(1, #cfg.random_first_names)],
						name = cfg.random_last_names[math.random(1, #cfg.random_last_names)],
						age = math.random(25, 40),
					}
				)
			end)
		end)
	end)
end)

-- city hall menu

local cityhall_menu = { name = lang.cityhall.title(), css = { top = "75px", header_color = "rgba(0,125,255,0.75)" } }

local function ch_identity(player, choice)
	local user_id = vRP.getUserId(player)
	if user_id == nil then return end

	vRP.prompt(player, lang.cityhall.identity.prompt_firstname(), "", function(player, firstname)
		if string.len(firstname) < 2 or string.len(firstname) >= 50 then
			vRP.notify(user_id, lang.common.invalid_value())
			return
		end
		firstname = sanitizeString(firstname, sanitizes.name[1], sanitizes.name[2])

		vRP.prompt(player, lang.cityhall.identity.prompt_name(), "", function(player, name)
			if string.len(name) < 2 or string.len(name) >= 50 then
				vRP.notify(user_id, lang.common.invalid_value())
				return
			end
			name = sanitizeString(name, sanitizes.name[1], sanitizes.name[2])

			vRP.prompt(player, lang.cityhall.identity.prompt_age(), "", function(player, age)
				age = parseInt(age)
				if age < 16 or age > 150 then
					vRP.notify(user_id, lang.common.invalid_value())
					return
				end

				if not vRP.tryPayment(user_id, cfg.new_identity_cost) then
					vRP.notify(user_id, lang.money.not_enough())
					return
				end

				vRP.generateRegistrationNumber(function(registration)
					vRP.generatePhoneNumber(function(phone)
						MySQL.Async.execute(
							"UPDATE vrp_user_identities SET firstname = @firstname, name = @name, age = @age, phone = @phone WHERE user_id = @user_id",
							{
								user_id = user_id,
								firstname = firstname,
								name = name,
								age = age,
								phone = phone,
							}
						)
						vRP.notify(user_id, lang.money.paid({ cfg.new_identity_cost }))
					end)
				end)
			end)
		end)
	end)
end

cityhall_menu[lang.cityhall.identity.title()] =
	{ ch_identity, lang.cityhall.identity.description({ cfg.new_identity_cost }) }

local function cityhall_enter()
	local user_id = vRP.getUserId(source)
	if user_id ~= nil then
		vRP.openMenu(source, cityhall_menu)
	end
end

local function cityhall_leave()
	vRP.closeMenu(source)
end

local function build_client_cityhall(source)
	local user_id = vRP.getUserId(source)
	if user_id == nil then return end

	local x, y, z = table.unpack(cfg.city_hall)
	vRPclient.addMarker(source, { x, y, z - 1, 0.7, 0.7, 0.5, 0, 255, 125, 125, 150 })
	vRP.setArea(source, "vRP:cityhall", x, y, z, 1, 1.5, cityhall_enter, cityhall_leave)
end

AddEventHandler("vRP:playerSpawn", function(user_id, source, first_spawn)
	vRP.getUserIdentity(user_id, function(identity)
		if identity then
			vRPclient.setRegistrationNumber(source, { identity.registration or "000AAA" })
		end
	end)

	if first_spawn then
		build_client_cityhall(source)
	end
end)

-- Helper: get driver license display text
local function getDriverLicenseText(dmvtest)
	if dmvtest == 1 then return "Ja"
	elseif dmvtest == 2 then return "Frataget"
	else return "Nej" end
end

-- Helper: get home address display
local function getAddressDisplay(address)
	if address then
		return address.home .. " nr. ", address.number
	end
	return "Hjemløs", ""
end

-- player identity menu
vRP.registerMenuBuilder("main", function(add, data)
	local user_id = vRP.getUserId(data.player)
	if user_id == nil then return end

	vRP.getUserIdentity(user_id, function(identity)
		if identity == nil then return end

		vRP.getUserAddress(user_id, function(address)
			local home, number = getAddressDisplay(address)

			MySQL.Async.fetchAll("SELECT DmvTest FROM vrp_users WHERE id = @user_id", { user_id = user_id }, function(rows)
				local driverlicense = getDriverLicenseText(#rows > 0 and rows[1].DmvTest or 1)

				local job = vRP.getUserGroupByType(user_id, "job")
				local checksub = vRP.getUserGroupByType(user_id, job)
				if checksub ~= nil and checksub ~= "" then
					job = checksub
				end

				local content = lang.cityhall.menu.info({
					htmlEntities.encode(identity.name),
					htmlEntities.encode(identity.firstname),
					identity.age,
					identity.registration,
					identity.phone,
					home,
					number,
					driverlicense,
					format_thousand(math.floor(vRP.getWalletAmount(user_id))),
					format_thousand(math.floor(vRP.getBankAmount(user_id))),
					user_id,
					job,
				})

				local choices = {}
				choices[lang.cityhall.menu.title()] = { function() end, content }
				add(choices)
			end)
		end)
	end)
end)
