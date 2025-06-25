fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'Crizii-Itemviewer'
version '1.2.9'

author 'Crizii'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/utils.lua',
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/icon.png',
    'locales/*.json',
}

dependencies {
    'vorp_core',
    'ox_lib',
}

lua54 'yes'