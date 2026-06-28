extends Node


static func hitstop(dmg, maxHealth):
	var duration = lerp(0.2, 2.0, clamp(float(dmg) / float(maxHealth), 0.0, 1.0))
	var tree = ActionProcessor.get_tree()
	tree.paused = true
	await tree.create_timer(duration, true, false, true).timeout
	tree.paused = false

static func turnSkip(target):
	for i in range(ActionProcessor.queuedActions.size() - 1, -1, -1):
			var action = ActionProcessor.queuedActions[i]
			if action["general"]["user"] == target:
				ActionProcessor.queuedActions.remove_at(i)

	for i in range(ActionProcessor.actions.size() - 1, -1, -1):
		var action = ActionProcessor.actions[i]
		if action["general"]["user"] == target:
			ActionProcessor.actions.remove_at(i)
