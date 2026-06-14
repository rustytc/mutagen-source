extends Node

signal levelUp

var pendingSkillUpgrade := false
var levelUpInProgress := false

var flee := false
var timer = null
var actionLog = null
var processing := false
var playerTurn := false
var enemyTurn := false
var currentTurn := ""
var systemActions := []
var actions := []
var queuedActions := []
var actionTemplate := { "general" : {
		"name" : "blank", # this pretty much exists exclusively for debugging purposes
		"type" : "blank",
		"sfx" : "res://Assets/Sounds/Random/boyoing.mp3",
		"user" : "",
		"userName" : "", # the name of the original enemy (true mutant A = true mutant)
		"target" : ["blank"], # stored as an array for cases where theres several targets
		"repeat" : 0, # decreases each time, default is 0
		"announcement" : "", #(i.e. Flynn chucked the [item] at [target], Flynn chugged the [item])
		"impactSFX" : "", # plays in between announcement and result
		"impactTXT" : "",
		"impactFX" : "",
		"announcementSFX" : "", # plays during announcement (as soon as the beginning of the action is processed)
		"result" : "", # i.e. dealt [damageAmount] HP
		"resultSFX" : "",
		"remember" : false,
		"priority" : 1, #(1-4) (1 is for normal actions, 2 is for immediate actions such as a quick attack or an item with instant use, 3 is for scripted events that must fire immediately such as the player dying at 0 HP, 4 is for system events like a scripted boss phase change or animation)
		"overridable" : true, # almost all actions should be overridable
		"typewriteSpeed" : 1, #speed that the battle log should display this action’s text
		"announcementPause" : 1, 
		"impactPause" : 2,
		"resultPause" : 1,
		"inputDependent" : false, # if true, the timer won't determine how text scrolls, rather it will move on if the player presses an input. for dialogue
		},
	
	"weaponData" : {
		"weaponName" : "",
		"ammoCost" : 0,
		"ammoRefill" : 0,
		"ammoType" : "",
		"isWeapon" : null,
		"singleUse" : false,
		},
	"itemData" : {
		"itemName" : "",
		"isHeal" : null,
		},
	"combatData" : {
		"atkBoost" : 0,
		"damage" : 0,
		"limb" : "",
		"statusEffects" : {
			"inflict" : {
				"bleed" : {
					"points" : 0,
					"chance": 0,
				},
				"illness" : {
					"points" : 0,
					"chance": 0,
				},
				"cripple" : {
					"points" : 0,
					"chance": 0,
				},
				"fatigue" : {
					"points" : 0,
					"chance": 0,
				},
				"berserk" : {
					"points" : 0,
					"chance": 0,
				},
			},
			
			"cure" : {
				"bleed" : false,
				"illness" : false,
				"cripple" : false,
				"fatigue" : false,
				"berserk" : false
			},
		},
		"telegraph" : "",
		"advanceDirection" : "",
		},
	"playerStatus" : {
		"radiationInflict" : 0,
		"radiationReduce" : 0,
	},
	"enemyStatus" : {
		"phaseChange" : "",
		"staminaCost" : 0,
		"staminaRegen": 0,
	},
	"levelling" : {
		"expGain" : 0,
	},
	"sharedData" : { ## shared means both the enemies and player have this sort of data
		"healMin" : 0,
		"healMax" : 0,
	},
	"globalFunction" : {
		"stdReload" : false,
		"altReload" : false, # alt reload functions differently from normal weapon reloading in that it actually calls the global reload function first
		# to bring up the slider to adjust a reload amount, but then calls a separate function to actually trigger the reload. this means
		# the global reload function gets queued normally EXCEPT when altReload is true, in which the global reload() function gets called immediately
		# but then confirmSpecialReload is queued
		"useItem" : false,
		},
		}



# Helper functions
func wait(duration):  
	var wait = get_tree().create_timer(duration, true, true, false)
	await wait.timeout
	
func waitForActionPause(duration, inputDependent):
	if inputDependent:
		while true:
			await get_tree().process_frame
			if Input.is_action_just_pressed("Accept") or Input.is_action_just_pressed("ui_accept"):
				return
	else:
		await wait(duration)


