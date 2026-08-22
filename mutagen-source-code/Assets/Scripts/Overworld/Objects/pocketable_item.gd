extends Node2D
@export var ID := 0
@export var taken := false
@export var itemID := "driedMeat"
@export var quantity := 2
@export var announcement := "[PLAYERNAME] found [QUANTITY] piece[PLURALIZER] of Dried Meat."
@export var result := "Dried Meat has been added to your inventory."
@export var ammo := false
@export var armor := false
@export var armorType := ""
@export var resultSFX := "res://Assets/Sounds/Item/item.mp3"
@export var announcementSFX := ""
var lineOfSight := false

func _ready():
	initializeRoom()
	if validateID() == false:
		ActorHelper.objectDatabase[PlayerDb.playerData["player"]["currentArea"]][PlayerDb.playerData["player"]["currentRoom"]][ID] = {
			"taken" : taken,
			"item" : itemID,
			"quantity" : quantity,
			"announcement": announcement,
			"result": result,
			"ammo": ammo,
			"armor": armor,
			"armorType": armorType,
			"resultSFX": resultSFX,
			"announcementSFX": announcementSFX,
		}

func _process(delta):
	if validateID() == true:
		if ActorHelper.objectDatabase[PlayerDb.playerData["player"]["currentArea"]][PlayerDb.playerData["player"]["currentRoom"]][ID]["taken"] == true and taken == false:
			taken = true
			$animatedSprite2d.play("taken")
		
	if Input.is_action_just_pressed("Interact") and lineOfSight == true and not taken:
		ActorHelper.pickUpItem(ID)
		ActorHelper.objectDatabase[PlayerDb.playerData["player"]["currentArea"]][PlayerDb.playerData["player"]["currentRoom"]][ID]["taken"] = true

func _on_area_2d_body_entered(body):
	if body.is_in_group("playerBody"):
		lineOfSight = true


func _on_area_2d_body_exited(body):
	if body.is_in_group("playerBody"):
		lineOfSight = false

func validateID():
	if ActorHelper.objectDatabase.has(PlayerDb.playerData["player"]["currentArea"]):
		if ActorHelper.objectDatabase[PlayerDb.playerData["player"]["currentArea"]].has(PlayerDb.playerData["player"]["currentRoom"]):
			if ActorHelper.objectDatabase[PlayerDb.playerData["player"]["currentArea"]][PlayerDb.playerData["player"]["currentRoom"]].has(ID):
				return true
			else:
				return false
		else:
			return false
	else:
		return false

func initializeRoom():
	var area = PlayerDb.playerData["player"]["currentArea"]
	var room = PlayerDb.playerData["player"]["currentRoom"]
	if not ActorHelper.objectDatabase.has(area):
		ActorHelper.objectDatabase[area] = {}
	if not ActorHelper.objectDatabase[area].has(room):
		ActorHelper.objectDatabase[area][room] = {}
