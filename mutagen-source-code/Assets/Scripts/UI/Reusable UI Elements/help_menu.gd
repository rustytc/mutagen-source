extends Control

@export var currentMenu := "weapons"
var currentSubMenu := ""
var previousMenu := "weapons"
var hoveredMenu := "weapons"
var hoveredWeapon := ""
var hoveredItem := ""
var hoveredArmor := ""
var hoveredGear := ""
var readied := false

# reloading from the global autoload
var selectedAmmo = null
var selectedAmmoType := ""

@onready var player := get_tree().get_nodes_in_group("playerBody")[0]

var weaponIDHolder := ""
var itemIDHolder := ""
var armorIDHolder := ""
var gearIDHolder := ""

signal limbPicked(limb, hide)
signal battleMoveDecided

# Called when the node enters the scene tree for the first time.
func _ready():
	
	Global.helpMenu = self # defines itself on the start of each screen as to avoid global.gd referencing an older instance of helpMenu
	InventoryHelper.helpMenu = self
	# Setting the size of the help menu/tab container
	$Tabs.clip_tabs = true # this must be on or else godot will force the tab container to be 3000 feet long to compensate for invisible tabs
	$Tabs.use_hidden_tabs_for_min_size = false # Not necessary, but probably teaches tab container a lesson about its previous mistake
	$Tabs.size = Vector2(624,136) # Sets the size of the tab container to the CORRECT size (after it gets tampered with by our lovely friend godot)
	
	
	# Setting menu variables to account for specific menu ordering (depending on which screen we're on, the first menu could either be Weapons or Actions)
	#TODO: don't forget to ALWAYS set this currentScreen variable when you config battle screens and switch back to the world scenes. If not, that could break UI
	if Global.currentScreen == "world":
		currentMenu = "weapons"
		previousMenu = "weapons"
		hoveredMenu = "weapons"
	else:
		
		currentMenu = "action"
		previousMenu = "action"
		hoveredMenu = "action"
		$Tabs/Action/actionList.grab_focus()
		
	
	
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	# Hiding specific tabs that aren't supposed to be user-accessible
	if Global.currentScreen == "world":
		$Tabs.set_tab_disabled(0, true)
		$Tabs.set_tab_hidden(0, true)
		$Tabs.set_tab_disabled(1, true)
		$Tabs.set_tab_hidden(1, true)
		$Tabs.set_tab_disabled(2, true) #enemy picker
		$Tabs.set_tab_hidden(2, true)
		$Tabs.set_tab_disabled(3, true) #limb picker
		$Tabs.set_tab_hidden(3, true)
		$Tabs.set_tab_disabled(4, true) #distance picker
		$Tabs.set_tab_hidden(4, true)
		$Tabs.current_tab = 5 # sets the tab to "weapons"
	else:
		$Tabs.set_tab_disabled(0, true)
		$Tabs.set_tab_hidden(0, true)
		$Tabs.set_tab_disabled(7, true) # stats
		$Tabs.set_tab_hidden(7, true)
		$Tabs.set_tab_disabled(8, true) # skills
		$Tabs.set_tab_hidden(8, true)
		$Tabs.set_tab_disabled(9, true) # radio
		$Tabs.set_tab_hidden(9, true)
		$Tabs.set_tab_disabled(2, true)
		$Tabs.set_tab_hidden(2, true)
		$Tabs.set_tab_disabled(3, true)
		$Tabs.set_tab_hidden(3, true)
		$Tabs.set_tab_hidden(4, true)
		$Tabs.set_tab_disabled(11, true) #system
		$Tabs.set_tab_hidden(11, true)
		$Tabs.current_tab = 1 # sets the tab to "Action"
	readied = true
	createWeaponDescriptions()
	updateWeaponDescriptions()
	createItemDescriptions()
	updateItemDescriptions()
	createArmorDescriptions()
	updateArmorDescriptions()
	createGearDescriptions()
	updateGearDescriptions()
	
	# Setting properties of the tabs (this disappeared from the code (probably highlighted and deleted by accident,)) so some of it might be messed up
	$Tabs/Weapons/weaponsList.scroll_horizontal_enabled = false
	$Tabs/Items/itemsList.scroll_horizontal_enabled = false
	$Tabs/Gear/gearList.scroll_horizontal_enabled = false
	#$Tabs.get_tab_bar().mouse_filter = MOUSE_FILTER_IGNORE originally I had these turned off because they broke the tab bar, but thats no longer an issue
	
	$Tabs/Weapons/weaponsList.focus_mode = Control.FOCUS_ALL
	#$Tabs/Weapons/weaponsList.mouse_filter = MOUSE_FILTER_IGNORE
	$Tabs/Weapons/weaponsList.select_mode = Tree.SELECT_ROW
	$Tabs/Items/itemsList.select_mode = Tree.SELECT_ROW
	$Tabs/Gear/gearList.select_mode = Tree.SELECT_ROW
	$Tabs/Armor/bodyArmorList.focus_mode = Control.FOCUS_ALL
	#$Tabs/Armor/bodyArmorList.mouse_filter = MOUSE_FILTER_IGNORE
	$Tabs/Armor/bodyArmorList.select_mode = Tree.SELECT_ROW
	$Tabs/Armor/headArmorList.focus_mode = Control.FOCUS_ALL
	#$Tabs/Armor/headArmorList.mouse_filter = MOUSE_FILTER_IGNORE
	$Tabs/Armor/headArmorList.select_mode = Tree.SELECT_ROW
	
	#might as well turn these off because they dont play nice with sizing
	$Tabs/Weapons/weaponsList.add_theme_constant_override("draw_guides", 0)
	$Tabs/Items/itemsList.add_theme_constant_override("draw_guides", 0)
	$Tabs/Gear/gearList.add_theme_constant_override("draw_guides", 0)
	$Tabs/Armor/bodyArmorList.add_theme_constant_override("draw_guides", 0)
	$Tabs/Armor/headArmorList.add_theme_constant_override("draw_guides", 0)
	$Tabs/Stats/statsList.add_theme_color_override("guide_color", Color(0, 0, 0, 0))
	$Tabs/Radio/radioList.add_theme_color_override("guide_color", Color(0, 0, 0, 0))
	$Tabs/System/systemList.add_theme_color_override("guide_color", Color(0, 0, 0, 0))
	$Tabs/Action/actionList.add_theme_color_override("guide_color", Color(0, 0, 0, 0))
	$Tabs/attackWho/enemyList.add_theme_color_override("guide_color", Color(0, 0, 0, 0))
	$Tabs/limbPicker/limbList.add_theme_color_override("guide_color", Color(0, 0, 0, 0))
	$Tabs/distancePicker/distanceList.add_theme_color_override("guide_color", Color(0, 0, 0, 0))
	
	
func _on_tabs_tab_selected(tab):
	hoveredMenu = $Tabs.get_tab_title($Tabs.current_tab).to_lower().replace(" ", "") # hacky, I know. it works effectively, though
	previousMenu = currentMenu
	currentMenu = hoveredMenu

func _on_action_menu_visibility_changed(): # giving touch focus to and back from the tabs when the action menu is selected
	if $actionMenu.visible == true:
		$Tabs/Weapons/weaponsList.mouse_filter = MOUSE_FILTER_IGNORE
		$Tabs/Items/itemsList.mouse_filter = MOUSE_FILTER_IGNORE
		$Tabs/Gear/gearList.mouse_filter = MOUSE_FILTER_IGNORE
		$Tabs/Armor/headArmorList.mouse_filter = MOUSE_FILTER_IGNORE
		$Tabs/Armor/bodyArmorList.mouse_filter = MOUSE_FILTER_IGNORE
		$Tabs.get_tab_bar().mouse_filter = MOUSE_FILTER_IGNORE
		$actionMenu/actionsTab/decisionsList.mouse_filter = MOUSE_FILTER_STOP
	if $actionMenu.visible == false:
		$Tabs/Weapons/weaponsList.mouse_filter = MOUSE_FILTER_STOP
		$Tabs/Items/itemsList.mouse_filter = MOUSE_FILTER_STOP
		$Tabs/Gear/gearList.mouse_filter = MOUSE_FILTER_STOP
		$Tabs/Armor/headArmorList.mouse_filter = MOUSE_FILTER_STOP
		$Tabs/Armor/bodyArmorList.mouse_filter = MOUSE_FILTER_STOP
		$actionMenu/actionsTab/decisionsList.mouse_filter = MOUSE_FILTER_IGNORE
		$Tabs.get_tab_bar().mouse_filter = MOUSE_FILTER_STOP


