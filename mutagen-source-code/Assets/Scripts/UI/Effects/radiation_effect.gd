extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var ratio : float = float(PlayerDb.playerData["player"]["stats"]["radiation"]) / float(PlayerDb.playerData["player"]["stats"]["maxRadiation"])
	$static.material.set_shader_parameter("strength", ratio)
