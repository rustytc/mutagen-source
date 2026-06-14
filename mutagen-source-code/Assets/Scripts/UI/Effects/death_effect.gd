extends Node2D
var rate := 0.002
var power := 0.0003
var screenSwap := false
var battleScreen = null
@export var triggered := false
@export var start := false
# Called when the node enters the scene tree for the first time.
func _ready():
	battleScreen = get_tree().get_first_node_in_group("Battle Screen Node Reference")
	BattleSystem.endBattleLose.connect(trigger)

func trigger():
	start = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if start == true:
		if self.visible == false:
			
			UniversalAudio.playSpecialSound("res://Assets/Sounds/UI/church_bells.mp3")
			self.visible = true
		else:
			await get_tree().create_timer(0.2).timeout
			rate += 0.01 * delta * 240 # framerate independence
			if power < 0.1:
				power += 0.0001 * delta * 240
			else:
				power += 0.001 * delta * 240
			self.get_node("glitch").material.set_shader_parameter("shake_rate", rate)
			self.get_node("glitch").material.set_shader_parameter("shake_power", power)
	if power > 1 and triggered == false:
		screenSwap = true
	if screenSwap == true:
		$"/root/Game/gameOver".show()
		get_tree().get_first_node_in_group("World Scene Node Reference").hide()
		get_tree().get_first_node_in_group("World Camera").enabled = false
		get_tree().get_first_node_in_group("World Camera").hide()
		get_tree().get_first_node_in_group("Overworld UI").hide()
		get_tree().get_first_node_in_group("World Scene Node Reference").process_mode = Node.PROCESS_MODE_DISABLED
		if is_instance_valid(battleScreen):
			battleScreen.queue_free()
