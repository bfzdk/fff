fx_version "cerulean"
game "gta5"

ui_page {
	"html/alerts.html",
}

client_scripts {
	"client.lua",
}

server_scripts {
	"server.lua",
	"@mysql-async/lib/MySQL.lua",
}


files {
	"html/alerts.html",
	"html/main.js",
	"html/style.css",
}