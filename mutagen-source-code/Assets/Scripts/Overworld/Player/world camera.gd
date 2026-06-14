extends Camera2D


var zoomMax : float = 3
var zoomMin : float = 1
@export var zoomValue := 1.0

func _ready():
	pass

func _process(delta):
	#zoom = zoom.lerp(Vector2(zoomValue, zoomValue), 10 * delta) originally there was a smooth zoom, but it causes artifacting errors
	zoom = Vector2(zoomValue, zoomValue)
	
	if Input.is_action_just_pressed("Scroll Up") and get_parent().can_process():
		zoomValue = (clamp(zoomValue + 1, zoomMin, zoomMax))

	if Input.is_action_just_pressed("Scroll Down") and get_parent().can_process():
		zoomValue = (clamp(zoomValue - 1, zoomMin, zoomMax))
	
