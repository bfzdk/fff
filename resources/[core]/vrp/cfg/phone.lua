local cfg = {}

-- Sørrelse af SMS Historik
cfg.sms_history = 15

-- Max størrelse af SMS.
cfg.sms_size = 500

-- Hvor lang tid SMS position skal være. (10 minutter)
cfg.smspos_duration = 600

-- define phone services
-- blipid, blipcolor (customize alert blip)
-- alert_time (alert blip display duration in seconds)
-- alert_permission (permission required to receive the alert)
-- alert_notify (notification received when an alert is sent)
-- notify (notification when sending an alert)
cfg.services = {
	["Politiet"] = {
		blipid = 304,
		blipcolor = 38,
		alert_time = 900, -- 15 minutter
		alert_permission = "police.drag",
		alert_notify = "📱^1^*Politi Besked:",
		notify = "📱 Du ringede til politiet.",
		answer_notify = "📱 Bare rolig, politiet er på vej.",
	},
	["Ambulance"] = {
		blipid = 153,
		blipcolor = 1,
		alert_time = 900, -- 15 minutter
		alert_permission = "emergency.service",
		alert_notify = "📱 112 Besked:",
		notify = "📱 Du har ringet til 112.",
		answer_notify = "📱 Bare rolig, ambulancen er på vej.",
	},
	["Advokat"] = {
		blipid = 351,
		blipcolor = 5,
		alert_time = 900, -- 15 minutter
		alert_permission = "advokat.service",
		alert_notify = "📱 Advokat besked:",
		notify = "📱 Du har ringet efter en advokat.",
		answer_notify = "📱 Vi har sendt en advokat ud til dig!",
	},
	["Journalist"] = {
		blipid = 135,
		blipcolor = 17,
		alert_time = 900, -- 15 minutter
		alert_permission = "journalist.phone",
		alert_notify = "📱 Journalist besked:",
		notify = "📱 Du har ringet efter en fra DR.",
		answer_notify = "📱 Vi har sendt en fra Danmarks Radio ud!",
	},
	["Uber"] = {
		blipid = 198,
		blipcolor = 5,
		alert_time = 900, -- 15 minutter
		alert_permission = "uber.service",
		alert_notify = "📱 Uber Besked:",
		notify = "📱 Du har ringet til en Uber.",
		answer_notify = "📱 En uber er på vej mod dig.",
	},
	["Taxi Chauffør"] = {
		blipid = 198,
		blipcolor = 5,
		alert_time = 900, -- 15 minutter
		alert_permission = "taxi.service",
		alert_notify = "📱 Taxa Besked:",
		notify = "📱 Du har ringet til en Taxa.",
		answer_notify = "📱 En taxa er på vej mod dig.",
	},
	["Automekaniker"] = {
		blipid = 446,
		blipcolor = 5,
		alert_time = 900, -- 15 minutter
		alert_permission = "repair.service",
		alert_notify = "📱 Falck Besked:",
		notify = "📱 Du har ringet efter Falck.",
		answer_notify = "📱 Falck er på vej.",
	},
}

-- define phone announces
-- image: background image for the announce (800x150 px)
-- price: amount to pay to post the announce
-- description (optional)
-- permission (optional): permission required to post the announce
cfg.announces = {
	["Admins"] = {
		--image = "nui://vrp_mod/announce_admin.png",
		image = "https://i.imgur.com/xjHvpMd.jpg",
		price = 0,
		description = "Kun for Admins",
		permission = "admin.besked",
	},
	["Politi"] = {
		--image = "nui://vrp_mod/announce_police.png",
		image = "https://i.imgur.com/xry5L1X.jpg",
		price = 0,
		description = "Kun for Politiet.",
		permission = "police.besked",
	},
	["112"] = {
		image = "https://i.imgur.com/5Ax6xPe.jpg",
		price = 0,
		description = "Kun for 112.",
		permission = "emergency.besked",
	},

	["Reklame"] = {
		--image = "nui://vrp_mod/announce_commercial.png",
		image = "https://i.imgur.com/wEIYPAP.jpg",
		description = "Bruges til salg, eller andet relateret.",
		price = 10000,
	},
	["Fest"] = {
		--image = "nui://vrp_mod/announce_party.png",
		image = "https://i.imgur.com/e91JtGQ.jpg",
		description = "Inviter folk til fest.",
		price = 5000,
	},
	["Taxi"] = {
		image = "https://i.imgur.com/iDWyOOk.jpg",
		description = "Meld din ankomst til byen, som Taxachauffør.",
		price = 50,
		permission = "taxi.besked",
	},
	["Falck"] = {
		image = "https://i.imgur.com/2MDzH3h.jpg",
		description = "Meld din ankomst til byen, som Mekaniker.",
		price = 50,
		permission = "repair.besked",
	},
}

return cfg
