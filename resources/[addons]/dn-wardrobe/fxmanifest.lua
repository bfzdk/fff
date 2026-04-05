fx_version "cerulean"
game "gta5"

dependency "vrp"

client_script "client/main.lua"

server_script "@vRP/lib/utils.lua"
server_script "config/config.lua"
server_script "server/main.lua"
