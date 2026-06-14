extends Node

var enemiesEncountered := []
var enemyIDsEncountered := []
var encounterTheme := []
var enemyDict := {}	
var identifiers := ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
var enemyQuantities := {}
var enemyIDsKilled := []

var battleLog := []

# Player Variables
var playerHealth : int = PlayerDb.playerData["player"]["stats"]["currentHealth"]
var radiation : int = PlayerDb.playerData["player"]["stats"]["radiation"]
var playerAlive := true
var playerDefending := false
var accumulatedExp := 0


# Battle Screen Global Variables
var selectedEnemy = []
var selectedLimb := ""
var turnOrderArray := []
var canAdvance := true
var battleEnded := false

signal battleAdvance
signal endBattleLose
signal endBattleWin
signal transition

func _init():
	enemiesEncountered = []
	enemyDict = {}
	enemyQuantities = {}
	encounterTheme = []
	
func battleInitiation():
	loadEnemies()
	turnOrderArray = turnOrder()
	battleConfig()
			

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	playerHealth = PlayerDb.playerData["player"]["stats"]["currentHealth"]
	radiation = PlayerDb.playerData["player"]["stats"]["radiation"]
	# Losing a battle
	if (playerHealth <= 0 or radiation >= 100) and playerAlive == true:
		playerDeath()


func loadEnemies():
	if enemiesEncountered.size() > 1:
		for i in enemiesEncountered.size():
			var value = enemiesEncountered[i]
			if not enemyQuantities.has(value): # checking if the specified enemy has been registered a quantity yet
				enemyDict[value + " A"] = EnemyDb.enemies[value].duplicate(true) # handles the first instance of an enemy type, adding it to the dictionary as "Enemy A"
				enemyQuantities[value] = 1 # gives the enemyQuantities dictionary a key of 1 for the original quantity before other instances are added onto this
				enemyIntroduction(value + " A")
				enemyDict[value + " A"]["ID"] = enemyIDsEncountered[i]
			else:
				enemyDict[value + " " + str(identifiers[enemyQuantities[value]])] = EnemyDb.enemies[value].duplicate(true) # sets sequential instances of enemies to have an identifier attached to their name from an array called 'identifiers', taking the index from its quantity specified in enemyQuantities
				enemyIntroduction(value + " " + str(identifiers[enemyQuantities[value]]))
				enemyDict[value + " " + str(identifiers[enemyQuantities[value]])]["ID"] = enemyIDsEncountered[i]
				enemyQuantities[value] += 1 # adds '1' to quantity for each new enemy instance
	else:
		enemyDict[enemiesEncountered[0]] = EnemyDb.enemies[enemiesEncountered[0]].duplicate(true)
		enemyQuantities[enemiesEncountered[0]] = 1
		enemyIntroduction(enemiesEncountered[0])
		enemyDict[enemiesEncountered[0]]["ID"] = enemyIDsEncountered[0]
		
func removeIdentifier(enemyName):
	for i in identifiers:
		if enemyName.ends_with(" " + i): # convenient
			enemyName = enemyName.trim_suffix((" " + i))
			return(enemyName)
	return enemyName

func battleConfig(): # this runs every phase change btw (in action processor)
	advanceCheck()

func advanceCheck():
	for i in enemyDict:
		if enemyDict[i]["logic"][enemyDict[i]["phase"]]["canAdvance"] == false:
			canAdvance = false

func enemyIntroduction(enemyName):
	var introduction = EnemyDb.enemies[removeIdentifier(enemyName)]["initiationText"].pick_random()
	ActionProcessor.queueAnnouncementAction(introduction["text"].replace("[NAME]", enemyName), introduction["speed"], introduction["sound"])

