resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

server_scripts {
  'config.lua',
  'server/main.lua',
}

client_scripts {
  '23008.lua',
  'config.lua',
  'client/main.lua',
}

ui_page('html/index.html')
files({
	"html/index.html",
	"html/index.css",
	"html/jquery.js",
	"html/index.js",
})