extends Control

var parsing := false
var characterName := "null"
var characterVoice := "null"
var tween : Tween = create_tween().set_trans(Tween.TRANS_SINE)
var defaultSpeakingSpeed := 0.5
var baseSpeakingSpeed := 0.5
var speakingSpeed := 0.5
var speakingMultiplier := 1
var sentenceStarted := false
var sentenceEnded := false

func _ready():
	Global.dialogueBox = self

func _process(delta):
	# Setting labels
	$Panel/VBoxContainer/HBoxContainer2/Name.text = characterName
	characterName = DialogueLoader.characterName
	characterVoice = DialogueLoader.characterVoice
	
	# Typewriter text
	if $Panel/VBoxContainer/HBoxContainer/Text.get_parsed_text().length() > $Panel/VBoxContainer/HBoxContainer/Text.visible_characters and parsing == false and DialogueLoader.conversing == true:
		sentenceEnded = false
		parsing = true
		$Timer.start()
	# pausing for a bit if theres a period or comma
		if $Panel/VBoxContainer/HBoxContainer/Text.get_parsed_text()[$Panel/VBoxContainer/HBoxContainer/Text.visible_characters] in [".","!","?"]:
			speakingSpeed = baseSpeakingSpeed
		elif $Panel/VBoxContainer/HBoxContainer/Text.get_parsed_text()[$Panel/VBoxContainer/HBoxContainer/Text.visible_characters] == ",":
			speakingSpeed = baseSpeakingSpeed * 0.6
		else:
			speakingSpeed = baseSpeakingSpeed * 0.06
		
		$Timer.wait_time = speakingSpeed / speakingMultiplier
		
	if Input.is_action_pressed("Accept") == true and parsing and $Panel/VBoxContainer/HBoxContainer/Text.visible_characters > 8: # > 8 is just there so that it doesn't immediately activate when the player presses Accept to continue dialogue
		speakingMultiplier = 4 # speeding up text
		
	if $Panel/VBoxContainer/HBoxContainer/Text.visible_characters == 0:
		speakingMultiplier = 1 # setting text speed back to original
	
	if $Panel/VBoxContainer/HBoxContainer/Text.get_parsed_text().length() == $Panel/VBoxContainer/HBoxContainer/Text.visible_characters and DialogueLoader.conversing == true and sentenceEnded == false:
		sentenceEnded = true
		sentenceStarted = false
		DialogueLoader.endSentence()
	
	if (Input.is_action_just_pressed("Accept") == true) and parsing == false and DialogueLoader.conversing == true: # has to be "is_action_just_pressed" or else dialogue and conversation choices will skip instantly and the player will be pissed
		if DialogueLoader.decision == false and DialogueLoader.loadedDialogueBlock["end"] == false:
			DialogueLoader.dialogueStringID = DialogueLoader.nextConversationID # this MUST be a string otherwise it will break.
			DialogueLoader.dialogueCycle()
			
		elif DialogueLoader.decision == true and DialogueLoader.loadedDialogueBlock["end"] == false:
			if $decisionMaker/Choices/HBoxContainer/VBoxContainer2/Option1.has_focus():
				DialogueLoader.dialogueStringID = DialogueLoader.loadedDialogueBlock["options"][0]["next"]
			elif $decisionMaker/Choices/HBoxContainer/VBoxContainer2/Option2.has_focus():
				DialogueLoader.dialogueStringID = DialogueLoader.loadedDialogueBlock["options"][1]["next"]
			elif $decisionMaker/Choices/HBoxContainer/VBoxContainer2/Option3.has_focus():
				DialogueLoader.dialogueStringID = DialogueLoader.loadedDialogueBlock["options"][2]["next"]
			DialogueLoader.dialogueCycle()
		
		else:
			DialogueLoader.endDialogue()
	
	


func _on_timer_timeout():
	speak()
	$Panel/VBoxContainer/HBoxContainer/Text.visible_characters += 1
	parsing = false
	if sentenceStarted == false:
		sentenceStarted = true
		DialogueLoader.beginSentence()

	
func speak():
	# loading the voice first
	
	#changing the tone of voice
	if DialogueLoader.tone == "neutral" or DialogueLoader.tone == "normal":
		$Voice.pitch_scale = Global.rng.randf_range(0.95,1.05)
		
	if DialogueLoader.tone == "excited":
		$Voice.pitch_scale = Global.rng.randf_range(1,1.2)
		
	if DialogueLoader.tone == "angry":
		$Voice.pitch_scale = Global.rng.randf_range(0.75, 1)
		
	if DialogueLoader.tone == "fearful":
		$Voice.pitch_scale = Global.rng.randf_range(1.1, 1.3)
	
	if $Voice.playing == false and characterVoice != "" and characterVoice != null: 
		if $Panel/VBoxContainer/HBoxContainer/Text.get_parsed_text()[$Panel/VBoxContainer/HBoxContainer/Text.visible_characters] not in [".","!", " ", ">", ",", "?", "-", ")", "("]:
			# idk why that extra condition fixes it so its technically a hack
			$Voice.volume_db = 0
			$Voice.stream = load("res://Assets/Sounds/NPC/Voices/" + characterVoice + [" A", " B", " C"].pick_random() + ".mp3")
			$Voice.play()
			#tween = create_tween().set_trans(Tween.TRANS_SINE)
			#tween.tween_property($Voice, "volume_db", -100, 0.15)
		if $Voice.volume_db <= -100:
			$Voice.stop()
		#	tween.kill()
		
	

func changeSpeakingSpeed(speed):
	baseSpeakingSpeed = speed
	
func resetSpeakingSpeed():
	baseSpeakingSpeed = defaultSpeakingSpeed

func cycle():
	show()
	$Panel/VBoxContainer/HBoxContainer/Text.visible_characters = 0
	if $animationPlayer.assigned_animation == "Hidden":
		$animationPlayer.play("Slide_In")
		$animationPlayer.queue("Normal")
	
func end():
	$Panel/VBoxContainer/HBoxContainer/Text.text = ""
	$decisionMaker.visible = false
	hide()
	if $animationPlayer.assigned_animation == "Slide_In" or $animationPlayer.assigned_animation == "Normal":
		$animationPlayer.play("Hidden")
