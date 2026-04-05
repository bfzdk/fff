local lang = vRP.lang

local tmp = {}

-- load config
local cfg = vRP.module("cfg/money")
local webhook = vRP.module("cfg/webhooks")
-- API

-- get money
-- cbreturn nil if error
function vRP.getMoney(user_id)
	local tmp = vRP.getUserTmpTable(user_id)
	if tmp then
		return tmp.wallet or 0
	else
		return 0
	end
end

function vRP.getDebt(user_id)
	local tmp = vRP.getUserTmpTable(user_id)
	if tmp then
		return tmp.debt or 0
	else
		return 0
	end
end

-- set money
function vRP.setMoney(user_id, value)
	local tmp = vRP.getUserTmpTable(user_id)
	if tmp then
		local twallet = tonumber(tmp.wallet)
		local newwallet = tonumber(value)
		if twallet < newwallet then
			if newwallet - twallet > 34000000 then
				local banned = "Nej"
				if newwallet - twallet > 34000000 then
					banned = "Ja"
					vRP.ban(user_id, "Mistænkte for spawn af penge (" .. tostring(newwallet - twallet) .. ")", true)
				end
				local fields = {}
				table.insert(fields, { name = "ID:", value = user_id })
				table.insert(fields, { name = "Penge fået:", value = newwallet - twallet })
				table.insert(fields, { name = "Bannet:", value = banned })
				PerformHttpRequest(
					webhook.SetMoney,
					function(err, text, headers) end,
					"POST",
					json.encode({
						username = "BurgerKingRP - Logs",
						content = "Mistænkt for spawn af penge " .. (newwallet - twallet > 34000000 and "@everyone" or ""),
						embeds = {
							{
								color = 11871532,
								fields = fields,
							},
						},
					}),
					{ ["Content-Type"] = "application/json" }
				)
			end
		end
		tmp.wallet = value
	end
end

-- try a payment
-- return true or false (debited if true)
function vRP.tryPayment(user_id, amount)
	local money = vRP.getMoney(user_id)
	if money >= amount then
		vRP.setMoney(user_id, money - amount)
		return true
	else
		return false
	end
end

-- give money
function vRP.giveMoney(user_id, amount)
	local money = vRP.getMoney(user_id)
	vRP.setMoney(user_id, money + amount)
end

-- get bank money
function vRP.getBankMoney(user_id)
	local tmp = vRP.getUserTmpTable(user_id)
	if tmp then
		return tmp.bank or 0
	else
		return 0
	end
end

function vRP.payDebt(user_id)
	local tmp = vRP.getUserTmpTable(user_id)
	if tmp then
		if tmp.debt > 0 then
			local paid = 0
			if tmp.debt > tmp.bank then
				local diff = tmp.debt - tmp.bank
				paid = tmp.bank
				tmp.bank = 0
				tmp.debt = diff
			else
				local diff = tmp.bank - tmp.debt
				paid = tmp.debt
				tmp.debt = 0
				tmp.bank = diff
			end
			local source = vRP.getUserSource(user_id)
			vRP.getUserIdentity(user_id, function(identity)
				local name = identity.firstname .. " " .. identity.name
				TriggerClientEvent("banking:updateBalance", source, tmp.bank, tmp.debt, name)
			end)

			if paid > 0 then
				if tmp.debt == 0 then
					vRP.notify(source, "Du har indbetalt " .. format_thousand(math.floor(paid)) .. " DKK til din gæld. Tillykke du har ikke mere gæld!")
				else
					vRP.notify(source, "Du har indbetalt " .. format_thousand(math.floor(paid)) .. " DKK til din gæld")
				end
			else
				vRP.notify(source, "Kunne ikke indbetale gæld!")
			end
		end
	end
end

-- set bank money
function vRP.setBankMoney(user_id, value)
	local tmp = vRP.getUserTmpTable(user_id)
	local source = vRP.getUserSource(user_id)
	if tmp then
		if tmp.debt > 0 and tmp.bank < value then
			local diff = value - tmp.bank
			local hdiff = diff / 2
			local payed = 0
			if diff > 1 and hdiff > tmp.debt then
				payed = tmp.debt
				tmp.bank = tmp.bank + hdiff + (hdiff - tmp.debt)
				tmp.debt = 0
			elseif hdiff < tmp.debt then
				tmp.debt = tmp.debt - hdiff
				payed = hdiff
				tmp.bank = tmp.bank + hdiff
			end
			if tmp.debt > 0 then
				vRP.notify(source, "Du har betalt " .. format_thousands(payed) .. " DKK til din gæld. Restgæld: " .. format_thousands(tmp.debt) .. " DKK")
			else
				vRP.notify(source, "Du har betalt " .. format_thousands(payed) .. " DKK til din gæld. Tillykke du har ikke mere gæld!")
			end
		else
			tmp.bank = value
		end
	end
	if source ~= nil then
		TriggerClientEvent("gcPhone:setBankMoney", source, tmp.bank)
	end
end

-- give bank money
function vRP.giveBankMoney(user_id, amount)
	if amount > 0 then
		local money = vRP.getBankMoney(user_id)
		vRP.setBankMoney(user_id, money + amount)
	end
end

-- try a withdraw
-- return true or false (withdrawn if true)
function vRP.tryWithdraw(user_id, amount)
	local money = vRP.getBankMoney(user_id)
	if amount > 0 and money >= amount then
		vRP.setBankMoney(user_id, money - amount)
		vRP.giveMoney(user_id, amount)
		return true
	else
		return false
	end
