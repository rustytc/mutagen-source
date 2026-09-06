extends Control
var saveSlot = preload("res://Assets/Scenes/UI/Reusable UI Elements/saveSlot.tscn")
var saveFileDirectory = null
@export var mode := "save"
var selectedSaveSlot := ""

var loadedData = {

}
func _ready():
	setUpSaveScreen()
	$scrollContainer.get_v_scroll_bar().modulate.a = 0
	if DirAccess.dir_exists_absolute("user://saves/"):
		saveFileDirectory = DirAccess.open("user://saves/")
	else:
		DirAccess.make_dir_absolute("user://saves/")
		saveFileDirectory = DirAccess.open("user://saves/")
		
func setUpSaveScreen():
	for i in get_tree().get_nodes_in_group("saveSlot"):
		i.queue_free()
	
	$savetext.show()
	
	var slot = saveSlot.instantiate()
	slot.slotClicked.connect(saveSlotClicked)
	slot.text = "Create New Save Slot"
	slot.get_node("icon").texture = null
	if mode == "save":
		$scrollContainer/vBoxContainer.add_child(slot)
	var saves = DirAccess.get_directories_at("user://saves/")
	for i in range(saves.size(), 0, -1):
		var indexedSlot = saveSlot.instantiate()
		var save = saves[i - 1]
		var playerDataJson = JSON.parse_string(FileAccess.open("user://saves/" + save + "/playerData.json", FileAccess.READ).get_as_text())
		print(save)
		indexedSlot.slotClicked.connect(saveSlotClicked)
		indexedSlot.saveFile = save
		indexedSlot.text = "LEVEL " + str(playerDataJson["player"]["level"]) + "\n" + LevelDb.areaDatabase[playerDataJson["player"]["currentArea"]]["areaMetadata"]["prettyName"] + "\n" + save.replace("T", " ").replace("_",":") + "\n" + playerDataJson["game"]["runTime"]
		indexedSlot.createFile = false
		$scrollContainer/vBoxContainer.add_child(indexedSlot)
	match mode:
		"save":
			for i in get_tree().get_nodes_in_group("saveSlot"):
				if i.createFile:
					i.grab_focus() # this makes the first slot highlighted when the screen initiates
		"load":
			for i in get_tree().get_nodes_in_group("saveSlot"):
				if i.is_queued_for_deletion() == false:
					i.grab_focus()
					break
			
func createSaveFile():
	var time = Time.get_datetime_string_from_system()
	DirAccess.make_dir_absolute("user://saves/" + str(time).replace(":","_"))
	writeSaveData("user://saves/" + str(time).replace(":","_"))
	

	
func saveSlotClicked(saveFile, createFile):
	if createFile:
		createSaveFile()
		setUpSaveScreen()
	else:
		selectedSaveSlot = saveFile
		$menuOptions/animationPlayer.play("appear")
		$menuOptions/animationPlayer.queue("shown")
		$menuOptions/back.focus_mode = FOCUS_ALL
		$menuOptions/load.focus_mode =  FOCUS_ALL
		$menuOptions/delete.focus_mode =  FOCUS_ALL
		$menuOptions/back.grab_focus()
		for i in get_tree().get_nodes_in_group("saveSlot"):
			i.focus_mode = FOCUS_NONE
	
func writeSaveData(filepath):
	var playerData = PlayerDb.playerData
	var npcDatabase = ActorHelper.npcDatabase
	var objectDatabase = ActorHelper.objectDatabase
	var areaDatabase = LevelDb.areaDatabase
	
	var playerDataJson = FileAccess.open(filepath + "/playerData.json", FileAccess.WRITE)
	playerDataJson.store_string(JSON.stringify(playerData))
	playerDataJson.close()
	
	var npcDatabaseJson = FileAccess.open(filepath + "/npcDatabase.json", FileAccess.WRITE)
	npcDatabaseJson.store_string(JSON.stringify(npcDatabase))
	npcDatabaseJson.close()
	
	var objectDatabaseJson = FileAccess.open(filepath + "/objectDatabase.json", FileAccess.WRITE)
	objectDatabaseJson.store_string(JSON.stringify(objectDatabase))
	objectDatabaseJson.close()
	
	var areaDatabaseJson = FileAccess.open(filepath + "/areaDatabase.json", FileAccess.WRITE)
	areaDatabaseJson.store_string(JSON.stringify(areaDatabase))
	areaDatabaseJson.close()
	
