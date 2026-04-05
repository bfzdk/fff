fx_version 'cerulean'
game 'gta5'

description 'chat management stuff'

dependency 'vrp'

ui_page 'html/index.html'

files {
    'html/index.html',
}

server_scripts {
    '@vrp/lib/utils.lua',
    'sv_chat.lua',
}

client_script 'cl_chat.lua'
