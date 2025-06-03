fx_version 'cerulean'
game 'gta5'
lua54 'yes'
version '1.0.0'
author 'Taco Development'
description 'Advanced Weed Planting'

ui_page 'web/index.html'

files {
    'web/*',
    'locales/*.json',
    'stream/weed_empty_pot.ydr',
}

data_file 'DLC_ITYP_REQUEST' 'stream/weed_empty_pot.ytyp'

shared_scripts {
    '@ox_lib/init.lua',
    'shared.lua',
}

client_scripts {
    'bridge/**/client.lua',
    'client/**'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/**/server.lua',
    'server/*.lua'
}

dependencies {
    '/server:6116',
    '/onesync',
    'oxmysql'
}