func loadSaveFile(filepath):
	if not DirAccess.dir_exists_absolute(str(filepath)):
		UniversalAudio._play_error()
		print("No filepath exists of that index")
		return
	var playerDataFile = FileAccess.open(filepath + "/playerData.json",	FileAccess.READ	)
	var playerData = JSON.parse_string(playerDataFile.get_as_text())
	playerDataFile.close()
	
	var npcDatabaseFile = FileAccess.open(filepath + "/npcDatabase.json", FileAccess.READ)
	var npcDatabase = JSON.parse_string(npcDatabaseFile.get_as_text())
	npcDatabaseFile.close()
	
	var objectDatabaseFile = FileAccess.open(filepath + "/objectDatabase.json", FileAccess.READ)
	var objectDatabase = JSON.parse_string(objectDatabaseFile.get_as_text())
	objectDatabaseFile.close()
	
	var areaDatabaseFile = FileAccess.open(filepath + "/areaDatabase.json", FileAccess.READ)
	var areaDatabase = JSON.parse_string(areaDatabaseFile.get_as_text())
	areaDatabaseFile.close()
	
	CowTools.loadDictionary(PlayerDb.playerData, playerData)
	CowTools.loadDictionary(ActorHelper.npcDatabase, npcDatabase)
	CowTools.loadDictionary(ActorHelper.objectDatabase, objectDatabase)
	CowTools.loadDictionary(LevelDb.areaDatabase, areaDatabase)
	
	Global.goToArea(PlayerDb.playerData["player"]["currentArea"], PlayerDb.playerData["player"]["currentRoom"])
	get_tree().get_nodes_in_group("Title Screen")[0].queue_free()
	
func _process(delta):
	if mode == "save":
		$menuOptions/load.hide()
	else:
		$menuOptions/load.show()
		$menuOptions/load.text = "LOAD"
	if self.visible == true and self.has_node("animationPlayer"):
		print(get_node("animationPlayer").current_animation)
		if get_node("animationPlayer").current_animation == ("") and (Input.is_action_just_pressed("Left") or $arrow3/button.button_pressed) and $menuOptions/animationPlayer.current_animation != "appear" and $menuOptions/animationPlayer.current_animation != "shown":
			get_node("animationPlayer").play("slideOut")
			UniversalAudio._play_back()



func _on_delete_pressed():
	DirAccess.remove_absolute("user://saves/" + selectedSaveSlot + "/playerData.json")
	DirAccess.remove_absolute("user://saves/" + selectedSaveSlot + "/objectDatabase.json")
	DirAccess.remove_absolute("user://saves/" + selectedSaveSlot + "/npcDatabase.json")
	DirAccess.remove_absolute("user://saves/" + selectedSaveSlot + "/areaDatabase.json")
	DirAccess.remove_absolute("user://saves/" + selectedSaveSlot)
	$menuOptions/animationPlayer.play("hide")
	for i in get_tree().get_nodes_in_group("saveSlot"):
		i.focus_mode = FOCUS_ALL
	$menuOptions/back.focus_mode = FOCUS_NONE
	$menuOptions/load.focus_mode = FOCUS_NONE
	$menuOptions/delete.focus_mode = FOCUS_NONE
	setUpSaveScreen()


func _on_back_pressed():
	$menuOptions/animationPlayer.play("hide")
	for i in get_tree().get_nodes_in_group("saveSlot"):
		i.focus_mode = FOCUS_ALL
	$menuOptions/back.focus_mode = FOCUS_NONE
	$menuOptions/load.focus_mode = FOCUS_NONE
	$menuOptions/delete.focus_mode = FOCUS_NONE
	UniversalAudio._play_back()
	setUpSaveScreen()


func _on_load_pressed():
	loadSaveFile("user://saves/" + selectedSaveSlot)
