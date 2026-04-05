fx_version("cerulean")
game("gta5")

lua54("yes")

description("Simple Notification Script using https://notifyjs.com/")

ui_page("html/index.html")

files({
	"html/index.html",
})

client_script("cl_notify.lua")

export("SetQueueMax")
export("SendNotification")
