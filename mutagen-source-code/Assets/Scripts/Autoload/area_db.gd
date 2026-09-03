extends Node
var areaDatabase := {
	
	
		"" : {
			"areaMetadata" : {
				"prettyName" : "Meat Factory"
			},
		},
		"huskValley" : { # Area ID
		"areaMetadata" : {
			"prettyName" : "Husk Valley",
			},
			
		"rooms" : {
			"town" : {
				"prettyName" : "Town",
				"variant" : "normal",
				"outOrIn" : "outdoors",
				"nodes" :
			{
				"normal" : "res://Assets/Scenes/World/Objects/Rooms/Maps/Husk Valley/huskValleyTown.tscn"
			},
				"bgm" : {
					"normal" : "res://Assets/Sounds/Music/Evelyn.ogg",
				},
				"radioConversations" : {
				"Evelyn" : {
				
				},
				},
				},
			
			"HQ" : {
				"prettyName" : "Headquarters",
				"variant" : "normal",
				"outOrIn" : "indoors",
				"nodes" :
			{
				"normal" : "res://Assets/Scenes/World/Objects/Rooms/Walls/Husk Valley/HQ.tscn"
			},
				"bgm" : {
					"normal" : "res://Assets/Sounds/Music/Ah.ogg",
				},
				"radioConversations" : {
				"Evelyn" : {
				
				},
				},
				},
			
			
			
			},
			},
	
	
	
}

var backroomsDatabase := {} # backrooms arcade mode where you play as evelyn. futureYou.png

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
