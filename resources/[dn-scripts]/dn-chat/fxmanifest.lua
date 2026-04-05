fx_version 'cerulean'
game 'gta5'

dependency 'vrp'

shared_script 'config.lua'

server_scripts {
    '@vrp/lib/utils.lua',
    'server.lua',
}

client_scripts {
    'client.lua',
}
