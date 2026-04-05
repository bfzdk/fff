fx_version("cerulean")
game("gta5")

dependency("vrp")
dependency("mysql-async")

client_scripts({
	"lib/Proxy.lua",
	"lib/Tunnel.lua",
	"lsconfig.lua",
	"menu.lua",
	"client.lua",
})

server_scripts({
	"@oxmysql/lib/MySQL.lua",
	"@vrp/lib/utils.lua",
	"server.lua",
})
