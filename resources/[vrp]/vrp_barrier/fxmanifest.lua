fx_version 'cerulean'
game 'gta5'

description 'vrp_animations'

dependency 'vrp'

client_scripts {
    'lib/Tunnel.lua',
    'lib/Proxy.lua',
    'client.lua',
}

server_scripts {
    '@vrp/lib/utils.lua',
    'server.lua',
}