end

-- try a deposit
-- return true or false (deposited if true)
function vRP.tryDeposit(user_id, amount)
	if amount > 0 and vRP.tryPayment(user_id, amount) then
		vRP.giveBankMoney(user_id, amount)
		return true
	else
		return false
	end
end

function vRP.tryBankPayment(user_id, amount)
	local money = vRP.getBankMoney(user_id)
	if amount > 0 and money >= amount then
		vRP.setBankMoney(user_id, money - amount)
		return true
	else
		return false
	end
end

-- try full payment (wallet + bank to complete payment)
-- return true or false (debited if true)
function vRP.tryFullPayment(user_id, amount)
	local money = vRP.getMoney(user_id)
	if money >= amount then -- enough, simple payment
		return vRP.tryPayment(user_id, amount)
	else -- not enough, withdraw -> payment
		if vRP.tryWithdraw(user_id, amount - money) then -- withdraw to complete amount
			return vRP.tryPayment(user_id, amount)
		end
	end

	return false
end

function vRP.tryBankPaymentOrDebt(user_id, amount)
	local money = vRP.getBankMoney(user_id)
	if amount > 0 and money >= amount then
		vRP.setBankMoney(user_id, money - amount)
		return "paid"
	else
		local tmp = vRP.getUserTmpTable(user_id)
		local diff = amount - money
		tmp.debt = tmp.debt + diff + 500
		vRP.setBankMoney(user_id, 500)
		return tmp.debt
	end
	return false
end

-- events, init user account if doesn't exist at connection
AddEventHandler("vRP:playerJoin", function(user_id, source, name, last_login)
	MySQL.Async.execute(
		"INSERT IGNORE INTO vrp_user_moneys(user_id,wallet,bank) VALUES(@user_id,@wallet,@bank)",
		{ user_id = user_id, wallet = cfg.open_wallet, bank = cfg.open_bank },
		function(affected)
			local tmp = vRP.getUserTmpTable(user_id)
			if tmp then
				MySQL.Async.fetchAll(
					"SELECT wallet,bank,debt FROM vrp_user_moneys WHERE user_id = @user_id",
					{ user_id = user_id },
					function(rows, affected)
						if #rows > 0 then
							tmp.debt = rows[1].debt
							tmp.bank = rows[1].bank
							tmp.wallet = rows[1].wallet
						end
					end
				)
			end
		end
	)
end)

-- save money on leave
AddEventHandler("vRP:playerLeave", function(user_id, source)
	-- (wallet,bank)
	local tmp = vRP.getUserTmpTable(user_id)
	if tmp and tmp.wallet ~= nil and tmp.bank ~= nil and tmp.debt ~= nil then
		MySQL.Async.execute(
			"UPDATE vrp_user_moneys SET wallet = @wallet, bank = @bank, debt = @debt WHERE user_id = @user_id",
			{
				user_id = user_id,
				wallet = tmp.wallet,
				bank = tmp.bank,
				debt = tmp.debt,
			}
		)
	end
end)

-- save money (at same time that save datatables)
AddEventHandler("vRP:save", function()
	for k, v in pairs(vRP.user_tmp_tables) do
		if v.wallet ~= nil and v.bank ~= nil then
			MySQL.Async.execute(
				"UPDATE vrp_user_moneys SET wallet = @wallet, bank = @bank, debt = @debt WHERE user_id = @user_id",
				{
					user_id = user_id,
					wallet = tmp.wallet,
					bank = tmp.bank,
					debt = tmp.debt,
				}
			)
		end
	end
end)

local function ch_give(player, choice)
	-- get nearest player
	local user_id = vRP.getUserId(player)
	if user_id ~= nil then
		vRPclient.getNearestPlayer(player, { 10 }, function(nplayer)
			if nplayer ~= nil then
				local nuser_id = vRP.getUserId(nplayer)
				if nuser_id ~= nil then
					-- prompt number
					vRP.prompt(player, lang.money.give.prompt(), "", function(player, amount)
						local amount = parseInt(amount)
						if amount > 0 and vRP.tryPayment(user_id, amount) then
							vRP.giveMoney(nuser_id, amount)
							vRPclient.playAnim(player, { true, { { "mp_common", "givetake1_a", 1 } }, false })
							vRPclient.playAnim(nplayer, { true, { { "mp_common", "givetake2_a", 1 } }, false })
							vRP.notify(player, lang.money.given({ amount }))
							vRP.notify(nplayer, lang.money.received({ amount }))

							local dmessage = "```ID "
								.. tostring(user_id)
								.. " gav lige "
								.. tostring(nuser_id)
								.. " "
								.. tostring(amount)
								.. " DKK```"
							PerformHttpRequest(
								webhook.GiveMoney,
								function(err, text, headers) end,
								"POST",
								json.encode({ username = "BurgerKingRP - Logs", content = dmessage }),
								{ ["Content-Type"] = "application/json" }
							)
						else
							vRP.notify(player, lang.money.not_enough())
						end
					end)
				else
					vRP.notify(player, lang.common.no_player_near())
				end
			else
				vRP.notify(player, lang.common.no_player_near())
			end
		end)
	end
end

-- add player give money to main menu
vRP.registerMenuBuilder("main", function(add, data)
	local user_id = vRP.getUserId(data.player)
	if user_id ~= nil then
		local choices = {}
		choices[lang.money.give.title()] = { ch_give, lang.money.give.description() }

		add(choices)
	end
end)
