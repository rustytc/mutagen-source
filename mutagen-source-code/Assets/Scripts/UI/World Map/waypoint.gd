extends Sprite2D
@export var areaID := "null"
@export var roomID := "null"
@export var areaName := "null"
@export var keyItem := "null"
@export var spawnpoint := Vector2i(0,0)
func _on_area_2d_body_entered(body):
	if body.is_in_group("Map Cursor"):
		get_parent().hoveredSpotID = areaID
		get_parent().hoveredSpotRoomID = roomID
		get_parent().hoveredSpotName = areaName
		get_parent().hoveredSpotKey = keyItem
		get_parent().hoveredSpotSpawnpoint = spawnpoint

func _on_area_2d_body_exited(body):
	if body.is_in_group("Map Cursor"):
		get_parent().hoveredSpotID = ""
		get_parent().hoveredSpotRoomID = ""
		get_parent().hoveredSpotName = ""
		get_parent().hoveredSpotKey = ""
		get_parent().hoveredSpotSpawnpoint = Vector2i(0,0)