func turnOrder():
	var candidates = enemyDict.keys()
	var users = []
	candidates.append("Player")

	if not ActionProcessor.playerTurn and not ActionProcessor.enemyTurn:
		for i in candidates.size():
			var user = candidates[i]
			var speed = 0
			
			if user == null:
				continue
			elif user == "Player":
				speed = PlayerDb.playerData["player"]["stats"]["speed"]
			else:
				speed = EnemyDb.enemies[removeIdentifier(user)]["stats"]["speed"]

			users.append([speed, user])

	users.sort_custom(sortDescending)
	for i in users.size():
		users[i] = (users[i][1])
	return(users)

func decideTurns():
	# Enemies
	
	for i in turnOrderArray:
		if i != "Player":
			var user = i
			var userNoID = removeIdentifier(i)
			var move = ""
		
			var phase = enemyDict[i]["phase"]
			var attacks = enemyDict[i]["logic"][phase]["attacks"]
			var stamina = enemyDict[i]["stats"]["stamina"]
			var maxStamina = enemyDict[i]["stats"]["maxStamina"]
			var health = enemyDict[i]["stats"]["health"]
			var maxHealth = enemyDict[i]["stats"]["maxHealth"]
			var surgeChance = enemyDict[i]["stats"]["surgeChance"]
			var telegraph = enemyDict[i]["telegraph"]
			enemyDict[i]["logic"][phase]["turns"] += 1
			
		# Decide to change phases
			if enemyDict[i]["logic"][phase].has("phaseChanges"):
				var phaseChanges = enemyDict[i]["logic"][phase]["phaseChanges"]
				for condition in phaseChanges:
					if phaseChanges[condition]["type"] == "healthLeq" and phaseChanges[condition]["amount"] >= health:
						move = "phaseChange"
						phaseChange(user, phaseChanges[condition]["phaseChange"], condition)
						break
				if move == "phaseChange":
					continue
			
		# Decide to surge
			var surgeRoll = Global.rng.randi_range(0,100)
			if (surgeRoll < surgeChance) and (stamina < maxStamina) and (telegraph == ""):
				move = "surge"
				surgeAction(user)
				continue
			# deciding what the enemy is going to do for its turn
		
			# ENEMY ATTACK PICKING
			if enemyDict[i]["telegraph"] != "":
				enemyAttackAction(i, EnemyDb.enemies[removeIdentifier(i)]["telegraphAttacks"][enemyDict[i]["telegraph"]])
				enemyDict[i]["telegraph"] = ""
				continue
			if stamina >= enemyDict[i]["stats"]["minStaminaToAttack"]:
				# BEHAVIORS:
				var viableAttacks = []
				var chosenAttack = ""
				match enemyDict[i]["logic"][enemyDict[i]["phase"]]["behavior"]:
					"random": # RANDOM ATTACK PATTERN
					# random enemies act completely randomly
					# they have a random chance of using any afforded attack
					# meaning they will spam whatever is accessible to them
					# without meaningful tact. despite this, theyre actually
					# moderately difficult because you cannot meaningfully
					# guess their next move
						viableAttacks = []
						for o in attacks:
							if stamina >= enemyDict[i]["attacks"][o]["cost"]:
								viableAttacks.append(o)
						chosenAttack = viableAttacks.pick_random()
					"cocky": # COCKY ATTACK PATTERN
					# cocky enemies will spam their heaviest available attack
					# on you. the best way to beat them is to anticipate this,
					# defend or heal first, and then knock them cold while theyre exhausted
					# they're probably the hardest to deal with early game
					# and easiest to deal with late game
						viableAttacks = []
						for o in attacks:
							if stamina >= enemyDict[i]["attacks"][o]["cost"]:
								viableAttacks.append(o)
						chosenAttack = viableAttacks[0]
						for o in viableAttacks:
							if enemyDict[i]["attacks"][o]["cost"] > enemyDict[i]["attacks"][chosenAttack]["cost"]:
								chosenAttack = o
					"scummy": #SCUMMY ATTACK PATTERN
					# scummy enemies will deliberately conserve energy on you
					# when you're strong. this is to lull you into thinking
					#they're weak, and let you take a few hits first.
					# if you're weak, they'll proceed to use their heaviest attacks on you
					
					# this one only works if you register heavy AND light attacks, otherwise they'll short circuit
						viableAttacks = []
						if PlayerDb.playerData["player"]["stats"]["currentHealth"] > (PlayerDb.playerData["player"]["stats"]["maxHealth"])/3:
							for o in attacks:
								if stamina >= enemyDict[i]["attacks"][o]["cost"] and (enemyDict[i]["attacks"][o]["weight"] == "Medium" or enemyDict[i]["attacks"][o]["weight"] == "Light"):
									viableAttacks.append(o)
						else:
							for o in attacks:
								if stamina >= enemyDict[i]["attacks"][o]["cost"]: # always uses its heaviest available attack on you
									viableAttacks.append(o)
									continue
								
						chosenAttack = viableAttacks.pick_random()
					
				enemyAttackAction(i, EnemyDb.enemies[removeIdentifier(i)]["attacks"][chosenAttack])
			else:
				restAction(user)
				
		else: # Player
			if ActionProcessor.queuedActions.size() > 0:
				ActionProcessor.queueSpecificAction(ActionProcessor.queuedActions.pop_front())
			else:
				playerAttackAction(selectedEnemy, selectedLimb)

