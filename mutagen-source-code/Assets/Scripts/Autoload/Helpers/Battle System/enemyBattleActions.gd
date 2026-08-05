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
	if announcement.has("sound"):
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
	if announcement.has("sound"):
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
	var announcement = BattleSystem.enemyDict[user]["restWarning"].pick_random()
	action["general"]["announcement"] = announcement["text"]
	if announcement.has("sound"):
		action["general"]["announcementSFX"] = announcement["sound"]
	action["general"]["announcementPause"] = 2
	ActionProcessor.queueSpecificAction(action)

static func attack(user, attack, priority = 1):
	var action : Dictionary = ActionProcessor.actionTemplate.duplicate(true)
	var userNoID : String = BattleSystem.removeIdentifier(user)
	var baseDmg := Global.rng.randi_range(int(attack["minDamage"]), int(attack["maxDamage"]))
	var radDmg := Global.rng.randi_range(int(attack["minRadDamage"]), int(attack["maxRadDamage"]))
	var compoundDmg : float = baseDmg * (BattleSystem.enemyDict[user]["stats"]["attackMultiplier"])
	var staminaCost := int(attack["cost"])
	var miss := false
	var playerDefense = int(PlayerDb.playerData["player"]["stats"]["compoundDefense"] * ActionProcessor.STATUS_MANAGER.checkDefenseMod("Player"))
	
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
	var speedDifference := int(BattleSystem.enemyDict[user]["stats"]["speed"] * ActionProcessor.STATUS_MANAGER.checkSpeedMod(user)) - int(PlayerDb.playerData["player"]["stats"]["speed"] * ActionProcessor.STATUS_MANAGER.checkSpeedMod("Player"))
	var accuracy : int = int(round(clamp(60 + speedDifference * 5, 10, 95) * closenessAccuracyDiff))
	
	
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
			action["combatData"]["damage"] = int(round(clamp((compoundDmg - playerDefense), 1, 10000000000)))
		else:
			action["combatData"]["damage"] = int(round(clamp((compoundDmg - (playerDefense*2)), 1, 10000000000)))
	action["enemyStatus"]["staminaCost"] = staminaCost
	if attack["type"] != "telegraphRadio" and attack["type"] != "telegraphStd":
		action["general"]["announcement"] = attack["announce"]
	if attack["type"] == "telegraphRadio":
		action["general"]["type"] = "telegraphRadio"
		BattleSystem.enemyDict[user]["telegraph"] = attack["telegraph"]
		var radioWarning = BattleSystem.enemyDict[user]["radioWarning"].pick_random()
		action["general"]["announcement"] = radioWarning["text"]
		if radioWarning.has("sound"):
			action["general"]["announcementSFX"] = radioWarning["sound"]
		action["general"]["type"] = "telegraph"
	if attack["type"] == "telegraphStd":
		action["general"]["type"] = "telegraphStd"
		BattleSystem.enemyDict[user]["telegraph"] = attack["telegraph"]
		var standardWarning = BattleSystem.enemyDict[user]["standardWarning"].pick_random()
		action["general"]["announcement"] = standardWarning["text"]
		if standardWarning.has("sound"):
			action["general"]["announcementSFX"] = standardWarning["sound"]
		action["general"]["type"] = "telegraph"
	action["general"]["priority"] = attack["priority"]
	if priority != 1:
		action["general"]["priority"] = priority
	action["general"]["announcementPause"] = attack["announcementPause"]
	action["general"]["impactPause"] = attack["impactPause"]
	action["general"]["resultPause"] = attack["resultPause"]
	if attack["type"] == "atkBoost":
		action["combatData"]["atkBoost"] = attack.get("atkBoost", 1.0)
	
	if (not miss) and attack["type"] != "telegraphRadio" and attack["type"] != "telegraphStd":
		action["general"]["type"] = "attack"
		if attack["blockable"] == true and BattleSystem.playerDefending == true:
			action["general"]["result"] = attack["blockResult"]
			action["general"]["resultSFX"] = attack["blockSound"]
		else:
			action["general"]["result"] = attack["result"]
		if (attack["blockable"] == true and BattleSystem.playerDefending == false) or attack["blockable"] == false:
			action["general"]["impactSFX"] = attack["sound"]
		var blocked : bool = (attack["blockable"] == true and BattleSystem.playerDefending == true)
		# status effect inflict
		if attack["statusEffect"] != null and not miss and not blocked:
			action["combatData"]["statusEffects"]["inflict"][attack["statusEffect"]]["points"] = Global.rng.randi_range(attack["statusEffectPointsMin"],attack["statusEffectPointsMax"]) 
			action["combatData"]["statusEffects"]["inflict"][attack["statusEffect"]]["chance"] = attack["statusEffectChance"]
		
		if not blocked:
			if BattleSystem.playerDefending == false:
				action["playerStatus"]["radiationInflict"] = clamp((radDmg - (playerDefense / 2)), 0, 10000000000)
			else:
				action["playerStatus"]["radiationInflict"] = clamp((radDmg - playerDefense), 0, 10000000000)
	if miss and attack["type"] != "telegraphRadio" and attack["type"] != "telegraphStd":
		action["general"]["type"] = "attackMiss"
		action["general"]["result"] = attack["missResult"]
		action["general"]["impactSFX"] = null
		action["general"]["resultSFX"] = attack["missSound"]
	
	ActionProcessor.queueSpecificAction(action)
	

	
