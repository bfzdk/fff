fx_version "cerulean"
game "gta5"

ui_page "html/index.html"

files {
	"html/index.html",
	"html/index.css",
	"html/index.js",
	"html/img/*.png",
}

client_script {
	"config.lua",
	"client.lua",
}

server_script "server.lua"