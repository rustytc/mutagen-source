extends Sprite2D
@export var areaID := "null"
@export var areaName := "null"


func _on_area_2d_body_entered(body):
	if body.is_in_group("Map Cursor"):
		get_parent().hoveredSpotID = areaID
		get_parent().hoveredSpotName = areaName


func _on_area_2d_body_exited(body):
	if body.is_in_group("Map Cursor"):
		get_parent().hoveredSpotID = ""
		get_parent().hoveredSpotName = ""
