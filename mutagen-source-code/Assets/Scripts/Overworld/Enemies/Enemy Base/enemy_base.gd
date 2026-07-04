extends CharacterBody2D

@export var boss := false

@export var ID = 0

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var player := get_parent().get_parent().get_node("Player/CharacterBody2D")
var lastAnimation := ""
## Enemy Walking Speed
@export var speed := 150
## Enemy Chase Speed
@export var chaseSpeed := 351
## Speed of the enemy running at the player when they are caught
@export var alertSpeed := 500
## Value taken away from the enemy's chase speed depending on their stamina drain
@export var speedFatigueDebuff := 100
## Default speed value when an enemy is prowling. Overrides 'speed' when the enemy's state is "prowl"
@export var prowlSpeed := 150
## State machine. Defaults to "idle," but can be adjusted to fit specific circumstances
@export var state := "idle"
@onready var canSeePlayer := false
## The enemy's name. Defaults to "blank" but must be changed to fit the specific enemy. Will break otherwise
@export var enemyType := "blank"
## The enemy's behavior. "default" is prowling, "idle" is standing still/monitoring one point
@export var enemyBehavior := "default"
## If the enemy's behavior is "path", it will go to each of these points in order
@export var orderedTargetZones: Array[int] = []
var orderedTargetIndex := 0
## If the enemy's behavior is "follow", it will create waypoints to the player's location each time it reaches an old waypoint
@export var useLastKnownPlayerPoint := false
var lastKnownPlayerPosition := Vector2.ZERO
@onready var raycast := $LineOfSight/Raycast2D
@onready var inVicinity := false
## Amount of zones to track
@export var zoneCount := 4
## Current targeted zone. On startup the enemy will walk to the original value this is set to
@export var targetZone := 0
## An array that determines the two numbers which will be used to generate a random zone the enemy will travel to each time prowl() is called. [min, max]. Do NOT put more than two values, otherwise it will break
@export var targetZoneRange := [0, 4] # 0,4 is a placeholder value. you will want to change this later on
## The angle of which an "idle" mode enemy will set it's raycast to. Usually overridden by the zone it reaches
@export var targetAngle := 0 # this tells idler enemies what angle to revert their line of sight to upon finishing a job
var newTargetZone := 0
## The distance which enemies account for by the player's velocity when choosing where to target. If you put this above 32, enemies will behave like cowards and run away from the player if they start chasing the enemy.
@export var targetDistance := 32.0
## An integer value which determines how unlikely an enemy is to stop chasing the player when they exit its line of sight. There is a 1/decisiveness chance of this happening
@export var decisiveness := 7000 # how unlikely the enemy is to disband when the player leaves their immediate LOS.
## Self explanatory. Lets the enemy randomize their targeted zone from the range provided by targetZoneRange
@export var canRandomizeZone := true
## Self explanatory. Enemy's maximum stamina when chasing the player. Set it REALLY HIGH if you want it to never run out of breath
@export var maxStamina: float = 100
## Enemy's original stamina value. Not to be confused with maxStamina
@export var stamina: float = 100
## Value by which the enemy's stamina decreases with time while in a moving state
@export var staminaDrain: float = 2
## Value by which the enemy's stamina increases with time while in an idle/resting state
@export var staminaGain: float = 20
var telegraphed := false # this exists so that the enemy alert sound effect plays once upon sight
@onready var rng := RandomNumberGenerator.new()
## Decides if the enemy should make an alert sound more than once. Should be kept on in almost all situations, but can be toggled for specific situations where you absolutely want the enemy to yam at the player
@export var oneScreamsEnough := true
var caughtThePlayer := false
@onready var insideLineOfView := false
## Self explanatory. Decides if the enemy has a chase theme or not
@export var hasChaseMusic := true
@export var alertSounds := ["res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_scream0.mp3","res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_hello.mp3", "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_sigh.mp3", "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_youcantrun.mp3", "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_whosthat.mp3"]
@export var chaseTheme := "res://Assets/Sounds/Music/Forebode B.ogg"
@export var screamSound := "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_scream0.mp3"
@export var chatterSound := "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_giggle.mp3"
@export var caughtSound := "res://Assets/Sounds/World/NPCs/Enemies/True Mutant B/TMB_laugh.mp3"
@export var encounterTheme := "res://Assets/Sounds/Music/Kepler.ogg"
var battleInitiated := false
@onready var catchSoundVolume : float = $AudioStreamPlayer2D.volume_db

var markedAsTargetter := false
signal playerCaught

# Movement

