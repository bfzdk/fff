fx_version "cerulean"
game "gta5"

shared_scripts { -- change ts
	'cfg/bank.lua',
	'cfg/robbery.lua'
}

client_script 'client/main.lua'
server_script 'server/main.lua'
