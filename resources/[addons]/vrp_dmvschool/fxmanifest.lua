fx_version "cerulean"
game "gta5"

ui_page "html/ui.html"

files {
	"html/ui.html",
	--'html/logo.png', weird
	"html/dmv.png",
	"html/cursor.png",
	"html/styles.css",
	"html/questions.js",
	"html/scripts.js",
	"html/debounce.min.js",
}

client_script 'client/main.lua'
server_scripts {
	"@oxmysql/lib/MySQL.lua",
	"server/main.lua",
}