func _ready():
	
	BattleSystem.connect("transition", returnToWorldState) # when the screen transitions, dead enemies are deleted
	
	stamina = rng.randf_range(80,100) # making sure that ALL ENEMIES dont freeze at the same time (that would be pretty weird!)
	
	for enemy in get_tree().get_nodes_in_group("Overworld Enemy"):
		if enemy != self and enemy is CharacterBody2D:
			add_collision_exception_with(enemy)
			enemy.add_collision_exception_with(self)
	for enemy in get_tree().get_nodes_in_group("Overworld Non-Player Character"):
		if enemy != self and enemy is CharacterBody2D:
			add_collision_exception_with(enemy)
			enemy.add_collision_exception_with(self)

	raycast.enabled = true
	raycast.add_exception(self)
	rng.randomize()
	lastKnownPlayerPosition = global_position
	# setting the initial navigationagent target to be a random point on the map (if that's what it's behavior calls for)
	if zoneCount > 0 && state != "idle" and not battleInitiated:
		prowl()
		
	$NavigationAgent2D.radius = 96 # setting the radius of the navagent2d to avoid walking into a wall
	$NavigationAgent2D.path_max_distance = 100
	
	if enemyBehavior == "idle": # corrects the position of the raycast so that the enemy is looking in the correct direction when theyre idle
		targetAngle = get_parent().get_parent().get_node("PathfindingZone" + str(targetZone)).enemyAngle
		$LineOfSight.rotation = deg_to_rad(360 - targetAngle) # godot uses radians for rotation math, so we have to turn degrees into radians each time. also, the y axis is negative, so we subtract the intended degrees from 360 to flip it

func _physics_process(delta):
	var direction = Vector2()
	
		
	if (((state == "prowl" or state == "chase") or (enemyBehavior == "idle" and stamina > 5)) and not caughtThePlayer) and not state == "wait":
		# originally this checked if the state was "idle" and stamina > 5 as an or statement but I think that was left over
		# from before enemyBehavior was a proper variable
		
		if canSeePlayer == true and not battleInitiated and BattleSystem.playerAlive:
			
			chase()
		
		direction = (agent.get_next_path_position() - global_position).normalized()
	
		velocity = direction * speed
	
		move_and_slide()
	
		if stamina > 0:
			stamina = stamina - (staminaDrain * delta)
			stamina = clamp(stamina, 0, maxStamina)
		else:
			idle()
			
	if state == "idle":
		velocity = Vector2.ZERO
		if stamina < maxStamina:
			stamina = stamina + (staminaGain * delta)
			stamina = clamp(stamina, 0, maxStamina)
		if stamina >= maxStamina and not battleInitiated and not state == "wait": # added this in as of 11/23/2025 to fix idler behavior not moving after stamina is depleted and then repleted
			match enemyBehavior:
				"default":
					prowl()
				"idle":
					if not reachedTarget():
						prowl()
					else:
						idle()
			
		
	
	# Moving line of sight to match enemy movement when the player isn't in view
	if velocity.normalized().length() > 0.1: # && canSeePlayer == false: fuggetaboutit
		$LineOfSight.rotation = velocity.normalized().angle()
	
	
	# Checking if the enemy can see the player
	raycast.target_position = raycast.to_local(player.global_position) # raycasts should target the player (local so that it doesnt bend if the sprite is mirrored)

	if raycast.is_colliding() and not battleInitiated: # and not battleInitiated was added in retroactively so that the enemies dont stop chasing you if you alerted them all
		if raycast.get_collider() == player and insideLineOfView:
			canSeePlayer = true
			lastKnownPlayerPosition = NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, player.global_position)
			if not telegraphed:
				callout()
				telegraphed = true
		elif inVicinity:
			canSeePlayer = true
			lastKnownPlayerPosition = NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, player.global_position)
		else:
			canSeePlayer = false
				
				
			
	
	# Abandoning Flynn if he's out of sight, targetting a zone instead
	if not canSeePlayer and state == "chase" and not battleInitiated and not state == "wait":
		letsDecideIfIStillWantToKillYou()
		
	
		
	if state == "prowl" and reachedTarget() and not battleInitiated: # checks if the enemy is inside of a patrol zone and changes their target by calling prowl()
		if enemyBehavior == "idle":
			idle()
		elif canRandomizeZone:
			prowl()
		else:
			idle()
	
