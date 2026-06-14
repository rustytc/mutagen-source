extends Control

@export var ticks = 24 # changes depending on amount specified by the system
@export var currentTick = 0
@onready var knob = $Knob
@onready var texButton = $Knob/knobTexButton
@onready var timer = $Timer
var drag = false
var dragDirection = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if texButton.has_focus() and (Input.is_action_pressed("ui_right") or dragDirection > 0) and timer.is_stopped():
		timer.start()
		if currentTick < ticks:
			currentTick += 1
		else:
			currentTick = 0
		knob.rotation = (currentTick * TAU) / (ticks + 1)
		if timer.wait_time > 0.01:
			UniversalAudio.playSpecialSound("res://Assets/Sounds/UI/select.mp3")
	if texButton.has_focus() and (Input.is_action_pressed("ui_left") or dragDirection < 0) and timer.is_stopped():
		timer.start()
		if currentTick == 0:
			currentTick = ticks
		else:
			currentTick -= 1
		knob.rotation = (currentTick * TAU) / (ticks + 1)
		if timer.wait_time > 0.01: # yeah let's not jumpscare anyone
			UniversalAudio.playSpecialSound("res://Assets/Sounds/UI/select.mp3")
		
		
		
	if drag == true: # must be set this way in order for it to be constantly checking
		dragDirection = get_local_mouse_position().x - $Knob.position.x
		
		
		
		
		
	

	if (Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right") or dragDirection != 0) and $holdDownTimer.is_stopped() and timer.wait_time > 0.05:
		$holdDownTimer.start()
		
		
	if $holdDownTimer.time_left < 0.05 and $holdDownTimer.is_stopped() == false:
			if ticks < 500:
				timer.wait_time =  0.05
			else:
				timer.wait_time =  0.01
		
	if (Input.is_action_just_released("ui_left") or Input.is_action_just_released("ui_right") or (Input.is_anything_pressed() == false and dragDirection == 0)):
		$holdDownTimer.stop()
		timer.wait_time = 0.1


func _on_knob_pressed():
	texButton.grab_focus()
	



func _on_knob_tex_button_button_down():
	drag = true
func _on_knob_tex_button_button_up():
	drag = false
	dragDirection = 0
