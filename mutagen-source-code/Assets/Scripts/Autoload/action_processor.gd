extends Node

# Helpers
const PROCESS_ACTION = preload("res://Assets/Scripts/Autoload/Helpers/Action Processor/processAction.gd")

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
				PROCESS_ACTION.execute(actions[0])
			else:
				PROCESS_ACTION.execute(actions[0])

func _on_timer_timeout():
	return
	


func queueSpecificAction(action):
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