# Animation Handler

	
func _process(delta):
	
	if canSeePlayer and not markedAsTargetter:
		markedAsTargetter = true
		ActorHelper.targetters += 1
	if not canSeePlayer and markedAsTargetter:
		markedAsTargetter = false
		ActorHelper.targetters -= 1
	
	if state != "idle":
		if velocity.length() == 0:
			if $AnimatedSprite2D.is_playing():
				$AnimatedSprite2D.stop()
			lastAnimation = ""
			return

		var x = int(round(velocity.normalized().x))
		var y = int(round(velocity.normalized().y))

		var newAnimation = ""

		# prioritize vertical movement if it's stronger
		if abs(y) > abs(x):
			newAnimation = "Walk Forwards" if y > 0 else "Walk Backwards"
		else:
			newAnimation = "Walk Sideways"

		# Flip for left movement
		$AnimatedSprite2D.flip_h = x < 0

		# Only change animation if it's different
		if newAnimation != lastAnimation:
			$AnimatedSprite2D.play(newAnimation)
			lastAnimation = newAnimation
		
		
		# randomly deciding when to play the chatter sound
		if rng.randf() < (1.0 / 180.0) * delta:
			chatter()
		
		
	
	if battleInitiated:
		$AudioStreamPlayer2D.volume_db = $AudioStreamPlayer2D.volume_db - (20 * delta) # fading out enemy sounds so there isn't a harsh cut when the battle screen opens up



		
# Line of Sight

func _on_line_of_sight_body_entered(body):
	if body == player:
		insideLineOfView = true


func _on_vicinity_body_entered(body):
	if body == player:
		canSeePlayer = true
		inVicinity = true
		

func _on_line_of_sight_body_exited(body):
	if body == player:
		insideLineOfView = false
		if not oneScreamsEnough:
			telegraphed = false


func _on_vicinity_body_exited(body):
	if body == player:
		inVicinity = false


func _on_collision_body_entered(body): # when another entity collides with this thing
	if body == player and caughtThePlayer == false and body.iframes == false: #checking if frames == false is a preventative in case the player somehow by chance spawns on top of an enemy
		caughtThePlayer = true
		pauseChaseTheme()
		$AnimatedSprite2D.play("Attack")
		catchSound()
		emit_signal("playerCaught")


func prowl():
	if state == "chase":
		pauseChaseTheme()
	
	
	if enemyBehavior == "path":
		prowlOrderedPath()
		return
	if enemyBehavior == "follow":
		prowlLastKnownPlayerPoint()
		return

	if enemyBehavior == "idle" or not canRandomizeZone:
		agent.target_position = get_parent().get_parent().get_node("PathfindingZone" + str(targetZone)).global_position # the Idler must return to its Zone...
		targetAngle = get_parent().get_parent().get_node("PathfindingZone" + str(targetZone)).enemyAngle
		speed = prowlSpeed
		state = "prowl"
		return
		
	
	newTargetZone = rng.randi_range(targetZoneRange[0], targetZoneRange[1])
	while newTargetZone == targetZone and zoneCount > 1 and canRandomizeZone == true:
		newTargetZone = rng.randi_range(targetZoneRange[0], targetZoneRange[1])
	if newTargetZone != targetZone and zoneCount > 1 and canRandomizeZone == true:
		targetZone = newTargetZone
	if canRandomizeZone:
		agent.target_position = get_parent().get_parent().get_node("PathfindingZone" + str(targetZone)).global_position
		speed = prowlSpeed
		state = "prowl"
	else: 
		agent.target_position = get_parent().get_parent().get_node("PathfindingZone" + str(targetZone)).global_position
		
func reachedTarget(): # godots navagent "reached target position" function checks the literal decimal so I just use this instead
	return round(global_position.distance_to(agent.target_position)) <= round(agent.target_desired_distance)

func prowlOrderedPath():
	if orderedTargetZones.is_empty():
		idle()
		return
	orderedTargetIndex = wrapi(orderedTargetIndex, 0, orderedTargetZones.size())
	targetZone = orderedTargetZones[orderedTargetIndex]
	orderedTargetIndex += 1
	orderedTargetIndex = wrapi(orderedTargetIndex, 0, orderedTargetZones.size())
	agent.target_position = get_parent().get_parent().get_node("PathfindingZone" + str(targetZone)).global_position
	targetAngle = get_parent().get_parent().get_node("PathfindingZone" + str(targetZone)).enemyAngle
	speed = prowlSpeed
	state = "prowl"

func prowlLastKnownPlayerPoint():
	if useLastKnownPlayerPoint:
		agent.target_position = lastKnownPlayerPosition
	else:
		agent.target_position = player.global_position + player.velocity.normalized() * targetDistance
	speed = prowlSpeed
	state = "prowl"

	
	