func sortDescending(a, b):
	return a[0] > b[0]
	
func sortAscending(a, b):
	return a[0] < b[0]

func surgeAction(user):
	var action = ActionProcessor.actionTemplate.duplicate(true)
	var userNoID = removeIdentifier(user) # for enemyDb calls
	action["general"]["type"] = "surge"
	action["enemyStatus"]["staminaRegen"] = enemyDict[user]["stats"]["maxStamina"] - enemyDict[user]["stats"]["stamina"]
	action["general"]["user"] = user
	action["general"]["userName"] = userNoID
	var announcement = enemyDict[user]["surgeWarning"].pick_random()
	action["general"]["announcement"] = announcement["text"]
	action["general"]["announcementSFX"] = announcement["sound"]
	action["general"]["announcementPause"] = 2
	ActionProcessor.queueSpecificAction(action)

func phaseChange(user, phaseName, trigger):
	var action = ActionProcessor.actionTemplate.duplicate(true)
	var userNoID = removeIdentifier(user)
	var phase = enemyDict[user]["phase"]
	action["general"]["type"] = "phaseChange"
	action["general"]["user"] = user
	action["general"]["userName"] = userNoID
	action["enemyStatus"]["phaseChange"] = phaseName
	var announcement = enemyDict[user]["logic"][phase]["phaseChanges"][trigger]["announcements"].pick_random()
	action["general"]["announcement"] = announcement["text"]
	action["general"]["announcementSFX"] = announcement["sound"]
	action["general"]["announcementPause"] = 2
	action["general"]["priority"] = 4
	ActionProcessor.queueSpecificAction(action)
	
func restAction(user):
	var action = ActionProcessor.actionTemplate.duplicate(true)
	var userNoID = removeIdentifier(user)
	action["general"]["type"] = "rest"
	action["enemyStatus"]["staminaRegen"] = enemyDict[user]["stats"]["maxStamina"]/4
	action["general"]["user"] = user
	action["general"]["userName"] = userNoID
	var announcement = EnemyDb["restWarning"].pick_random()
	action["general"]["announcement"] = announcement["text"]
	action["general"]["announcementSFX"] = announcement["sound"]
	action["general"]["announcementPause"] = 2
	ActionProcessor.queueSpecificAction(action)

