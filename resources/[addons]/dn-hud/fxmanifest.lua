fx_version "cerulean"
game "gta5"

ui_page "html/ui.html"
files {
	"html/fonts/gta-ui.ttf",
	"html/ui.html",
	"html/ui.css",
	"html/ui.js",
}

shared_script 'config.lua'
client_script "client/main.lua"
server_script "server/main.lua"