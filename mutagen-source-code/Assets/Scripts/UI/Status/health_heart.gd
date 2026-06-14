extends Control
var playerCaughtFlag := 0
# Called when the node enters the scene tree for the first time.
func _ready():
	BattleSystem.connect("transition", unhide)

func unhide():
	playerCaughtFlag = 0
	modulate.a = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	# text must be centered
	$Heart/Percentage.text = "[center]" + str(PlayerDb.playerData["player"]["stats"]["currentHealth"]) + "+"
	# The heart pulsates at 100 - your health divided by 15 plus 1.2 so it doesnt stop (could be literally any positive number, I just think 1.2 is the best starting pace even if its not the default animation speed)
	$Pulsation.speed_scale = ((PlayerDb.playerData["player"]["stats"]["maxHealth"] - (PlayerDb.playerData["player"]["stats"]["currentHealth"]))/15) + 1.2
	# Heart turns redder by a value of your lost health divided by 20 plus 1 so your heart doesnt turn blue
	if playerCaughtFlag != 2:
		modulate = Color(((PlayerDb.playerData["player"]["stats"]["maxHealth"] - (PlayerDb.playerData["player"]["stats"]["currentHealth"]))/20) + 1, 1, 1, 1)
	
	if Global.player != null and Global.currentScreen == "world":
		if Global.playerCharBody2D.caught == true and playerCaughtFlag == 0:
			playerCaughtFlag = 1
			
	if playerCaughtFlag == 1:
		playerCaughtFlag = 2
		var tween = get_tree().create_tween()
		tween.tween_property(self, "modulate", Color(((100 - (PlayerDb.playerData["player"]["stats"]["currentHealth"]))/20) + 1, 1, 1, 0), 1)
