extends Node


static func execute():
	# Enemies
	
	for i in BattleSystem.turnOrderArray:
		if i != "Player":
			var user = i
			var userNoID = BattleSystem.removeIdentifier(i)
			var move = ""
		
			var phase = BattleSystem.enemyDict[i]["phase"]
			var attacks = BattleSystem.enemyDict[i]["logic"][phase]["attacks"]
			var stamina = BattleSystem.enemyDict[i]["stats"]["stamina"]
			var maxStamina = BattleSystem.enemyDict[i]["stats"]["maxStamina"]
			var health = BattleSystem.enemyDict[i]["stats"]["health"]
			var maxHealth = BattleSystem.enemyDict[i]["stats"]["maxHealth"]
			var surgeChance = BattleSystem.enemyDict[i]["stats"]["surgeChance"]
			var telegraph = BattleSystem.enemyDict[i]["telegraph"]
			BattleSystem.enemyDict[i]["logic"][phase]["turns"] += 1
			
		# Decide to change phases
			if BattleSystem.enemyDict[i]["logic"][phase].has("phaseChanges"):
				var phaseChanges = BattleSystem.enemyDict[i]["logic"][phase]["phaseChanges"]
				for condition in phaseChanges:
					if phaseChanges[condition]["type"] == "healthLeq" and phaseChanges[condition]["amount"] >= health:
						move = "phaseChange"
						BattleSystem.ENEMY_MOVES.changePhase(user, phaseChanges[condition]["phaseChange"], condition)
						break
				if move == "phaseChange":
					continue
			
		# Decide to surge
			var surgeRoll = Global.rng.randi_range(0,100)
			if (surgeRoll < surgeChance) and (stamina < maxStamina) and (telegraph == ""):
				move = "surge"
				BattleSystem.ENEMY_MOVES.surge(user)
				continue
			# deciding what the enemy is going to do for its turn
		
			# ENEMY ATTACK PICKING
			if BattleSystem.enemyDict[i]["telegraph"] != "":
				BattleSystem.ENEMY_MOVES.attack(i, EnemyDb.enemies[BattleSystem.removeIdentifier(i)]["telegraphAttacks"][BattleSystem.enemyDict[i]["telegraph"]])
				BattleSystem.enemyDict[i]["telegraph"] = ""
				continue
			if stamina >= BattleSystem.enemyDict[i]["stats"]["minStaminaToAttack"]:
				# BEHAVIORS:
				var viableAttacks = []
				var chosenAttack = ""
				match BattleSystem.enemyDict[i]["logic"][BattleSystem.enemyDict[i]["phase"]]["behavior"]:
					"random": # RANDOM ATTACK PATTERN
					# random enemies act completely randomly
					# they have a random chance of using any afforded attack
					# meaning they will spam whatever is accessible to them
					# without meaningful tact. despite this, theyre actually
					# moderately difficult because you cannot meaningfully
					# guess their next move
						viableAttacks = []
						for o in attacks:
							if stamina >= BattleSystem.enemyDict[i]["attacks"][o]["cost"]:
								viableAttacks.append(o)
						chosenAttack = viableAttacks.pick_random()
					"cocky": # COCKY ATTACK PATTERN
					# cocky enemies will spam their heaviest available attack
					# on you. the best way to beat them is to anticipate this,
					# defend or heal first, and then knock them cold while theyre exhausted
					# they're probably the hardest to deal with early game
					# and easiest to deal with late game
						viableAttacks = []
						for o in attacks:
							if stamina >= BattleSystem.enemyDict[i]["attacks"][o]["cost"]:
								viableAttacks.append(o)
						chosenAttack = viableAttacks[0]
						for o in viableAttacks:
							if BattleSystem.enemyDict[i]["attacks"][o]["cost"] > BattleSystem.enemyDict[i]["attacks"][chosenAttack]["cost"]:
								chosenAttack = o
					"scummy": #SCUMMY ATTACK PATTERN
					# scummy enemies will deliberately conserve energy on you
					# when you're strong. this is to lull you into thinking
					#they're weak, and let you take a few hits first.
					# if you're weak, they'll proceed to use their heaviest attacks on you
					
					# this one only works if you register heavy AND light attacks, otherwise they'll short circuit
						viableAttacks = []
						if PlayerDb.playerData["player"]["stats"]["currentHealth"] > (PlayerDb.playerData["player"]["stats"]["maxHealth"])/3:
							for o in attacks:
								if stamina >= BattleSystem.enemyDict[i]["attacks"][o]["cost"] and (BattleSystem.enemyDict[i]["attacks"][o]["weight"] == "Medium" or BattleSystem.enemyDict[i]["attacks"][o]["weight"] == "Light"):
									viableAttacks.append(o)
						else:
							for o in attacks:
								if stamina >= BattleSystem.enemyDict[i]["attacks"][o]["cost"]: # always uses its heaviest available attack on you
									viableAttacks.append(o)
									continue
								
						chosenAttack = viableAttacks.pick_random()
					
				BattleSystem.ENEMY_MOVES.attack(i, EnemyDb.enemies[BattleSystem.removeIdentifier(i)]["attacks"][chosenAttack])
			else:
				BattleSystem.ENEMY_MOVES.rest(user)
				
		else: # Player
			if BattleSystem.turnSkips.has("Player"):
				continue
			if ActionProcessor.queuedActions.size() > 0:
				ActionProcessor.queueSpecificAction(ActionProcessor.queuedActions.pop_front())
			else:
				BattleSystem.PLAYER_MOVES.attack(BattleSystem.selectedEnemy, BattleSystem.selectedLimb)
