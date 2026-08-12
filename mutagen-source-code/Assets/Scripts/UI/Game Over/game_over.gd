extends Node2D
var fadeIn := false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if fadeIn == true:
		await get_tree().create_timer(0.1).timeout
		$gameOver.modulate.a += 0.01 * delta * 240


func _on_visible_on_screen_notifier_2d_visibility_changed():
	if self.visible == true:
		fadeItIn()
		
		
func fadeItIn():
	await get_tree().create_timer(2).timeout
	fadeIn = true
	await get_tree().create_timer(2).timeout
	$Music.play()
	var tween = create_tween()
	tween.tween_property($Music, "volume_db", 5, 4.0)
