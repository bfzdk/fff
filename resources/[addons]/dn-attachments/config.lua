cfg = {}

cfg.equip_text = "Du satte en %s på dit våben"
cfg.remove_text = "Du fjernede en %s fra dit våben"

-- Liste af components: https://wiki.rage.mp/index.php?title=Weapons_Components.
cfg.attachments = {
	["silencer"] = {
		itemName = "Lyddæmper",
		description = "Gør dit våben mere stille når du skyder",
		weight = 0.5,
		components = {
			"COMPONENT_AT_PI_SUPP_02",
			"COMPONENT_AT_PI_SUPP",
			"COMPONENT_AT_AR_SUPP_02",
			"COMPONENT_AT_SR_SUPP",
			"COMPONENT_AT_AR_SUPP",
			"COMPONENT_AT_SR_SUPP_03",
		},
	},

	["flashlight"] = {
		itemName = "Våbenlygte",
		description = "Lygte til dit våben, så du kan se i mørket",
		weight = 0.35,
		components = {
			"COMPONENT_AT_PI_FLSH",
			"COMPONENT_AT_PI_FLSH_03",
			"COMPONENT_AT_PI_FLSH_02",
			"COMPONENT_AT_AR_FLSH",
		},
	},

	["extendedclip"] = {
		itemName = "Udvidet magasin",
		description = "Udvidet magasin til dit våben, kan holde en større mængde skud",
		weight = 0.85,
		components = {
			"COMPONENT_PISTOL_CLIP_02",
			"COMPONENT_COMBATPISTOL_CLIP_02",
			"COMPONENT_APPISTOL_CLIP_02",
			"COMPONENT_PISTOL50_CLIP_02",
			"COMPONENT_SNSPISTOL_CLIP_02",
			"COMPONENT_HEAVYPISTOL_CLIP_02",
			"COMPONENT_REVOLVER_MK2_CLIP_02",
			"COMPONENT_SNSPISTOL_MK2_CLIP_02",
			"COMPONENT_PISTOL_MK2_CLIP_02",
			"COMPONENT_VINTAGEPISTOL_CLIP_02",
			"COMPONENT_MICROSMG_CLIP_02",
			"COMPONENT_SMG_CLIP_02",
			"COMPONENT_ASSAULTSMG_CLIP_02",
			"COMPONENT_MINISMG_CLIP_02",
			"COMPONENT_SMG_MK2_CLIP_02",
			"COMPONENT_MACHINEPISTOL_CLIP_02",
			"COMPONENT_COMBATPDW_CLIP_02",
			"COMPONENT_ASSAULTSHOTGUN_CLIP_02",
			"COMPONENT_HEAVYSHOTGUN_CLIP_02",
			"COMPONENT_ASSAULTRIFLE_CLIP_02",
			"COMPONENT_CARBINERIFLE_CLIP_02",
			"COMPONENT_ADVANCEDRIFLE_CLIP_02",
			"COMPONENT_SPECIALCARBINE_CLIP_02",
			"COMPONENT_BULLPUPRIFLE_CLIP_02",
			"COMPONENT_BULLPUPRIFLE_MK2_CLIP_02",
			"COMPONENT_SPECIALCARBINE_MK2_CLIP_02",
			"COMPONENT_ASSAULTRIFLE_MK2_CLIP_02",
			"COMPONENT_CARBINERIFLE_MK2_CLIP_02",
			"COMPONENT_COMPACTRIFLE_CLIP_02",
			"COMPONENT_MILITARYRIFLE_CLIP_02",
			"COMPONENT_MG_CLIP_02",
			"COMPONENT_COMBATMG_CLIP_02",
			"COMPONENT_COMBATMG_MK2_CLIP_02",
			"COMPONENT_GUSENBERG_CLIP_02",
			"COMPONENT_MARKSMANRIFLE_MK2_CLIP_02",
			"COMPONENT_HEAVYSNIPER_MK2_CLIP_02",
			"COMPONENT_MARKSMANRIFLE_CLIP_02",
		},
	},

	["compensator"] = {
		itemName = "Våben kompensator",
		description = "Våben kompensator et brugt til at formindske recoil",
		weight = 0.45,
		components = {
			"COMPONENT_AT_PI_COMP",
			"COMPONENT_AT_PI_COMP_02",
			"COMPONENT_AT_PI_COMP_03",
		},
	},

	["smallscope"] = {
		itemName = "Lille sigtekorn",
		description = "Et sigtekorn er brugt for en forøget præcision",
		weight = 0.25,
		components = {
			"COMPONENT_AT_SCOPE_MACRO_MK2",
			"COMPONENT_AT_SCOPE_MACRO_02_SMG_MK2",
			"COMPONENT_AT_SCOPE_MACRO_02_MK2",
		},
	},

	["mediumscope"] = {
		itemName = "Mellem sigtekorn",
		description = "Et sigtekorn er brugt for en forøget præcision",
		weight = 0.35,
		components = {
			"COMPONENT_AT_SCOPE_SMALL_SMG_MK2",
			"COMPONENT_AT_SCOPE_SMALL_MK2",
		},
	},

	["scope"] = {
		itemName = "Normalt sigtekorn",
		description = "Et sigtekorn er brugt for en forøget præcision",
		weight = 0.45,
		components = {
			"COMPONENT_AT_SCOPE_MACRO",
			"COMPONENT_AT_SCOPE_MEDIUM",
			"COMPONENT_AT_SCOPE_SMALL",
			"COMPONENT_AT_SCOPE_SMALL_02",
			"COMPONENT_AT_SCOPE_LARGE",
			"COMPONENT_AT_SCOPE_LARGE_FIXED_ZOOM",
		},
	},

	["largescope"] = {
		itemName = "Stort sigtekorn",
		description = "Et sigtekorn er brugt for en forøget præcision",
		weight = 0.55,
		components = {
			"COMPONENT_AT_SCOPE_MEDIUM_MK2",
		},
	},

	["advancedScope"] = {
		itemName = "Advanceret sigtekorn",
		description = "Et sigtekorn er brugt for en forøget præcision",
		weight = 0.65,
		components = {
			"COMPONENT_AT_SCOPE_MAX",
		},
	},

	["grip"] = {
		itemName = "Våbengreb",
		description = "Et våbengreb er brugt for en forøget præcision og stabalisering af våbnet",
		weight = 0.75,
		components = {
			"COMPONENT_AT_AR_AFGRIP",
			"COMPONENT_AT_AR_AFGRIP_02",
		},
	},
}

return cfg