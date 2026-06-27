extends Node

var enemies := {
	"True Mutant Beta": {
		"battleSprite" : "res://Assets/Scenes/Battle/Battle Sprites/Template/templateEnemyBattleSprite.tscn",
		"battleSpriteID" : "",
		"ID" : 0,
		"phase": "Phase 1",
		"distance":"mid",
		"telegraph": "",
		"stats" : {
			"experience":10,
			"health": 100,
			"maxHealth": 100,
			"stamina":100,
			"maxStamina" : 100,
			"minStaminaToAttack" : 0,
			"attackMultiplier" : 1,
			"speed" : 8,
			"surgeChance" : 5, # 5% chance of the enemy per turn to randomly regain a huge chunk of stamina
		},
		
		"statusEffects": {
		"bleeding": {
			"active" : false,
			"points" : 0,
			"harming" : true,
			"baseDmg" : 5,
			"appliedDmg" : 5,
			"turnSkip": false,
			"announcementInflict" : "[NAME] started bleeding.",
			"announcementCure" : "[NAME] licked its wound.",
			"resultCure" : "[NAME] stopped bleeding.",
			"announcementHarm" : ["[NAME] suffered blood loss.",],
			"resultHarm" : "[NAME] took [DAMAGE] HP damage.",
		},
		"illness": {
			"active" : false,
			"points" : 0,
			"harming" : true,
			"baseDmg" : 5,
			"appliedDmg" : 5,
			"turnSkip": true,
			"effectChance":50,
			"announcementInflict" : "[NAME] got sick.",
			"announcementCure" : "[NAME] stopped coughing.",
			"resultCure" : "[NAME] is no longer sick.",
			"announcementHarm" : ["[NAME] coughed.","[NAME] vomitted blood.","[NAME] is suffering from a headache.",],
			"resultHarm" : "[NAME] took [DAMAGE] HP damage.",
		},
		"cripple": {
			"active" : false,
			"points" : 0,
			"harming" : false,
			"turnSkip": false,
			"announcementInflict" : "[NAME] became crippled.",
			"announcementCure" : "[NAME] stopped limping.",
			"resultCure" : "[NAME] is no longer crippled.",
		},
		"fatigue": {
			"active" : false,
			"points" : 0,
			"harming" : false,
			"turnSkip": true,
			"effectChance":10,
			"announcementInflict" : "[NAME] is fatigued.",
			"announcementCure" : "[NAME] snapped out of it!",
			"resultCure" : "[NAME] is no longer fatigued.",
		},
		"berserk": {
			"active" : false,
			"points" : 0,
			"harming" : false,
			"turnSkip": true,
			"effectChance": 100,
			"announcementInflict" : "[color=red][NAME] WENT BERSERK!!![/color]",
			"announcementCure" : "!..",
			"resultCure" : "[NAME] is no longer berserk.",
			"announcementAttack" : ["[color=red][NAME] CLAWED AT [TARGET]![/color]","[color=red][NAME] DOVE HEAD FIRST TO BITE [TARGET]![/color]","[color=red][NAME] POKED [TARGET] IN THE EYES![/color]",],
			"resultAttack" : "[color=red][TARGET] took [DAMAGE] HP damage.[/color]"
		},
		},
		
		"limbs" : {
			"Head" : {
				"damagePercent" : 300,
				"hitRate" : 17, # Only a 10% chance you'd actually be able to shoot the head
				"description" : "HEAD\nDamage %: 300\nHit Chance %: 17\nVery unlikely to hit, but if you do, it's fatal.",
				"affinities" : { # multiplier for specific limbs
					"woodenBat" : 2
				}
				
			},
			"Torso" : {
				"damagePercent" : 50,
				"hitRate" : 90, 
				"description" : "TORSO\nDamage %: 50\nHit Chance %: 90\nEasiest to aim at, deals moderate damage."
				
			},
			"Left Arm" : {
				"damagePercent" : 100,
				"hitRate" : 40,
				"description" : "LEFT ARM\nDamage %: 100\nHit Chance %: 40\nImportant appendage, deals decent damage to target."
				
			},
			"Right Arm" : {
				"damagePercent" : 100,
				"hitRate" : 40,
				"description" : "RIGHT ARM\nDamage %: 100\nHit Chance %: 40\nImportant appendage, deals decent damage to target."
				
			},
			"Left Leg" : {
				"damagePercent" : 90,
				"hitRate" : 50,
				"description" : "LEFT LEG\nDamage %: 90\nHit Chance %: 50\nImportant appendage, deals decent damage to target."
				
			},
			"Right Leg" : {
				"damagePercent" : 90,
				"hitRate" : 50,
				"description" : "RIGHT LEG\nDamage %: 90\nHit Chance %: 50\nImportant appendage, deals decent damage to target."
				
			},
			"Tail" : {
				"damagePercent" : 300,
				"hitRate" : 8,
				"description" : "TAIL\nDamage %: 300\nHit Chance %: 8\nExtremely unlikely to hit, but if you do, it's fatal."
				
			},
		},
		"logic" : {
			"Phase 1": {
				"maxStamina": 100,
				"health" : 100,
				"maxHealth" : 100,
				"attacks": ["Slash", "Bite", "InjectTelegraph", "Screech"],
				"behavior" : "cocky",
				"canFlee" : true,
				"turns" : 0,
				"canAdvance" : true,
				}
			},
		"attacks":
			{
				"Slash" : {
					
				"minDamage": 10,
				"maxDamage": 12,
				"minRadDamage": 0,
				"maxRadDamage": 0,
				"weight": "Light",
				"cost": 0,
				"type": "Normal",
				"statusEffect": null,
				"announce": "[NAME] tore into your chest!",
				"result": "...that dealt [DAMAGE] to your health!",
				"sound": "res://Assets/Sounds/Battle/pew.mp3",
				"missResult": "...Flynn got out of the way.",
				"missSound": "res://Assets/Sounds/Random/weird.mp3",
				"announcementPause": 2,
				"impactPause": 2,
				"resultPause":2,
				"priority" : 1,
				"blockable" : false,
				},
				"Bite" : {
				"minDamage": 20,
				"maxDamage": 40,
				"minRadDamage": 0,
				"maxRadDamage": 0,
				"weight": "Medium",
				"cost": 30,
				"type": "Normal",
				"statusEffect": null,
				"announce": "[NAME] snapped at you with teeth and fangs!",
				"result": "...that dealt [DAMAGE] to your health!",
				"sound": "res://Assets/Sounds/Battle/impact.mp3",
				"missResult": "...Flynn got out of the way.",
				"missSound": "res://Assets/Sounds/Random/weird.mp3",
				"announcementPause": 2,
				"impactPause": 2,
				"resultPause":2,
				"priority" : 1,
				"blockable" : false,
			},
				"Screech" : {
				"minDamage": 0,
				"maxDamage": 0,
				"minRadDamage": 0,
				"maxRadDamage": 0,
				"weight": "Light",
				"cost": 15,
				"type": "atkBoost",
				"statusEffect": null,
				"announce": "[NAME] screeched painfully!",
				"result": "Its ATTACK is now [ATTACK]!",
				"missResult": "...Flynn remains unaffected.",
				"missSound": "res://Assets/Sounds/Random/weird.mp3",
				"sound": "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_scream1.mp3",
				"announcementPause": 2,
				"impactPause": 2,
				"resultPause":2,
				"priority" : 1,
				"blockable" : false,
			},
				"Advance" : {
				"minDamage": 0,
				"maxDamage": 0,
				"minRadDamage": 0,
				"maxRadDamage": 0,
				"weight": "Light",
				"cost": 0,
				"type": "Normal",
				"statusEffect": null,
				"announce": "[NAME] is creeping towards you slowly.",
				"result": "[NAME] is horribly close to you.",
				"sound": "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_hello.mp3",
				"announcementPause": 1,
				"impactPause": 1,
				"resultPause":1,
				"priority" : 1,
				"blockable" : false,
				"distanceChange" : "close",
				},
			"InjectTelegraph" : {
				"minDamage": 0,
				"maxDamage": 0,
				"minRadDamage": 0,
				"maxRadDamage": 0,
				"weight": "Heavy",
				"cost": 60,
				"type": "telegraphRadio",
				"telegraph": "Inject",
				"statusEffect": null,
				"announcementPause": 2,
				"impactPause": 2,
				"resultPause":2,
				"priority" : 1,
				"blockable" : false,
			},
			
		},
				"telegraphAttacks":
			{
				 "Inject" : {
				"minDamage": 23,
				"maxDamage": 48,
				"minRadDamage": 32,
				"maxRadDamage": 42,
				"weight": "Heavy",
				"cost": 0,
				"type": "Radioactive",
				"statusEffect": null,
				"announce": "[NAME] bit you with its snake-like appendage!",
				"result": "...that dealt [DAMAGE] to your health and gave you +[RADIATION]% radiation!",
				"sound": "res://Assets/Sounds/Blood/gib0.mp3",
				"missResult": "...It didn't hit you.",
				"blockResult": "...Flynn got out of the way.",
				"missSound": "res://Assets/Sounds/Random/weird.mp3",
				"blockSound": "res://Assets/Sounds/Random/weird3.mp3",
				"announcementPause": 2,
				"impactPause": 2,
				"resultPause":2,
				"priority" : 1,
				"blockable" : true,
				"distanceChange" : "close"
			},
		},
		
		"dialogue": [
			{
				"text" : "[NAME]: Heeeeeeeeeeeyyyyyyyy...",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_cry.mp3"
			},
			{
				"text" : "[NAME]: Heeeellllooooooo?...",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_hello.mp3"
			},
			{
				"text" : "[NAME]: Oouch...",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_ouch.mp3"
			},
			{
				"text" : "[NAME] is eyeing your helmet.",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_giggle.mp3"
			},
			{
				"text" : "[NAME] yelled an obscenity!",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_obscenity.mp3"
			},
		],
		"radioWarning": [
			{
				"text" : "[color=lime][!] [NAME] is readying itself for something...[/color]",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_grovel.mp3",
			},
			{
				"text" : "[color=lime][!] [NAME] looks ready to pounce.[/color]",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_grovel.mp3",
			},
			{
				"text" : "[color=lime][!] [NAME] looks ready. Brace for impact.[/color]",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_grovel.mp3",
			},
			{
				"text" : "[color=lime][!] [NAME] is posturing itself eagerly.[/color]",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_grovel.mp3",
			},
		],
		"surgeWarning": [
			{
				"text" : "[color=yellow][*] [NAME] looks energetic.[/color]",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_laugh.mp3",
			},
			{
				"text" : "[color=yellow][*] [NAME] looks motivated.[/color]",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_laugh.mp3",
			},
			{
				"text" : "[color=yellow][*] [NAME] has become more aware.[/color]",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_laugh.mp3",
			},
			{
				"text" : "[color=yellow][*] [NAME] is laughing maliciously.[/color]",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_laugh.mp3",
			},
			{
				"text" : "[color=yellow][*] [NAME] is ready to throw some.[/color]",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_laugh.mp3",
			}
		],
				"restWarning": [
			{
				"text" : "[NAME] is hesitating.",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_sigh.mp3",
			},
			{
				"text" : "[NAME] looks tired.",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_sigh.mp3",
			},
			{
				"text" : "[NAME] is resting.",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_sigh.mp3",
			},
			{
				"text" : "[NAME] looks winded.",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_sigh.mp3",
			},
			{
				"text" : "[NAME] is taking a break.",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_sigh.mp3",
			}
		],
				"deathMessage": [
			{
				"text" : "[NAME] was killed.",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_cry.mp3",
			},
			{
				"text" : "[NAME] keeled over.",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_cry.mp3",
			},
			{
				"text" : "[NAME] died.",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_cry.mp3",
			},
			{
				"text" : "[NAME] stopped moving.",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_cry.mp3",
			},
			{
				"text" : "[NAME] was incapacitated.",
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_cry.mp3",
			}
		],
		"initiationText": [
			{
				"text" : "[NAME] blocks the way!",
				"speed" : 2,
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_laugh.mp3",
			},
			{
				"text" : "You didn't outrun [NAME]!",
				"speed" : 2,
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_laugh.mp3",
			},
			{
				"text" : "[NAME] creeps towards you!",
				"speed" : 2,
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_giggle.mp3",
			},
			{
				"text" : "[NAME] snarls at you viciously.",
				"speed" : 2,
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_youcantrun.mp3",
			},
			{
				"text" : "[NAME] is croaking something that sounds almost like speech.",
				"speed" : 4,
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_laugh.mp3",
			},
			{
				"text" : "[NAME] lunges at you!",
				"speed" : 2,
				"sound" : "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_laugh.mp3",
			},
		]
	}
}