# Called when the node enters the scene tree for the first time.
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(timer)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if actionLog != null and (timer.time_left == 0 or timer.time_left == null) and processing == false: # in case it somehow fires right before it exists
		if actions.is_empty():
			
			if queuedActions.size() == 0 and systemActions.size() == 0:
				
				if pendingSkillUpgrade == true:
					pendingSkillUpgrade = false
					levelUp.emit()
					levelUpInProgress = true
				elif levelUpInProgress == false and BattleSystem.battleEnded == true and actionLog.get_node("Panel/VBoxContainer/HBoxContainer/Text").get_parsed_text().length() <= actionLog.get_node("Panel/VBoxContainer/HBoxContainer/Text").visible_characters:
					if flee == true:
						BattleSystem.exitBattle(flee)
						flee = false
					else:
						BattleSystem.exitBattle()
					
			if BattleSystem.playerAlive:
				BattleSystem.endTurns()
			return
			
		# Priority
		if actions.size() > 0:
			for i in range(actions.size()):
				if actions[i]["general"]["priority"] == 2:
					var action = actions[i]
					actions.pop_at(i)
					actions.push_front(action)
			for i in range(actions.size()):
				#these run sequentially
				if actions[i]["general"]["priority"] == 3:
					var action = actions[i]
					actions.pop_at(i)
					actions.push_front(action)
						
						
						
			# processing action
			processing = true
			if actionLog.empty == false:
				await actionLog.finishedTyping
				processAction(actions[0])
			else:
				processAction(actions[0])

func _on_timer_timeout():
	return
	
