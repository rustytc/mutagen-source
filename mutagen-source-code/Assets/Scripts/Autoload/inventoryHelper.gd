extends Node
var helpMenu : Control = null
var playerData : Dictionary = PlayerDb.playerData

func updateWeaponDatabases():
	if playerData != null:
		for i in GlobalDb.weaponDatabase:
			if GlobalDb.weaponDatabase[i]["type"] == "ranged":
				GlobalDb.weaponDatabase[i]["statDescription"] = GlobalDb.weaponDatabase[i]["statDescriptionPlaceholder"].replace("[AMMOVALUE]", str(playerData["player"]["weapons"][i]["ammo"]))
	


# Player Menu Functions

func getAmmo(WEAPONNAME, alt = false):
	match alt:
		false: return playerData["player"]["ammo"][GlobalDb.weaponDatabase[WEAPONNAME]["ammoType"]]
		true: return playerData["player"]["ammo"][GlobalDb.weaponDatabase[WEAPONNAME]["ammoTypeAlt"]]

func getLoadedAmmo(WEAPONNAME):
	return playerData["player"]["weapons"][WEAPONNAME]["ammo"]

func getAmmoType(WEAPONNAME, alt = false):
	match alt:
		false: return GlobalDb.weaponDatabase[WEAPONNAME]["ammoType"]
		true: return GlobalDb.weaponDatabase[WEAPONNAME]["ammoTypeAlt"]
	

func reload(WEAPONNAME, ammoType = null): # weapon's name must be provided! because of menus and stuff using different variables to check
	if GlobalDb.weaponDatabase[WEAPONNAME]["ammoAlternation"] == false:
		if Global.currentScreen == "world":
			UniversalAudio.playSpecialSound("res://Assets/Sounds/Battle/" + WEAPONNAME + "Reload.mp3")
		if playerData["player"]["weapons"][WEAPONNAME]["ammo"] != GlobalDb.weaponDatabase[WEAPONNAME]["maxAmmo"] and playerData["player"]["weapons"][WEAPONNAME]["packs"] > 0:
			playerData["player"]["weapons"][WEAPONNAME]["packs"] -= 1
			playerData["player"]["weapons"][WEAPONNAME]["ammo"] = GlobalDb.weaponDatabase[WEAPONNAME]["maxAmmo"]
			updateWeaponDatabases()
		else:
			UniversalAudio._play_error()
	if GlobalDb.weaponDatabase[WEAPONNAME]["ammoAlternation"] == true and ammoType == GlobalDb.weaponDatabase[WEAPONNAME]["ammoType"]:
		CowTools.dial(clamp(playerData["player"]["ammo"][(GlobalDb.weaponDatabase[WEAPONNAME]["ammoType"])], 0, GlobalDb.weaponDatabase[WEAPONNAME]["maxAmmo"] - playerData["player"]["ammo"][(GlobalDb.weaponDatabase[WEAPONNAME]["ammoType"])]), helpMenu.get_node("ammoSlider/Dial"))
		helpMenu.disable_decisionList()
		helpMenu.enable_ammo_slider()
		helpMenu.selectedAmmo = GlobalDb.weaponDatabase[WEAPONNAME]["ammoType"] # pulling from helpmenu could cause problems if another menu utilizes reloading
	elif GlobalDb.weaponDatabase[WEAPONNAME]["ammoAlternation"] == true and ammoType == GlobalDb.weaponDatabase[WEAPONNAME]["ammoTypeAlt"]:
		CowTools.dial(clamp(playerData["player"]["ammo"][(GlobalDb.weaponDatabase[WEAPONNAME]["ammoTypeAlt"])], 0, GlobalDb.weaponDatabase[WEAPONNAME]["maxAmmo"] - playerData["player"]["ammo"][(GlobalDb.weaponDatabase[WEAPONNAME]["ammoTypeAlt"])]), helpMenu.get_node("ammoSlider/Dial"))
		helpMenu.disable_decisionList()
		helpMenu.enable_ammo_slider()
		helpMenu.selectedAmmo = GlobalDb.weaponDatabase[WEAPONNAME]["ammoTypeAlt"]
	helpMenu.updateWeaponDescriptions()
