extends Area2D


func _on_body_entered(body):
	if body.is_in_group("playerBody"):
		var camera = body.get_node("Camera2D")
		var collisionShape = $collisionShape2d
		var size = collisionShape.shape.extents*2
		var viewportSize = get_viewport_rect().size
		camera.limit_top = collisionShape.global_position.y - size.y/2
		camera.limit_left = collisionShape.global_position.x - size.x/2
		camera.limit_bottom = camera.limit_top + size.y
		camera.limit_right = camera.limit_left + size.x
		camera.reset_smoothing()
		camera.force_update_scroll()

func _on_body_exited(body):
	if body.is_in_group("playerBody") and Global.currentScreen == "world" and body.controllable:
		Global.goToMap()
