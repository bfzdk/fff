fx_version 'cerulean'
game 'gta5'

dependency 'vrp'

shared_file 'config.lua'

server_scripts {
    '@vrp/lib/utils.lua',
    'server/server.lua',
}

client_scripts {
    'client/client.lua',
}
