extends Button
@export var saveFile := ""
@export var autosave := false
@export var createFile := true
signal slotClicked(saveFile, createFile)

func _on_pressed():
	slotClicked.emit(saveFile, createFile)