func confirmSpecialReload(quantity): # get_parsed_text() takes out the bbcode [center]
	var WEAPONNAME = playerData["player"]["body"]["weapon"]
	if helpMenu != null: # this messes up modularity if theres going to be other reload menus. #TODO: add other reload menus here if necessary
		if quantity != 0:
			playerData["player"]["weapons"][helpMenu.weaponIDHolder]["ammo"] += quantity
			playerData["player"]["ammo"][helpMenu.selectedAmmo] -= quantity
			var loop = quantity
			while loop > 0:
				loop -= 1 # ok isnt it really funny that godot has a function to capitalize the first letter of a string but doesnt let you multiply strings so we need this whole loop to be here
				playerData["player"]["weapons"][helpMenu.weaponIDHolder]["ammoOrder"].append((helpMenu.selectedAmmo).substr(0, 1).capitalize())
				
				# this is kind of brittle. nested ifs
				if helpMenu.selectedAmmo == GlobalDb.weaponDatabase[helpMenu.weaponIDHolder]["ammoTypeAlt"]:
					playerData["player"]["weapons"][helpMenu.weaponIDHolder]["loadOrder"].append("alt")
				else:
					playerData["player"]["weapons"][helpMenu.weaponIDHolder]["loadOrder"].append("std")
			if Global.currentScreen == "world":
				UniversalAudio.playSpecialSound("res://Assets/Sounds/Battle/" + helpMenu.weaponIDHolder + "Reload.mp3") # reload sound effect
			updateWeaponDatabases()
			helpMenu.updateWeaponDescriptions()
	
func ammoDump(WEAPONNAME):
	playerData["player"]["weapons"][WEAPONNAME]["ammo"] = 0
	playerData["player"]["weapons"][WEAPONNAME]["ammoOrder"] = []
	playerData["player"]["weapons"][WEAPONNAME]["loadOrder"] = []
	
func ammoEject(WEAPONNAME, amount = 1, sound = true):
	if playerData["player"]["weapons"][WEAPONNAME]["ammo"] > 0:
		playerData["player"]["weapons"][WEAPONNAME]["ammo"] -= amount
		if playerData["player"]["weapons"][WEAPONNAME].has("ammoOrder"):
			while amount > 0:
				playerData["player"]["weapons"][WEAPONNAME]["ammoOrder"].remove_at(0)
				playerData["player"]["weapons"][WEAPONNAME]["loadOrder"].remove_at(0)
				amount -= 1
	if GlobalDb.weaponDatabase[WEAPONNAME]["singleUse"] == true:
		playerData["player"]["weapons"][WEAPONNAME]["quantity"] -= amount
	if sound == true:
		UniversalAudio.playSpecialSound("res://Assets/Sounds/Battle/" + WEAPONNAME + "Eject.mp3")
	InventoryHelper.updateWeaponDatabases()
	helpMenu.updateWeaponDescriptions()

		
func tossItem(ITEMNAME):
	if GlobalDb.itemDatabase[ITEMNAME]["general"]["disposable"] == true and  playerData["player"]["inventory"][ITEMNAME]["key"] == false:
		if playerData["player"]["inventory"][ITEMNAME]["quantity"] < 2:
			deleteItem(ITEMNAME)
			UniversalAudio.playSpecialSound("res://Assets/Sounds/Item/toss.mp3")
		else:
			return
func deleteItem(ITEMNAME):
	playerData["player"]["inventory"].erase(ITEMNAME)
func deleteArmor(ARMORNAME):
	if ARMORNAME.begins_with("headArmor"):
		if playerData["player"]["armor"]["head"][ARMORNAME]["equipped"] == true:
			playerData["player"]["armor"]["head"][ARMORNAME]["equipped"] = false
			playerData["player"]["stats"]["headArmorDefense"] = 0
			playerData["player"]["stats"]["compoundDefense"] = playerData["player"]["stats"]["headArmorDefense"] + playerData["player"]["stats"]["bodyArmorDefense"] + playerData["player"]["stats"]["baseDefense"]
		playerData["player"]["armor"]["head"].erase(ARMORNAME)
	else:
		if playerData["player"]["armor"]["body"][ARMORNAME]["equipped"] == true:
			playerData["player"]["armor"]["body"][ARMORNAME]["equipped"] = false
			playerData["player"]["stats"]["bodyArmorDefense"] = 0
			playerData["player"]["stats"]["compoundDefense"] = playerData["player"]["stats"]["headArmorDefense"] + playerData["player"]["stats"]["bodyArmorDefense"] + playerData["player"]["stats"]["baseDefense"]
		playerData["player"]["armor"]["body"].erase(ARMORNAME)

func findEquippedWeapon():
	for i in playerData["player"]["weapons"]:
		if playerData["player"]["weapons"][i]["equipped"] == "true":
			return i
			
func findEquippedWeaponType():
	for i in playerData["player"]["weapons"]:
		if playerData["player"]["weapons"][i]["equipped"] == "true":
			return GlobalDb.weaponDatabase[i]["type"]
			
func findEquippedWeaponAmmo():
	for i in playerData["player"]["weapons"]:
		if playerData["player"]["weapons"][i]["equipped"] == "true":
			if GlobalDb.weaponDatabase[i]["singleUse"] == false:
				return playerData["player"]["weapons"][i]["ammo"]
			else:
				return playerData["player"]["weapons"][i]["quantity"]
