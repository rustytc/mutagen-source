extends Node


static func surge(user):
	var action = ActionProcessor.actionTemplate.duplicate(true)
	var userNoID = BattleSystem.removeIdentifier(user) # for enemyDb calls
	action["general"]["type"] = "surge"
	action["enemyStatus"]["staminaRegen"] = BattleSystem.enemyDict[user]["stats"]["maxStamina"] - BattleSystem.enemyDict[user]["stats"]["stamina"]
	action["general"]["user"] = user
	action["general"]["userName"] = userNoID
	var announcement = BattleSystem.enemyDict[user]["surgeWarning"].pick_random()
	action["general"]["announcement"] = announcement["text"]
	action["general"]["announcementSFX"] = announcement["sound"]
	action["general"]["announcementPause"] = 2
	ActionProcessor.queueSpecificAction(action)

static func changePhase(user, phaseName, trigger):
	var action = ActionProcessor.actionTemplate.duplicate(true)
	var userNoID = BattleSystem.removeIdentifier(user)
	var phase = BattleSystem.enemyDict[user]["phase"]
	action["general"]["type"] = "phaseChange"
	action["general"]["user"] = user
	action["general"]["userName"] = userNoID
	action["enemyStatus"]["phaseChange"] = phaseName
	var announcement = BattleSystem.enemyDict[user]["logic"][phase]["phaseChanges"][trigger]["announcements"].pick_random()
	action["general"]["announcement"] = announcement["text"]
	action["general"]["announcementSFX"] = announcement["sound"]
	action["general"]["announcementPause"] = 2
	action["general"]["priority"] = 4
	ActionProcessor.queueSpecificAction(action)
	
static func rest(user):
	var action = ActionProcessor.actionTemplate.duplicate(true)
	var userNoID = BattleSystem.removeIdentifier(user)
	action["general"]["type"] = "rest"
	action["enemyStatus"]["staminaRegen"] = BattleSystem.enemyDict[user]["stats"]["maxStamina"]/4
	action["general"]["user"] = user
	action["general"]["userName"] = userNoID
	var announcement = EnemyDb["restWarning"].pick_random()
	action["general"]["announcement"] = announcement["text"]
	action["general"]["announcementSFX"] = announcement["sound"]
	action["general"]["announcementPause"] = 2
	ActionProcessor.queueSpecificAction(action)