func enemyAttackAction(user, attack, priority = 1):
	var action : Dictionary = ActionProcessor.actionTemplate.duplicate(true)
	var userNoID : String = removeIdentifier(user)
	var baseDmg := Global.rng.randi_range(int(attack["minDamage"]), int(attack["maxDamage"]))
	var radDmg := Global.rng.randi_range(int(attack["minRadDamage"]), int(attack["maxRadDamage"]))
	var compoundDmg : int = baseDmg * int(enemyDict[user]["stats"]["attackMultiplier"])
	var staminaCost := int(attack["cost"])
	var miss := false
	var playerDefense = PlayerDb.playerData["player"]["stats"]["compoundDefense"]
	
	# Distance
	if attack.has("distanceChange"):
		enemyDict[user]["distance"] = attack["distanceChange"]
	var closenessDamageDiff := 1.0
	if enemyDict[user]["distance"] == "far":
		closenessDamageDiff = 0.8
	elif enemyDict[user]["distance"] == "mid":
		closenessDamageDiff = 1
	elif enemyDict[user]["distance"] == "close":
		closenessDamageDiff = 1.2
	compoundDmg *= closenessDamageDiff
	var closenessAccuracyDiff := 1.0
	if enemyDict[user]["distance"] == "far":
		closenessAccuracyDiff = 0.8
	elif enemyDict[user]["distance"] == "mid":
		closenessAccuracyDiff = 1
	elif enemyDict[user]["distance"] == "close":
		closenessAccuracyDiff = 1.2
	
		# Accuracy Calculator
	var speedDifference := int(EnemyDb.enemies[userNoID]["stats"]["speed"]) - int(PlayerDb.playerData["player"]["stats"]["speed"])
	var accuracy : int = clamp(60 + speedDifference * 5, 10, 95) * closenessAccuracyDiff
	
	
	# Miss roll
	var roll = Global.rng.randi_range(1, 100)
	if roll >= accuracy:
		# Miss
		baseDmg = 0
		radDmg = 0
		compoundDmg = 0
		miss = true
	
	action["general"]["user"] = user
	action["general"]["userName"] = userNoID
	action["general"]["target"] = ["Player"]
	if (attack["blockable"] == true and playerDefending == true) or miss == true:
		action["combatData"]["damage"] = 0
		action["playerStatus"]["radiationInflict"] = 0
	elif (attack["blockable"] == true and playerDefending == false) or (attack["blockable"] == false) and not miss:
		if playerDefending == false:
			action["combatData"]["damage"] = clamp((compoundDmg - playerDefense), 0, 10000000000)
		else:
			action["combatData"]["damage"] = clamp((compoundDmg - (playerDefense*2)), 0, 10000000000)
	action["enemyStatus"]["staminaCost"] = staminaCost
	if attack["type"] != "telegraphRadio":
		action["general"]["announcement"] = attack["announce"]
	if attack["type"] == "telegraphRadio":
		action["general"]["type"] = "telegraphRadio"
		enemyDict[user]["telegraph"] = attack["telegraph"]
		action["general"]["announcement"] = enemyDict[user]["radioWarning"].pick_random()["text"]
		action["general"]["announcementSFX"] = enemyDict[user]["radioWarning"].pick_random()["sound"]
		action["general"]["type"] = "telegraph"
	action["general"]["priority"] = attack["priority"]
	if priority != 1:
		action["general"]["priority"] = priority
	action["general"]["announcementPause"] = attack["announcementPause"]
	action["general"]["impactPause"] = attack["impactPause"]
	action["general"]["resultPause"] = attack["resultPause"]
	
	if (not miss) and attack["type"] != "telegraphRadio":
		action["general"]["type"] = "attack"
		if attack["blockable"] == true and playerDefending == true:
			action["general"]["result"] = attack["blockResult"]
			action["general"]["resultSFX"] = attack["blockSound"]
		else:
			action["general"]["result"] = attack["result"]
		if (attack["blockable"] == true and playerDefending == false) or attack["blockable"] == false:
			action["general"]["impactSFX"] = attack["sound"]
		action["combatData"]["statusEffect"] = attack["statusEffect"]
		var blocked : bool = (attack["blockable"] == true and playerDefending == true)
		if not blocked:
			if playerDefending == false:
				action["playerStatus"]["radiationInflict"] = clamp((radDmg - (playerDefense / 2)), 0, 10000000000)
			else:
				action["playerStatus"]["radiationInflict"] = clamp((radDmg - playerDefense), 0, 10000000000)
	if miss and attack["type"] != "telegraphRadio":
		action["general"]["type"] = "attackMiss"
		action["general"]["result"] = attack["missResult"]
		action["general"]["impactSFX"] = null
		action["general"]["resultSFX"] = attack["missSound"]
	
	ActionProcessor.queueSpecificAction(action)
	

	
