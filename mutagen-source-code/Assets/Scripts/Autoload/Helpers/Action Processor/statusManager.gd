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
		
	# cure
	if data["points"] == 0:
		data["active"] = false
		if data["announcementCure"].exists():
			action["general"]["announcement"] = data["announcementCure"] # no need to replace '[NAME]' as the action processor script does this for us
		if data["resultCure"].exists():
			action["general"]["result"] = data["resultCure"]
		action["general"]["type"] = "statusEffectClear"
		action["combatData"]["statusEffects"]["cure"][effect] = true
		ActionProcessor.queueSpecificAction(action)
		return
			
	# inflict
	if data["points"] > 0:
		if data["active"] == false:
			if data["announcementInflict"].exists():
				action["general"]["announcement"] = data["announcementInflict"]
			action["general"]["type"] = "statusEffectInflict"
			ActionProcessor.queueSpecificAction(action)
			data["active"] = true
		else:
			if data["announcementHarm"].exists():
				action["general"]["announcement"] = data["announcementHarm"].pick_random()
			if data["resultHarm"].exists():
				action["general"]["result"] = data["resultHarm"]
			action["general"]["type"] = "statusEffectHarm"
			ActionProcessor.queueSpecificAction(action)
	data["points"] -= 1

static func statusEffectPerRound():
	var playerFX = ActionProcessor.STATUS_MANAGER.checkPlayerStatusEffects()
	var enemyFX = ActionProcessor.STATUS_MANAGER.checkEnemyStatusEffects()
	if playerFX != null:
		for effect in playerFX:
			ActionProcessor.STATUS_MANAGER.applyEffect(effect, "Player")
	if enemyFX != null:
		for i in enemyFX:
			ActionProcessor.STATUS_MANAGER.applyEffect(i[0], i[1])