func _on_weapons_list_item_activated():
	UniversalAudio.playSpecialSound("res://Assets/Sounds/UI/click.mp3")
	
	if readied == true:
		
		var weaponsList = $Tabs/Weapons/weaponsList # this defines weaponsList. only runs
		# if readied because you cannot assign an object until it is initialized, and without
		#this check the game would crash. could be touched up later TODO
		
		# Selecting an item
		if weaponsList.get_selected_column() == 0:
			hoveredWeapon = str(weaponsList.get_selected().get_text(0)).replace(" (Equipped)", "")
			weaponIDHolder = (CowTools.getCurrentItemByID(hoveredWeapon, "weapon"))
			
			if GlobalDb.weaponDatabase[weaponIDHolder].has("maxAmmo") and GlobalDb.weaponDatabase[weaponIDHolder]["ammoAlternation"] == false:
				CowTools.clearItemList($actionMenu/actionsTab/decisionsList)
				CowTools.populateItemList($actionMenu/actionsTab/decisionsList, {"Shoot" : {
					"icon" : null,
					"selectable" : true,
					"text" : "> Equip",
				},
				"Reload" : {
					"icon" : null,
					"selectable" : true,
					"text" : "> Reload",
				},
				"Info" : {
					"icon" : null,
					"selectable" : true,
					"text" : "> Info",
				},
				"Back" : {
					"icon" : null,
					"selectable" : true,
					"text" : "< Back",
				},
				
				})
				$actionMenu/actionsTab/decisionsList.size.x = 76
				$actionMenu.size.y = 112
				$actionMenu.size.x = 96
			elif GlobalDb.weaponDatabase[weaponIDHolder].has("maxAmmo") and GlobalDb.weaponDatabase[weaponIDHolder]["ammoAlternation"] == true:
				CowTools.clearItemList($actionMenu/actionsTab/decisionsList)
				CowTools.populateItemList($actionMenu/actionsTab/decisionsList, {"Shoot" : {
					"icon" : null,
					"selectable" : true,
					"text" : "> Equip",
				},
				"Reload" : {
					"icon" : null,
					"selectable" : true,
					"text" : "> Reload" + " " + GlobalDb.weaponDatabase[weaponIDHolder]["ammoType"].capitalize(),
					"meta" : {
						"type" : "std"
					}
				},
				"Reload Alt" : {
					"icon" : null,
					"selectable" : true,
					"text" : "> Reload" + " " + GlobalDb.weaponDatabase[weaponIDHolder]["ammoTypeAlt"].capitalize(),
					"meta" : {
						"type" : "alt"
					}
				},
				"Eject" : {
					"icon" : null,
					"selectable" : true,
					"text" : "> Eject 1 Shell",
				},
				"Info" : {
					"icon" : null,
					"selectable" : true,
					"text" : "> Info",
				},
				"Back" : {
					"icon" : null,
					"selectable" : true,
					"text" : "< Back",
				},
				
				})
				$actionMenu.size.x = 160
				$actionMenu/actionsTab/decisionsList.size.x = 144
				$actionMenu.size.y = 144
			else:
				CowTools.clearItemList($actionMenu/actionsTab/decisionsList)
				CowTools.populateItemList($actionMenu/actionsTab/decisionsList, {"Use" : {
					"icon" : null,
					"selectable" : true,
					"text" : "> Equip",
					
				},
				"Info" : {
					"icon" : null,
					"selectable" : true,
					"text" : "> Info",
				},
				"Back" : {
					"icon" : null,
					"selectable" : true,
					"text" : "< Back",
				}
				
				})
				$actionMenu.size.x = 96
				$actionMenu.size.y = 96
				$actionMenu/actionsTab/decisionsList.size.x = 76
				
				
			$actionMenu.show()
			var list = $Tabs/Weapons/weaponsList
			var rectangle: Rect2 = list.get_item_area_rect(list.get_selected(), 0)
			
			var menuOffset = Vector2(200, round($actionMenu.size.y * 2/-3.8) - 16) #TODO this equation is kind of clunky and you might want to change it later
			var scrollOffset = Vector2(0, list.get_scroll().y)
			$actionMenu.global_position = list.get_global_position() + rectangle.position + menuOffset - scrollOffset - (Vector2(0, list.get_global_position().y * 0.1))
			drop_tab_focus()

					
	updateWeaponDescriptions()
				

func _on_items_list_item_activated():
	
	UniversalAudio.playSpecialSound("res://Assets/Sounds/UI/click.mp3")
	
	if readied == true:
		
		
		
		var itemsList = $Tabs/Items/itemsList

		
		# Selecting an item
		if itemsList.get_selected_column() == 0:
			
			
			for i in PlayerDb.playerData["player"]["inventory"]: # checks the player's inventory for all possibly equipped weapons
				if itemsList.get_selected() == null: # a check in case that the item the player is currently hovering is getting deleted
					continue
				else:
					
					hoveredItem = str(itemsList.get_selected().get_text(0))
					itemIDHolder = (CowTools.getCurrentItemByID(hoveredItem, "item"))
					
					var options = {"Use" : {
							"icon" : null,
							"selectable" : true,
							"text" : "> Use",
						},
						"Info" : {
							"icon" : null,
							"selectable" : true,
							"text" : "> Info",
						}, }
						
					if PlayerDb.playerData["player"]["inventory"][itemIDHolder]["bookmarked"] == true:
						options["Unbookmark"] = {
							"icon" : null,
							"selectable" : true,
							"text" : "> Unsave",
						}
					else:
						options["Bookmark"] = {
							"icon" : null,
							"selectable" : true,
							"text" : "> Save",
						}
					
					if GlobalDb.itemDatabase[itemIDHolder]["general"]["key"] != true:
						options["Toss"] = {
							"icon" : null,
							"selectable" : true,
							"text" : "< Toss",
						}
						
					options["Back"] = {
							"icon" : null,
							"selectable" : true,
							"text" : "< Back",
						}
						
					if GlobalDb.itemDatabase[itemIDHolder]["general"]["key"] != true:
						$actionMenu.size.y = 128
					else:
						$actionMenu.size.y = 112
					
					CowTools.clearItemList($actionMenu/actionsTab/decisionsList)
					CowTools.populateItemList($actionMenu/actionsTab/decisionsList, options)
					
					
					$actionMenu.show()
					var list = $Tabs/Items/itemsList
					var rectangle: Rect2 = list.get_item_area_rect(list.get_selected(), 0)
					
					var menuOffset = Vector2(200, -96)
					var scrollOffset = Vector2(0, list.get_scroll().y)
					$actionMenu.global_position = list.get_global_position() + rectangle.position + menuOffset - scrollOffset
					drop_tab_focus()
					
	
		updateItemDescriptions()

func createWeaponDescriptions(): # cant be made into a cow tool because of specific parameters
	
	$Tabs/Weapons/weaponsList.set_column_custom_minimum_width(0,128) # custom width for certain columns
	$Tabs/Weapons/weaponsList.set_column_custom_minimum_width(1,64)
	$Tabs/Weapons/weaponsList.set_column_custom_minimum_width(2,512)
	
	var weaponsList = $Tabs/Weapons/weaponsList
	var root = weaponsList.get_root()
	if root == null:
		root = weaponsList.create_item()
		weaponsList.set_hide_root(true)
	weaponsList.columns = 3
	
	for i in PlayerDb.playerData["player"]["weapons"]:
		if PlayerDb.playerData["player"]["weapons"][i]["unlocked"] == true and PlayerDb.playerData["player"]["weapons"][i]["quantity"] > 0:
			var row = weaponsList.create_item(root)
			
			row.set_icon(0, load("res://Assets/Images/Sprites/UI/Menu/Icons/Armory/" + i + ".png"))
			row.set_icon_max_width(0, 32)
			row.set_text(0, GlobalDb.weaponDatabase[i]["name"])
			row.set_icon_max_width(0, 32)
			row.set_meta("weapon",i)
			for c in range(weaponsList.columns):
				row.set_tooltip_text(c, " ") # if godot 4.3 had autotooltip I wouldnt need this thing
			
			
			if GlobalDb.weaponDatabase[i]["type"] == "ranged":
				if GlobalDb.weaponDatabase[i]["singleUse"] == false:
					if PlayerDb.playerData["player"]["weapons"][i].has("ammoOrder") == false:
						row.set_text(1, str(PlayerDb.playerData["player"]["weapons"][i]["ammo"]) + "/" + str(GlobalDb.weaponDatabase[i]["maxAmmo"]) + "    " + str(PlayerDb.playerData["player"]["ammo"][i]) + " Packs of Ammo")
						row.set_icon(1, load("res://Assets/Images/Sprites/UI/Menu/Icons/Armory/" + i + "Ammo.png"))
					else:
						# the following line of code is pretty long. also copy pasted from the other function funnily enough. old habits die even harder
						row.set_text(1, "[" + (str("".join(PlayerDb.playerData["player"]["weapons"][i]["ammoOrder"]))) + 
						("_").repeat((int(GlobalDb.weaponDatabase[i]["maxAmmo"] - 
						PlayerDb.playerData["player"]["weapons"][i]["ammo"]))) + "]    " + 
						str(PlayerDb.playerData["player"]["ammo"][(GlobalDb.weaponDatabase[i]["ammoType"])]) + " " +
						GlobalDb.weaponDatabase[i]["ammoType"].capitalize() + ", " + 
						str(PlayerDb.playerData["player"]["ammo"][(GlobalDb.weaponDatabase[i]["ammoTypeAlt"])])
						+ " " + GlobalDb.weaponDatabase[i]["ammoTypeAlt"].capitalize())
						row.set_icon(1, load("res://Assets/Images/Sprites/UI/Menu/Icons/Armory/" + i + "Ammo.png"))
					
				else:
					row.set_icon(1, load("res://Assets/Images/Sprites/UI/Menu/Icons/Armory/" + i + "Ammo.png"))
					if PlayerDb.playerData["player"]["weapons"][i]["quantity"] < 2:
						row.set_text(1, str(PlayerDb.playerData["player"]["weapons"][i]["quantity"]) + " Unit Left")
					else:
						row.set_text(1, str(PlayerDb.playerData["player"]["weapons"][i]["quantity"]) + " Units Left")
			else:
				row.set_text(1, "Melee")
				
			row.set_selectable(2, false)
			row.set_selectable(1, false)
			
			