func playerAttackAction(targets, limbs, priority = 1):
	var action := ActionProcessor.actionTemplate.duplicate(true)
	var weapon : String = PlayerDb.playerData["player"]["body"]["weapon"]
	var baseDmg := 0
	var ammoType := "undef"
	var affinity := 1.0
	var modifier := 1.0
	var miss := false
	if GlobalDb.weaponDatabase[weapon]["ammoAlternation"] == true and PlayerDb.playerData["player"]["weapons"][weapon]["equipped"] == true:
		if PlayerDb.playerData["player"]["weapons"][weapon]["loadOrder"][0] == "std":
			ammoType =  GlobalDb.weaponDatabase[weapon]["ammoType"]
			baseDmg = GlobalDb.weaponDatabase[weapon]["damage"]
			modifier = GlobalDb.weaponDatabase[weapon]["modifier"]
		else:
			ammoType =  GlobalDb.weaponDatabase[weapon]["ammoTypeAlt"]
			baseDmg = GlobalDb.weaponDatabase[weapon]["damageAlt"]
			modifier = GlobalDb.weaponDatabase[weapon]["modifierAlt"]
	else:
		ammoType = "std"
		baseDmg = GlobalDb.weaponDatabase[weapon]["damage"]
		modifier = GlobalDb.weaponDatabase[weapon]["modifier"]
		
	if enemyDict[selectedEnemy]["limbs"][selectedLimb].has("affinities"):
		for i in enemyDict[selectedEnemy]["limbs"][selectedLimb]["affinities"].keys():
			if i == weapon:
				affinity = enemyDict[selectedEnemy]["limbs"][selectedLimb]["affinities"][i]
		
		
	# Crit Calculator
	var critChance := 0
	critChance = Global.rng.randi_range(0,100)
	var crit := false
	var critDmg : float = 1
	if critChance < round(2 + (0.2 * PlayerDb.playerData["player"]["stats"]["intelligence"])):
		crit = true
		critDmg = Global.rng.randf_range(1.4,1.7)
	
	
	
	var attack : int = PlayerDb.playerData["player"]["stats"]["attack"]
	var compoundDmg : int = int((((baseDmg * attack/30) + baseDmg + attack)))
	if enemyDict.has(targets) and enemyDict[targets].has("limbs") and enemyDict[targets]["limbs"].has(limbs):
		var limbDamagePercent : float = (enemyDict[targets]["limbs"][limbs]["damagePercent"]) / 100.0
		var closenessDamageDiff := 1.0
		var closenessAccuracyDiff := 1.0
		match enemyDict[targets].get("distance"):
			"far":
				closenessDamageDiff = 0.8
				closenessAccuracyDiff = 0.8
			"close":
				closenessDamageDiff = 1.2
				closenessAccuracyDiff = 1.2
			"mid":
				closenessDamageDiff = 1.0
				closenessAccuracyDiff = 1.0
		compoundDmg = int(round(compoundDmg * limbDamagePercent * affinity * critDmg * closenessDamageDiff)) # critDmg moved here from compoundDmg so that
		# crits arent negated when the damage reduction is high
		
	# Miss Calculator	
		var missChance := 0
		missChance = Global.rng.randi_range(1,100)
		var hitChance = clamp((enemyDict[targets]["limbs"][limbs]["hitRate"] * modifier * closenessAccuracyDiff + PlayerDb.playerData["player"]["stats"]["battleIQ"]), 0.0, 100.0)
		if missChance > hitChance and crit == false:
			miss = true
		
	# Changing Distance
	#if GlobalDb.weaponDatabase[weapon]["type"] == "melee":
		#enemyDict[targets]["distance"] = "close"
		# In case I change my mind. Maybe itll even require closeness? >:)
		
		
	var ammoCost = null
	if GlobalDb["weaponDatabase"][weapon].has("ammoCost"):
		ammoCost = GlobalDb["weaponDatabase"][weapon]["ammoCost"]
	action["general"]["type"] = "attack"
	action["general"]["user"] = "Player"
	action["general"]["target"] = [targets]
	action["weaponData"]["weaponName"] = weapon
	action["weaponData"]["ammoType"] = ammoType
	action["weaponData"]["isWeapon"] = true
	action["weaponData"]["singleUse"] = GlobalDb["weaponDatabase"][weapon]["singleUse"]
	action["general"]["userName"] = "Flynn"
	if not miss and not playerDefending:
		action["combatData"]["damage"] = compoundDmg
	else:
		action["combatData"]["damage"] = 0
	action["combatData"]["limb"] = limbs
	action["weaponData"]["ammoCost"] = ammoCost
	action["general"]["result"] = GlobalDb["weaponDatabase"][weapon]["attackResult"]
	action["general"]["announcementPause"] = GlobalDb["weaponDatabase"][weapon]["announcementPause"]
	action["general"]["impactPause"] = GlobalDb["weaponDatabase"][weapon]["impactPause"]
	action["general"]["resultPause"] = GlobalDb["weaponDatabase"][weapon]["resultPause"]
	if crit == false:
		action["general"]["announcement"] = GlobalDb["weaponDatabase"][weapon]["attackAnnouncement"]
		action["general"]["impactSFX"] = GlobalDb["weaponDatabase"][weapon]["attackSound"]
		action["general"]["announcementSFX"] = GlobalDb["weaponDatabase"][weapon]["attackAnnouncementSound"]
		
	else:
		action["general"]["announcement"] = GlobalDb["weaponDatabase"][weapon]["attackAnnouncementCritical"]
		action["general"]["impactSFX"] = GlobalDb["weaponDatabase"][weapon]["attackCritSound"]
		action["general"]["announcementSFX"] = GlobalDb["weaponDatabase"][weapon]["critAnnouncementSound"]
	action["general"]["priority"] = priority
	# if the weapon has a status effect, the game will generate a number from
	# 1 to 100, and if that number falls beneath or is equal to the weapon's "statusEffectChance"
	# key, itll effect. this means a weapon with 40% likelihood to have a status
	# effect apply will only have it if the effect roll is less than or equal to 40
	var statusEffectChance := 0
	statusEffectChance = Global.rng.randi_range(1, 100) # self reminder to use 1 as a starting value so it doesnt have 101 values NOTE
	if statusEffectChance <= GlobalDb["weaponDatabase"][weapon]["statusEffectChance"]:
		action["combatData"]["statusEffect"] = GlobalDb["weaponDatabase"][weapon]["statusEffect"]
		
	if miss:
		action["general"]["type"] = "attackMiss"
		action["general"]["result"] = GlobalDb["weaponDatabase"][weapon]["attackMissResult"]
		action["general"]["impactSFX"] = null
		action["general"]["resultSFX"] = GlobalDb["weaponDatabase"][weapon]["attackMissSound"]
		
	ActionProcessor.queueSpecificAction(action)

