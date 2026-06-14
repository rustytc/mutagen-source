extends Node2D

@export var defeatedEnemies := []
@export var turnOrder := []
@export var nextTurn = null
enum turnModes {WAIT, DECIDE}
@export var turnMode = turnModes.WAIT
var canAdvanceFromLog = false
func _init():
	Global.currentScreen = "battle" # must be set on init otherwise some nodes will load in before and will be misconfigured (help menu)

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connecting battle system win signal to do stuff when the battle ends
	BattleSystem.endBattleWin.connect(battleWon)
	BattleSystem.transition.connect(transition)
	# Connecting battle log signal to determine when it is done typing
	$battleLog.finishedTyping.connect(finishedTyping)
	$helpMenu.limbPicked.connect(limbPicked)
	$helpMenu.battleMoveDecided.connect(battleAdvance)
	BattleSystem.battleAdvance.connect(battleAdvance)
	
	BattleSystem.battleInitiation() # initiates the battle system
	populateBattleSprites()
	
	
	
	
func battleWon():
	staticEffect()
	
func staticEffect():
	var tween = create_tween()
	tween.tween_property($VideoStreamPlayer/staticEffect/static, "color:a", 255, 5)

func finishedTyping():
	if ActionProcessor.actions.size() == 0:
		canAdvanceFromLog = true
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	
	# there was a weird bug with this doing nothing sometimes but it just randomly stopped happening so if it happens again look at this
	if (turnMode == turnModes.WAIT and canAdvanceFromLog and 
	Input.is_action_just_pressed("Accept") and 
	$battleLog/Panel/VBoxContainer/HBoxContainer/Text.get_parsed_text().length() > 0 and 
	$helpMenu/AnimationPlayer.current_animation != "PanIn" and BattleSystem.playerAlive == true
	and ActionProcessor.processing == false
	and $battleLog.parsing == false
	and ActionProcessor.actions.is_empty() and BattleSystem.battleEnded == false):
		turnMode = turnModes.DECIDE
		$helpMenu.panIn()
		$helpMenu/Tabs.current_tab = 1
		var actionList = $helpMenu.get_node("Tabs/Action/actionList")
		actionList.focus_mode = Control.FOCUS_ALL
		actionList.select(0)
		actionList.call_deferred("grab_focus")
		$battleLog.panOut()
		canAdvanceFromLog = false
	
	
	# looping music
	if $Music.playing == false and BattleSystem.encounterTheme != [] and BattleSystem.battleEnded == false:
		$Music.stream = load(pickMusic())
		$Music.play()

	if (BattleSystem.playerAlive == false or BattleSystem.battleEnded == true) and $Music.playing:
		$Music.stop()
		$LHMusic.stop()
		get_viewport().gui_release_focus()


	# low health music
	if BattleSystem.playerAlive == true and BattleSystem.battleEnded == false:
		var currentHealth = PlayerDb.playerData["player"]["stats"]["currentHealth"]
		var maxHealth = PlayerDb.playerData["player"]["stats"]["maxHealth"]
		var hpRatio = float(currentHealth) / float(maxHealth)

		var t = clamp((0.30 - hpRatio) / 0.30, 0.0, 1.0)
		t = pow(t, 0.7)

		if !$LHMusic.playing and t > 0.0:
			$LHMusic.play()

		if $LHMusic.playing:
			$LHMusic.volume_db = lerp(-40.0, -10.0, t)

		$Music.volume_db = lerp(0.0, -50.0, t)
	pass

func populateBattleSprites():
	for i in BattleSystem.enemyDict:
		var node = load(BattleSystem.enemyDict[i]["battleSprite"]).instantiate() # instantiates a .tscn file for each enemy's battle sprite
		$EnemyRow.add_child(node)
		BattleSystem.enemyDict[i]["battleSpriteID"] = node.get_instance_id()



func pickMusic():
	var music = BattleSystem.encounterTheme
	var counts = {}

	for i in music:
		if i in counts:
			counts[i] += 1
		else:
			counts[i] = 1

	var maxCount = 0
	var mostCommon = null
	for i in counts:
		if counts[i] > maxCount:
			maxCount = counts[i]
			mostCommon = i

	return mostCommon





# Battle Functions

func limbPicked(limb, hide):
	if hide == false:
		$statDisplay/Panel/VBoxContainer/HBoxContainer/Text.text = EnemyDb.enemies[BattleSystem.removeIdentifier(BattleSystem.selectedEnemy)]["limbs"][limb]["description"]
		$statDisplay.show()
	else:
		$statDisplay.hide()

func battleAdvance():
	if turnMode == turnModes.DECIDE:
		canAdvanceFromLog = false
		turnMode = turnModes.WAIT
	get_viewport().gui_release_focus()
	$helpMenu.gain_tab_focus()
	$helpMenu/actionMenu.hide()
	$helpMenu.drop_toss_dial_focus()
	$helpMenu.drop_ammo_dial_focus()
	$statDisplay.hide()
	$battleLog.show()
	$battleLog.panIn()
	$helpMenu.panOut()

func transition():
	$fadeTransition/animationPlayer.play("fadeIn")
