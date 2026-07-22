extends Control

@export var interval : float = 0.5
@export var color : Color = Color.RED
@export var string := ""
@export var charLength := string.length()
@export var centered : bool = true
var index := 0

func _ready():
	self.autowrap_mode = TextServer.AUTOWRAP_OFF # with autowrap on it stutters between words
	charLength = string.length()
	scroll()
	
func scroll():
	while true:
		await get_tree().create_timer(interval).timeout
		index += 1
		if index > charLength:
			index = 0
		
		self.text = "[color=" + color.to_html(false) + "]" + (string.substr(index) + string).left(charLength) if not centered else "[center]" + "[color=" + color.to_html(false) + "]" + (string.substr(index) + string).left(charLength)
	
	
