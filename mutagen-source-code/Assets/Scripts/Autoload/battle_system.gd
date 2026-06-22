extends Node

const TURN_PICKER = preload("res://Assets/Scripts/Autoload/Helpers/Battle System/turnPicker.gd")
const PLAYER_MOVES = preload("res://Assets/Scripts/Autoload/Helpers/Battle System/playerBattleActions.gd")
const ENEMY_MOVES = preload("res://Assets/Scripts/Autoload/Helpers/Battle System/enemyBattleActions.gd")

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
var selectedEnemy := []
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



		
func startTurns():
	ActionProcessor.STATUS_MANAGER.statusEffectPerRound()
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
			GameplayActions.levelUp()
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
	
