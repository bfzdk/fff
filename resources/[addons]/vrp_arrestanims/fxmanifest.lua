fx_version("cerulean")
game("gta5")

description("vRP ArrestAnims")

dependency("vrp")

client_scripts({
	"cfg/commands.lua",
	"client.lua",
})

server_scripts({
	"@vrp/lib/utils.lua",
	"server.lua",
})
