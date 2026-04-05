fx_version "cerulean"
game "gta5"

client_scripts { -- fix ts
	'client/main.lua',
	'client/notifs.lua',
	'client/GUI.lua',
	'client/map.lua'
}

server_script 'server/main.lua'