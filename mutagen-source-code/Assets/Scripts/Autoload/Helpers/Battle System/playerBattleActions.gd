extends Node


static func attack(targets, limbs, priority = 1):
	var action := ActionProcessor.actionTemplate.duplicate(true)
	var weapon : String = PlayerDb.playerData["player"]["body"]["weapon"]
	var baseDmg := 0
	var ammoType := "undef"
	var affinity := 1.0
	var modifier := 1.0
	var miss := false
	if GlobalDb.weaponDatabase[weapon]["ammoAlternation"] == true and PlayerDb.playerData["player"]["weapons"][weapon]["equipped"] == true:
		if PlayerDb.playerData["player"]["weapons"][weapon]["loadOrder"][0] == "std":
			ammoType =  GlobalDb.weaponDatabase[weapon]["ammoType"]
			baseDmg = GlobalDb.weaponDatabase[weapon]["damage"]
			modifier = GlobalDb.weaponDatabase[weapon]["modifier"]
		else:
			ammoType =  GlobalDb.weaponDatabase[weapon]["ammoTypeAlt"]
			baseDmg = GlobalDb.weaponDatabase[weapon]["damageAlt"]
			modifier = GlobalDb.weaponDatabase[weapon]["modifierAlt"]
	else:
		ammoType = "std"
		baseDmg = GlobalDb.weaponDatabase[weapon]["damage"]
		modifier = GlobalDb.weaponDatabase[weapon]["modifier"]
		
	if BattleSystem.enemyDict[BattleSystem.selectedEnemy]["limbs"][BattleSystem.selectedLimb].has("affinities"):
		for i in BattleSystem.enemyDict[BattleSystem.selectedEnemy]["limbs"][BattleSystem.selectedLimb]["affinities"].keys():
			if i == weapon:
				affinity = BattleSystem.enemyDict[BattleSystem.selectedEnemy]["limbs"][BattleSystem.selectedLimb]["affinities"][i]
		
		
	# Crit Calculator
	var critChance := 0
	critChance = Global.rng.randi_range(0,100)
	var crit := false
	var critDmg : float = 1
	if critChance < round(2 + (0.2 * PlayerDb.playerData["player"]["stats"]["intelligence"])):
		crit = true
		critDmg = Global.rng.randf_range(1.4,1.7)
	
	
	
	var attack : int = PlayerDb.playerData["player"]["stats"]["attack"]
	var compoundDmg : float = (((baseDmg * attack/30) + baseDmg + attack)) * ActionProcessor.STATUS_MANAGER.checkDefenseMod(targets)
	if BattleSystem.enemyDict.has(targets) and BattleSystem.enemyDict[targets].has("limbs") and BattleSystem.enemyDict[targets]["limbs"].has(limbs):
		var limbDamagePercent : float = (BattleSystem.enemyDict[targets]["limbs"][limbs]["damagePercent"]) / 100.0
		var closenessDamageDiff := 1.0
		var closenessAccuracyDiff := 1.0
		match BattleSystem.enemyDict[targets].get("distance"):
			"far":
				closenessDamageDiff = 0.8
				closenessAccuracyDiff = 0.8
			"close":
				closenessDamageDiff = 1.2
				closenessAccuracyDiff = 1.2
			"mid":
				closenessDamageDiff = 1.0
				closenessAccuracyDiff = 1.0
		compoundDmg = int(round(compoundDmg * limbDamagePercent * affinity * critDmg * closenessDamageDiff)) # critDmg moved here from compoundDmg so that
		# crits arent negated when the damage reduction is high
		
	# Miss Calculator	
		var missChance := 0
		missChance = Global.rng.randi_range(1,100)
		var hitChance = clamp((BattleSystem.enemyDict[targets]["limbs"][limbs]["hitRate"] * modifier * closenessAccuracyDiff + PlayerDb.playerData["player"]["stats"]["battleIQ"]), 0.0, 100.0)
		if missChance > hitChance and crit == false:
			miss = true
		
	# Changing Distance
	#if GlobalDb.weaponDatabase[weapon]["type"] == "melee":
		#enemyDict[targets]["distance"] = "close"
		# In case I change my mind. Maybe itll even require closeness? >:)
		
		
	var ammoCost = null
	if GlobalDb["weaponDatabase"][weapon].has("ammoCost"):
		ammoCost = GlobalDb["weaponDatabase"][weapon]["ammoCost"]
	action["general"]["type"] = "attack"
	action["general"]["user"] = "Player"
	action["general"]["target"] = [targets]
	action["weaponData"]["weaponName"] = weapon
	action["weaponData"]["ammoType"] = ammoType
	action["weaponData"]["isWeapon"] = true
	action["weaponData"]["singleUse"] = GlobalDb["weaponDatabase"][weapon]["singleUse"]
	action["general"]["userName"] = PlayerDb.playerData["player"]["name"]
	if not miss and not BattleSystem.playerDefending:
		action["combatData"]["damage"] = int(round(compoundDmg))
	else:
		action["combatData"]["damage"] = 0
	action["combatData"]["limb"] = limbs
	action["weaponData"]["ammoCost"] = ammoCost
	action["general"]["result"] = GlobalDb["weaponDatabase"][weapon]["attackResult"]
	action["general"]["announcementPause"] = GlobalDb["weaponDatabase"][weapon]["announcementPause"]
	action["general"]["impactPause"] = GlobalDb["weaponDatabase"][weapon]["impactPause"]
	action["general"]["resultPause"] = GlobalDb["weaponDatabase"][weapon]["resultPause"]
	if crit == false:
		action["general"]["announcement"] = GlobalDb["weaponDatabase"][weapon]["attackAnnouncement"]
		action["general"]["impactSFX"] = GlobalDb["weaponDatabase"][weapon]["attackSound"]
		action["general"]["announcementSFX"] = GlobalDb["weaponDatabase"][weapon]["attackAnnouncementSound"]
		
	else:
		action["general"]["announcement"] = GlobalDb["weaponDatabase"][weapon]["attackAnnouncementCritical"]
		action["general"]["impactSFX"] = GlobalDb["weaponDatabase"][weapon]["attackCritSound"]
		action["general"]["announcementSFX"] = GlobalDb["weaponDatabase"][weapon]["critAnnouncementSound"]
		action["combatData"]["crit"] = true
	action["general"]["priority"] = priority
	
	if GlobalDb["weaponDatabase"][weapon]["statusEffect"] != null  and not miss:
		action["combatData"]["statusEffects"]["inflict"][GlobalDb["weaponDatabase"][weapon]["statusEffect"]]["points"] = Global.rng.randi_range(GlobalDb["weaponDatabase"][weapon]["statusEffectPointsMin"],GlobalDb["weaponDatabase"][weapon]["statusEffectPointsMax"]) 
		action["combatData"]["statusEffects"]["inflict"][GlobalDb["weaponDatabase"][weapon]["statusEffect"]]["chance"] = GlobalDb["weaponDatabase"][weapon]["statusEffectChance"]
	if miss:
		action["general"]["type"] = "attackMiss"
		action["general"]["result"] = GlobalDb["weaponDatabase"][weapon]["attackMissResult"]
		action["general"]["impactSFX"] = null
		action["general"]["resultSFX"] = GlobalDb["weaponDatabase"][weapon]["attackMissSound"]
		
	ActionProcessor.queueSpecificAction(action)

