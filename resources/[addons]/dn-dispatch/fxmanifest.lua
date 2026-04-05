fx_version "cerulean"
game "gta5"

ui_page {
	"html/alerts.html",
}

client_script "client/main.lua"

server_script "@mysql-async/lib/MySQL.lua"
server_script "server/main.lua"

files {
	"html/alerts.html",
	"html/main.js",
	"html/style.css",
}
