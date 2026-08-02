extends CharacterBody2D


@export var speed : float = 200
@export var controllable := true
@onready var iframes := true
@onready var pauseMenu : Control = get_node("Camera2D/Overworld UI/helpMenu")
@export var caught := false
var enemyType := "blank"
var enemyID := 0
var encounterTheme := "blank"
var cameraFizz := false
var cameraFizzValue : float = 0
var darkness : float = 0
var transition := false
var resting := false
var climbing := false

signal battleInitiated
signal walking

func _init():
	Global.currentScreen = "world" # The player's existence tells the game that the player is moving around in the world

func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	Global.player = self.get_parent()
	Global.playerCharBody2D = self
	BattleSystem.connect('transition', exitBattle)
	
	for enemy in get_tree().get_nodes_in_group("Overworld Enemy"):
		enemy.connect("playerCaught", Callable(self, "playerCaught").bind(enemy))
		connect("battleInitiated", Callable(enemy, "onBattleInitiated"))
			
	

func _process(delta):
	
	# Resting
	if Input.is_action_pressed("Rest") and controllable == true and transition == false:
		resting = true
	elif (not Input.is_action_pressed("Rest") or controllable == false) and resting == true:
		resting = false
		Engine.time_scale = 1
	if controllable == false:
		resting = false
		Engine.time_scale = 1
	if transition:
		resting = false
		Engine.time_scale = 1
	if resting == true:
		Engine.time_scale = 10
	
	# Flashlight
	if Global.playerCharBody2D.get_node("flashlight") != null:
		if Input.is_action_just_pressed("Flashlight") and controllable == true and PlayerDb.playerData["player"]["gear"]["flashlight"]["equipped"] == true and Global.playerCharBody2D.get_node("flashlight").visible == false:
			Global.playerCharBody2D.get_node("flashlight").show()
			UniversalAudio.playSpecialSound("res://Assets/Sounds/Item/flashlightOn.mp3", &"SFX", 10)
		elif Input.is_action_just_pressed("Flashlight") and Global.playerCharBody2D.get_node("flashlight").visible == true:
			UniversalAudio.playSpecialSound("res://Assets/Sounds/Item/flashlightOff.mp3", &"SFX", 10)
			Global.playerCharBody2D.get_node("flashlight").hide()
		elif PlayerDb.playerData["player"]["gear"]["flashlight"]["equipped"] == false:
			Global.playerCharBody2D.get_node("flashlight").hide()
	
	# Background Music
	if Global.cutsceneIsActive == false:
		var musicTweening := false # prevents clipping
		if Global.musicPlaying == true and $Music.playing == false and Global.musicCanPlay == true and Global.music != "" and Global.music != null: # getting the music to play
			$Music.stream = load(Global.music)
			$Music.play()
			$Music.volume_db = Global.musicVolume
		if Global.musicPlaying == true and $Music.volume_db < -1 and Global.musicCanPlay and musicTweening == false: # getting the music to unpause
			var musicTween = create_tween().tween_property($Music, "volume_db", Global.musicVolume, 2)
			musicTweening = true
			await musicTween.finished
			musicTweening = false
		
		if Global.musicPlaying == false and $Music.playing == true: # getting the music to stop playing
			create_tween().tween_property($Music, "volume_db", -300, 2)
		if Global.musicCanPlay == false and Global.musicPlaying == true:
			create_tween().tween_property($Music, "volume_db", -300, 2)
		
	#if AudioServer.get_bus_peak_volume_left_db(AudioServer.get_bus_index("Chase Music"),0) > -195: # checking if theres any chase music playing
	# ^proooobably not going to use this, keep in case of change
	if ActorHelper.targetters > 0:
		# ^ this could present issues in some sections where enemies perpetually chase you, so keep that in mind. maybe outright
		# dont count those enemies as targetters or subtract another variable like perpetual targetters. or just use the old code
		Global.musicCanPlay = false
	else:
		Global.musicCanPlay = true
		
		
