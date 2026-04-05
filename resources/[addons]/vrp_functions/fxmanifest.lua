fx_version("cerulean")
game("gta5")

dependency("vrp")

ui_page("index.html")

files({
	"index.html",
})

client_scripts({
	"lib/Tunnel.lua",
	"lib/Proxy.lua",
	"client.lua",
})

server_scripts({
	"@vrp/lib/utils.lua",
	"server.lua",
})
