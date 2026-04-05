fx_version "cerulean"
game "gta5"

shared_scripts { -- fix ts
	'cfg/blips.lua',
	'cfg/display.lua'
}

client_script 'client/main.lua'
server_script 'server/main.lua'