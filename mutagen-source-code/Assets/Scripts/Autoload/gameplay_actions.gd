extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func useItem(item):
	var action = ActionProcessor.actionTemplate.duplicate(true)
	var itemData = GlobalDb["itemDatabase"][item]
	var uiContext = "world"
	if Global.currentScreen == "battle":
		uiContext = "battle"
	var uiData = itemData["uiData"][uiContext]
	var statusData = itemData["statusData"]
	var combatData = itemData["combatData"]
	var actionData = itemData["actionData"]
	
	action["general"]["type"] = "useItem"
	action["general"]["name"] = "Use Item: " + itemData["general"]["name"]
	action["general"]["user"] = actionData["user"]
	action["general"]["userName"] = "Flynn"
	action["general"]["target"] = actionData["target"]
	action["general"]["repeat"] = actionData["repeat"]
	action["general"]["announcement"] = uiData["announcement"]
	action["general"]["announcementSFX"] = uiData["announcementSFX"]
	action["general"]["impactSFX"] = uiData["impactSFX"]
	action["general"]["impactTXT"] = uiData["impactTXT"]
	action["general"]["result"] = uiData["result"]
	action["general"]["announcementPause"] = uiData["announcementPause"]
	action["general"]["impactPause"] = uiData["impactPause"]
	action["general"]["resultPause"] = uiData["resultPause"]
	action["general"]["inputDependent"] = uiData["inputDependent"]

	action["itemData"]["itemName"] = item
	action["itemData"]["isHeal"] = itemData["general"]["isHeal"]
	action["combatData"]["atkBoost"] = combatData["atkBoost"]
	action["combatData"]["damage"] = combatData["damage"]
	action["combatData"]["limb"] = combatData["limb"]
	action["combatData"]["statusEffect"] = combatData["statusEffect"]
	action["combatData"]["telegraph"] = combatData["telegraph"]
	action["playerStatus"]["radiationInflict"] = statusData["radiationInflict"]
	action["playerStatus"]["radiationReduce"] = statusData["radiationReduce"]
	action["sharedData"]["healMin"] = statusData["healMin"]
	action["sharedData"]["healMax"] = statusData["healMax"]

	
	match Global.currentScreen:
		"battle":
			ActionProcessor.queuedActions.append(action)
			BattleSystem.startTurns()
		"world":
			ActionProcessor.queueSpecificAction(action)
			
			
func levelUp():
	var player = Global.playerData["player"]
	var levelsRemaining = max(player["levelCap"] - player["level"], 0)
	for i in range(levelsRemaining):
		if player["experience"]["current"] < player["experience"]["needed"]:
			break
		PlayerDb.levelUp()
		
		var action = ActionProcessor.actionTemplate.duplicate(true)
		action["general"]["announcement"] = "Flynn has reached level " + str(player["level"]) + "!"
		action["general"]["announcementSFX"] = "res://Assets/Sounds/UI/level_up.mp3"
		action["general"]["type"] = "levelUp"
		action["general"]["inputDependent"] = true
		ActionProcessor.actions.append(action)



func haveEpiphany(levelCap):
	var action = ActionProcessor.actionTemplate.duplicate(true)
	var player = Global.playerData["player"]
	player["levelCap"] = levelCap
	player["epiphany"] = player["epiphany"] + 1
	action["general"]["announcement"] = "Flynn had an epiphany."
	action["general"]["announcementSFX"] = "res://Assets/Sounds/UI/epiphany.ogg"
	action["general"]["type"] = "epiphany"
	ActionProcessor.actions.append(action)