func updateWeaponDescriptions():
	var weaponsList = $Tabs/Weapons/weaponsList
	var root = weaponsList.get_root()
	var row = root.get_first_child()
	var nextRow = null

	while row != null:
		nextRow = row.get_next()
		
		for i in PlayerDb.playerData["player"]["weapons"]:

			if row.get_meta("weapon") == i:
				
				# Checking conditions for weapons
				
				if PlayerDb.playerData["player"]["weapons"][i]["equipped"] == true:
					row.set_text(0, str(GlobalDb.weaponDatabase[i]["name"]) + " (Equipped)")
				else:
					row.set_text(0, str(GlobalDb.weaponDatabase[ i]["name"]))
				
				if PlayerDb.playerData["player"]["weapons"][i]["quantity"] < 1:
					row.free()
					InventoryHelper.deleteItem(i)
					break
					
					
				# this ammo update code is all copy pasted
				if GlobalDb.weaponDatabase[i]["type"] == "ranged":
					if GlobalDb.weaponDatabase[i]["singleUse"] == false:
						if PlayerDb.playerData["player"]["weapons"][i].has("ammoOrder") == false:
							row.set_text(1, str(PlayerDb.playerData["player"]["weapons"][i]["ammo"]) + "/" + str(GlobalDb.weaponDatabase[i]["maxAmmo"]) + "    " + str(PlayerDb.playerData["player"]["ammo"][i]) + " Packs of Ammo")
							row.set_icon(1, load("res://Assets/Images/Sprites/UI/Menu/Icons/Armory/" + i + "Ammo.png"))
						else:
							# the following line of code is pretty long. my ap csp teacher used to tell me to scrunch my code so it could be readable. old habits die hard
							row.set_text(1, "[" + (str("".join(PlayerDb.playerData["player"]["weapons"][i]["ammoOrder"]))) + 
							("_").repeat((int(GlobalDb.weaponDatabase[i]["maxAmmo"] - 
							PlayerDb.playerData["player"]["weapons"][i]["ammo"]))) + "]    " + 
							str(PlayerDb.playerData["player"]["ammo"][(GlobalDb.weaponDatabase[i]["ammoType"])]) + " " +
							 GlobalDb.weaponDatabase[i]["ammoType"].capitalize() + ", " + 
							str(PlayerDb.playerData["player"]["ammo"][(GlobalDb.weaponDatabase[i]["ammoTypeAlt"])])
							  + " " + GlobalDb.weaponDatabase[i]["ammoTypeAlt"].capitalize())
							row.set_icon(1, load("res://Assets/Images/Sprites/UI/Menu/Icons/Armory/" + i + "Ammo.png"))
						
						
					else:
						row.set_icon(1, load("res://Assets/Images/Sprites/UI/Menu/Icons/Armory/" + i + "Ammo.png"))
						if PlayerDb.playerData["player"]["weapons"][i]["quantity"] < 2:
							row.set_text(1, str(PlayerDb.playerData["player"]["weapons"][i]["quantity"]) + " Unit Left")
						else:
							row.set_text(1, str(PlayerDb.playerData["player"]["weapons"][i]["quantity"]) + " Units Left")
				else:
					row.set_text(1, "Melee")
					
				row.set_selectable(2, false)
				row.set_selectable(1, false)
				
		row = nextRow		
		
		
func createItemDescriptions(): # cant be made into a cow tool because of specific parameters
	
	var itemsList = $Tabs/Items/itemsList
	var root = itemsList.get_root()
	if root == null:
		root = itemsList.create_item()
		itemsList.set_hide_root(true)
	itemsList.columns = 3
	
	for i in PlayerDb.playerData["player"]["inventory"]:
			var row = itemsList.create_item(root)
			
			row.set_icon_max_width(0, 32)
			row.set_text(0, GlobalDb.itemDatabase[i]["general"]["name"]) # before this checked "keyItem_", but I removed that as it seemed useless
			row.set_icon_max_width(0, 32)
			row.set_meta("item",i)
			if PlayerDb.playerData["player"]["inventory"][i]["quantity"] > 1:
				row.set_text(2, "x" + str(PlayerDb.playerData["player"]["inventory"][i]["quantity"]))
			if GlobalDb.itemDatabase[i]["general"]["key"] == true:
				row.set_icon(1, load("res://Assets/Images/Sprites/UI/Menu/Icons/Inventory/key.png"))
			if PlayerDb.playerData["player"]["inventory"][i]["bookmarked"] == true:
				row.set_icon(0, load("res://Assets/Images/Sprites/UI/Menu/Icons/Inventory/star.png"))
				row.move_before(root.get_first_child())
			
			for c in range(itemsList.columns):
				row.set_tooltip_text(c, " ") # if godot 4.3 had autotooltip I wouldnt need this thing
			row.set_selectable(2, false)
			row.set_selectable(1, false)

func updateItemDescriptions():
	var itemsList = $Tabs/Items/itemsList
	var root = itemsList.get_root()
	var row = root.get_first_child()
	var nextRow = null

	while row != null:
		nextRow = row.get_next()
		
		for i in PlayerDb.playerData["player"]["inventory"]:

			if row.get_meta("item") == i:
				
				# Checking conditions for items
				
				if PlayerDb.playerData["player"]["inventory"][i]["quantity"] < 1:
					row.free()
					break
				elif PlayerDb.playerData["player"]["inventory"][i]["quantity"] > 1:
					row.set_text(2, "x" + str(PlayerDb.playerData["player"]["inventory"][i]["quantity"]))
				elif PlayerDb.playerData["player"]["inventory"][i]["quantity"] == 1:
					row.set_text(2, "")
					
				row.set_selectable(2, false)
				row.set_selectable(1, false)
				
			
		row = nextRow		
		
func resetItemDescriptions(): # necessary for changing item list order for bookmarks
	$Tabs/Items/itemsList.clear()
	createItemDescriptions()

func resetArmorDescriptions():
	$Tabs/Armor/headArmorList.clear()
	$Tabs/Armor/bodyArmorList.clear()
	createArmorDescriptions()

func createArmorDescriptions():
	var armorList = null
	var root = null

	for type in ["head", "body"]:
		match type:
			"head":
				armorList = $Tabs/Armor/headArmorList
				root = armorList.get_root()
			"body":
				armorList = $Tabs/Armor/bodyArmorList
				root = armorList.get_root()
			

		if root == null:
			root = armorList.create_item()
			armorList.set_hide_root(true)
		armorList.columns = 3
	
		for i in PlayerDb.playerData["player"]["armor"][type]:
				var row = armorList.create_item(root)
			
				row.set_text(0, GlobalDb.armorDatabase[type + "_" + i]["name"])
				row.set_meta("armor",i)
				row.set_text(1,str(GlobalDb.armorDatabase[type + "_" + i]["defense"]))
				row.set_custom_color(1, Color.YELLOW)
				row.set_text(2,str(str(PlayerDb.playerData["player"]["stats"][type + "ArmorDefense"]) + "->" + str(int(GlobalDb.armorDatabase[type + "_" + i]["defense"]))))
				if PlayerDb.playerData["player"]["stats"][type + "ArmorDefense"] <= GlobalDb.armorDatabase[type + "_" + i]["defense"]:
					row.set_custom_color(2, Color.GREEN)
				else:
					row.set_custom_color(2, Color.RED)
			
			
				for c in range(armorList.columns):
					row.set_tooltip_text(c, " ") # if godot 4.3 had autotooltip, again, I wouldnt need this thing
					
					#TODO: IF YOU SWITCH FROM GODOT 4.3 TO A LATER VERSION, GET RID OF THESE things. if not, keep them in :) there's several of them, by the way :(
			
		
				
				row.set_selectable(2, false)
				row.set_selectable(1, false)

