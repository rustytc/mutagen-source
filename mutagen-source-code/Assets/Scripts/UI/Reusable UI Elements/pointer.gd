extends AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var focus = get_viewport().gui_get_focus_owner()
	# Pointer/Cursor
	# Originally this checked every specific instance where I wanted the pointer to go, but I think it works better if its just universal to all Trees
	# Trees
	if focus is Tree and focus.is_visible_in_tree() and focus.get_selected() != null:
		# ^ The extra check of get_viewport().gui_get_focus_owner().get_selected() != null ensures that a million errors do not print in the situation that nothing is selected
		
		visible = true
		var list = focus
		var rectangle : Rect2 = list.get_item_area_rect(list.get_selected(), 0) # the rectangle is the local coordinates of the treeitem
		if global_position != (Rect2(list.get_global_position() + (rectangle.position - Vector2(0, -10)), rectangle.size)).position - Vector2(0, list.get_scroll().y): # get_scroll().y is necessary to compensate for the scroll distance offset so that the cursor doesnt go off screen
			global_position = (Rect2(list.get_global_position() + (rectangle.position - Vector2(0, -10)), rectangle.size)).position - Vector2(0, list.get_scroll().y)
			play("horizontalIdle")
			
# functionality for itemlists VVVV
# the functions for itemlist are slightly different than the ones for a tree
	elif (focus is ItemList and focus.is_visible_in_tree() and focus.name != "decisionsList") and focus.get_selected_items().size() > 0:
		# its probably less verbose to apply the cursor to all of the menu's itemlists except this one rather than specify every single instance of itemlist
		visible = true
		var list = focus
		var rectangle : Rect2 = list.get_item_rect(list.get_selected_items()[0], 0)
		if global_position != (Rect2(list.get_global_position() + (rectangle.position - Vector2(16, -10)), rectangle.size)).position  - Vector2(0, float(list.get_v_scroll_bar().value)): 
			global_position = (Rect2(list.get_global_position() + (rectangle.position - Vector2(16, -10)), rectangle.size)).position - Vector2(0, float(list.get_v_scroll_bar().value))
			play("horizontalIdle")
	else:
		visible = false
