fx_version "cerulean"
game "gta5"

client_scripts {
	"mapmanager_shared.lua",
	"mapmanager_client.lua",
}

server_scripts {
	"mapmanager_shared.lua",
	"mapmanager_server.lua",
}

-- remove ts
server_export("getCurrentGameType")
server_export("getCurrentMap")
server_export("changeGameType")
server_export("changeMap")
server_export("doesMapSupportGameType")
server_export("getMaps")
server_export("roundEnded")
