extends Node

static func checkPlayerStatusEffects():
	print('player check ran')
	var data : Dictionary = PlayerDb.playerData["player"]["statusEffects"]
	var result := []
	for effect in data:
		if data[effect]["points"] > 0 or data[effect]["active"] == true:
			result.append(effect)
	return result
	
static func checkEnemyStatusEffects():
	print('enemy check ran')
	var enemyDb : Dictionary = BattleSystem.enemyDict
	var result := []
	if enemyDb == {}:
		return null
	for enemy in enemyDb:
		for effect in enemyDb[enemy]["statusEffects"]:
			if enemyDb[enemy]["statusEffects"][effect]["points"] > 0 or enemyDb[enemy]["statusEffects"][effect]["active"] == true:
				result.append([effect, enemy])
	return result



static func applyEffect(effect, target):
	print('apply function ran')
	var action = ActionProcessor.actionTemplate.duplicate(true)
	var data = null
	var chance = Global.rng.randi_range(1,100)
	if target == "Player":
		data = PlayerDb.playerData["player"]["statusEffects"][effect]
		action["general"]["target"] = ["Player"]
	else:
		data = BattleSystem.enemyDict[target]["statusEffects"][effect]
		action["general"]["target"] = [target]
	if chance > data["effectChance"] and data["points"] > 0:
		return
			
	# inflict
	if data["points"] > 0:
		if data["active"] == true: # this is put specifically here so that it doesnt subtract on the first round when nothing gets applied
			data["points"] -= 1
		if data["active"] == false:
			if data.has("announcementInflict"):
				action["general"]["announcement"] = data["announcementInflict"]
			action["general"]["type"] = "statusEffectInflict"
			action["general"]["user"] = target
			ActionProcessor.queueSpecificAction(action)
			data["active"] = true
			print('inflicted')
		else:
			if data.has("announcementHarm"):
				action["general"]["announcement"] = data["announcementHarm"].pick_random()
			if data.has("resultHarm"):
				action["general"]["result"] = data["resultHarm"]
			action["general"]["type"] = "statusEffectHarm"
			action["general"]["user"] = target
			if data["harming"] == true:
				action["combatData"]["damage"] = calcDamage(effect, target)
			if data.has("appliedAtk"):
				action["combatData"]["damage"] = calcAttack(effect, target)
			if data["turnSkip"] == true:
				applySpecialEffects(effect, target)
			if data.has("announcementHarm") or data.has("resultHarm"): # this has to be here to prevent a blank action from queueing if an effect doesnt print anything
				ActionProcessor.queueSpecificAction(action)
		return
		
	# cure
	if data["points"] == 0:
		data["active"] = false
		if data.has("announcementCure"):
			action["general"]["announcement"] = data["announcementCure"] # no need to replace '[NAME]' as the action processor script does this for us
		if data.has("resultCure"):
			action["general"]["result"] = data["resultCure"]
		action["general"]["type"] = "statusEffectClear"
		action["combatData"]["statusEffects"]["cure"][effect] = true
		action["general"]["user"] = target
		ActionProcessor.queueSpecificAction(action)
		return
	
	
static func statusEffectPerRound():
	var playerFX = ActionProcessor.STATUS_MANAGER.checkPlayerStatusEffects()
	var enemyFX = ActionProcessor.STATUS_MANAGER.checkEnemyStatusEffects()
	if playerFX != null:
		for effect in playerFX:
			ActionProcessor.STATUS_MANAGER.applyEffect(effect, "Player")
	if enemyFX != null:
		for i in enemyFX:
			ActionProcessor.STATUS_MANAGER.applyEffect(i[0], i[1])

static func showEffectInitiation(effect, target):
	var action = ActionProcessor.actionTemplate.duplicate(true)
	var data = null
	if target.size() == 1:
		target = str(target[0])
	if target == "Player":
		data = PlayerDb.playerData["player"]["statusEffects"][effect]
		action["general"]["target"] = ["Player"]
	else:
		data = BattleSystem.enemyDict[target]["statusEffects"][effect]
		action["general"]["target"] = [target]
	# inflict
	if data["active"] == false:
		if data.has("announcementInflict"):
			action["general"]["announcement"] = data["announcementInflict"]
		action["general"]["type"] = "statusEffectInflict"
		action["general"]["user"] = target
		ActionProcessor.queueSpecificAction(action)
		data["active"] = true
		print('inflicted')
		
static func calcDamage(effect, target):
	var data = null
	var effects = fetchData(target)
	data = effects[effect]
	match effect:
		"bleeding" :
			data["appliedDmg"] = data["baseDmg"] + data["appliedDmg"]
			return(data["appliedDmg"])
		"illness": # illness is mostly a turn skip punishment and the damage effect is secondary
			data["appliedDmg"] = data["baseDmg"] - Global.rng.randi_range(0, data["baseDmg"] - (data["baseDmg"] - 1))
			return(data["appliedDmg"])
			
static func calcAttack(effect, target):
	var data = null
	var effects = fetchData(target)
	data = effects[effect]
	match effect:
		"berserk" :
			data["appliedAtk"] = data["appliedAtk"] * 1.5
			return(data["appliedAtk"])
			
static func applySpecialEffects(effect, target):
	var data = null
	var effects = fetchData(target)
	data = effects[effect]
	if data["turnSkip"] == true:
		ActionProcessor.PROCEDURES.turnSkip(target)
		print('skipped ' + target)

static func checkSpeedMod(target):
	var data = null
	var result = 1
	data = fetchData(target)
	for effect in data:
		if data[effect].has("speedMod") and data[effect]["active"] == true:
			result = result * data[effect]["speedMod"]
	return result

static func checkDefenseMod(target):
	var data = null
	var result : float = 1.0
	var enemy := false
	data = fetchData(target)
	enemy = isEnemy(target)
	for effect in data:
		if data[effect].has("defenseMod") and data[effect]["active"] == true:
			result = result * data[effect]["defenseMod"]
	if enemy and result < 1:
		result = 1/result
	return result

static func applyBerserk(target):
	var data = null
	var enemy := false
	data = fetchData(target)
	enemy = isEnemy(target)
	if enemy:
		BattleSystem.ENEMY_MOVES.berserk(target, data)
	else:
		BattleSystem.PLAYER_MOVES.berserk(target, data)
		
static func isEnemy(target): # KISS
	if target == "Player":
		return false
	else:
		return true
		
static func fetchData(target): # KISS
	if target == "Player":
		return(PlayerDb.playerData["player"]["statusEffects"])
	else:
		return(BattleSystem.enemyDict[target]["statusEffects"])
		
