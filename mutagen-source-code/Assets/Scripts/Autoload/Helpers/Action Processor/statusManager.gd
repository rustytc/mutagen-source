extends Node


static func checkPlayerStatusEffects():
	var data : Dictionary = PlayerDb.playerData["player"]["statusEffects"]
	var result := []
	for effect in data:
		if data[effect]["points"] > 0:
			result.append(effect)
	return result
	
static func checkEnemyStatusEffects():
	var enemyDb : Dictionary = BattleSystem.enemyDict
	var result := []
	if enemyDb == {}:
		return null
	for enemy in enemyDb:
		for effect in enemyDb[enemy]["statusEffects"]:
			if enemyDb[enemy]["statusEffects"][effect]["points"] > 0:
				result.append([effect, enemy])
	return result
	
static func applyEffect(effect, target):
	var action = ActionProcessor.actionTemplate.duplicate(true)
	var data = null
	if target == "Player":
		data = PlayerDb.playerData["player"]["statusEffects"][effect]
		action["general"]["target"] = ["Player"]
	else:
		data = BattleSystem.enemyDict[target]["statusEffects"][effect]
		action["general"]["target"] = [target]
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
		action["result"] = data["resultInflict"]
		action["type"] = "statusEffectInflict"
	ActionProcessor.queueSpecificAction(action)
