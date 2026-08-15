extends Node2D
@export var area = "area" ## Area it takes you to
@export var room = "room" ## Room it takes you to
@export var pos = Vector2i(0,0) ## Position it takes you to
@export var openSoundEffect = ""
func _on_area_2d_body_entered(body):
	if body.is_in_group("playerBody"):
		Global.spawnpoint = pos
		Global.goToArea(area, room)
