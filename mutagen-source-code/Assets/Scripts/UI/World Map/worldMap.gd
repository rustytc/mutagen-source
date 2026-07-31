extends Node2D
var hoveredSpotID := ""
var hoveredSpotName := ""
# Called when the node enters the scene tree for the first time.
func _ready():
	Global.currentScreen = "world"
	Global.musicCanPlay = false
	Global.musicPlaying = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$canvasLayer/areaName.text = "[center][color=green]" + hoveredSpotName
	
	var minX = $mapCursor/camera2d.limit_left
	var minY = $mapCursor/camera2d.limit_top
	var maxX = $mapCursor/camera2d.limit_right
	var maxY = $mapCursor/camera2d.limit_bottom
	$mapCursor.velocity = Vector2.ZERO
	if Input.is_action_pressed("Up"):
		$mapCursor.velocity.y -= 1
	if Input.is_action_pressed("Down"):
		$mapCursor.velocity.y += 1
	if Input.is_action_pressed("Left"):
		$mapCursor.velocity.x -= 1
	if Input.is_action_pressed("Right"):
		$mapCursor.velocity.x += 1
	$mapCursor.velocity = $mapCursor.velocity.normalized() * 100
	$mapCursor.move_and_slide()
	$mapCursor.global_position.x = clamp($mapCursor.global_position.x, minX, maxX)
	$mapCursor.global_position.y = clamp($mapCursor.global_position.y, minY, maxY)
	if ($mapCursor.velocity.length() != 0):
		if (Input.is_action_pressed("Up") == true) && (Input.is_action_pressed("Down") == false) && (Input.is_action_pressed("Left") == false) && (Input.is_action_pressed("Right") == false):
			$mapCursor/animatedSprite2d.play("Walk Backwards")
		if (Input.is_action_pressed("Down") == true) && (Input.is_action_pressed("Up") == false) && (Input.is_action_pressed("Left") == false) && (Input.is_action_pressed("Right") == false):
			$mapCursor/animatedSprite2d.play("Walk Forwards")
		if ((Input.is_action_pressed("Left") == true) or (Input.is_action_pressed("Right") == true)) and not ((Input.is_action_pressed("Left") == true) and (Input.is_action_pressed("Right") == true)):
			$mapCursor/animatedSprite2d.play("Walk Sideways")
		if ((Input.is_action_pressed("Left") == true) and (Input.is_action_pressed("Right") == true) and (Input.is_action_pressed("Up") == true)):
			$mapCursor/animatedSprite2d.play("Walk Backwards")
		if ((Input.is_action_pressed("Left") == true) and (Input.is_action_pressed("Right") == true) and (Input.is_action_pressed("Down") == true)):
			$mapCursor/animatedSprite2d.play("Walk Forwards")
		if (Input.is_action_pressed("Left") == true):
			$mapCursor/animatedSprite2d.flip_h = true
		else:
			$mapCursor/animatedSprite2d.flip_h = false
	else:
		if $mapCursor/animatedSprite2d.animation == "Walk Backwards":
			$mapCursor/animatedSprite2d.play("Idle Backwards")
		if $mapCursor/animatedSprite2d.animation == "Walk Forwards":
			$mapCursor/animatedSprite2d.play("Idle Forwards")
		if $mapCursor/animatedSprite2d.animation == "Walk Sideways":
			$mapCursor/animatedSprite2d.play("Idle Sideways")
