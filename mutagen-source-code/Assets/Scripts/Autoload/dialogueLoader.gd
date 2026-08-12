extends Node

# Dialogue Data
@onready var characterName := "John Wolfmann"
@onready var characterVoice := "John Wolfmann"
@onready var tone := "neutral"
@onready var dialogueStringID : String = "0" # HAS TO BE A STRING
@onready var nextConversationID : String = "0"
@onready var loadedDialogue := {}
@onready var loadedDialogueBlock := {}
@onready var conversing := false
@onready var currentSpeaker = null
var decision := false
var text := ""


# Called when the node enters the scene tree for the first time.
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Global.dialogueBox == null:
		return
	
	# Hiding/showing the dialogue box
	if not conversing: #and Global.dialogueBox != null: # It's null by default, by the way
		Global.dialogueBox.hide()
		
	
	if decision == true and (Global.dialogueBox.get_node("Panel/VBoxContainer/HBoxContainer/Text").get_parsed_text().length() <= Global.dialogueBox.get_node("Panel/VBoxContainer/HBoxContainer/Text").visible_characters) and Global.dialogueBox.get_node("decisionMaker").visible == false: # the last condition is important because it makes this only run once and prevents it from grabbing focus infinitely
		if loadedDialogueBlock["options"].size() > 0: # these checks show/hide the option buttons depending on how many options are specified by the dialogue json
			Global.dialogueBox.get_node("decisionMaker/Choices/HBoxContainer/VBoxContainer2/Option1").text = "> " + (loadedDialogueBlock["options"][0]["text"]) # adding the > right here out of laziness
			Global.dialogueBox.get_node("decisionMaker/Choices/HBoxContainer/VBoxContainer2/Option1").visible = true
		else:
			Global.dialogueBox.get_node("decisionMaker/Choices/HBoxContainer/VBoxContainer2/Option1").visible = false
		if loadedDialogueBlock["options"].size() > 1:
			Global.dialogueBox.get_node("decisionMaker/Choices/HBoxContainer/VBoxContainer2/Option2").text = "> " + (loadedDialogueBlock["options"][1]["text"])
			Global.dialogueBox.get_node("decisionMaker/Choices/HBoxContainer/VBoxContainer2/Option2").visible = true
		else:
			Global.dialogueBox.get_node("decisionMaker/Choices/HBoxContainer/VBoxContainer2/Option2").visible = false
		if loadedDialogueBlock["options"].size() > 2:
			Global.dialogueBox.get_node("decisionMaker/Choices/HBoxContainer/VBoxContainer2/Option3").text = "> " + (loadedDialogueBlock["options"][2]["text"])
			Global.dialogueBox.get_node("decisionMaker/Choices/HBoxContainer/VBoxContainer2/Option3").visible = true
		else:
			Global.dialogueBox.get_node("decisionMaker/Choices/HBoxContainer/VBoxContainer2/Option3").visible = false
			
		Global.dialogueBox.get_node("decisionMaker").visible = true
		
		# Grab focus
		Global.dialogueBox.get_node("decisionMaker/Choices/HBoxContainer/VBoxContainer2/Option1").grab_focus()
		
	#elif Global.dialogueBox != null:
	if Global.dialogueBox.get_node("decisionMaker").visible == true and (Global.dialogueBox.get_node("Panel/VBoxContainer/HBoxContainer/Text").get_parsed_text().length() > Global.dialogueBox.get_node("Panel/VBoxContainer/HBoxContainer/Text").visible_characters):
		Global.dialogueBox.get_node("decisionMaker").visible = false

func parseArguments(args):
	var parsedArgs : Array = []
	for i in args:
		match i["type"]:
			"string":
				parsedArgs.append(str(i["value"]))
			"integer":
				parsedArgs.append(int(i["value"]))
			"float":
				parsedArgs.append(float(i["value"]))
			"boolean":
				parsedArgs.append(bool(i["value"]))
			"identifier": # because get() doesnt infer autoloads and must
				# be variables directly from self, it first checks if it is referencing
				# a known autoload, and only if not does it check self.
				if i["value"].begins_with("Global."):
					parsedArgs.append(Global.get(i["value"].substr(7)))
				elif i["value"].begins_with("ActorHelper."):
					parsedArgs.append(ActorHelper.get(i["value"].substr(12)))
				elif i["value"].begins_with("UniversalAudio."):
					parsedArgs.append(UniversalAudio.get(i["value"].substr(15)))
				else:
					parsedArgs.append(get(i["value"])) # probably never used might as well throw up an error lol
	return(parsedArgs)

