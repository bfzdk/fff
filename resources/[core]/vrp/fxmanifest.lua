fx_version "cerulean"
game "gta5"

ui_page "gui/index.html"

files {
	"cfg/client.lua",
	"gui/index.html",
	"gui/design.css",
	"gui/bg.png",
	"gui/main.js",
	"gui/Menu.js",
	"gui/ProgressBar.js",
	"gui/WPrompt.js",
	"gui/RequestManager.js",
	"gui/AnnounceManager.js",
	"gui/Div.js",
	"gui/dynamic_classes.js",
}

shared_scripts {
	'lib/utils.lua',
	'main.lua' -- new main handler
}

server_scripts {
	"@oxmysql/lib/MySQL.lua",
	"server/base.lua",
	"server/gui.lua",
	"server/group.lua",
	"server/admin.lua",
	"server/survival.lua",
	"server/player_state.lua",
	"server/map.lua",
	"server/money.lua",
	"server/inventory.lua",
	"server/identity.lua",
	"server/business.lua",
	"server/item_transformer.lua",
	"server/emotes.lua",
	"server/police.lua",
	"server/home.lua",
	"server/home_components.lua",
	"server/mission.lua",
	"server/aptitude.lua",
	"server/paycheck.lua",
	"server/basic_phone.lua",
	"server/basic_market.lua",
	"server/basic_garage.lua",
	"server/basic_items.lua",
	"server/basic_skinshop.lua",
	"server/basic_gunshop.lua",
	"server/cloakroom.lua",
}

client_scripts {
	"client/base.lua",
	"client/iplloader.lua",
	"client/gui.lua",
	"client/player_state.lua",
	"client/survival.lua",
	"client/map.lua",
	"client/identity.lua",
	"client/basic_garage.lua",
	"client/police.lua",
	"client/policespikes.lua",
	"client/drag.lua",
	"client/adminvehicle.lua",
	"client/admin.lua",
}