func playerBlockAction():
	playerDefending = true
	var action := ActionProcessor.actionTemplate.duplicate(true)
	action["general"]["priority"] = 2
	action["general"]["announcement"] = "Flynn is defending."
	action["general"]["type"] = "block"
	action["general"]["user"] = "Player"
	ActionProcessor.queuedActions.append(action)
	
func playerAdvanceAction(direction):
	var action := ActionProcessor.actionTemplate.duplicate(true)
	action["general"]["type"] = "advance"
	action["general"]["user"] = "Player"
	action["general"]["userName"] = "Flynn"
	action["combatData"]["advanceDirection"] = direction
	if direction == "forwards":
		action["general"]["announcement"] = "Flynn inches closer."
	else:
		action["general"]["announcement"] = "Flynn is backing away."
	ActionProcessor.queuedActions.append(action)

func playerFleeAction():
	var index = 0
	var action := ActionProcessor.actionTemplate.duplicate(true)
	action["general"]["announcement"] = "Flynn tried to run."
	action["general"]["user"] = "Player"
	action["general"]["userName"] = "Flynn"
	action["general"]["priority"] = 3
	
	for i in enemyDict:
		index += 1
		var enemy = enemyDict[i]
		if (enemy["stats"]["speed"] > (PlayerDb.playerData["player"]["stats"]["speed"] * 1.5)) or (enemy["distance"] == "close") or (enemy["logic"][enemy["phase"]]["canFlee"] == false):
			action["general"]["result"] = "He could not escape."
			action["general"]["type"] = "fleeFail"
			ActionProcessor.queuedActions.append(action)
			break
		if (enemy["distance"] == "mid"):
			var luck = Global.rng.randi_range(1,100)
			if luck <= 50:
				if index == enemyDict.size():
					action["general"]["result"] = "Flynn successfully fled."
					action["general"]["type"] = "fleeSuccess"
					ActionProcessor.queuedActions.append(action)
					break
				else:
					continue
			if luck > 50:
				action["general"]["result"] = "He could not escape."
				action["general"]["type"] = "fleeFail"
				ActionProcessor.queuedActions.append(action)
				break
		if (enemy["distance"] == "far"):
			var luck = Global.rng.randi_range(1,100)
			if luck <= 75:
				if index == enemyDict.size():
					action["general"]["result"] = "Flynn successfully fled."
					action["general"]["type"] = "fleeSuccess"
					ActionProcessor.queuedActions.append(action)
					break
				else:
					continue
			if luck > 75:
				action["general"]["result"] = "He could not escape."
				action["general"]["type"] = "fleeFail"
				ActionProcessor.queuedActions.append(action)
				break
	
	
