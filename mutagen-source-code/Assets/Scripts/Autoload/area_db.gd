extends Node
var areaDatabase := {
	"areaTemplate" : {
		"areaMetadata" : {
			},
			
		"rooms" : {
			"roomTemplate" : {
				"variant" : "normal",
				"outOrIn" : "indoors",
		"nodes" :
			{
				"normal" : "res://Assets/Scenes/World/Objects/Rooms/Maps/the_room.tscn"
			},
		"bgm" : "",
		"radioConversations" : {
			"Evelyn" : {
				
			},
		}
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
