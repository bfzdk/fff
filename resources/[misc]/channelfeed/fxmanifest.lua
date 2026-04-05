fx_version "cerulean"
game "gta5"

files {
	"client/html/index.html",
	"client/html/feed.js",
	"client/fonts/roboto-regular.ttf",
	"client/fonts/roboto-condensed.ttf",
}

ui_page "client/html/index.html"

client_script "client/channelfeed.lua"

export "printTo"
export "addChannel"
export "removeChannel"