func playerDeath():
	BattleSystem.playerAlive = false
	get_viewport().gui_release_focus()
	Global.playerCharBody2D.controllable = false
	var action = ActionProcessor.actionTemplate.duplicate(true)
	action["general"]["priority"] = 3
	action["general"]["announcement"] = "Flynn was killed."
	action["general"]["type"] = "death"
	action["general"]["user"] = "Player"
	ActionProcessor.actions.clear()
	ActionProcessor.queuedActions.clear()
	ActionProcessor.queueSpecificAction(action)

func enemyDeath(enemy):
	var action = ActionProcessor.actionTemplate.duplicate(true)
	action["general"]["priority"] = 3
	var announcement = BattleSystem.enemyDict[enemy]["deathMessage"].pick_random()
	action["general"]["announcement"] = announcement["text"]
	action["general"]["announcementSFX"] = announcement["sound"]
	action["general"]["type"] = "death"
	action["general"]["user"] = enemy
	accumulatedExp += BattleSystem.enemyDict[enemy]["stats"]["experience"]
	for i in range(ActionProcessor.queuedActions.size() - 1, -1, -1):
		var deadAction = ActionProcessor.queuedActions[i]
		if deadAction["general"]["user"] == enemy:
			ActionProcessor.queuedActions.remove_at(i)
	for i in range(ActionProcessor.actions.size() - 1, -1, -1):
		var deadAction = ActionProcessor.actions[i]
		if deadAction["general"]["user"] == enemy:
			ActionProcessor.actions.remove_at(i)
	ActionProcessor.queueSpecificAction(action)
	enemyIDsKilled.append(BattleSystem.enemyDict[enemy]["ID"])


		
