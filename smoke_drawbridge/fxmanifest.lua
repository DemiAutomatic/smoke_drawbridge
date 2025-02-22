fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

name 'smoke_drawbridge'
repository 'https://github.com/BigSmoKe07/smoke_drawbridge'
version '1.1.0'
author 'BigSmoKe07

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua',
}

dependencies {
    '/onesync',
    'ox_lib',
}

files {
    'config/*.lua',
}
