extends Node


var playerData := { # various important player variables stored in a dictionary
	"player": {
		"name": "Flynn",
		"level": 1,
		"levelCap":15, # maximum level until exp stops going up. increases each epiphany
		"epiphany":0,
		"experience": {
			"current": 0,
			"needed": 10
		},
		"skillPoints":0,
		"stats": { # TODO: you were making enemydb globals match player globals to calculate battle states like speed to determine turn order
			"strength":1,
			"intelligence":1,
			"survival":1,
			"currentHealth": 100,
			"maxHealth": 100,
			"battleIQ" : 1, # increases your accuracy
			"speed": 5,
			"attack": 1,
			"expGain":1.0,# multiplier for how much exp each fight gives you, modified by Intelligence (secret stat)
			"baseDefense": 5,
			"headArmorDefense": 0,
			"bodyArmorDefense": 0,
			"compoundDefense": 5, # compound defense = baseDefense + armorDefense
			"radiation": 0,
			"maxRadiation": 100
		},
		"body": {
			"weapon": "woodenBat",
			"body": "oldLeatherJacket",
			"head": "wornHelmet",
			"gear": [],
		},
		"gear" : {
			"gasMask": {
				"equipped" : true,
			},
		},
		"position": {
			"x": 0,
			"y": 0,
			"zone": "Desert_00"
		},
		"inventory": {
				"radio" : {
				"quantity": 1,
				"bookmarked" : false,
				},
				"familyPhoto" : {
				"quantity": 1,
				"bookmarked" : false,
				},
				"driedMeat" : {
				"quantity" : 5,
				"bookmarked" : false,
				}
				
			},
			
		"weapons": {
				"woodenBat" : {
				"quantity": 1,
				"unlocked": true,
				"equipped":true
				
				},
				"magnum" : {
				"quantity": 1,
				"ammo": 4,
				"unlocked": true,
				"equipped":false
				},
				"shotgun" : {
				"quantity": 1,
				"ammo": 1,
				"ammoOrder" : ["S",],
				"loadOrder" : ["alt"],
				"unlocked": true,
				"equipped":false,
				
				},
				"rpg22" : {
				"quantity": 1,
				"ammo": 1,
				"unlocked": true,
				"equipped":false
				},
			},
		"ammo" : {
			"magnum" : 3, # THESE ARE PACKS
			"buckshot" : 3, # THESE ARE INDIVIDUAL ROUNDS
			"slug" : 2,
			
		},
			
		"armor": {
				"head" : {
					"wornHelmet" : {
					"quantity": 1,
					"equipped":true,
					},
				},
				"body" : {
				"oldLeatherJacket" : {
					"quantity": 1,
					"equipped":true,
					},
				},
			},
		"statusEffects": {
		"bleeding": {
			"active" : false,
			"points" : 0,
			"harming" : true,
			"baseDmg" : 5,
			"appliedDmg" : 5,
			"turnSkip": false,
			"effectChance": 100,
			
			"announcementCure" : "Flynn's wounds dried up.",
			"resultCure" : "He is no longer Bleeding.",
			
			"announcementInflict" : "Flynn started bleeding.",
			"announcementHarm" : ["Flynn suffered blood loss.",],
			"resultHarm" : "Flynn took [DAMAGE] HP damage.",
			
		},
		"illness": {
			"active" : false,
			"points" : 0,
			"harming" : true,
			"baseDmg" : 5,
			"appliedDmg" : 5,
			"turnSkip": true,
			"effectChance": 25, # 25% chance this effect will do something per turn
			
			"announcementCure" : "Flynn started ignoring his illness.",
			"resultCure" : "He is no longer Ill.",
			
			"announcementInflict" : "Flynn got sick.",
			"announcementHarm" : ["Flynn coughed.","Flynn vomitted blood.","Flynn is suffering from a headache.",],
			"resultHarm" : "Flynn took [DAMAGE] HP damage.",
		},
		"cripple": {
			"active" : false,
			"points" : 0,
			"harming" : false,
			"turnSkip": false,
			"speedMod":0.25,
			"effectChance": 100,
			
			"announcementCure" :  "Flynn stopped caring about his injury.",
			"resultCure" : "He is no longer crippled.",
			
			"announcementInflict" : "Flynn became crippled.",
		},
		"fatigue": {
			"active" : false,
			"points" : 0,
			"harming" : false,
			"turnSkip": true,
			"effectChance":50,
			"speedMod":0.75,
			"defenseMod":0.5,
			
			"announcementCure" : "Flynn's circulation is kicking in.",
			"resultCure" : "He is no longer fatigued.",
			
			"announcementInflict" : "Flynn is fatigued.",
			"announcementHarm" : ["Flynn blanked out.", "Flynn is staring off.", "Flynn couldn't react in time."],
		},
		"berserk": {
			"active" : false,
			"points" : 10,
			"harming" : false,
			"turnSkip": true,
			"effectChance":100,
			"baseAtk" : 10,
			"appliedAtk" : 10,
			
			"announcementCure" : "!..",
			"resultCure" : "Flynn is no longer berserk.",
			
			"announcementInflict" : "[color=red]FLYNN WENT BERSERK!!![/color]",
			"announcementAttack" : ["[color=red]FLYNN PUNCHED [TARGET]![/color]","[color=red]FLYNN DOVE HEAD FIRST TO BITE [TARGET]![/color]","[color=red]FLYNN STRANGLED [TARGET]![/color]",],
			"resultAttack" : "[color=red][TARGET] took [DAMAGE] HP damage.[/color]"
		},
		},
		"flags": {
		}
	},
	"game" : {
		"difficulty" : "normal",
		"lastSaved": "Never",
		"startTime" : null,
		"runTime" : 0,
	}
}


# Player Data Change Functions

func levelUp():
	var player = playerData["player"]
	player["level"] = player["level"] + 1
	player["experience"]["needed"] = int(round(player["experience"]["needed"] * 1.5))
	player["skillPoints"] += 1
	
func skillUp(skill):
	playerData["player"]["stats"][skill] += 1
	playerData["player"]["skillPoints"] -= 1
	
func skillConfig(skill):
	var stats = playerData["player"]["stats"]
	match skill:
		"strength":
			stats["attack"] += 1
		"survival":
			stats["baseDefense"] = 5 + (stats["survival"] / 2)
			stats["speed"] = 5 + (stats["survival"] / 5)
			playerData["player"]["stats"]["compoundDefense"] = playerData["player"]["stats"]["headArmorDefense"] + playerData["player"]["stats"]["bodyArmorDefense"] + playerData["player"]["stats"]["baseDefense"]
			var maxHealth = stats["maxHealth"]
			var currentHealth = stats["currentHealth"]
			var ratio = float(currentHealth) / float(maxHealth)
			stats["maxHealth"] = 100 + (stats["survival"] * 6)
			stats["currentHealth"] = clamp(int(round(stats["maxHealth"] * ratio)),0,stats["maxHealth"])
		"intelligence":
			stats["battleIQ"] = 1 + stats["intelligence"]
			stats["expGain"] = mini(stats["intelligence"] * 3, 50) # the maximum exp multiplier is 50%.
