extends Node
# Cow Tools: Helper functions for stupid things like UI which make code less redundant

var defaultMenuItems := {}

func populateItemList(menu, values = null): # populates an itemlist from a dictionary. Made specifically for dictionaries meant to be converted into menus
	if values == null:
		values = defaultMenuItems[menu] # if no values are specified, the default list items will be pulled
	if menu is ItemList:
		for i in values: # NOTE you just added metadata to itemlists so that the metadata can be read each time an action is called from it (such as reloading and needing to get the chosen ammo)
			var item = menu.add_item(values[i]["text"], values[i]["icon"], values[i]["selectable"])
			if values[i].has("meta"): # adding metadata
				menu.set_item_metadata(item, values[i]["meta"]) # metadata is a dictionary
				
	disableTooltips(menu)


func generateItemListFromDictAndDB(menu, dictionary, textValueDictionary): # populates an itemlist based on a dictionary and a database (not pre-generated)
	for i in dictionary:
		menu.add_item(textValueDictionary[i]["name"])
	disableTooltips(menu)
		
func populateItemListDirect(menu, values = null, icon = null, selectable = true): # populates an itemlist from literal key names, no special icons unless specified. Ideal for direct conversion of dictionaries or arrays to a clean list
	if values == null:
		values = defaultMenuItems[menu] # if no values are specified, the default list items will be pulled
	if menu is ItemList:
		for i in values:
			menu.add_item(i, icon, selectable)
	disableTooltips(menu)
	
		
func populateItemListDirectWithMeta(menu, values = null, icon = null, selectable = true):
	if values == null:
		values = defaultMenuItems[menu]

	if menu is ItemList:
		for i in values:
			var item = menu.add_item(i["text"], icon, selectable)
			menu.set_item_metadata(item, i["meta"])

	disableTooltips(menu)
	
func populateBattleEnemyList(menu, enemyDict):
	clearItemList(menu)
	populateItemListDirect(menu, ["< Back"], null, true)
	var enemyItems = []
	for i in enemyDict.keys():
		var distance = enemyDict[i].get("distance", "mid")
		enemyItems.append({
			"text": "%s [%s]" % [i, distance.capitalize()],
			"meta": i
		})
	populateItemListDirectWithMeta(menu, enemyItems)

		
func clearItemList(menu):
	menu.clear()

func disableTooltips(menu):
	var i = 0
	while i < menu.get_item_count():
		menu.set_item_tooltip(i, " ")
		menu.set_item_tooltip_enabled(i, false)
		i += 1

func getCurrentItemByID(item:String, type:String): # finds the relative ID for a menu item
	match type:
		"weapon":
			for i in GlobalDb.weaponDatabase:
				item = item.replace(" (Equipped)", "")
				if GlobalDb.weaponDatabase[i]["name"] == item:
					# ID always corresponds to the key's name
					return(i)
		"item":
			for i in GlobalDb.itemDatabase:
				if GlobalDb.itemDatabase[i]["general"]["name"] == item:
					return(i)
		"gear":
			for i in GlobalDb.gearDatabase:
				if GlobalDb.gearDatabase[i]["name"] == item:
					return(i)
		"headArmor":
			for i in GlobalDb.armorDatabase:
				item = item.replace(" (Equipped)", "")
				if ("head" in i) and (GlobalDb.armorDatabase[i]["name"] == item):
					return(i.replace("head_", ""))
		"bodyArmor":
			for i in GlobalDb.armorDatabase:
				item = item.replace(" (Equipped)", "")
				if ("body" in i) and (GlobalDb.armorDatabase[i]["name"] == item):
					return(i.replace("body_", ""))

func get_position_of_tree_column(tree:Tree, column: int = 0) -> Vector2:
	var item = tree.get_selected()
	if not item:
		return Vector2.ZERO
	var rect := tree.get_item_area_rect(item, column)
	return tree.to_global(rect.position)

func dial(max, dialNode):
	dialNode.currentTick = 0
	dialNode.get_child(1).rotation = 0
	dialNode.ticks = max
	
