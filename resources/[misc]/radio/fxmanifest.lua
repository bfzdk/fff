fx_version 'cerulean'
game 'gta5'

files {
    'index.html',
}

ui_page 'index.html'

client_scripts {
    'data.js',
    'client.js',
}

supersede_radio 'RADIO_02_POP' { url = '...', volume = 0.2, name = 'The Voice' }
