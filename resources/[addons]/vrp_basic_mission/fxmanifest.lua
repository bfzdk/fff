fx_version("cerulean")
game("gta5")

description("vRP basic mission")

dependency("vrp")

client_scripts({
	"client/Tunnel.lua",
	"client/Proxy.lua",
	"client.lua",
})

server_scripts({
	"@vrp/lib/utils.lua",
	"server.lua",
})
