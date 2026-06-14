extends TextureRect



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func shake(intensity := 30, duration := 0.5, shakes := 8):
	var origin = position
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	for i in range(shakes):
		var strength = intensity * (1.0 - float(i) / shakes)
		var offset = Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength))
		tween.tween_property(self, "position", origin + offset, duration / shakes)

	tween.tween_property(self, "position", origin, duration / shakes)

func hurtAnimation(intensity := 30, duration := 0.5, shakes := 8):
	shake(intensity, duration, shakes)
	$animationPlayer.play("Hurt")
	
func deathAnimation():
	$animationPlayer.play("Death")

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "Hurt":
		$animationPlayer.play("Idle")
	if anim_name == "Death":
		queue_free()
