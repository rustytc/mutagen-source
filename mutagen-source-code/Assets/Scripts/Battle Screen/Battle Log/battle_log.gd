extends Control
@export var empty := true
var parsing := false
var speakingSpeed := 0.03
var speakingMultiplier := 1
signal finishedTyping

func _ready():
	Global.actionLog = self
	ActionProcessor.actionLog = self
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Global.currentScreen == "world":
		if not visible and ActionProcessor.processing == true and $AnimationPlayer.current_animation != "PanIn":
			panIn()
		if visible and ActionProcessor.processing == false and $AnimationPlayer.current_animation != "PanOut" and Input.is_action_just_pressed("Accept") and ActionProcessor.actions.is_empty() and ActionProcessor.queuedActions.is_empty() and  $Panel/VBoxContainer/HBoxContainer/Text.get_parsed_text().length() == $Panel/VBoxContainer/HBoxContainer/Text.visible_characters:
			panOut()
			if Global.helpMenu.currentMenu == "items":
				Global.helpMenu.grab_item_list_focus()
	if Global.currentScreen == "battle":
		if not visible and ActionProcessor.processing == true and $AnimationPlayer.current_animation != "PanIn" and not get_parent().is_in_group("Overworld UI"):
			# ^ last check makes sure the actionlog doesnt randomly become visible again when you leave a battle
			panIn()
	
	
	# Speeding up dialogue (and everything else)
	if Input.is_action_pressed("Speed Up Dialogue") and ActionProcessor.processing == true and BattleSystem.battleEnded == false:
		Engine.time_scale = 10
	else:
		Engine.time_scale = 1
	
	
	if $Panel/VBoxContainer/HBoxContainer/Text.get_parsed_text().length() > 0:
		empty = false
	else:
		empty = true
	
	# Typewriter text
	if $Panel/VBoxContainer/HBoxContainer/Text.get_parsed_text().length() > $Panel/VBoxContainer/HBoxContainer/Text.visible_characters and parsing == false:
		parsing = true
		$Timer.start()
	# pausing for a bit if theres a period or comma
		if $Panel/VBoxContainer/HBoxContainer/Text.get_parsed_text()[$Panel/VBoxContainer/HBoxContainer/Text.visible_characters] in [".","!","?"]:
			speakingSpeed = 0.1
		elif $Panel/VBoxContainer/HBoxContainer/Text.get_parsed_text()[$Panel/VBoxContainer/HBoxContainer/Text.visible_characters] == ",":
			speakingSpeed = 0.06
		else:
			speakingSpeed = 0.04
		
		$Timer.wait_time = speakingSpeed / speakingMultiplier
		
	if $Panel/VBoxContainer/HBoxContainer/Text.get_parsed_text().length() <= $Panel/VBoxContainer/HBoxContainer/Text.visible_characters and $Panel/VBoxContainer/HBoxContainer/Text.get_parsed_text().length() > 0:
		finishedTyping.emit()
		
func _on_timer_timeout():
	$Panel/VBoxContainer/HBoxContainer/Text.visible_characters += 1
	parsing = false


func panIn():
	$AnimationPlayer.stop()
	$AnimationPlayer.play("PanIn")
	$AnimationPlayer.queue("Idle")
	
func panOut():
	$AnimationPlayer.stop()
	$AnimationPlayer.play("PanOut")
	$AnimationPlayer.queue("Hidden")