# reading tilemap data
	climbing = false
	for i in get_tree().get_nodes_in_group("tilemap"):
		if i is not TileMapLayer:
			continue
		var tilemap : TileMapLayer = i
		var data := tilemap.get_cell_tile_data(tilemap.local_to_map(tilemap.to_local(global_position)))
		if data == null:
			continue
		if tilemap.tile_set.get_custom_data_layer_by_name("climbing") == -1:
			continue
		if data.get_custom_data("climbing") and not climbing:
			climbing = true
			$AnimatedSprite2D.play("Walk Backwards")


var radiationTimer := 0.0
var illnessTimer := 0.0
var bleedTimer := 0.0
var fatigueTimer := 0.0
var crippleTimer := 0.0
# no berserk
func _physics_process(delta):

	if controllable:
		
		velocity = Vector2.ZERO
		if Input.is_action_pressed("Up"):
			velocity.y -= 1
		if Input.is_action_pressed("Down"):
			velocity.y += 1
		if Input.is_action_pressed("Left") and not climbing:
			velocity.x -= 1
		if Input.is_action_pressed("Right") and not climbing:
			velocity.x += 1
		
		velocity = velocity.normalized() * speed
		move_and_slide()
		
		if Input.is_action_pressed("Up") or Input.is_action_pressed("Down") or Input.is_action_pressed("Left") or Input.is_action_pressed("Right"):
			if PlayerDb.playerData["player"]["stats"]["radiation"] > 0:
				
				radiationTimer += delta

				if radiationTimer >= 60.0:
					radiationTimer = 0.0

					if PlayerDb.playerData["player"]["stats"]["radiation"] > 0:
						PlayerDb.playerData["player"]["stats"]["radiation"] -= 1





# Sprinting

		if Input.is_action_pressed("Shift") and PlayerDb.playerData["player"]["statusEffects"]["cripple"]["active"] == false:
			speed = 350 + (10*(pow((PlayerDb.playerData["player"]["stats"]["speed"]*ActionProcessor.STATUS_MANAGER.checkSpeedMod("Player")),0.5)))
			# the player's running speed is 350 pluswD 10 times their speed stat to the power of 0.5
			if $AnimatedSprite2D.animation in ["Walk Backwards", "Walk Forwards", "Walk Sideways"]:
				$AnimatedSprite2D.speed_scale = 1.25
		else:
			speed = 200
			if $AnimatedSprite2D.animation in ["Walk Backwards", "Walk Forwards", "Walk Sideways"]:
				$AnimatedSprite2D.speed_scale = 1

		
		


# Animations

	# Animation Handler
	if (velocity.length() != 0) && controllable:
		if (Input.is_action_pressed("Up") == true) && (Input.is_action_pressed("Down") == false) && (Input.is_action_pressed("Left") == false) && (Input.is_action_pressed("Right") == false):
			$AnimatedSprite2D.play("Walk Backwards")
		if (Input.is_action_pressed("Down") == true) && (Input.is_action_pressed("Up") == false) && (Input.is_action_pressed("Left") == false) && (Input.is_action_pressed("Right") == false) && not climbing:
			$AnimatedSprite2D.play("Walk Forwards")
		if ((Input.is_action_pressed("Left") == true) or (Input.is_action_pressed("Right") == true)) and not ((Input.is_action_pressed("Left") == true) and (Input.is_action_pressed("Right") == true)) && not climbing:
			$AnimatedSprite2D.play("Walk Sideways")
		if ((Input.is_action_pressed("Left") == true) and (Input.is_action_pressed("Right") == true) and (Input.is_action_pressed("Up") == true)):
			$AnimatedSprite2D.play("Walk Backwards")
		if ((Input.is_action_pressed("Left") == true) and (Input.is_action_pressed("Right") == true) and (Input.is_action_pressed("Down") == true)) && not climbing:
			$AnimatedSprite2D.play("Walk Forwards")
		if (Input.is_action_pressed("Left") == true) && not climbing:
			$AnimatedSprite2D.flip_h = true
		else:
			$AnimatedSprite2D.flip_h = false
	else:
		if controllable:
			if $AnimatedSprite2D.animation == "Walk Backwards":
				$AnimatedSprite2D.play("Idle Backwards")
			if $AnimatedSprite2D.animation == "Walk Forwards":
				$AnimatedSprite2D.play("Idle Forwards")
			if $AnimatedSprite2D.animation == "Walk Sideways":
				$AnimatedSprite2D.play("Idle Sideways")
			
			
			
			
			
			
			
		# Camera Fizz Effect
	if cameraFizz == true:
		cameraFizzValue = (cameraFizzValue + (1 * delta))*1.02
		# print(cameraFizzValue)
		$"Camera2D/Overworld Battle Fizz Effect/Noise".material.set_shader_parameter("intensity", cameraFizzValue)
		if cameraFizzValue < 1000:
			$"Camera2D/Overworld Battle Fizz Effect/Noise".material.set_shader_parameter("color_bleed_strength", cameraFizzValue * 0.04) 
		if cameraFizzValue > 1000:
			$"Camera2D/Overworld Battle Fizz Effect/Noise".material.set_shader_parameter("darkness", darkness)
			darkness = (darkness + (1 * delta))*1.06
			
	if transition == true and $Timer.is_stopped() == true:
		$Timer.wait_time = 2.5
		$Timer.start()