func updateArmorDescriptions():
	# these get put here because putting them in the create function would just let them be overridden by this one, anyways.
	$Tabs/Armor/headArmorList.set_column_expand(0, true)
	$Tabs/Armor/headArmorList.set_column_expand(1, true)
	$Tabs/Armor/headArmorList.set_column_expand(2, true)
	#TODO youll probably want to tinker with these later
	$Tabs/Armor/headArmorList.set_column_expand_ratio(0, 14) # these ratios determine the sizes of each column in the tree. important for insuring they dont expand too much and clip outside of the box or override each other.
	$Tabs/Armor/headArmorList.set_column_expand_ratio(1, 2)
	$Tabs/Armor/headArmorList.set_column_expand_ratio(2, 5)

	$Tabs/Armor/bodyArmorList.set_column_expand(0, true)
	$Tabs/Armor/bodyArmorList.set_column_expand(1, true)
	$Tabs/Armor/bodyArmorList.set_column_expand(2, true)

	$Tabs/Armor/bodyArmorList.set_column_expand_ratio(0, 14)
	$Tabs/Armor/bodyArmorList.set_column_expand_ratio(1, 2)
	$Tabs/Armor/bodyArmorList.set_column_expand_ratio(2, 5)
	var armorListHead = $Tabs/Armor/headArmorList
	var armorListBody = $Tabs/Armor/bodyArmorList
	var rootHead = armorListHead.get_root()
	var rootBody = armorListBody.get_root()
	var rowHead = rootHead.get_first_child()
	var rowBody = rootBody.get_first_child()
	var nextRow = null

	while rowHead != null:
		nextRow = rowHead.get_next()
		
		for i in PlayerDb.playerData["player"]["armor"]["head"]:

			if rowHead.get_meta("armor") == i:
				
				# Checking conditions for weapons
				
				rowHead.set_text(2,str(str(PlayerDb.playerData["player"]["stats"]["headArmorDefense"]) + "->" + str(int(GlobalDb.armorDatabase["head_" + i]["defense"]))))
				if PlayerDb.playerData["player"]["stats"]["headArmorDefense"] <= GlobalDb.armorDatabase["head_" + i]["defense"]:
					rowHead.set_custom_color(2, Color.GREEN)
				else:
					rowHead.set_custom_color(2, Color.RED)
				
				if PlayerDb.playerData["player"]["armor"]["head"][i]["equipped"] == true:
					rowHead.set_text(0, str(GlobalDb.armorDatabase["head_" + i]["name"]) + " (Equipped)")
				else:
					rowHead.set_text(0, str(GlobalDb.armorDatabase["head_" + i]["name"]))
				
				if PlayerDb.playerData["player"]["armor"]["head"][i]["quantity"] < 1:
					rowHead.free()
					InventoryHelper.deleteItem(i)
				
					
		rowHead = nextRow
	while rowBody != null:
		nextRow = rowBody.get_next()
		
		for i in PlayerDb.playerData["player"]["armor"]["body"]:

			if rowBody.get_meta("armor") == i:
				
				# Checking conditions for weapons
				rowBody.set_text(2,str(str(PlayerDb.playerData["player"]["stats"]["bodyArmorDefense"]) + "->" + str(int(GlobalDb.armorDatabase["body_" + i]["defense"]))))
				if PlayerDb.playerData["player"]["stats"]["bodyArmorDefense"] <= GlobalDb.armorDatabase["body_" + i]["defense"]:
					rowBody.set_custom_color(2, Color.GREEN)
				else:
					rowBody.set_custom_color(2, Color.RED)
				if PlayerDb.playerData["player"]["armor"]["body"][i]["equipped"] == true:
					rowBody.set_text(0, str(GlobalDb.armorDatabase["body_" + i]["name"]) + " (Equipped)")
				else:
					rowBody.set_text(0, str(GlobalDb.armorDatabase["body_" + i]["name"]))
				
				if PlayerDb.playerData["player"]["armor"]["body"][i]["quantity"] < 1:
					rowBody.free()
					InventoryHelper.deleteItem(i)
				
					
		
		rowBody = nextRow
		
func createGearDescriptions():
	var gearList = $Tabs/Gear/gearList
	var root = gearList.get_root()

	if root == null:
		root = gearList.create_item()
		gearList.set_hide_root(true)
	gearList.columns = 1

	for i in PlayerDb.playerData["player"]["gear"]:
			var row = gearList.create_item(root)
		
			row.set_text(0, GlobalDb.gearDatabase[i]["name"])
			row.set_meta("gear",i)
			
			for c in range(gearList.columns):
				row.set_tooltip_text(c, " ") # if godot 4.3 had autotooltip, again again, I wouldnt need this thing
					
				
			row.set_selectable(2, false)
			row.set_selectable(1, false)

func updateGearDescriptions():
	#blatantly copy pasted from armor. I probably shouldve put them all inside of one single function,
	# and maybe ill do that when I go and refactor all the code
	#TODO
	
	# these get put here because putting them in the create function would just let them be overridden by this one, anyways.
	$Tabs/Gear/gearList.set_column_expand(0, true)
	var gearList = $Tabs/Gear/gearList
	var root = gearList.get_root()
	var row = root.get_first_child()
	var nextRow = null

	while row != null:
		nextRow = row.get_next()
		
		for i in PlayerDb.playerData["player"]["gear"]:

			if row.get_meta("gear") == i:
							
				if PlayerDb.playerData["player"]["gear"][i]["equipped"] == true:
					row.set_text(0, str(GlobalDb.gearDatabase[i]["name"]) + " (Equipped)")
				else:
					row.set_text(0, str(GlobalDb.gearDatabase[i]["name"]))							
		row = nextRow

func _on_decisions_list_item_activated(index):
	var ind = $actionMenu/actionsTab/decisionsList.get_item_text(index)
	# Re-enabling everything
	
	if "Back" in ind:
		exitActionMenu()
		UniversalAudio.playSpecialSound("res://Assets/Sounds/UI/scrape.mp3")
	elif "Equip" in ind:
		if currentMenu == "weapons":
			equipWeapon()
			updateWeaponDescriptions()
		elif currentMenu == "armor":
			equipArmor()
			updateArmorDescriptions()
			gain_tab_focus() # i have no idea why (its been a while since I wrote this originally) but these have to be inserted now because tabs lose focus when you equip or unequip armor
		elif currentMenu == "gear":
			equipGear()
			updateGearDescriptions()
			gain_tab_focus()
	elif "Unequip" in ind:
		if currentMenu == "armor":
			unequipArmor()
			updateArmorDescriptions()
			gain_tab_focus()
		else:
			unequipGear()
			updateGearDescriptions()
			gain_tab_focus()
	elif "Reload" in ind:
		if GlobalDb.weaponDatabase[weaponIDHolder]["ammoAlternation"] == true:
			if $actionMenu/actionsTab/decisionsList.get_item_metadata(index)["type"] == "std":
				callReload("alt", "std")
				selectedAmmoType = "std"
			else:
				callReload("alt", "alt")
				selectedAmmoType = "alt"
		else:
			callReload("std", "std")
			selectedAmmoType = "std"
	elif "Dump" in ind:
		InventoryHelper.ammoDump(weaponIDHolder)
		updateWeaponDescriptions()
	elif "Eject" in ind:
		InventoryHelper.ammoEject(weaponIDHolder)
		updateWeaponDescriptions()
	elif "Info" in ind:
		gain_tab_focus()
		$actionMenu.hide()
		$actionMenu.release_focus() # in case hiding it doesn't already work for some reason
		if currentMenu == "weapons":
			$Tabs/Weapons/weaponsList.grab_focus()
		elif currentMenu == "items":
			$Tabs/Items/itemsList.grab_focus()
		showDescription()
	elif "Use" in ind:
		release_item_use_focus()
		GameplayActions.useItem(itemIDHolder)
		updateItemDescriptions()
	elif "Toss" in ind: # Tossing out items does not take up a turn in combat (unusual, but intentional)
		if currentMenu == "items" and PlayerDb.playerData["player"]["inventory"][itemIDHolder]["quantity"] == 1:
			InventoryHelper.deleteItem(itemIDHolder)
			$Tabs/Items/itemsList.get_selected().free()
			UniversalAudio.playSpecialSound("res://Assets/Sounds/Item/toss.mp3")
			$actionMenu.hide()
			$actionMenu.release_focus()
			updateItemDescriptions()
			gain_tab_focus()
			$Tabs/Items/itemsList.grab_focus()
		elif currentMenu == "items" and PlayerDb.playerData["player"]["inventory"][itemIDHolder]["quantity"] > 1:
			CowTools.dial(PlayerDb.playerData["player"]["inventory"][itemIDHolder]["quantity"], $tossSlider/Dial)
			$tossSlider.show()
			drop_tab_focus()
			gain_toss_dial_focus()
		elif currentMenu == "armor" and PlayerDb.playerData["player"]["armor"][currentSubMenu][armorIDHolder]["quantity"] == 1:
			if PlayerDb.playerData["player"]["armor"][currentSubMenu].size() == 1:
				UniversalAudio.playSpecialSound("res://Assets/Sounds/UI/error.mp3")
				return
			else:
				InventoryHelper.deleteArmor(armorIDHolder)
				match currentSubMenu:
					"head":
						$Tabs/Armor/headArmorList.get_selected().free()
						$Tabs/Armor/headArmorList.grab_focus()
					"body":
						$Tabs/Armor/bodyArmorList.get_selected().free()
						$Tabs/Armor/headArmorList.grab_focus()
				UniversalAudio.playSpecialSound("res://Assets/Sounds/Item/toss.mp3")
				$actionMenu.hide()
				$actionMenu.release_focus()
				updateArmorDescriptions()
				gain_tab_focus()
	elif "Save" in ind:
		gain_tab_focus()
		$actionMenu.hide()
		$actionMenu.release_focus()
		if PlayerDb.playerData["player"]["inventory"][itemIDHolder]["bookmarked"] == false:
			PlayerDb.playerData["player"]["inventory"][itemIDHolder]["bookmarked"] = true
			resetItemDescriptions()
			$Tabs/Items/itemsList.grab_focus()
	elif "Unsave" in ind:
		gain_tab_focus()
		$actionMenu.hide()
		$actionMenu.release_focus()
		if PlayerDb.playerData["player"]["inventory"][itemIDHolder]["bookmarked"] == true:
			PlayerDb.playerData["player"]["inventory"][itemIDHolder]["bookmarked"] = false
			resetItemDescriptions()
			$Tabs/Items/itemsList.grab_focus()

		
		
