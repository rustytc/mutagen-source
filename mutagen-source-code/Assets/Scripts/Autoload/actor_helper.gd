extends Node
@export var targetters : int = 0 ## count of how many enemies are currently chasing the player


# NPC Actors

var npcDatabase : Dictionary = {
	"huskValley" : {
		"HQ" : {
			"Captain Alexson" : {
				"present" : false
			}
		}
		}
}
var objectDatabase : Dictionary = {
}

func pickUpItem(ID):
	var key = objectDatabase[PlayerDb.playerData["player"]["currentArea"]][PlayerDb.playerData["player"]["currentRoom"]][ID]
	var action = ActionProcessor.actionTemplate.duplicate(true)
	action["general"]["announcement"] = key["announcement"]
	action["general"]["result"] = key["result"]
	action["general"]["resultSFX"] = key["resultSFX"]
	action["general"]["announcementSFX"] = key["announcementSFX"]
	
	if key["ammo"] == false and key["armor"] == false:
		InventoryHelper.addItem(key["item"],key["quantity"])
	elif key["ammo"] == true:
		PlayerDb.playerData["player"]["ammo"][key["item"]] += key["quantity"]
		Global.helpMenu.updateWeaponDescriptions()
	elif key["armor"] == true:
		InventoryHelper.addArmor("item", "armorType", "quantity")
			
	action["general"]["announcement"] = key["announcement"].replace("[QUANTITY]",str(key["quantity"]))
	if key["quantity"] > 1:
		action["general"]["announcement"] = action["general"]["announcement"].replace("[PLURALIZER]","s")
	else:
		action["general"]["announcement"] = action["general"]["announcement"].replace("[PLURALIZER]","")
		
	ActionProcessor.queueSpecificAction(action)
	
func interact(announcement, result, announcementSFX, resultSFX): # for interacting with objects that arent items
	var action = ActionProcessor.actionTemplate.duplicate(true)
	if announcement != null:
		action["general"]["announcement"] = announcement
	if announcementSFX != null:
		action["general"]["announcementSFX"] = announcementSFX
	if result != null:
		action["general"]["result"] = result
	if resultSFX != null:
		action["general"]["resultSFX"] = resultSFX
	ActionProcessor.queueSpecificAction(action)

func _process(delta):
	var area = PlayerDb.playerData["player"]["currentArea"]
	var room = PlayerDb.playerData["player"]["currentRoom"]

	for i in get_tree().get_nodes_in_group("Talkative NPC"):
		var characterName = i.characterName
		if Global.cutsceneIsActive:
			continue
		if not npcDatabase.has(area):
			continue
		if not npcDatabase[area].has(room):
			continue
		if not npcDatabase[area][room].has(characterName):
			continue
		if npcDatabase[area][room][characterName].has("present") and npcDatabase[area][room][characterName]["present"] == false:
			i.queue_free()
			
func changeNPCProperty(characterName, area, room, property, value):
	npcDatabase[area][room][characterName][property] = value

# Animation Switching from Triggers
func animate(object : Node, animationName : String, animationNode : String = "AnimatedSprite2D"):
	if object.has_node(animationNode):
		object.get_node(animationNode).play(animationName)
	else:
		print('ACTOR HELPER ISN"T WORKIIIIING')

func nextConversation(object : Node, conversationPath : String, initialID : String):
	var area = PlayerDb.playerData["player"]["currentArea"]
	var room = PlayerDb.playerData["player"]["currentRoom"]
	var npc = object.characterName
	if not npcDatabase.has(area):
		npcDatabase[area] = {}
	if not npcDatabase[area].has(room):
		npcDatabase[area][room] = {}
	if not npcDatabase[area][room].has(npc):
		npcDatabase[area][room][npc] = {}
	npcDatabase[area][room][npc]["dialogueJsonPath"] = conversationPath
	npcDatabase[area][room][npc]["initialConversationID"] = initialID
	object.dialogueJsonPath = conversationPath
	object.initialConversationID = str(initialID)

func die():
	get_tree().paused = false
	DialogueLoader.endDialogue()
	Global.playerCharBody2D.controllable = false
	BattleSystem.endBattleLose.emit()