func processAction(data):
	
	var targets := []
	var state = 0 # 0 = No statement 1 = Announcement 2 = Impact 3 = Result
	actions.remove_at(0)
	
	# Interrupting player attack if the target is gone
	if data["general"]["user"] == "Player" and (data["general"]["type"] == "attack" or data["general"]["type"] == "attackMiss"):
		for target in data["general"]["target"]:
			if target != "Player" and not BattleSystem.enemyDict.has(target):
				data["general"]["type"] = "attackInterrupted"
				data["general"]["announcement"] = "Flynn's plan of attack was interrupted."
				data["general"]["announcementSFX"] = "res://Assets/Sounds/Random/weird2.mp3"
				data["general"]["impactSFX"] = null
				data["general"]["result"] = ""
				data["general"]["resultSFX"] = null
				data["combatData"]["damage"] = 0
				data["weaponData"]["ammoCost"] = null
				break

	
	# Stuff that applies to all actions
	var textSpeed := 1
	var textSpeedSetting = Settings.settingsRaw["textSpeed"]
	if textSpeedSetting == "fast":
		textSpeed = 2
	else:
		textSpeed = 1
	actionLog.speakingMultiplier = data["general"]["typewriteSpeed"] * textSpeed


	
	
	
	#Announcement
	if actionLog.get_node("Panel/VBoxContainer/HBoxContainer/Text").get_parsed_text().length() > 0:
		actionLog.get_node("Panel/VBoxContainer/HBoxContainer/Text").text += ("\n")
	if data["general"]["announcementSFX"] != null and data["general"]["announcementSFX"] != "":
		UniversalAudio.stopAllSpecialSounds()
		UniversalAudio.playSpecialSound(data["general"]["announcementSFX"])
		
	if data["general"]["announcement"] != null and data["general"]["announcement"] != "":
		state = 1
		actionLog.get_node("Panel/VBoxContainer/HBoxContainer/Text").text += "> " + formatActionText(data["general"]["announcement"], data, targets)
		# ^^^ replaces placeholder text with data
		await waitForActionPause(data["general"]["announcementPause"], data["general"]["inputDependent"])
		
	# "Impact" (FX and audio for when a thing changes)
	if data["general"]["impactTXT"] != null and data["general"]["impactTXT"] != "":
		# probably not entirely necessary, but the placeholder replacement
		#gets applied to impact text too in case its ever used preemptively
		actionLog.get_node("Panel/VBoxContainer/HBoxContainer/Text").text += "\n> " + formatActionText(data["general"]["impactTXT"], data, targets)
	if data["general"]["impactSFX"] != null and data["general"]["impactSFX"] != "" and BattleSystem.playerAlive: # important stuff, unlike announcement and
		# ^ playerAlive check makes sure that sounds dont clip when the player is dead from an attack
		# result, for impact is tacked onto SFX. this is because all
		# impact FX will make a sound, but not all sounds will have
		# on screen FX. if you ever find that impact is behaving weirdly,
		# that is probably why
		UniversalAudio.playSpecialSound(data["general"]["impactSFX"])
		
		if data["combatData"]["damage"] > 0:
			for i in data["general"]["target"]:
				if i != "Player":
					var maxHealth = BattleSystem.enemyDict[i]["stats"]["maxHealth"]
					var damage = data["combatData"]["damage"]
					instance_from_id(BattleSystem.enemyDict[i]["battleSpriteID"]).hurtAnimation(clamp((damage / maxHealth) * 100, 5, 25),0.5,8)
		
		await waitForActionPause(data["general"]["impactPause"], data["general"]["inputDependent"])

		
	# "Result" (What gets displayed after a thing changes and its time to tell the player what happened)
	# Note: ALL of these are optional. They're all gonna be used together very often, though. Almost ALWAYS in combat actions
	if data["general"]["result"] != null and data["general"]["result"] != "":
		actionLog.get_node("Panel/VBoxContainer/HBoxContainer/Text").text += "\n> " + formatActionText(data["general"]["result"], data, targets)
	if data["general"]["resultSFX"] != null and data["general"]["resultSFX"] != "":
		UniversalAudio.playSpecialSound(data["general"]["resultSFX"])
		# ^^^ replaces placeholder text with data
	if data["general"]["result"] != null and data["general"]["result"] != "":
		await waitForActionPause(data["general"]["resultPause"], data["general"]["inputDependent"])
	

			
	# Combat Action
	if data["weaponData"].has("ammoCost") and data["weaponData"]["ammoCost"] != null and (data["general"]["type"] == "attack" or data["general"]["type"] == "attackMiss") and data["general"]["user"] == "Player":
		if data["weaponData"]["ammoCost"] > 0:
			InventoryHelper.ammoEject(data["weaponData"]["weaponName"], data["weaponData"]["ammoCost"], false) # false means a sound wont play
			InventoryHelper.updateWeaponDatabases()
			
	if data["combatData"]["damage"] > 0:
		for i in data["general"]["target"]:
			if i == "Player":
				var health = PlayerDb.playerData["player"]["stats"]["currentHealth"]
				var maxHealth = PlayerDb.playerData["player"]["stats"]["maxHealth"]
				var damage = data["combatData"]["damage"]
				PlayerDb.playerData["player"]["stats"]["currentHealth"] = clamp((health - damage), 0, maxHealth)
				
			else:
				var health = BattleSystem.enemyDict[i]["stats"]["health"]
				var maxHealth = BattleSystem.enemyDict[i]["stats"]["maxHealth"]
				var damage = data["combatData"]["damage"]
				health = clamp((health - damage), 0, maxHealth)
				if health > 0 and damage > 0:
					BattleSystem.enemyDict[i]["stats"]["health"] = health
				elif health <= 0:
					BattleSystem.enemyDeath(i)
					
					
	if data["playerStatus"]["radiationInflict"] > 0:
		var radiation = PlayerDb.playerData["player"]["stats"]["radiation"]
		var radDamage = data["playerStatus"]["radiationInflict"]
		PlayerDb.playerData["player"]["stats"]["radiation"] = clamp((radiation + radDamage), 0, 100)
	
	
	# Advancing/Regressing in Combat
	if data["general"]["type"] == "advance" and data["general"]["user"] == "Player":
		match data["combatData"]["advanceDirection"]:
			"forwards":
				for i in BattleSystem.enemyDict.keys():
					if BattleSystem.enemyDict[i]["distance"] == "far":
						BattleSystem.enemyDict[i]["distance"] = "mid"
					elif BattleSystem.enemyDict[i]["distance"] == "mid":
						BattleSystem.enemyDict[i]["distance"] = "close"
			"backwards":
				for i in BattleSystem.enemyDict.keys():
					if BattleSystem.enemyDict[i]["distance"] == "mid":
						BattleSystem.enemyDict[i]["distance"] = "far"
					elif BattleSystem.enemyDict[i]["distance"] == "close":
						BattleSystem.enemyDict[i]["distance"] = "mid"
					
	# Surge/Rest Action
	if data["general"]["type"] == "surge" or data["general"]["type"] == "rest":
		BattleSystem.enemyDict[data["general"]["user"]]["stats"]["stamina"] = clamp(
			BattleSystem.enemyDict[data["general"]["user"]]["stats"]["stamina"] + data["enemyStatus"]["staminaRegen"], 0, BattleSystem.enemyDict[data["general"]["user"]]["stats"]["maxStamina"])
		
	# Phase Change Action
	if data["enemyStatus"]["phaseChange"] != "":
		BattleSystem.enemyDict[data["general"]["user"]]["phase"] = data["enemyStatus"]["phaseChange"]
		BattleSystem.battleConfig()
		
	# Enemy Stamina Cost
	
	if data["general"]["user"] != "Player" and (data["general"]["type"] == "attack" or data["general"]["type"] == "attackMiss" or data["general"]["type"] == "telegraph"):
		BattleSystem.enemyDict[data["general"]["user"]]["stats"]["stamina"] = clamp(
		BattleSystem.enemyDict[data["general"]["user"]]["stats"]["stamina"] - data["enemyStatus"]["staminaCost"], 0, BattleSystem.enemyDict[data["general"]["user"]]["stats"]["maxStamina"])
		
	# Reload Action
	if data["general"]["type"] == "reload":
		if data["globalFunction"]["stdReload"] == true:
			InventoryHelper.reload(data["weaponData"]["weaponName"], data["weaponData"]["ammoType"])
		elif data["globalFunction"]["altReload"] == true:
			InventoryHelper.confirmSpecialReload(data["weaponData"]["ammoRefill"])
		await get_tree().create_timer(data["general"]["resultPause"]).timeout
		InventoryHelper.updateWeaponDatabases()
		
	
	# Use Item Action
	if data["general"]["type"] == "useItem":
		var itemName = data["itemData"]["itemName"]
		if itemName != null and itemName != "" and PlayerDb.playerData["player"]["inventory"].has(itemName):
			var currentHealth = PlayerDb.playerData["player"]["stats"]["currentHealth"]
			var maxHealth = PlayerDb.playerData["player"]["stats"]["maxHealth"]
			var currentRadiation = PlayerDb.playerData["player"]["stats"]["radiation"]
			var healAmount = randi_range(data["sharedData"]["healMin"], data["sharedData"]["healMax"])
			var radReduceAmount = data["playerStatus"]["radiationReduce"]
			
			PlayerDb.playerData["player"]["stats"]["currentHealth"] = clamp(currentHealth + healAmount, 0, maxHealth)
			PlayerDb.playerData["player"]["stats"]["radiation"] = clamp(currentRadiation - radReduceAmount, 0, 100)
			
			if GlobalDb.itemDatabase[itemName]["general"]["disposable"] == true:
				PlayerDb.playerData["player"]["inventory"][itemName]["quantity"] -= 1
				if PlayerDb.playerData["player"]["inventory"][itemName]["quantity"] <= 0:
					PlayerDb.playerData["player"]["inventory"].erase(itemName)
			Global.helpMenu.updateItemDescriptions()
		
	# Death Action
	if data["general"]["type"] == "death":
		if data["general"]["user"] == "Player":
			BattleSystem.endBattleLose.emit()
		else:
			instance_from_id(BattleSystem.enemyDict[data["general"]["user"]]["battleSpriteID"]).deathAnimation()
			BattleSystem.turnOrderArray.erase(data["general"]["user"])
			BattleSystem.enemyDict.erase(data["general"]["user"])
			
			if BattleSystem.enemyDict.size() == 0 and BattleSystem.battleEnded == false:
				BattleSystem.battleEnded = true
				BattleSystem.winBattle()

	# Flee Action
	
	if data["general"]["type"] == "fleeSuccess":
		actions.clear()
		queuedActions.clear()
		flee = true
		BattleSystem.battleEnded = true
		BattleSystem.winBattle(true)

	# Level Up
	if data["general"]["type"] == "levelUp":
		pendingSkillUpgrade = true
		




	processing = false
		
		
		


