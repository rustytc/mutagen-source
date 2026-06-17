extends Node

const TURN_PICKER = preload("res://Assets/Scripts/Autoload/Helpers/Battle System/turnPicker.gd")
const PLAYER_MOVES = preload("res://Assets/Scripts/Autoload/Helpers/Battle System/playerBattleActions.gd")

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
		PLAYER_MOVES.die()


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
	TURN_PICKER.execute()
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
	
