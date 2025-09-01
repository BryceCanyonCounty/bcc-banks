fx_version 'adamant'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

game 'rdr3'
lua54 'yes'
version '1.0.0'
author 'BCC Scripts'

client_scripts {
   'client/api-loader.lua',
   'client/helpers/*.lua',
   'client/services/*.lua',
   'client/menus/*.lua',
   'client/main.lua',
}

server_scripts {
   '@oxmysql/lib/MySQL.lua',
   'server/api-loader.lua',
   'server/helpers/*.lua',
   'server/controllers/*.lua',
   'server/services/*.lua',
   'server/main.lua',
}

shared_scripts {
   'shared/helpers/*.lua',
   'shared/config.lua'
}

dependencies {
   'oxmysql',
}

files {
  'ui/*',
  'ui/images/*',
}

exports {}
