extends Node

@onready var selectedItem = null
var streamNumber := 0
var audio: AudioStreamPlayer
var playback:AudioStreamPlaybackPolyphonic
var activeStreams := []

# Universal Sound Effects



func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Create an audio player
	audio = AudioStreamPlayer.new()
	add_child(audio)
	get_child(0).process_mode = Node.PROCESS_MODE_ALWAYS
	audio.process_mode = Node.PROCESS_MODE_ALWAYS
	audio.bus = &"SFX"
	
	# Create a polyphonic stream so we can play sounds directly from it
	var stream = AudioStreamPolyphonic.new()
	stream.polyphony = 32
	audio.stream = stream
	audio.process_mode = Node.PROCESS_MODE_ALWAYS
	audio.play()
	
	# Get the polyphonic playback stream to play sounds
	playback = audio.get_stream_playback()
	get_tree().node_added.connect(_on_node_added)
	get_viewport().gui_focus_changed.connect(_on_gui_focus_changed)
	



func _on_node_added(node:Node) -> void:
	if ((node is Control) ): # and node.visible == true  was a condition, but I need to get rid of it
		# because it breaks some UI nodes that arent immediately visible. for now im just going to move it
		# into the actual focus change code for when play_hover() is called instead of outright not connecting
		# initially hidden ui elements to the focus entered signal
		if node is Tree or node is ItemList: # these two don't need the signal and will play the sound twice otherwise
			return

		node.focus_entered.connect(_play_hover)


func _play_hover() -> void:
	# this extra if event is here so that the sound doesnt immediately play once a button becomes visible and focused on
	if (Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right")) and get_viewport().gui_get_focus_owner() is Control and get_viewport().gui_get_focus_owner().visible == true:
		#playback.stop_stream(streamNumber):
		streamNumber += 1
		audio.bus = &"SFX"
		playback.play_stream(preload("res://Assets/Sounds/UI/select.mp3"), 0, 0, 1)
		
func _play_accept() -> void:
	streamNumber += 1
	audio.bus = &"SFX"
	playback.play_stream(preload("res://Assets/Sounds/UI/click.mp3"), 0, 0, 1)



func _play_error():
	streamNumber += 1
	playback.play_stream(preload("res://Assets/Sounds/UI/error.mp3"), 0, 0, 1)

# func _play_pressed() -> void: yeah let's forget about this it doesn't work
	# playback.play_stream(preload("res://Assets/Sounds/UI/click.mp3"), 0, 0, 1)


func _on_gui_focus_changed():
	var focus = get_viewport().gui_get_focus_owner()
	if focus is Tree or focus is ItemList or focus is Button:
		_play_hover()


# Playing Specified Noises
func playSpecialSound(x, bus = &"SFX"):
	var stream := load(x)  
	streamNumber += 1
	audio.bus = bus
	var streamId = playback.play_stream(stream, 0, 0, 1)
	activeStreams.append(streamId)
	
func stopAllSpecialSounds():
	if playback == null:
		return
	for streamId in activeStreams:
		playback.stop_stream(streamId)
	activeStreams.clear()




func _process(delta):
	
	
	# Bus Volumes
	
	# Adjust sound volume
	if AudioServer.get_bus_index("SFX") != (0 - (100 - Settings.settingsRaw["sfxVolume"])/2) and Settings.settingsRaw["sfxVolume"] != 0:
			AudioServer.set_bus_volume_db(3, (0 - (100 -Settings.settingsRaw["sfxVolume"])/2))
	elif Settings.settingsRaw["sfxVolume"] == 0 and AudioServer.get_bus_index("SFX") != -99999:
		AudioServer.set_bus_volume_db(3, -99999)
	# Adjust BGM volume
	if AudioServer.get_bus_index("BGM") != (0 - (100 - Settings.settingsRaw["musicVolume"])/2) and Settings.settingsRaw["musicVolume"] != 0:
		AudioServer.set_bus_volume_db(1, (0 - (100 - Settings.settingsRaw["musicVolume"])/2))
	elif Settings.settingsRaw["musicVolume"] == 0 and AudioServer.get_bus_index("BGM") != -99999:
		AudioServer.set_bus_volume_db(1, -99999)
	
	# if it's a button, for left clicks, it checks if it has focus, isnt null and is being hovered over. otherwise, godot handles this automatically
	if get_viewport().gui_get_focus_owner() is Button:
		if (Input.is_action_just_pressed("ui_accept") or (Input.is_action_just_pressed("Left Click") and get_viewport().gui_get_focus_owner() != null and get_viewport().gui_get_focus_owner().is_hovered()) and get_viewport().gui_get_focus_owner().visible == true):
			_play_accept()
	
	
	if get_viewport().gui_get_focus_owner() != null && (get_viewport().gui_get_focus_owner() is Tree):
		if get_viewport().gui_get_focus_owner().select_mode == Tree.SELECT_ROW and Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
			return
			# nested ifs. yeah.
		if get_viewport().gui_get_focus_owner().get_selected() != selectedItem:
			if get_viewport().gui_get_focus_owner() == null:
				return
			else:
				selectedItem = get_viewport().gui_get_focus_owner()
				_play_hover()
	if get_viewport().gui_get_focus_owner() != null && (get_viewport().gui_get_focus_owner() is ItemList):
		if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
			return
		else:
			_play_hover()
			
			