static func attack(user, attack, priority = 1):
	var action : Dictionary = ActionProcessor.actionTemplate.duplicate(true)
	var userNoID : String = BattleSystem.removeIdentifier(user)
	var baseDmg := Global.rng.randi_range(int(attack["minDamage"]), int(attack["maxDamage"]))
	var radDmg := Global.rng.randi_range(int(attack["minRadDamage"]), int(attack["maxRadDamage"]))
	var compoundDmg : int = baseDmg * int(BattleSystem.enemyDict[user]["stats"]["attackMultiplier"])
	var staminaCost := int(attack["cost"])
	var miss := false
	var playerDefense = PlayerDb.playerData["player"]["stats"]["compoundDefense"]
	
	# Distance
	if attack.has("distanceChange"):
		BattleSystem.enemyDict[user]["distance"] = attack["distanceChange"]
	var closenessDamageDiff := 1.0
	if BattleSystem.enemyDict[user]["distance"] == "far":
		closenessDamageDiff = 0.8
	elif BattleSystem.enemyDict[user]["distance"] == "mid":
		closenessDamageDiff = 1
	elif BattleSystem.enemyDict[user]["distance"] == "close":
		closenessDamageDiff = 1.2
	compoundDmg *= closenessDamageDiff
	var closenessAccuracyDiff := 1.0
	if BattleSystem.enemyDict[user]["distance"] == "far":
		closenessAccuracyDiff = 0.8
	elif BattleSystem.enemyDict[user]["distance"] == "mid":
		closenessAccuracyDiff = 1
	elif BattleSystem.enemyDict[user]["distance"] == "close":
		closenessAccuracyDiff = 1.2
	
		# Accuracy Calculator
	var speedDifference := int(EnemyDb.enemies[userNoID]["stats"]["speed"]) - int(PlayerDb.playerData["player"]["stats"]["speed"])
	var accuracy : int = clamp(60 + speedDifference * 5, 10, 95) * closenessAccuracyDiff
	
	
	# Miss roll
	var roll = Global.rng.randi_range(1, 100)
	if roll >= accuracy:
		# Miss
		baseDmg = 0
		radDmg = 0
		compoundDmg = 0
		miss = true
	
	action["general"]["user"] = user
	action["general"]["userName"] = userNoID
	action["general"]["target"] = ["Player"]
	if (attack["blockable"] == true and BattleSystem.playerDefending == true) or miss == true:
		action["combatData"]["damage"] = 0
		action["playerStatus"]["radiationInflict"] = 0
	elif (attack["blockable"] == true and BattleSystem.playerDefending == false) or (attack["blockable"] == false) and not miss:
		if BattleSystem.playerDefending == false:
			action["combatData"]["damage"] = clamp((compoundDmg - playerDefense), 0, 10000000000)
		else:
			action["combatData"]["damage"] = clamp((compoundDmg - (playerDefense*2)), 0, 10000000000)
	action["enemyStatus"]["staminaCost"] = staminaCost
	if attack["type"] != "telegraphRadio":
		action["general"]["announcement"] = attack["announce"]
	if attack["type"] == "telegraphRadio":
		action["general"]["type"] = "telegraphRadio"
		BattleSystem.enemyDict[user]["telegraph"] = attack["telegraph"]
		action["general"]["announcement"] = BattleSystem.enemyDict[user]["radioWarning"].pick_random()["text"]
		action["general"]["announcementSFX"] = BattleSystem.enemyDict[user]["radioWarning"].pick_random()["sound"]
		action["general"]["type"] = "telegraph"
	action["general"]["priority"] = attack["priority"]
	if priority != 1:
		action["general"]["priority"] = priority
	action["general"]["announcementPause"] = attack["announcementPause"]
	action["general"]["impactPause"] = attack["impactPause"]
	action["general"]["resultPause"] = attack["resultPause"]
	
	if (not miss) and attack["type"] != "telegraphRadio":
		action["general"]["type"] = "attack"
		if attack["blockable"] == true and BattleSystem.playerDefending == true:
			action["general"]["result"] = attack["blockResult"]
			action["general"]["resultSFX"] = attack["blockSound"]
		else:
			action["general"]["result"] = attack["result"]
		if (attack["blockable"] == true and BattleSystem.playerDefending == false) or attack["blockable"] == false:
			action["general"]["impactSFX"] = attack["sound"]
		action["combatData"]["statusEffect"] = attack["statusEffect"]
		var blocked : bool = (attack["blockable"] == true and BattleSystem.playerDefending == true)
		if not blocked:
			if BattleSystem.playerDefending == false:
				action["playerStatus"]["radiationInflict"] = clamp((radDmg - (playerDefense / 2)), 0, 10000000000)
			else:
				action["playerStatus"]["radiationInflict"] = clamp((radDmg - playerDefense), 0, 10000000000)
	if miss and attack["type"] != "telegraphRadio":
		action["general"]["type"] = "attackMiss"
		action["general"]["result"] = attack["missResult"]
		action["general"]["impactSFX"] = null
		action["general"]["resultSFX"] = attack["missSound"]
	
	ActionProcessor.queueSpecificAction(action)
	

	


static func die(enemy):
	var action = ActionProcessor.actionTemplate.duplicate(true)
	action["general"]["priority"] = 3
	var announcement = BattleSystem.enemyDict[enemy]["deathMessage"].pick_random()
	action["general"]["announcement"] = announcement["text"]
	action["general"]["announcementSFX"] = announcement["sound"]
	action["general"]["type"] = "death"
	action["general"]["user"] = enemy
	BattleSystem.accumulatedExp += BattleSystem.enemyDict[enemy]["stats"]["experience"]
	for i in range(ActionProcessor.queuedActions.size() - 1, -1, -1):
		var deadAction = ActionProcessor.queuedActions[i]
		if deadAction["general"]["user"] == enemy:
			ActionProcessor.queuedActions.remove_at(i)
	for i in range(ActionProcessor.actions.size() - 1, -1, -1):
		var deadAction = ActionProcessor.actions[i]
		if deadAction["general"]["user"] == enemy:
			ActionProcessor.actions.remove_at(i)
	ActionProcessor.queueSpecificAction(action)
	BattleSystem.enemyIDsKilled.append(BattleSystem.enemyDict[enemy]["ID"])
