fx_version("cerulean")
game("gta5")

dependency("vrp")

server_scripts({
	"@vrp/lib/utils.lua",
	"server.lua",
})
