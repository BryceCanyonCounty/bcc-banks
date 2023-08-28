fx_version 'adamant'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

game 'rdr3'
lua54 'yes'
version '1.0.0'
author 'BCC Scripts'

client_scripts {
   'client/main.lua',
}

server_scripts {
   '@oxmysql/lib/MySQL.lua',
   'server/api-loader.lua', -- Load Core and Inventory API's
   'server/helpers/*.lua',
   'server/controllers/*.lua',
   'server/services/*.lua',
   'server/main.lua',
}

shared_scripts {
   'shared/config.lua'
}


ui_page {
   "ui/index.html"
}

files {
   "ui/index.html",
   "ui/js/*.*",
   "ui/css/*.*",
   "ui/fonts/*.*",
   "ui/images/*.*",
}

dependencies {
   'oxmysql',
}


exports {}
