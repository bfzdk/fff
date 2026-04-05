fx_version("cerulean")
game("gta5")

this_is_a_map("yes")

dependency("vrp")

shared_script("config.lua")

files({
	"stream/v_int_shop.ytyp",
})

data_file("DLC_ITYP_REQUEST")("stream/v_int_shop.ytyp")

client_scripts({
	"lib/Tunnel.lua",
	"lib/Proxy.lua",
	"callback/client.lua",
	"client.lua",
})

server_scripts({
	"lib/Tunnel.lua",
	"lib/Proxy.lua",
	"@vrp/lib/utils.lua",
	"callback/server.lua",
	"server.lua",
})
