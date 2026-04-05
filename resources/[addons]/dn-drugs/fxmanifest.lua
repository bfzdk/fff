fx_version "cerulean"
game "gta5"

dependency "vrp"

client_scripts {
	"@vRP/lib/Tunnel.lua",
	"@vRP/lib/Proxy.lua",
	"client/main.lua",
}

server_scripts {
	"@vRP/lib/utils.lua",
	"server/main.lua",
}
