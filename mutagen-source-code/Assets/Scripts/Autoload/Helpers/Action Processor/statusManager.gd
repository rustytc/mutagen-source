extends Node


func checkStatusEffects():
	var data : Dictionary = PlayerDb.playerData["player"]["statusEffects"]
	var result := []
	for effect in data:
		if data[effect]["points"] > 0:
			result.append(effect)
	return result
	
func applyEffect(effect, target):
	var action = ActionProcessor.actionTemplate.duplicate(true)
	var data = null
	if target == "Player":
		data = PlayerDb.playerData["player"]["statusEffects"][effect]
		data["general"]["target"] = ["Player"]
		data["points"] -= 1
		
	# cure
	if data["points"] == 0:
		data["active"] = false
		action["announcement"] = data["announcementCure"] # no need to replace '[NAME]' as the action processor script does this for us
		action["result"] = data["resultCure"]
		action["type"] = "statusEffectClear"
		action["combatData"]["statusEffects"]["cure"][effect] = true
		return
			
	# inflict
	if data["points"] > 0:
		data["active"] = true
		action["announcement"] = data["announcementInflict"]
		action["announcement"] = data["resultInflict"]
		action["type"] = "statusEffectInflict"
	ActionProcessor.queueSpecificAction(action)