static func itemDrop(enemy):
	var action = ActionProcessor.actionTemplate.duplicate(true)
	var enemyNoID = BattleSystem.removeIdentifier(enemy)
	var likelihood = EnemyDb.enemies[enemyNoID]["stats"]["itemDropLikelihood"]
	var chance : int = Global.rng.randi_range(1,100)
	var success := false
	var items := []
	var result = null
	var quantity := 0
	var type = null
	action["general"]["type"] = "itemDrop"
	
	
	if chance <= likelihood:
		success = true
	if success == true:
		for item in EnemyDb.enemies[enemyNoID]["itemDrops"]:
			for weight in EnemyDb.enemies[enemyNoID]["itemDrops"][item]["weight"]:
				items.append(item)
		result = items.pick_random()
		type = EnemyDb.enemies[enemyNoID]["itemDrops"][result]["type"]
		quantity = EnemyDb.enemies[enemyNoID]["itemDrops"][result]["quantity"]
		var trueName = null
		if type == "item":
			trueName = GlobalDb.itemDatabase[result]["general"]["name"]
		elif type == "ammo":
			trueName = GlobalDb.ammoDatabase[result]["name"]
		if quantity > 1:
			action["general"]["announcement"] = enemy + " dropped " + str(quantity) + " " + trueName + "."
		else:
			action["general"]["announcement"] = enemy + " dropped " + trueName + "."
		if type == "item":
			InventoryHelper.addItem(result, quantity)
		elif type == "ammo":
			PlayerDb.playerData["player"]["ammo"][result] += quantity
			Global.helpMenu.updateWeaponDescriptions()
		ActionProcessor.queueSpecificAction(action)
		print('item supposed to be dropped')
		
		
static func die(enemy):
	var action = ActionProcessor.actionTemplate.duplicate(true)
	action["general"]["priority"] = 3
	var announcement = BattleSystem.enemyDict[enemy]["deathMessage"].pick_random()
	action["general"]["announcement"] = announcement["text"]
	if announcement.has("sound"):
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
	itemDrop(enemy)
	BattleSystem.enemyIDsKilled.append(BattleSystem.enemyDict[enemy]["ID"])

static func berserk(user, data):
	var action = ActionProcessor.actionTemplate.duplicate(true)
	action["general"]["user"] = user
	action["general"]["type"] = "attack"
	action["general"]["priority"] = 3
	action["general"]["announcement"] = BattleSystem.enemyDict[user]["statusEffects"]["berserk"]["announcementAttack"].pick_random()
	action["general"]["result"] =  BattleSystem.enemyDict[user]["statusEffects"]["berserk"]["resultAttack"]
	action["combatData"]["damage"] = data["appliedAtk"]
	action["general"]["target"] = ["Player"]
	ActionProcessor.queuedActions.append(action)
