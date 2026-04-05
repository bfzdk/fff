fx_version 'cerulean'
game 'gta5'

dependency 'vrp'

ui_page 'html/ui.html'

files {
    'html/ui.html',
    'html/logo.png',
    'html/dmv.png',
    'html/cursor.png',
    'html/styles.css',
    'html/questions.js',
    'html/scripts.js',
    'html/debounce.min.js',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@vrp/lib/utils.lua',
    'server.lua',
}

client_scripts {
    'client.lua',
    'GUI.lua',
}
