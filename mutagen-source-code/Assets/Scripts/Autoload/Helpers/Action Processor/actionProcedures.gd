extends Node


static func hitstop(dmg, maxHealth):
	var duration = lerp(0.2, 2.0, clamp(float(dmg) / float(maxHealth), 0.0, 1.0))
	var tree = ActionProcessor.get_tree()
	tree.paused = true
	await tree.create_timer(duration, true, false, true).timeout
	tree.paused = false

static func turnSkip(target):
	if target == "Player":
		BattleSystem.playerDefending = false
		BattleSystem.selectedEnemy = ""
		BattleSystem.selectedLimb = ""
	for i in range(ActionProcessor.queuedActions.size() - 1, -1, -1):
			var action = ActionProcessor.queuedActions[i]
			if action["general"]["user"] == target and isTurnAction(action):
				ActionProcessor.queuedActions.remove_at(i)
	for i in range(ActionProcessor.actions.size() - 1, -1, -1):
		var action = ActionProcessor.actions[i]
		if action["general"]["user"] == target and isTurnAction(action):
			ActionProcessor.actions.remove_at(i)
	if not BattleSystem.turnSkips.has(target):
		BattleSystem.turnSkips.append(target)

static func isTurnAction(action):
	return (action["general"]["priority"] < 2 and action["general"]["type"] != "statusEffectInflict" and action["general"]["type"] != "statusEffectClear" and action["general"]["type"] != "statusEffectHarm")
