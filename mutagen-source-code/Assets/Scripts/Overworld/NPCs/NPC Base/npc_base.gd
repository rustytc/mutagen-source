extends Node2D
@export var dialogueJsonPath = "res://Assets/Data/Dialogue/World/Test/NPC/test/test.json"
@export var characterName = "test"
@export var initialConversationID = "0"
## If enabled, interacting with this NPC will pause the player's surroundings. Ideal if there's enemies in the same area.
@export var pauseToInteract = true
var lineOfSight = false
# Important things to know:
# When initialConversationID is equal to "endpoint", the conversation should not start.



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	if initialConversationID != "endpoint" and DialogueLoader.conversing == false and lineOfSight and ActorHelper.targetters == 0:
		if (Input.is_action_pressed("Interact") == true):
			DialogueLoader.currentSpeaker = self
			DialogueLoader.conversing = true
			DialogueLoader.dialogueStringID = initialConversationID
			DialogueLoader.loadedDialogue = JSON.parse_string(FileAccess.get_file_as_string(dialogueJsonPath))
			DialogueLoader.dialogueCycle()
			if pauseToInteract == true:
				get_tree().paused = true # pause the scene when the player is interacting with an npc


func _on_line_of_sight_area_body_entered(body):
	if body.is_in_group("playerBody"):
		lineOfSight = true
		


func _on_line_of_sight_area_body_exited(body):
	if body.is_in_group("playerBody"):
		lineOfSight = false