func queueSpecificAction(action):
	actions.append(action)



# action templates (to hasten things up!)
func queueReloadAction(weaponName, ammoType, reloadType, ammoRefill):
	var action = actionTemplate.duplicate(true) # can't just reference the variable,
	#because dictionaries are objects and if you define a variable as another variable that is an object
	# it will simply always point at the same memory address as that variable
	# instead of making a copy
	action["general"]["announcement"] = GlobalDb.weaponDatabase[weaponName]["reloadAnnouncement"]
	action["general"]["announcementSFX"] = GlobalDb.weaponDatabase[weaponName]["reloadAnnouncementSFX"]
	
	action["general"]["name"] = "RELOAD " + weaponName
	action["general"]["type"] = "reload"
	action["general"]["user"] = "Player"
	action["weaponData"]["weaponName"] = weaponName
	action["weaponData"]["ammoType"] = ammoType
	action["weaponData"]["reloadType"] = reloadType
	match reloadType:
		"std":
			action["globalFunction"]["stdReload"] = true
			action["weaponData"]["ammoRefill"] = ammoRefill
			
		"alt":
			action["globalFunction"]["altReload"] = true
			action["weaponData"]["ammoRefill"] = ammoRefill
	queuedActions.append(action)

func queueLevelUp():
	var player = Global.playerData["player"]
	var levelsRemaining = max(player["levelCap"] - player["level"], 0)
	for i in range(levelsRemaining):
		if player["experience"]["current"] < player["experience"]["needed"]:
			break
		PlayerDb.levelUp()
		
		var action = actionTemplate.duplicate(true)
		action["general"]["announcement"] = "Flynn has reached level " + str(player["level"]) + "!"
		action["general"]["announcementSFX"] = "res://Assets/Sounds/UI/level_up.mp3"
		action["general"]["type"] = "levelUp"
		action["general"]["inputDependent"] = true
		actions.append(action)



