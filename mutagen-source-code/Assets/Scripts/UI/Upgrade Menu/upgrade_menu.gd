extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ActionProcessor.connect("levelUp", levelUp)

func _process(delta) -> void:
	if PlayerDb.playerData["player"]["skillPoints"] > 1:
		$Tabs/upgradePicker/SPLeft.text = "[pulse color=green]" + str(PlayerDb.playerData["player"]["skillPoints"]) + " Skill Points Left"
	elif PlayerDb.playerData["player"]["skillPoints"] == 1:
		$Tabs/upgradePicker/SPLeft.text = "[pulse color=green]" + str(PlayerDb.playerData["player"]["skillPoints"]) + " Skill Point Left"
	else:
		$Tabs/upgradePicker/SPLeft.text = "[color=gray]" + "0 Skill Points Left"
func levelUp():
	var values = {
	"strength": {
		"text": "Strength (Current Level: " + str(PlayerDb.playerData["player"]["stats"]["strength"]) + ")",
		"icon": load("res://Assets/Images/Sprites/UI/Menu/Icons/Stats/strength.png"),
		"selectable": true,
		"meta": null
	},
	"survival": {
		"text": "Survival (Current Level: " + str(PlayerDb.playerData["player"]["stats"]["survival"]) + ")",
		"icon": load("res://Assets/Images/Sprites/UI/Menu/Icons/Stats/survival.png"),
		"selectable": true,
		"meta": null
	},
	"intelligence": {
		"text": "Intelligence (Current Level: " + str(PlayerDb.playerData["player"]["stats"]["intelligence"]) + ")",
		"icon": load("res://Assets/Images/Sprites/UI/Menu/Icons/Stats/intelligence.png"),
		"selectable": true,
		"meta": null
	},
	"cancel": {
		"text": "< Done",
		"icon": null,
		"selectable": true,
		"meta": null
	}
}
	$Tabs/upgradePicker/upgradesList.clear()
	CowTools.populateItemList($Tabs/upgradePicker/upgradesList, values)
	$Tabs/upgradePicker/upgradesList.select(0)
	if visible == false:
		$AnimationPlayer.play("PanIn")
		await get_tree().create_timer(1).timeout
		$Tabs/upgradePicker/upgradesList.grab_focus()
	




func _on_upgrades_list_item_activated(index: int) -> void:
	if index == 0:
		PlayerDb.skillUp("strength")
		PlayerDb.skillConfig("strength")
	if index == 1:
		PlayerDb.skillUp("survival")
		PlayerDb.skillConfig("survival")
	if index == 2:
		PlayerDb.skillUp("intelligence")
		PlayerDb.skillConfig("intelligence")
	if index == 3:
		proceed()
		return
		
	if PlayerDb.playerData["player"]["skillPoints"] > 0:
		levelUp()
	else:
		proceed()
func proceed():
	$AnimationPlayer.play("PanOut")
	BattleSystem.exitBattle()
