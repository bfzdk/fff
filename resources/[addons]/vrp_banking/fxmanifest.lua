fx_version("cerulean")
game("gta5")

dependency("vrp")

ui_page("html/ui.html")

files({
	"html/ui.html",
	"html/pricedown.ttf",
})

server_scripts({
	"@vrp/lib/utils.lua",
	"server.lua",
})

client_script("client.lua")
