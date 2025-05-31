
fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author '[Fros Development]'
description ''
version '1.0.0'


client_scripts {
    'client/client.lua' -- Make sure your script file is named properly
}

server_scripts {
    'server/server.lua',
    '@oxmysql/lib/MySQL.lua'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}






