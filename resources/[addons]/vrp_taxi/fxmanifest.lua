fx_version "cerulean"
game "gta5"

ui_page "html/ui.html"

files {
	"html/ui.html",
	"html/taximeter.ttf",
	"html/cursor.png",
	"html/styles.css",
	"html/scripts.js",
	"html/debounce.min.js",
}

client_script 'client/main.lua'
server_script 'server/main.lua'