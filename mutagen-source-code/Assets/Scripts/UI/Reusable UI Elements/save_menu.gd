extends Control
var saveSlot = preload("res://Assets/Scenes/UI/Reusable UI Elements/saveSlot.tscn")
var saveFileDirectory = null
var mode := "save"
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
	mode = "save"
	for i in get_tree().get_nodes_in_group("saveSlot"):
		i.queue_free()
	
	$savetext.show()
	var slot = saveSlot.instantiate()
	slot.slotClicked.connect(saveSlotClicked)
	slot.text = "Create New Save Slot"
	slot.get_node("icon").texture = null
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
	for i in get_tree().get_nodes_in_group("saveSlot"):
		if i.createFile:
			i.grab_focus() # this makes the first slot highlighted when the screen initiates
func createSaveFile():
	var time = Time.get_datetime_string_from_system()
	DirAccess.make_dir_absolute("user://saves/" + str(time).replace(":","_"))
	writeSaveData("user://saves/" + str(time).replace(":","_"))
	
func saveSlotClicked(saveFile, createFile):
	if createFile:
		createSaveFile()
		setUpSaveScreen()
	else:
		$menuOptions/animationPlayer.play("appear")
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
	
