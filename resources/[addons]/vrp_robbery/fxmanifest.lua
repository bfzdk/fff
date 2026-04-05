fx_version("cerulean")
game("gta5")

description("vRP bank")

dependency("vrp")

client_scripts({
	"cfg/bank.lua",
	"client.lua",
})

server_scripts({
	"@vrp/lib/utils.lua",
	"cfg/bank.lua",
	"server.lua",
})