static func block():
	BattleSystem.playerDefending = true
	var action := ActionProcessor.actionTemplate.duplicate(true)
	action["general"]["priority"] = 2
	action["general"]["announcement"] = "[PLAYERNAME] is defending."
	action["general"]["type"] = "block"
	action["general"]["user"] = "Player"
	ActionProcessor.queuedActions.append(action)
	
static func advance(direction):
	var action := ActionProcessor.actionTemplate.duplicate(true)
	action["general"]["type"] = "advance"
	action["general"]["user"] = "Player"
	action["general"]["userName"] = PlayerDb.playerData["player"]["name"]
	action["combatData"]["advanceDirection"] = direction
	action["general"]["priority"] = 1
	if direction == "forwards":
		action["general"]["announcement"] = "[PLAYERNAME] inches closer."
	else:
		action["general"]["announcement"] = "[PLAYERNAME] is backing away."
	ActionProcessor.queuedActions.append(action)

static func flee():
	var index = 0
	var action := ActionProcessor.actionTemplate.duplicate(true)
	action["general"]["announcement"] = "[PLAYERNAME] tried to run."
	action["general"]["user"] = "Player"
	action["general"]["userName"] = PlayerDb.playerData["player"]["name"]
	action["general"]["priority"] = 2
	
	for i in BattleSystem.enemyDict:
		index += 1
		var enemy = BattleSystem.enemyDict[i]
		if ( enemy["stats"]["speed"] * ActionProcessor.STATUS_MANAGER.checkSpeedMod(i) > (PlayerDb.playerData["player"]["stats"]["speed"] * 1.5 * ActionProcessor.STATUS_MANAGER.checkSpeedMod("Player"))) or (enemy["distance"] == "close") or (enemy["logic"][enemy["phase"]]["canFlee"] == false) or PlayerDb.playerData["player"]["statusEffects"]["cripple"]["active"] == true:
			action["general"]["result"] = "[PERSONALCAP] could not escape."
			action["general"]["type"] = "fleeFail"
			ActionProcessor.queuedActions.append(action)
			break
		if (enemy["distance"] == "mid"):
			var luck = Global.rng.randi_range(1,100)
			if luck <= 50:
				if index == BattleSystem.enemyDict.size():
					action["general"]["result"] = "[PLAYERNAME] successfully fled."
					action["general"]["type"] = "fleeSuccess"
					ActionProcessor.queuedActions.append(action)
					break
				else:
					continue
			if luck > 50:
				action["general"]["result"] = "[PERSONALCAP] could not escape."
				action["general"]["type"] = "fleeFail"
				ActionProcessor.queuedActions.append(action)
				break
		if (enemy["distance"] == "far"):
			var luck = Global.rng.randi_range(1,100)
			if luck <= 75:
				if index == BattleSystem.enemyDict.size():
					action["general"]["result"] = "[PLAYERNAME] successfully fled."
					action["general"]["type"] = "fleeSuccess"
					ActionProcessor.queuedActions.append(action)
					break
				else:
					continue
			if luck > 75:
				action["general"]["result"] = "[PERSONALCAP] could not escape."
				action["general"]["type"] = "fleeFail"
				ActionProcessor.queuedActions.append(action)
				break
	