func chase():
	if $pathfindingTimer.time_left == 0: # this prevents a lag spike especially when navigating corners. also fixes animation flickering. but be aware. the wait time will probably need to be adjusted for really fast enemies. #TODO: adjust the wait time for really fast enemies
		agent.target_position = NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, player.global_position + player.velocity.normalized() * targetDistance)
		$pathfindingTimer.start()
		
	state = "chase"
	playChaseTheme()
	if stamina > (maxStamina/4):
		speed = chaseSpeed
	else:
		speed = chaseSpeed - speedFatigueDebuff

func idle(): 
	pauseChaseTheme()
	if state != "idle":
		state = "idle"
	velocity = Vector2.ZERO
	move_and_slide()
	
	if enemyBehavior == "idle":
		$LineOfSight.rotation = deg_to_rad(360 - targetAngle) # godot uses radians for rotation math, so you have to turn degrees into radians each time. also, the y axis is negative, so you subtract the intended degrees from 360 to flip it
	
	
	if $AnimatedSprite2D.animation != "Idle":
		$AnimatedSprite2D.play("Idle")
		lastAnimation = "Idle"

func scream():
	if $AudioStreamPlayer2D.playing:
		return
	$AudioStreamPlayer2D.stream = load(screamSound)
	$AudioStreamPlayer2D.pitch_scale = rng.randf_range(0.9, 1.4)
	$AudioStreamPlayer2D.play()

	
func chatter():
	if $AudioStreamPlayer2D.playing:
		return
	$AudioStreamPlayer2D.stream = load(chatterSound)
	$AudioStreamPlayer2D.pitch_scale = rng.randf_range(0.9, 1.4)
	$AudioStreamPlayer2D.play()
	
func callout():
	if $AudioStreamPlayer2D.playing:
		return
	$AudioStreamPlayer2D.stream = load(alertSounds.pick_random())
	$AudioStreamPlayer2D.pitch_scale = rng.randf_range(0.8, 1.1)
	$AudioStreamPlayer2D.play()
	
func catchSound():
	$AudioStreamPlayer2D.pitch_scale = 1
	$AudioStreamPlayer2D.stream = load(caughtSound)
	$AudioStreamPlayer2D.play()

func playChaseTheme():
	if state == "chase" and not $chaseMusic.playing and hasChaseMusic == true and not $chaseMusic.process_mode == $chaseMusic.PROCESS_MODE_DISABLED:
		$chaseMusic.stream = load(chaseTheme)
		$chaseMusic.play()
	if $chaseMusic.process_mode == $chaseMusic.PROCESS_MODE_DISABLED:
		$chaseMusic.process_mode = $chaseMusic.PROCESS_MODE_INHERIT
		
		

	
func pauseChaseTheme():
	if hasChaseMusic:
		$chaseMusic.process_mode = $chaseMusic.PROCESS_MODE_DISABLED # NOTE: USING AUDIOSTREAM'S .PAUSE() FUNCTION WILL AUTOMATICALLY UNPAUSE IT ANY TIME THE TREE GETS UNPAUSED, MEANING YOU MUST MANUALLY DISABLE PROCESSING ON EACH AUDIOSTREAM YOURSELF UNLESS YOU WANT IT TO START PLAYING WHEN THE TREE IS UNPAUSED
		
# decision maker to decide if the enemy should still be chasing the player. exists to make the player's life harder
var randomNum = 0
func letsDecideIfIStillWantToKillYou():
	if randomNum != decisiveness and state == "chase" and not battleInitiated:
		randomNum = rng.randi_range(0,decisiveness)  # this has to stay inside of the if statement or else it will literally run every single tick and randomNum will be both the right and wrong number at the same time
		canSeePlayer = true
	if randomNum == decisiveness and state == "chase" and not battleInitiated:
		canSeePlayer = false # this is really important otherwise Nothing Happens
		prowl()
		randomNum = 0
		

		
func onBattleInitiated():
	$chaseMusic.stop()
	battleInitiated = true
	iHearYou()

	
func iHearYou():
	if not caughtThePlayer and battleInitiated and state != "chase" and state != "wait": # hunting down the player when a battle is about to begin
		if not canSeePlayer:
			state = "chase"
			canSeePlayer = true
		agent.target_position = player.global_position
		speed = alertSpeed

func returnToWorldState():
	for i in BattleSystem.enemyIDsKilled:
		if ID == i:
			ActorHelper.targetters -= 1
			queue_free()
			return
	if canSeePlayer:
		state = "wait"
		$AnimatedSprite2D.play("Alert")
		await get_tree().create_timer(4, false, true, false).timeout
		prowl()
	canSeePlayer = false
	battleInitiated = false
	caughtThePlayer = false
	$AudioStreamPlayer2D.volume_db = catchSoundVolume