# Initiating a Battle
func playerCaught(enemy = null):
	# print(enemyType)
	Global.musicPlaying = false
	$Music.playing = false
	if caught == false:
		controllable = false
		caught = true
		get_tree().paused = true # short pause right after a battle is triggered (dramatic effect)
		$Timer.wait_time = 1
		$Timer.start()
	if enemy != null and BattleSystem.enemiesEncountered.size() < 4:
		enemyType = enemy.enemyType
		enemyID = enemy.ID
		encounterTheme = enemy.encounterTheme
		BattleSystem.enemiesEncountered.append(enemyType)
		BattleSystem.enemyIDsEncountered.append(enemyID)
		BattleSystem.encounterTheme.append(encounterTheme)
		if enemy.boss:
			BattleSystem.encounterTheme.append(encounterTheme)
			BattleSystem.encounterTheme.append(encounterTheme)
			BattleSystem.encounterTheme.append(encounterTheme)
			BattleSystem.encounterTheme.append(encounterTheme)



func _on_timer_timeout():
	
	if transition == true:
		var gameScene = get_tree().get_first_node_in_group("Game Scene")
		get_tree().get_first_node_in_group("Battle Screen Node Reference").add_child(load("res://Assets/Scenes/Battle/Battle Screen/battle_screen.tscn").instantiate())
		# pausing the overworld
		get_tree().get_first_node_in_group("World Scene Node Reference").hide()
		get_tree().get_first_node_in_group("World Camera").enabled = false
		get_tree().get_first_node_in_group("World Camera").hide()
		get_tree().get_first_node_in_group("Overworld UI").hide()
		get_tree().get_first_node_in_group("World Scene Node Reference").process_mode = Node.PROCESS_MODE_DISABLED
		
	if transition == false:
		get_tree().paused = false # BEWARE THAT OBJECTS WITH PROCESS MODE AS "ALWAYS" SUCH AS THE TIMER AND AUDIOSTREAMPLAYER2D WONT BE AFFECTED
		$Sounds.stream = load("res://Assets/Sounds/Random/guitarPickSlide.wav")
		$Sounds.play()
		emit_signal("battleInitiated")
		$"Camera2D/Overworld Battle Fizz Effect".visible = true
		cameraFizz = true
		transition = true
		




func _on_iframes_timer_timeout():
	Global.battleJustEnded = false
	Global.playerJustFled = false
	iframes = false # as soon as the player instance is created they get 1 second of iframes in case they somehow spawned on top of default enemy coordinates


func resetBattleTransition():
	caught = false
	transition = false
	cameraFizz = false
	cameraFizzValue = 0
	darkness = 0
	controllable = true
	resting = false
	$Timer.stop()
	$"Camera2D/Overworld Battle Fizz Effect".visible = false
	$"Camera2D/Overworld Battle Fizz Effect/Noise".material.set_shader_parameter("darkness", 0)

func exitBattle():
	
	caught = false
	Global.currentScreen = "world"
	iframes = true
	get_parent().get_node("iframesTimer").start(2)
	Global.musicPlaying = true
	