func _on_toss_confirm_pressed():
	if int($tossSlider/Dial.currentTick) == 0:
		drop_toss_dial_focus()
		gain_tab_focus()
		$Tabs/Items/itemsList.grab_focus()
	else:
		InventoryHelper.tossItem(itemIDHolder, $tossSlider/Dial.currentTick)
		UniversalAudio.playSpecialSound("res://Assets/Sounds/Item/toss.mp3")
		drop_toss_dial_focus()
		gain_tab_focus()
		$Tabs/Items/itemsList.grab_focus()
		resetItemDescriptions()
		
		
func equipWeapon():
	
	if readied == true:
		
		var weaponsList = $Tabs/Weapons/weaponsList # this defines weaponsList. only runs
		# if readied because you cannot assign an object until it is initialized, and without
		#this check the game would crash.
		
		# Selecting an item
		if weaponsList.get_selected_column() == 0:
			
			
			for i in PlayerDb.playerData["player"]["weapons"]: # checks the player's inventory for all possibly equipped weapons
				if weaponsList.get_selected() == null: # a check in case that the item the player is currently hovering is getting deleted
					continue
				else:	
					if hoveredWeapon == GlobalDb.weaponDatabase[i]["name"] and PlayerDb.playerData["player"]["weapons"][i]["equipped"] == false: # if the text in the weaponsList tree's 
						# first (name) column is the same as the provided text in the designated weapon's weaponDatabase key,
						# it will then point back to that weapon as being switched to (equipped)
						PlayerDb.playerData["player"]["weapons"][i]["equipped"] = true
						PlayerDb.playerData["player"]["body"]["weapon"] = i
						UniversalAudio.playSpecialSound("res://Assets/Sounds/Item/weaponSwitch.mp3")
						
					elif hoveredWeapon != GlobalDb.weaponDatabase[i]["name"] and hoveredWeapon != (GlobalDb.weaponDatabase[i]["name"] + " (Equipped)"):
						PlayerDb.playerData["player"]["weapons"][i]["equipped"] = false
					
					elif hoveredWeapon == GlobalDb.weaponDatabase[i]["name"] and PlayerDb.playerData["player"]["weapons"][i]["equipped"] == true:
						UniversalAudio._play_error()
						
	updateWeaponDescriptions()
	
func equipArmor():
	
	if readied == true:
		
		var armorList = null
		match currentSubMenu:
			"head":
				armorList = $Tabs/Armor/headArmorList
			"body":
				armorList = $Tabs/Armor/bodyArmorList
		
		# Selecting an item
		if armorList.get_selected_column() == 0:
			
			
			for i in PlayerDb.playerData["player"]["armor"][currentSubMenu]:
				if armorList.get_selected() == null: # a check in case that the item the player is currently hovering is getting deleted
					continue
				else:	
					if hoveredArmor == GlobalDb.armorDatabase[currentSubMenu + "_" + i]["name"] and PlayerDb.playerData["player"]["armor"][currentSubMenu][i]["equipped"] == false:
						
						PlayerDb.playerData["player"]["armor"][currentSubMenu][i]["equipped"] = true
						PlayerDb.playerData["player"]["body"][currentSubMenu] = i
						PlayerDb.playerData["player"]["stats"][currentSubMenu + "ArmorDefense"] =  GlobalDb.armorDatabase[currentSubMenu + "_" + i]["defense"]
						PlayerDb.playerData["player"]["stats"]["compoundDefense"] = PlayerDb.playerData["player"]["stats"]["headArmorDefense"] + PlayerDb.playerData["player"]["stats"]["bodyArmorDefense"] + PlayerDb.playerData["player"]["stats"]["baseDefense"]
						UniversalAudio.playSpecialSound("res://Assets/Sounds/Item/armorEquip.mp3")
						drop_tab_focus()
						disable_decisionList()
						armorList.grab_focus()
						
					elif hoveredArmor != GlobalDb.armorDatabase[currentSubMenu + "_" + i]["name"] and hoveredArmor != (GlobalDb.armorDatabase[currentSubMenu + "_" + i]["name"] + " (Equipped)"):
						PlayerDb.playerData["player"]["armor"][currentSubMenu][i]["equipped"] = false
					
					elif hoveredArmor == GlobalDb.armorDatabase[currentSubMenu + "_" + i]["name"] and PlayerDb.playerData["player"]["armor"][currentSubMenu][i]["equipped"] == true:
						UniversalAudio._play_error()
						
	updateArmorDescriptions()
	
func unequipArmor():
	for i in PlayerDb.playerData["player"]["armor"][currentSubMenu]:
		var armorList = null
		match currentSubMenu:
			"head":
				armorList = $Tabs/Armor/headArmorList
			"body":
				armorList = $Tabs/Armor/bodyArmorList
		if hoveredArmor ==GlobalDb.armorDatabase[currentSubMenu + "_" + i]["name"] and PlayerDb.playerData["player"]["armor"][currentSubMenu][i]["equipped"] == true:
			PlayerDb.playerData["player"]["body"][currentSubMenu] = ""
			PlayerDb.playerData["player"]["armor"][currentSubMenu][i]["equipped"] = false
			PlayerDb.playerData["player"]["stats"][currentSubMenu + "ArmorDefense"] =  0
			PlayerDb.playerData["player"]["stats"]["compoundDefense"] = PlayerDb.playerData["player"]["stats"]["headArmorDefense"] + PlayerDb.playerData["player"]["stats"]["bodyArmorDefense"] + PlayerDb.playerData["player"]["stats"]["baseDefense"]
			updateArmorDescriptions()
			UniversalAudio.playSpecialSound("res://Assets/Sounds/Item/armorUnequip.mp3")
			drop_tab_focus()
			disable_decisionList()
			armorList.grab_focus()

func equipGear():
	
	if readied == true:
		
		var gearList = $Tabs/Gear/gearList
		
		# Selecting an item
		if gearList.get_selected_column() == 0:
			
			for i in PlayerDb.playerData["player"]["gear"]:
				if gearList.get_selected() == null: # a check in case that the item the player is currently hovering is getting deleted
					continue
				else:	
					if hoveredGear == GlobalDb.gearDatabase[i]["name"] and PlayerDb.playerData["player"]["gear"][i]["equipped"] == false:
						
						PlayerDb.playerData["player"]["gear"][i]["equipped"] = true
						PlayerDb.playerData["player"]["body"]["gear"].append(i)
						UniversalAudio.playSpecialSound("res://Assets/Sounds/Item/armorEquip.mp3")
						drop_tab_focus()
						disable_decisionList()
						gearList.grab_focus()
						
					
					elif hoveredGear == GlobalDb.gearDatabase[i]["name"] and PlayerDb.playerData["player"]["gear"][i]["equipped"] == true:
						UniversalAudio._play_error()
						
	updateGearDescriptions()

func unequipGear():
	for i in PlayerDb.playerData["player"]["gear"]:
		var gearList = $Tabs/Gear/gearList
		if hoveredGear == GlobalDb.gearDatabase[i]["name"] and PlayerDb.playerData["player"]["gear"][i]["equipped"] == true:
			PlayerDb.playerData["player"]["body"]["gear"].erase(i)
			PlayerDb.playerData["player"]["gear"][i]["equipped"] = false
			updateGearDescriptions()
			UniversalAudio.playSpecialSound("res://Assets/Sounds/Item/armorUnequip.mp3")
			drop_tab_focus()
			disable_decisionList()
			gearList.grab_focus()

