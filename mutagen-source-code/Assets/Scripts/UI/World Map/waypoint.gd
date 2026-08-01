extends Sprite2D
@export var areaID := "null"
@export var roomID := "null"
@export var areaName := "null"
@export var keyItem := "null"

func _on_area_2d_body_entered(body):
	if body.is_in_group("Map Cursor"):
		get_parent().hoveredSpotID = areaID
		get_parent().hoveredSpotRoomID = roomID
		get_parent().hoveredSpotName = areaName
		get_parent().hoveredSpotKey = keyItem
		print(areaID)
		print(roomID)
		print(areaName)
		print(keyItem)

func _on_area_2d_body_exited(body):
	if body.is_in_group("Map Cursor"):
		get_parent().hoveredSpotID = ""
		get_parent().hoveredSpotRoomID = ""
		get_parent().hoveredSpotName = ""
		get_parent().hoveredSpotKey = ""
