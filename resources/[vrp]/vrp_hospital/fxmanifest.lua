fx_version 'cerulean'
game 'gta5'

dependency 'vrp'

server_scripts {
    'sv_hospital.lua',
}

client_scripts {
    'lib/Tunnel.lua',
    'lib/Proxy.lua',
    'cl_hospital.lua',
}
