fx_version("cerulean")
game("gta5")

ui_page("notifs/index.html")

client_scripts({
	"map.lua",
	"client.lua",
	"GUI.lua",
	"models_c.lua",
})

server_scripts({
	"@vrp/lib/utils.lua",
	"server.lua",
})
