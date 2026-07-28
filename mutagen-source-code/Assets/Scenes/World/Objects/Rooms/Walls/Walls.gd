extends TileMapLayer

var astar : AStarGrid2D = AStarGrid2D.new()
# Called when the node enters the scene tree for the first time.
func _ready():
	var tilemapSize := get_used_rect().end - get_used_rect().position
	var mapRect := Rect2i(Vector2i.ZERO, tilemapSize)
	var tileSize := get_tile_set().tile_size
	astar.region = mapRect
	astar.cell_size = tileSize
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	
	
	#for i in tilemapSize.x:
	#	for j in tilemapSize.y:
	#		var coords = Vector2i(i,j)
	#		var tileData = get_cell_tile_data(coords)
	#		if tile_set.get_custom_data_layer_by_name("type") == -1:
	#			return
	#		if tileData and tileData.get_custom_data("type") == "Wall":
	#			astar.set_point_solid(coords)
				
	#set_meta("astar", astar) Saving all of this in case I use it later. I was originally gonna have
	# walls set their own pathfinding automatically, but im instead gonna manually draw the pathfinding
	# using red and green tiles. for now. unless I change my mind.



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
