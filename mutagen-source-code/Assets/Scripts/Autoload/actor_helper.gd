extends Node
@export var targetters : int = 0 ## count of how many enemies are currently chasing the player


# NPC Actors

var npcDatabase = {
	"huskValley" : {
		"HQ" : {
			"Captain Alexson" : {
				"present" : false
			}
		}
		}
}

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