func showDescription():
	$Tabs/Description/descriptionText.get_v_scroll_bar().value = 0 # resetting scroll position when a description is loaded in
	$escapeCooldown.start() # upon opening the menu, this thing immediately fires. Another function utilizes this when the player presses any key to exit the menu, as not having it would make the menu instantly close upon opening it
	var item = null
	var itemId = null
	var type = null
	match currentMenu:
		"weapons":
			item = hoveredWeapon
			for i in PlayerDb.playerData["player"]["weapons"]: # checks the player's inventory for all possibly equipped weapons
				if item == GlobalDb.weaponDatabase[i]["name"]:
					itemId = i
					type = "weapon"
					$Tabs/Description/descriptionText.text = GlobalDb.weaponDatabase[itemId]["description"] + "\n\n" + GlobalDb.weaponDatabase[itemId]["statDescription"]
		"gear":
			item = hoveredGear
			for i in PlayerDb.playerData["player"]["gear"]:
				if item == GlobalDb.gearDatabase[i]["name"]:
					itemId = i
					type = "gear"
					$Tabs/Description/descriptionText.text = GlobalDb.gearDatabase[itemId]["description"] + "\n\n" + GlobalDb.gearDatabase[itemId]["statDescription"]
		"items":
			item = hoveredItem
			for i in PlayerDb.playerData["player"]["inventory"]:
				if item == GlobalDb.itemDatabase[i]["general"]["name"]:
					itemId = i
					type = "item"
					$Tabs/Description/descriptionText.text = GlobalDb.itemDatabase[itemId]["general"]["description"] + "\n\n" + GlobalDb.itemDatabase[itemId]["general"]["statDescription"]
		"armor":
				item = hoveredArmor
				for i in PlayerDb.playerData["player"]["armor"][currentSubMenu]:
					if item == GlobalDb.armorDatabase[currentSubMenu + "_" + i]["name"]:
						itemId = currentSubMenu + "_" + i # the headArmor_ or bodyArmor_ tag gets assigned to i already
						type = "armor"
						$Tabs/Description/descriptionText.text = GlobalDb.armorDatabase[itemId]["description"] + "\n\n" + GlobalDb.armorDatabase[itemId]["statDescription"]
		
	$Tabs/Description/descriptionName.text = item.to_upper()
	UniversalAudio.playSpecialSound("res://Assets/Sounds/UI/blip.mp3")
	$Tabs.current_tab = 0
	$Tabs/Description/descriptionText.grab_focus()




# UI Theming and Aesthetics

func _process(delta):


	# Stats Menu
	if currentMenu == "stats": # this check is here to stop it from constantly running
		$Tabs/Stats/statsList.set_item_text(0, "STRENGTH: " + str(PlayerDb.playerData["player"]["stats"]["strength"]))
		$Tabs/Stats/statsList.set_item_text(1, "SURVIVAL: " + str(PlayerDb.playerData["player"]["stats"]["survival"]))
		$Tabs/Stats/statsList.set_item_text(2, "INTELLIGENCE: " + str(PlayerDb.playerData["player"]["stats"]["intelligence"]))
		$Tabs/Stats/statsList.set_item_text(3, "LEVEL: " + str(PlayerDb.playerData["player"]["level"]))
		$Tabs/Stats/statsList.set_item_text(4, "EXP: " + str(PlayerDb.playerData["player"]["experience"]["current"]))
		$Tabs/Stats/statsList.set_item_text(5, "EXP NEEDED: " + str(PlayerDb.playerData["player"]["experience"]["needed"]))
		$Tabs/Stats/statsList.set_item_text(6, "BASE ATTACK: " + str(PlayerDb.playerData["player"]["stats"]["attack"]))
		$Tabs/Stats/statsList.set_item_text(7, "BASE DEFENSE: " + str(PlayerDb.playerData["player"]["stats"]["baseDefense"]))
		$Tabs/Stats/statsList.set_item_text(8, "TOTAL DEFENSE: " + str(PlayerDb.playerData["player"]["stats"]["compoundDefense"]))
		$Tabs/Stats/statsList.set_item_text(9, "SPEED: " + str(PlayerDb.playerData["player"]["stats"]["speed"]))
		$Tabs/Stats/statsList.set_item_text(10, "BATTLE IQ: " + str(PlayerDb.playerData["player"]["stats"]["battleIQ"]))
		$Tabs/Stats/statsList.set_item_text(11, "RUNTIME: " + PlayerDb.playerData["game"]["runTime"])
		for i in $Tabs/Stats/statsList.item_count:
			$Tabs/Stats/statsList.set_item_tooltip(i, " ")
			
			
	# Radio Menu
	for i in $Tabs/Radio/radioList.item_count:
			$Tabs/Radio/radioList.set_item_tooltip(i, " ")
	




	# Toss Menu
	if $tossSlider/tossQuantity.visible == true:
		$tossSlider/tossQuantity.text = "[center]" + str($tossSlider/Dial.currentTick)
		
	# Reload Menu
	
	if $ammoSlider/reloadQuantity.visible == true:
		$ammoSlider/reloadQuantity.text = "[center]" + str($ammoSlider/Dial.currentTick)
	
	
	


	# Switching back from the description

	
	if currentMenu == "description" and Input.is_anything_pressed() and $escapeCooldown.time_left == 0 and not Input.is_action_pressed("Blacklist") and not Input.is_action_pressed("ui_up") and not Input.is_action_pressed("ui_down"):
		for i in $Tabs.get_child_count():
			if $Tabs.get_tab_title(i) == previousMenu.capitalize():
				$Tabs.current_tab = i
				if currentMenu == "weapons": # brings the focus back to the tree node
					$Tabs/Weapons/weaponsList.call_deferred("grab_focus")
				elif currentMenu == "items":
					$Tabs/Items/itemsList.call_deferred("grab_focus")
				elif currentMenu == "gear":
					$Tabs/Gear/gearList.call_deferred("grab_focus")
				elif currentMenu == "armor":
					match currentSubMenu:
						"head":
							$Tabs/Armor/headArmorList.call_deferred("grab_focus")
						"body":
							$Tabs/Armor/bodyArmorList.call_deferred("grab_focus")
				return
	
	# Scrolling through Menus
	if currentMenu == "description" and Input.is_action_pressed("ui_down"):
		$Tabs/Description/descriptionText.get_v_scroll_bar().value += 250 * delta
	if currentMenu == "description" and Input.is_action_pressed("ui_up"):
		$Tabs/Description/descriptionText.get_v_scroll_bar().value -= 250 * delta

	# UI Events
	# Pausing the game
	if Input.is_action_just_pressed("Escape") and Global.currentScreen == "world" and $tossSlider.visible == false and $ammoSlider.visible == false and ActionProcessor.processing == false: # the player probably shouldnt be able to unpause if the dial is out otherwise itd still be there when they unpause and the menu would be broken
		if $actionMenu.visible == false:
			if get_tree().paused == false and player.controllable == true:
				if Global.playerCharBody2D.resting == true:
					Global.playerCharBody2D.resting = false
					Engine.time_scale = 1
				get_tree().paused = true
				panIn() # making the menu visible
				player.get_node("pauseMusic").play() # playing pause music
				player.get_node("Music").process_mode = Node.PROCESS_MODE_DISABLED # pausing the level music
			elif player.controllable == true and get_tree().paused == true:
				panOut() #making the menu not visible/invisible
				$Tabs.current_tab = 5
				get_tree().paused = false
				get_viewport().gui_release_focus()
				player.get_node("pauseMusic").stop() # stopping pause music
				player.get_node("Music").process_mode = Node.PROCESS_MODE_ALWAYS # unpausing the level music
		else:
			exitActionMenu()

