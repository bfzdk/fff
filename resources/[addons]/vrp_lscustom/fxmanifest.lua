fx_version "cerulean"
game "gta5"

shared_script 'config.lua'

client_scripts {
	"client/menu.lua",
	"client/main.lua",
}

server_scripts {
	"@oxmysql/lib/MySQL.lua",
	"server/main.lua",
}