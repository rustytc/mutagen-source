extends Node


func checkStatusEffects():
	var data : Dictionary = PlayerDb.playerData["player"]["statusEffects"]
	var result := []
	for effect in data:
		if data[effect]["points"] > 0:
			result.append(effect)