func dialogueCycle():
	Global.dialogueBox.cycle()
	Engine.time_scale = 1
	Global.player.get_node("CharacterBody2D").controllable = false
	if conversing == true and Global.dialogueBox.parsing == false:
		for node in loadedDialogue["nodes"]:
			if node["id"] == str(dialogueStringID):
				loadedDialogueBlock = node
	
	characterName = loadedDialogueBlock["npc"]
	characterVoice = loadedDialogueBlock["voice"]
	text = loadedDialogueBlock["text"]
	
	# Functions
	
	# Running dialogue block intiialization commands (such as setting a talking animation)
	if loadedDialogueBlock["startCommands"] != null and loadedDialogueBlock["startCommands"] != []:
		runCommands(loadedDialogueBlock["startCommands"])
	
	
	# Dialogue Options/Branching Dialogue
	
	if loadedDialogueBlock["options"] == []:
		decision = false # we need these for when the decision variable was previously true
	else:
		decision = true
		
		
	if loadedDialogueBlock["end"] == false and loadedDialogueBlock["options"] == []:
		if loadedDialogueBlock.has("next"):
			nextConversationID = loadedDialogueBlock["next"] # the next dialogue ID will always be the one that's set as "next." Not having this will fallback on it being the next ID sequentially, which could break dialogue that loops around
		else:
			nextConversationID = str(int(loadedDialogueBlock["id"]) + 1)

		
		

	(Global.dialogueBox.get_node("Panel/VBoxContainer/HBoxContainer/Text") as RichTextLabel).text = loadedDialogueBlock["text"]
	tone =  loadedDialogueBlock["tone"]
	
	
# Handling timing-specific events

func beginSentence():
	if loadedDialogueBlock["talkCommands"] != null and loadedDialogueBlock["talkCommands"] != []:
		runCommands(loadedDialogueBlock["talkCommands"])

func endSentence():
	if loadedDialogueBlock["endCommands"] != null and loadedDialogueBlock["endCommands"] != []:
		runCommands(loadedDialogueBlock["endCommands"])

	
# Run commands (start and finish)
func runCommands(commands):
	for i in commands:
		var functionName = i["action"]
		var arguments = i["args"]
		var parsedArgs = parseArguments(arguments)
		if has_method(functionName):
			callv(functionName, parsedArgs)
		#TODO: make sure nothing can be executed through the commands in this whitelist
		# NOTE: Function whitelist
		elif functionName in ["print", "UniversalAudio.playSpecialSound", "ActorHelper.animate", "ActorHelper.nextConversation", "stopMusic", "Global.stopMusic", "animate", "sound", "initiateBattle", "hideBox", "showBox", "setEncounterTheme"]: # NOTE whenever you want a global function to be loaded, put it in this array
			var parts = functionName.split(".")
			var target: Object
			var method: String
			if parts.size() == 1:
				target = self
				method = parts[0]
			else:
				target = get_node("/root/" + parts[0])
				method = parts[1]
				
			target.callv(method, parsedArgs)
	
	
func endDialogue():
	decision = false
	conversing = false
	nextConversationID = "0"
	Global.player.get_node("CharacterBody2D").controllable = true
	if get_tree().paused == true: # unpauses the game is the npc's dialogue paused it
		get_tree().paused = false
	







# Quick Function Shortcuts

func animate(actor, animation):
	ActorHelper.animate(actor, animation)
	
func nextConversation(actor, conversation):
	ActorHelper.nextConversation(actor, conversation)
	
func die():
	ActorHelper.die()
	
func stopMusic():
	Global.stopMusic()
	
func sound(sound):
	UniversalAudio.playSpecialSound(sound)

func initiateBattle(enemy, ID := -1):
	BattleSystem.enemiesEncountered.append(enemy)
	BattleSystem.enemyIDsEncountered.append(ID)
	Global.playerCharBody2D.playerCaught()

func hideBox():
	Global.dialogueBox.hide()
	
func showBox():
	Global.dialogueBox.show()

func setEncounterTheme(theme):
	BattleSystem.encounterTheme.append(theme)
	BattleSystem.encounterTheme.append(theme)
	BattleSystem.encounterTheme.append(theme)
	BattleSystem.encounterTheme.append(theme)
	BattleSystem.encounterTheme.append(theme)
