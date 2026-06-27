extends Node


static func execute(data):
	
	var targets := []
	var state = 0 # 0 = No statement 1 = Announcement 2 = Impact 3 = Result
	ActionProcessor.actions.remove_at(0)
	
	# Interrupting player attack if the target is gone
	if data["general"]["user"] == "Player" and (data["general"]["type"] == "attack" or data["general"]["type"] == "attackMiss"):
		for target in data["general"]["target"]:
			if target != "Player" and not BattleSystem.enemyDict.has(target):
				data["general"]["type"] = "attackInterrupted"
				data["general"]["announcement"] = "Flynn's plan of attack was interrupted."
				data["general"]["announcementSFX"] = "res://Assets/Sounds/Random/weird2.mp3"
				data["general"]["impactSFX"] = null
				data["general"]["result"] = ""
				data["general"]["resultSFX"] = null
				data["combatData"]["damage"] = 0
				data["weaponData"]["ammoCost"] = null
				break

	
	# Stuff that applies to all actions
	var textSpeed := 1
	var textSpeedSetting = Settings.settingsRaw["textSpeed"]
	if textSpeedSetting == "fast":
		textSpeed = 2
	else:
		textSpeed = 1
	ActionProcessor.actionLog.speakingMultiplier = data["general"]["typewriteSpeed"] * textSpeed


	
	
	
	#Announcement
	if ActionProcessor.actionLog.get_node("Panel/VBoxContainer/HBoxContainer/Text").get_parsed_text().length() > 0:
		ActionProcessor.actionLog.get_node("Panel/VBoxContainer/HBoxContainer/Text").text += ("\n")
	if data["general"]["announcementSFX"] != null and data["general"]["announcementSFX"] != "":
		UniversalAudio.stopAllSpecialSounds()
		UniversalAudio.playSpecialSound(data["general"]["announcementSFX"])
		
	if data["general"]["announcement"] != null and data["general"]["announcement"] != "":
		state = 1
		ActionProcessor.actionLog.get_node("Panel/VBoxContainer/HBoxContainer/Text").text += "> " + ActionProcessor.formatActionText(data["general"]["announcement"], data, targets)
		# ^^^ replaces placeholder text with data
		await ActionProcessor.waitForActionPause(data["general"]["announcementPause"], data["general"]["inputDependent"])
		
	# "Impact" (FX and audio for when a thing changes)
	if data["general"]["impactTXT"] != null and data["general"]["impactTXT"] != "":
		# probably not entirely necessary, but the placeholder replacement
		#gets applied to impact text too in case its ever used preemptively
		ActionProcessor.actionLog.get_node("Panel/VBoxContainer/HBoxContainer/Text").text += "\n> " + ActionProcessor.formatActionText(data["general"]["impactTXT"], data, targets)
	if data["general"]["impactSFX"] != null and data["general"]["impactSFX"] != "" and BattleSystem.playerAlive: # important stuff, unlike announcement and
		# ^ playerAlive check makes sure that sounds dont clip when the player is dead from an attack
		# result, for impact is tacked onto SFX. this is because all
		# impact FX will make a sound, but not all sounds will have
		# on screen FX. if you ever find that impact is behaving weirdly,
		# that is probably why
		UniversalAudio.playSpecialSound(data["general"]["impactSFX"])
		
		if data["combatData"]["damage"] > 0:
			for i in data["general"]["target"]:
				if i != "Player":
					var maxHealth = BattleSystem.enemyDict[i]["stats"]["maxHealth"]
					var damage = data["combatData"]["damage"]
					instance_from_id(BattleSystem.enemyDict[i]["battleSpriteID"]).hurtAnimation(clamp((damage / maxHealth) * 100, 5, 25),0.5,8)
					if data["combatData"]["crit"] == true:
						await hitstop(damage, maxHealth)
		await ActionProcessor.waitForActionPause(data["general"]["impactPause"], data["general"]["inputDependent"])

		
	# "Result" (What gets displayed after a thing changes and its time to tell the player what happened)
	# Note: ALL of these are optional. They're all gonna be used together very often, though. Almost ALWAYS in combat actions
	if data["general"]["result"] != null and data["general"]["result"] != "":
		ActionProcessor.actionLog.get_node("Panel/VBoxContainer/HBoxContainer/Text").text += "\n> " + ActionProcessor.formatActionText(data["general"]["result"], data, targets)
	if data["general"]["resultSFX"] != null and data["general"]["resultSFX"] != "":
		UniversalAudio.playSpecialSound(data["general"]["resultSFX"])
		# ^^^ replaces placeholder text with data
	if data["general"]["result"] != null and data["general"]["result"] != "":
		await ActionProcessor.waitForActionPause(data["general"]["resultPause"], data["general"]["inputDependent"])
	

			
	# Combat Action
	if data["weaponData"].has("ammoCost") and data["weaponData"]["ammoCost"] != null and (data["general"]["type"] == "attack" or data["general"]["type"] == "attackMiss") and data["general"]["user"] == "Player":
		if data["weaponData"]["ammoCost"] > 0:
			InventoryHelper.ammoEject(data["weaponData"]["weaponName"], data["weaponData"]["ammoCost"], false) # false means a sound wont play
			InventoryHelper.updateWeaponDatabases()
			
	if data["combatData"]["damage"] > 0:
		for i in data["general"]["target"]:
			if i == "Player":
				var health = PlayerDb.playerData["player"]["stats"]["currentHealth"]
				var maxHealth = PlayerDb.playerData["player"]["stats"]["maxHealth"]
				var damage = data["combatData"]["damage"]
				PlayerDb.playerData["player"]["stats"]["currentHealth"] = clamp((health - damage), 0, maxHealth)
				
			else:
				var health = BattleSystem.enemyDict[i]["stats"]["health"]
				var maxHealth = BattleSystem.enemyDict[i]["stats"]["maxHealth"]
				var damage = data["combatData"]["damage"]
				health = clamp((health - damage), 0, maxHealth)
				if health > 0 and damage > 0:
					BattleSystem.enemyDict[i]["stats"]["health"] = health
				elif health <= 0:
					BattleSystem.ENEMY_MOVES.die(i)
					
					
	if data["playerStatus"]["radiationInflict"] > 0:
		var radiation = PlayerDb.playerData["player"]["stats"]["radiation"]
		var radDamage = data["playerStatus"]["radiationInflict"]
		PlayerDb.playerData["player"]["stats"]["radiation"] = clamp((radiation + radDamage), 0, 100)
	
	
	# Advancing/Regressing in Combat
	if data["general"]["type"] == "advance" and data["general"]["user"] == "Player":
		match data["combatData"]["advanceDirection"]:
			"forwards":
				for i in BattleSystem.enemyDict.keys():
					if BattleSystem.enemyDict[i]["distance"] == "far":
						BattleSystem.enemyDict[i]["distance"] = "mid"
					elif BattleSystem.enemyDict[i]["distance"] == "mid":
						BattleSystem.enemyDict[i]["distance"] = "close"
			"backwards":
				for i in BattleSystem.enemyDict.keys():
					if BattleSystem.enemyDict[i]["distance"] == "mid":
						BattleSystem.enemyDict[i]["distance"] = "far"
					elif BattleSystem.enemyDict[i]["distance"] == "close":
						BattleSystem.enemyDict[i]["distance"] = "mid"
					
	# Surge/Rest Action
	if data["general"]["type"] == "surge" or data["general"]["type"] == "rest":
		BattleSystem.enemyDict[data["general"]["user"]]["stats"]["stamina"] = clamp(
			BattleSystem.enemyDict[data["general"]["user"]]["stats"]["stamina"] + data["enemyStatus"]["staminaRegen"], 0, BattleSystem.enemyDict[data["general"]["user"]]["stats"]["maxStamina"])
		
	# Phase Change Action
	if data["enemyStatus"]["phaseChange"] != "":
		BattleSystem.enemyDict[data["general"]["user"]]["phase"] = data["enemyStatus"]["phaseChange"]
		BattleSystem.battleConfig()
		
	# Enemy Stamina Cost
	
	if data["general"]["user"] != "Player" and (data["general"]["type"] == "attack" or data["general"]["type"] == "attackMiss" or data["general"]["type"] == "telegraph"):
		BattleSystem.enemyDict[data["general"]["user"]]["stats"]["stamina"] = clamp(
		BattleSystem.enemyDict[data["general"]["user"]]["stats"]["stamina"] - data["enemyStatus"]["staminaCost"], 0, BattleSystem.enemyDict[data["general"]["user"]]["stats"]["maxStamina"])
		
	# Reload Action
	if data["general"]["type"] == "reload":
		if data["globalFunction"]["stdReload"] == true:
			InventoryHelper.reloadSystem(data["weaponData"]["weaponName"], data["weaponData"]["ammoType"])
		elif data["globalFunction"]["altReload"] == true:
			InventoryHelper.confirmSpecialReload(data["weaponData"]["ammoRefill"])
		await ActionProcessor.get_tree().create_timer(data["general"]["resultPause"]).timeout
		InventoryHelper.updateWeaponDatabases()
		
	
	# Use Item Action
	if data["general"]["type"] == "useItem":
		var itemName = data["itemData"]["itemName"]
		if itemName != null and itemName != "" and PlayerDb.playerData["player"]["inventory"].has(itemName):
			var currentHealth = PlayerDb.playerData["player"]["stats"]["currentHealth"]
			var maxHealth = PlayerDb.playerData["player"]["stats"]["maxHealth"]
			var currentRadiation = PlayerDb.playerData["player"]["stats"]["radiation"]
			var healAmount = randi_range(data["sharedData"]["healMin"], data["sharedData"]["healMax"])
			var radReduceAmount = data["playerStatus"]["radiationReduce"]
			
			PlayerDb.playerData["player"]["stats"]["currentHealth"] = clamp(currentHealth + healAmount, 0, maxHealth)
			PlayerDb.playerData["player"]["stats"]["radiation"] = clamp(currentRadiation - radReduceAmount, 0, 100)
			
			if GlobalDb.itemDatabase[itemName]["general"]["disposable"] == true:
				PlayerDb.playerData["player"]["inventory"][itemName]["quantity"] -= 1
				if PlayerDb.playerData["player"]["inventory"][itemName]["quantity"] <= 0:
					PlayerDb.playerData["player"]["inventory"].erase(itemName)
			Global.helpMenu.updateItemDescriptions()
		
	# Death Action
	if data["general"]["type"] == "death":
		if data["general"]["user"] == "Player":
			BattleSystem.endBattleLose.emit()
		else:
			instance_from_id(BattleSystem.enemyDict[data["general"]["user"]]["battleSpriteID"]).deathAnimation()
			BattleSystem.turnOrderArray.erase(data["general"]["user"])
			BattleSystem.enemyDict.erase(data["general"]["user"])
			
			if BattleSystem.enemyDict.size() == 0 and BattleSystem.battleEnded == false:
				BattleSystem.battleEnded = true
				BattleSystem.winBattle()

	# Flee Action
	
	if data["general"]["type"] == "fleeSuccess":
		ActionProcessor.actions.clear()
		ActionProcessor.queuedActions.clear()
		ActionProcessor.flee = true
		BattleSystem.battleEnded = true
		BattleSystem.winBattle(true)

	# Level Up
	if data["general"]["type"] == "levelUp":
		ActionProcessor.pendingSkillUpgrade = true
		
	
	# Status Effects
	# Possibility of inflicting an effect per effect attack
	for effect in data["combatData"]["statusEffects"]["inflict"]:
		var list = data["combatData"]["statusEffects"]["inflict"]
		if list[effect]["points"] > 0 and not data["general"]["type"] == "attackMiss":
			var chance = Global.rng.randi_range(1,100)
			if list[effect]["chance"] >= chance: # Success
				if data["general"]["target"][0] == "Player":
					PlayerDb.playerData["player"]["statusEffects"][effect]["points"] += list[effect]["points"]
					ActionProcessor.STATUS_MANAGER.showEffectInitiation(effect, data["general"]["target"])
				else:
					for enemy in data["general"]["target"]:
						BattleSystem.enemyDict[enemy]["statusEffects"][effect]["points"] += list[effect]["points"]
						ActionProcessor.STATUS_MANAGER.showEffectInitiation(effect, data["general"]["target"])
	
	ActionProcessor.processing = false
		
		
		
static func hitstop(dmg, maxHealth):
	var duration = lerp(0.2, 2.0, clamp(float(dmg) / float(maxHealth), 0.0, 1.0))
	var tree = ActionProcessor.get_tree()
	tree.paused = true
	await tree.create_timer(duration, true, false, true).timeout
	tree.paused = false
