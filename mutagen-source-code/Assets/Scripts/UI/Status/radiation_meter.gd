extends Control
var playerCaughtFlag := 0
# Called when the node enters the scene tree for the first time.
func _ready():
	BattleSystem.connect("transition", unhide)

func unhide():
	playerCaughtFlag = 0
	modulate.a = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var radiation = PlayerDb.playerData["player"]["stats"]["radiation"]
	$Geiger.value = radiation
	$Geiger/Percentage.text = "[center]" + str(radiation) + "%"
	
	# Radiation blinker animation will play faster depending on how much radiation you've accumulated
	$AnimationPlayer.speed_scale = (radiation)/25

	if Global.player != null and Global.currentScreen == "world":
		if Global.playerCharBody2D.caught:
			$AnimationPlayer.play("Idle")
			var tween = get_tree().create_tween()
			tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 1)


	if radiation == 0:
		self.hide()
	else:
		self.show()
		if $AnimationPlayer.current_animation != "Blink":
			$AnimationPlayer.play("Blink")
		$AnimationPlayer.speed_scale = max(0.5, float(radiation) / 25.0)
			