static func lastStand():
	if PlayerDb.playerData["player"]["stats"]["currentHealth"] <= 0:
		PlayerDb.playerData["player"]["stats"]["currentHealth"] = 1
	if PlayerDb.playerData["player"]["stats"]["radiation"] >= PlayerDb.playerData["player"]["stats"]["maxRadiation"]:
		PlayerDb.playerData["player"]["stats"]["radiation"] = PlayerDb.playerData["player"]["stats"]["maxRadiation"] - 1
	PlayerDb.playerData["player"]["statusEffects"]["lastStand"]["points"] += 1
	ActionProcessor.STATUS_MANAGER.showEffectInitiation("lastStand",["Player"])
	
static func die():
	BattleSystem.playerAlive = false
	BattleSystem.get_viewport().gui_release_focus()
	Global.playerCharBody2D.controllable = false
	var action = ActionProcessor.actionTemplate.duplicate(true)
	action["general"]["priority"] = 2
	action["general"]["announcement"] = "[PLAYERNAME] was killed."
	action["general"]["type"] = "death"
	action["general"]["user"] = "Player"
	ActionProcessor.actions.clear()
	ActionProcessor.queuedActions.clear()
	ActionProcessor.queueSpecificAction(action)

static func reloadWeapon(weaponName, ammoType, reloadType, ammoRefill):
	var action = ActionProcessor.actionTemplate.duplicate(true) # can't just reference the variable,
	#because dictionaries are objects and if you define a variable as another variable that is an object
	# it will simply always point at the same memory address as that variable
	# instead of making a copy
	action["general"]["announcement"] = GlobalDb.weaponDatabase[weaponName]["reloadAnnouncement"]
	action["general"]["announcementSFX"] = GlobalDb.weaponDatabase[weaponName]["reloadAnnouncementSFX"]
	
	action["general"]["name"] = "RELOAD " + weaponName
	action["general"]["type"] = "reload"
	action["general"]["user"] = "Player"
	action["weaponData"]["weaponName"] = weaponName
	action["weaponData"]["ammoType"] = ammoType
	action["weaponData"]["reloadType"] = reloadType
	match reloadType:
		"std":
			action["globalFunction"]["stdReload"] = true
			action["weaponData"]["ammoRefill"] = ammoRefill
			
		"alt":
			action["globalFunction"]["altReload"] = true
			action["weaponData"]["ammoRefill"] = ammoRefill
	ActionProcessor.queuedActions.append(action)

static func berserk(user, data):
	var action = ActionProcessor.actionTemplate.duplicate(true)
	action["general"]["user"] = "Player"
	action["general"]["type"] = "attack"
	action["general"]["priority"] = 2
	action["general"]["announcement"] = PlayerDb.playerData["player"]["statusEffects"]["berserk"]["announcementAttack"].pick_random()
	action["general"]["result"] = PlayerDb.playerData["player"]["statusEffects"]["berserk"]["resultAttack"]
	action["combatData"]["damage"] = data["appliedAtk"]
	if not BattleSystem.enemyDict.keys().is_empty():
		action["general"]["target"] = [BattleSystem.enemyDict.keys().pick_random()]
		ActionProcessor.queueSpecificAction(action) # this skips turnskip()
	else:
		return