func queueEpiphany(levelCap):
	var action = actionTemplate.duplicate(true)
	var player = Global.playerData["player"]
	player["levelCap"] = levelCap
	player["epiphany"] = player["epiphany"] + 1
	action["general"]["announcement"] = "Flynn had an epiphany."
	action["general"]["announcementSFX"] = "res://Assets/Sounds/UI/epiphany.ogg"
	action["general"]["type"] = "epiphany"
	actions.append(action)

func queueAnnouncementAction(text, speed, sound, priority=1):
	var action = actionTemplate.duplicate(true)
	action["general"]["type"] = "announcement"
	action["general"]["announcement"] = text
	action["general"]["announcementSFX"] = sound
	action["general"]["typewriteSpeed"] = speed
	action["general"]["priority"] = priority
	actions.append(action)

func formatActionText(txt, data, targetsArray = []):
	var text = str(txt)
	var targets = targetsArray
	text = text.replace("[ITEM]", data["itemData"]["itemName"])

	if data["general"].has("target") and data["general"]["target"] != null:
		var rawTarget = data["general"]["target"]
		if typeof(rawTarget) == TYPE_ARRAY:
			if rawTarget.is_empty():
				targets = ""
			elif rawTarget.size() > 2:
				var front := []
				for i in range(rawTarget.size() - 1):
					front.append(str(rawTarget[i]))
				targets = ", ".join(front) + ", and %s" % str(rawTarget[-1])
			elif rawTarget.size() == 2:
				targets = str(rawTarget[0]) + " and %s" % str(rawTarget[1])
			else:
				targets = str(rawTarget[0])
		else:
			targets = str(rawTarget)

	text = text.replace("[TARGET]", targets)
	text = text.replace("[LIMB]", (data["combatData"]["limb"]).to_lower())
	text = text.replace("[AMMOVALUE]", str(data["weaponData"]["ammoRefill"]))
	text = text.replace("[AMMOTYPE]", data["weaponData"]["ammoType"])
	text = text.replace("[DAMAGE]", str(data["combatData"]["damage"]))
	text = text.replace("[NAME]", str(data["general"]["user"]))
	text = text.replace("[RADIATION]", str(data["playerStatus"]["radiationInflict"]))
	return(text)