func _on_tabs_tab_changed(tab):
	if $AnimationPlayer.current_animation == "PanOut" or $AnimationPlayer.current_animation == "Hidden":
		return # this hack prevents the tab bar from regaining focus when it shouldnt and then becoming visible when the game is unpaused
	if Input.is_action_just_pressed("ui_left") or Input.is_action_pressed("ui_left"):
		$AnimationPlayer.play("SwitchLeft")
	if Input.is_action_just_pressed("ui_right") or Input.is_action_pressed("ui_right"):
		$AnimationPlayer.play("SwitchRight")
	$Pointer.visible = false
	# Tab switch sound
	if self.visible == true and (Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right")): # extra conditions for input were added so that it doesnt play the click sound when the tabs are initialized or reordered
		UniversalAudio.playSpecialSound("res://Assets/Sounds/UI/bleep.mp3")



func hidePointer():
	$Pointer.visible = false


func _on_visible_on_screen_notifier_2d_visibility_changed(): # Be careful, if you mess up the visibility of the childnodes of help_menu, this may break and show an arrow on the screen
	if currentMenu == "weapons":
		$Tabs/Weapons/weaponsList.call_deferred("grab_focus")
	elif currentMenu == "items":
		$Tabs/Items/itemsList.call_deferred("grab_focus")
	elif currentMenu == "action":
		$Tabs/Action/actionList.call_deferred("grab_focus")
		
		
# Helpers

func callReload(type, ammoType):
	match Global.currentScreen: # sorry if this is formatted really weird I was trying super hard to keep it readable
		"world":
			match type:
				"std":
					InventoryHelper.reloadSystem(weaponIDHolder, InventoryHelper.getAmmoType(weaponIDHolder, false))
					updateWeaponDescriptions()
				"alt":
					match ammoType:
						"std":
							InventoryHelper.reloadSystem(weaponIDHolder, InventoryHelper.getAmmoType(weaponIDHolder, false))
							updateWeaponDescriptions()
						"alt":
							InventoryHelper.reloadSystem(weaponIDHolder, InventoryHelper.getAmmoType(weaponIDHolder, true))
							updateWeaponDescriptions()
					
		"battle":
			match type:
				"std":
					BattleSystem.PLAYER_MOVES.reloadWeapon(weaponIDHolder, InventoryHelper.getAmmoType(weaponIDHolder, false), "std", null) # ammo refill is set to null because it isnt currently used for standard weapons
					BattleSystem.startTurns()
				"alt":
					match ammoType:
						"std":
							InventoryHelper.reloadSystem(weaponIDHolder, InventoryHelper.getAmmoType(weaponIDHolder, false))
						"alt":
							InventoryHelper.reloadSystem(weaponIDHolder, InventoryHelper.getAmmoType(weaponIDHolder, true))
		
func drop_tab_focus():
	$actionMenu/actionsTab/decisionsList.focus_mode = Control.FOCUS_ALL
	$actionMenu/actionsTab/decisionsList.select_mode = ItemList.SELECT_SINGLE
	$actionMenu/actionsTab/decisionsList.grab_focus()
	$actionMenu/actionsTab/decisionsList.select(0)
	$Tabs/Weapons/weaponsList.focus_mode = FOCUS_NONE
	$Tabs/Items/itemsList.focus_mode = FOCUS_NONE
	$Tabs.get_tab_bar().focus_mode = Control.FOCUS_NONE # disabling focus of the tab bar

func gain_tab_focus():
	$actionMenu/actionsTab/decisionsList.focus_mode = Control.FOCUS_NONE
	$Tabs/Weapons/weaponsList.focus_mode = FOCUS_ALL
	$Tabs/Items/itemsList.focus_mode = FOCUS_ALL
	$Tabs/Armor/headArmorList.focus_mode = FOCUS_ALL
	$Tabs/Armor/bodyArmorList.focus_mode = FOCUS_ALL
	$Tabs.get_tab_bar().focus_mode = Control.FOCUS_ALL # enabling focus of the tab bar
	
func drop_toss_dial_focus():
	$tossSlider.focus_mode = Control.FOCUS_NONE
	$tossSlider.release_focus()
	$tossSlider.hide()
	
func gain_toss_dial_focus():
	disable_decisionList()
	$tossSlider.focus_mode = Control.FOCUS_ALL
	$tossSlider/Dial/Knob/knobTexButton.grab_focus()
	$tossSlider/tossConfirm.focus_neighbor_top = $tossSlider/Dial/Knob/knobTexButton.get_path()
	
func drop_ammo_dial_focus():
	$ammoSlider.focus_mode = Control.FOCUS_NONE
	$ammoSlider.release_focus()
	$ammoSlider.hide()
	
	
func enable_ammo_slider():
	$ammoSlider.show()
	gain_ammo_dial_focus()

func gain_ammo_dial_focus():
	disable_decisionList()
	$ammoSlider.focus_mode = Control.FOCUS_ALL
	$ammoSlider/Dial/Knob/knobTexButton.grab_focus()
	$ammoSlider/reloadConfirm.focus_neighbor_top = $ammoSlider/Dial/Knob/knobTexButton.get_path()
	
	
func disable_decisionList():
	$actionMenu/actionsTab/decisionsList.focus_mode = Control.FOCUS_NONE
	$actionMenu.hide()
	$actionMenu/actionsTab/decisionsList.release_focus()


func _on_head_armor_list_focus_entered(): # adding this in because trees don't clear highlight when you switch focus neighbors and that can cause confusion
	$Tabs/Armor/bodyArmorList.deselect_all()
	if $Tabs/Armor/headArmorList.get_root().get_first_child() != null:
		$Tabs/Armor/headArmorList.get_root().get_first_child().select(0)
		currentSubMenu = "head"

func _on_body_armor_list_focus_entered():
	$Tabs/Armor/headArmorList.deselect_all()
	if $Tabs/Armor/bodyArmorList.get_root().get_first_child() != null:
		$Tabs/Armor/bodyArmorList.get_root().get_first_child().select(0)
		currentSubMenu = "body"
	



func _on_armor_list_item_activated():
	UniversalAudio.playSpecialSound("res://Assets/Sounds/UI/click.mp3")
	var selected = null
	var list = null
	if currentSubMenu == "head":
		list = $Tabs/Armor/headArmorList
		selected = list.get_selected()
	elif currentSubMenu ==  "body":
		list = $Tabs/Armor/bodyArmorList
		selected = list.get_selected()
	if selected:
		hoveredArmor = str(selected.get_text(0)).replace(" (Equipped)", "")
		
		armorIDHolder = (CowTools.getCurrentItemByID(hoveredArmor, currentSubMenu + "Armor"))
		CowTools.clearItemList($actionMenu/actionsTab/decisionsList)
		if PlayerDb.playerData["player"]["armor"][currentSubMenu][armorIDHolder]["equipped"] == false:
			
			CowTools.populateItemList($actionMenu/actionsTab/decisionsList, {"Use" : {
			"icon" : null,
			"selectable" : true,
			"text" : "> Equip",
			},
			"Info" : {
			"icon" : null,
			"selectable" : true,
			"text" : "> Info",
			},
			"Toss" : {
			"icon" : null,
			"selectable" : true,
			"text" : "< Toss",
			},
			"Back" : {
			"icon" : null,
			"selectable" : true,
			"text" : "< Back",
			},
			
			})
		else:
			CowTools.populateItemList($actionMenu/actionsTab/decisionsList, {"Unequip" : {
			"icon" : null,
			"selectable" : true,
			"text" : "> Unequip",
			},
			"Info" : {
			"icon" : null,
			"selectable" : true,
			"text" : "> Info",
			},
			"Toss" : {
			"icon" : null,
			"selectable" : true,
			"text" : "< Toss",
			},
			"Back" : {
			"icon" : null,
			"selectable" : true,
			"text" : "< Back",
			},
			
			})
		$actionMenu/actionsTab/decisionsList.size.x = 96
		$actionMenu.size.y = 112
		$actionMenu.size.x = 112
		$actionMenu.show()
		var rectangle: Rect2 = list.get_item_area_rect(list.get_selected(), 0)
		
		var menuOffset = Vector2(200, -30)
		var scrollOffset = Vector2(0, list.get_scroll().y)
		$actionMenu.global_position = list.get_global_position() + rectangle.position + menuOffset - scrollOffset - (Vector2(0, list.get_global_position().y * 0.1))
		drop_tab_focus()
		
		


func _on_gear_list_item_activated() -> void:
	UniversalAudio.playSpecialSound("res://Assets/Sounds/UI/click.mp3")
	var list = $Tabs/Gear/gearList
	var selected = list.get_selected()
	if selected:
		hoveredGear = str(selected.get_text(0)).replace(" (Equipped)", "")
		gearIDHolder = (CowTools.getCurrentItemByID(hoveredGear, "gear"))
		CowTools.clearItemList($actionMenu/actionsTab/decisionsList)
		if PlayerDb.playerData["player"]["gear"][gearIDHolder]["equipped"] == false:
			
			CowTools.populateItemList($actionMenu/actionsTab/decisionsList, {"Use" : {
			"icon" : null,
			"selectable" : true,
			"text" : "> Equip",
			},
			"Info" : {
			"icon" : null,
			"selectable" : true,
			"text" : "> Info",
			},
			"Back" : {
			"icon" : null,
			"selectable" : true,
			"text" : "< Back",
			},
			
			})
		else:
			CowTools.populateItemList($actionMenu/actionsTab/decisionsList, {"Unequip" : {
			"icon" : null,
			"selectable" : true,
			"text" : "> Unequip",
			},
			"Info" : {
			"icon" : null,
			"selectable" : true,
			"text" : "> Info",
			},
			"Back" : {
			"icon" : null,
			"selectable" : true,
			"text" : "< Back",
			},
			
			})
		$actionMenu/actionsTab/decisionsList.size.x = 96
		$actionMenu.size.y = 96
		$actionMenu.size.x = 112
		$actionMenu.show()
		var rectangle: Rect2 = list.get_item_area_rect(list.get_selected(), 0)
		
		var menuOffset = Vector2(200, -30)
		var scrollOffset = Vector2(0, list.get_scroll().y)
		$actionMenu.global_position = list.get_global_position() + rectangle.position + menuOffset - scrollOffset - (Vector2(0, list.get_global_position().y * 0.1))
		drop_tab_focus()


func _on_action_list_item_activated(index):
	$Tabs.focus_mode = FOCUS_NONE
	if index == 0:
		if (
			(
				PlayerDb.playerData["player"]["weapons"][PlayerDb.playerData["player"]["body"]["weapon"]].has("ammo")
				and
				PlayerDb.playerData["player"]["weapons"][PlayerDb.playerData["player"]["body"]["weapon"]]["ammo"] >= GlobalDb.weaponDatabase[PlayerDb.playerData["player"]["body"]["weapon"]]["ammoCost"]
			)
			or
			(
				!PlayerDb.playerData["player"]["weapons"][PlayerDb.playerData["player"]["body"]["weapon"]].has("ammo")
				and
				PlayerDb.playerData["player"]["weapons"][PlayerDb.playerData["player"]["body"]["weapon"]]["quantity"] > 0
			)
		):
			$Tabs.current_tab = 2
			CowTools.populateBattleEnemyList($Tabs/attackWho/enemyList, BattleSystem.enemyDict) # populates the enemyList with enemy names
			$Tabs/attackWho/enemyList.grab_focus()
			$Tabs/attackWho/enemyList.select(0) # highlighting the first value automatically
		else:
			UniversalAudio._play_error()
	if index == 1:
		if BattleSystem.canAdvance:
			$Tabs.current_tab = 4
			$Tabs/distancePicker/distanceList.grab_focus()
			$Tabs/distancePicker/distanceList.select(0) # highlighting the first value automatically
		else:
			UniversalAudio._play_error()
	if index == 2:
		BattleSystem.PLAYER_MOVES.block()
		BattleSystem.startTurns()
	if index == 3:
		BattleSystem.PLAYER_MOVES.flee()
		BattleSystem.startTurns()

func _on_enemy_list_item_activated(index):
	if index == 0: # returning
		$Tabs/attackWho/enemyList.release_focus()
		 # reset the list
		CowTools.clearItemList($Tabs/attackWho/enemyList)
		CowTools.populateItemListDirect($Tabs/attackWho/enemyList,["< Back"],null,true)
		$Tabs.current_tab = 1
		$Tabs/Action/actionList.grab_focus()
	else:
		BattleSystem.selectedEnemy = $Tabs/attackWho/enemyList.get_item_metadata(index)
		$Tabs/attackWho/enemyList.release_focus()
		CowTools.clearItemList($Tabs/attackWho/enemyList)
		CowTools.populateItemListDirect($Tabs/attackWho/enemyList,["< Back"],null,true)
		CowTools.clearItemList($Tabs/limbPicker/limbList)
		CowTools.populateItemListDirect($Tabs/limbPicker/limbList,["< Back"],null,true)
		# maybe removeIdentifier should become a cow tool
		CowTools.populateItemListDirect($Tabs/limbPicker/limbList, EnemyDb.enemies[BattleSystem.removeIdentifier(BattleSystem.selectedEnemy)]["limbs"])
		$Tabs.current_tab = 3
		$Tabs/limbPicker/limbList.grab_focus()

func _on_limb_list_item_selected(index): # limb is selected in limb picker
	for i in instance_from_id(BattleSystem.enemyDict[BattleSystem.selectedEnemy]["battleSpriteID"]).get_node("Limbs").get_children():
		if i.name == $Tabs/limbPicker/limbList.get_item_text(index):
			i.visible = true
			limbPicked.emit($Tabs/limbPicker/limbList.get_item_text(index), false)
		elif $Tabs/limbPicker/limbList.get_item_text(index) == "< Back":
			limbPicked.emit($Tabs/limbPicker/limbList.get_item_text(index), true)  # signal to hide
			i.visible = false
		else:
			i.visible = false
			

func _on_limb_list_item_activated(index):
	if index == 0: # returning
		limbPicked.emit($Tabs/limbPicker/limbList.get_item_text(index), true) # signal to hide
		$Tabs/limbPicker/limbList.release_focus()
		 # reset the list
		CowTools.clearItemList($Tabs/limbPicker/limbList)
		CowTools.populateItemListDirect($Tabs/limbPicker/limbList,["< Back"],null,true)
		$Tabs.current_tab = 2
		$Tabs/attackWho/enemyList.grab_focus()
		CowTools.populateBattleEnemyList($Tabs/attackWho/enemyList, BattleSystem.enemyDict)
	else:
		for i in instance_from_id(BattleSystem.enemyDict[BattleSystem.selectedEnemy]["battleSpriteID"]).get_node("Limbs").get_children():
			i.hide()
		BattleSystem.selectedLimb = $Tabs/limbPicker/limbList.get_item_text(index)
		BattleSystem.startTurns()
		$Tabs.current_tab = 1
		CowTools.clearItemList($Tabs/limbPicker/limbList)
		CowTools.populateItemListDirect($Tabs/limbPicker/limbList,["< Back"],null,true)
		
		emit_signal("battleMoveDecided")
		# this should execute a signal to initiate each fighter's actions based on turn order established in battlesystem
		# battlesystem should then iterate through this turn order to add attack actions
		
		
func _on_distance_list_item_activated(index: int) -> void:
	if index == 0: # returning
		$Tabs/distancePicker/distanceList.release_focus()
		$Tabs.current_tab = 1
		$Tabs/Action/actionList.grab_focus()
	if index == 1: # advance
		BattleSystem.PLAYER_MOVES.advance("forwards")
		BattleSystem.startTurns()
	if index == 2: #regress
		BattleSystem.PLAYER_MOVES.advance("backwards")
		BattleSystem.startTurns()
		
		
# Animations

func panIn():
	$AnimationPlayer.stop()
	$AnimationPlayer.play("PanIn")
	$AnimationPlayer.queue("Idle")
	
func panOut():
	$AnimationPlayer.stop()
	$AnimationPlayer.play("PanOut")
	$AnimationPlayer.queue("Hidden")

func release_item_use_focus():
	gain_tab_focus()
	$actionMenu.hide()
	$actionMenu.release_focus()
	$actionMenu/actionsTab/decisionsList.release_focus()
	$Tabs/Items/itemsList.release_focus()
	get_viewport().gui_release_focus()
	
func grab_item_list_focus():
	gain_tab_focus()
	$Tabs/Items/itemsList.grab_focus()

func _on_reload_confirm_pressed():
	var quantity = int($ammoSlider/Dial.currentTick)
	
	if quantity == 0:
		drop_ammo_dial_focus()
		gain_tab_focus()
		get_node("Tabs/Weapons/weaponsList").call_deferred("grab_focus")
	elif quantity != 0 and Global.currentScreen == "world":
		drop_ammo_dial_focus()
		gain_tab_focus()
		get_node("Tabs/Weapons/weaponsList").call_deferred("grab_focus")	
		InventoryHelper.confirmSpecialReload(quantity) # connects back to the global function for the sake of modularity (in case this menu gets replaced and I just want it to do the same thing)
	elif quantity != 0 and Global.currentScreen == "battle":
		drop_ammo_dial_focus()
		gain_tab_focus()
		get_node("Tabs/Weapons/weaponsList").call_deferred("grab_focus")
		var type := false
		match selectedAmmoType:
			"alt":
				type = true
			"std":
				type = false
		BattleSystem.PLAYER_MOVES.reloadWeapon(weaponIDHolder, InventoryHelper.getAmmoType(weaponIDHolder, type), "alt", (int($ammoSlider/Dial.currentTick)))
		# ^^^ the third parameter must ALWAYS be "alt" or else reload() can incorrectly trigger and leave the reload menu open
		BattleSystem.startTurns()


func _on_decisions_list_item_clicked(index, at_position, mouse_button_index):
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		_on_decisions_list_item_activated(index)


func exitActionMenu():
	gain_tab_focus()
	$actionMenu.hide()
	$actionMenu.release_focus() # in case hiding it doesn't already work for some reason
	if currentMenu == "weapons":
		$Tabs/Weapons/weaponsList.grab_focus()
	elif currentMenu == "items":
		$Tabs/Items/itemsList.grab_focus()
	elif currentMenu == "gear":
		$Tabs/Gear/gearList.grab_focus()
	elif currentMenu == "armor":
		match currentSubMenu:
			"head":
				$Tabs/Armor/headArmorList.grab_focus()
			"body":
				$Tabs/Armor/bodyArmorList.grab_focus()

	