func startTurns():
	decideTurns()
	battleAdvance.emit()

func endTurns():
	playerDefending = false

func winBattle(flee := false):
	endBattleWin.emit()
	get_viewport().gui_release_focus()
	var action = ActionProcessor.actionTemplate.duplicate(true)
	var result = null
	action["general"]["priority"] = 3
	var announcement = ""
	if flee == false:
		announcement = "Area secured."
	else:
		announcement = "Area escaped."
	PlayerDb.playerData["player"]["experience"]["current"] += accumulatedExp
	action["levelling"]["expGain"] = accumulatedExp
	if PlayerDb.playerData["player"]["levelCap"] > PlayerDb.playerData["player"]["level"]:
		if PlayerDb.playerData["player"]["experience"]["needed"] <= PlayerDb.playerData["player"]["experience"]["current"]:
			ActionProcessor.queueLevelUp()
		else:
			result = str(accumulatedExp) + " experience points gained. " + str(PlayerDb.playerData["player"]["experience"]["needed"] - PlayerDb.playerData["player"]["experience"]["current"]) + " exp until the next level."
	else:
		action["levelling"]["expGain"] = accumulatedExp * 0.2
		result = str(accumulatedExp * 0.2) + " experience points gained. " + str(PlayerDb.playerData["player"]["experience"]["needed"] - PlayerDb.playerData["player"]["experience"]["current"]) + " exp until the next level. Gained experience is at a 0.2x deficit until next epiphany."
	action["general"]["announcement"] = announcement
	action["general"]["result"] = result
	action["general"]["inputDependent"] = true
	ActionProcessor.actions.append(action)
	
func exitBattle(flee = false):
	if Global.battleJustEnded == false:
		Global.battleJustEnded = true
		UniversalAudio.stopAllSpecialSounds()
		encounterTheme = []
		enemyQuantities = {}
		enemiesEncountered = []
		enemyIDsEncountered = []
		battleLog = []
		playerDefending = false
		accumulatedExp = 0
		selectedEnemy = []
		selectedLimb = ""
		turnOrderArray = []
		enemyDict = {}
		ActionProcessor.levelUpInProgress = false
		ActionProcessor.playerTurn = false
		ActionProcessor.enemyTurn = false
		ActionProcessor.systemActions = []
		ActionProcessor.actions = []
		ActionProcessor.queuedActions = []
		ActionProcessor.pendingSkillUpgrade = false
		if flee == true:
			Global.playerJustFled = true
		transition.emit()
		await get_tree().create_timer(2.0).timeout
		
		canAdvance = true
		battleEnded = false
		Global.playerCharBody2D.resetBattleTransition()
		# unpausing the overworld
		get_tree().get_first_node_in_group("World Scene Node Reference").show()
		get_tree().get_first_node_in_group("World Camera").enabled = true
		get_tree().get_first_node_in_group("World Camera").show()
		get_tree().get_first_node_in_group("Overworld UI").show()
		get_tree().get_first_node_in_group("World Scene Node Reference").process_mode = Node.PROCESS_MODE_PAUSABLE
		get_tree().get_first_node_in_group("Battle Screen Node Reference").get_child(0).queue_free()
		Global.helpMenu = get_tree().get_first_node_in_group("Overworld UI").get_node("helpMenu")
		InventoryHelper.helpMenu = Global.helpMenu
		ActionProcessor.actionLog = get_tree().get_first_node_in_group("Overworld UI").get_node("actionLog")
		Global.actionLog = get_tree().get_first_node_in_group("Overworld UI").get_node("actionLog")
		Global.helpMenu.updateItemDescriptions()
		Global.helpMenu.updateWeaponDescriptions()
		Global.helpMenu.updateArmorDescriptions()
		Global.helpMenu.updateGearDescriptions()
		enemyIDsKilled.clear()
	
