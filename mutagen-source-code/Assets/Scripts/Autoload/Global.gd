extends Node

# Loader Variables
var waitTimer := 0 # this variable exists as a buffer to execute code after everything is loaded in

# System Data
var rng := RandomNumberGenerator.new()

# Area Data
@export var music := "res://Assets/Sounds/Music/Survival_of_the_Fittest.ogg"
@export var musicVolume : float = 0
@export var musicPlaying := true
@export var musicCanPlay := true # this is an extra variable check to see if other music is playing. if you want a scene to be mute, I recommend not using this but rather using musicPlaying instead
var currentScreen := "world" # There are types of screens, 'world' screens, and 'battle' screens. These change UI
@export var cutsceneIsActive := false

# Battles Data
var enemiesKilled := {}
var playerJustFled := false
var battleJustEnded := false

# NOTE to self: at one point you refactored global variables for weapons, moving static variables to globaldb

# Global Object References
@export var player : Node2D = null
@export var playerCharBody2D : CharacterBody2D = null
@export var dialogueBox : Control = null
@export var actionLog : Control = null
@export var helpMenu : Control = null
@export var cutscenePlayer = null


# Variables from other autoloads
var playerData : Dictionary = PlayerDb.playerData
	





var flags := {
	"debug" : {
		"setting" : "false",
		"result" : {
			"print" : "it worked.",
			"affectedNodeGroup" : "Talkative NPC",
			"animate" : {
				# The nodepath is the path directly from the parent node
				"animationPlayerPath" : NodePath("AnimatedSprite2D"),
				"animationName" : "Wink"
			}
		}
	}
}






# func get_item_description(id: String) -> String:
	# if items.has(id):
	# 	return items[id]["description"]
	#return "No description found."



	

func _ready():
	
	process_mode = Node.PROCESS_MODE_ALWAYS # this has to be here or else certain functions will stop working when the game is paused
	
	rng.randomize() # changing the seed so RNG is truly random
	InventoryHelper.updateWeaponDatabases() # Call this to set up the weapon descriptions
	
	call_deferred("handleFlags") # flags are checked on startup after everything is loaded in and their appropriate functions get executed
	
	cutscenePlayer = get_tree().get_first_node_in_group("Cutscene Player")
	#playCutscene("doTheHokeyPokey")
	
	
	
# Global Object References

func _process(delta):
		
	# Updating Runtime # TODO: MAKE START TIME LOAD FROM THE PLAYER'S SAVE FILE BEFORE THIS EVER RUNS
	if playerData["game"]["startTime"] == null:
		playerData["game"]["startTime"] = Time.get_unix_time_from_system()
	var seconds : int = round((Time.get_unix_time_from_system() - playerData["game"]["startTime"])) + delta # adding delta is KIND OF useless because it must return an int, but it's just there to address an issue with lag spikes causing za warudo to activate
	var hours : int = seconds / 3600
	var minutes : int = (seconds % 3600) / 60
	var secs : int = seconds % 60
	playerData["game"]["runTime"] = "%02d:%02d:%02d" % [hours, minutes, secs]
	if get_tree().get_first_node_in_group("Cutscene Player") != null:
		cutscenePlayer = get_tree().get_first_node_in_group("Cutscene Player")
		if cutscenePlayer.is_playing() == false and cutsceneIsActive:
			endCutscene()
	


func handleFlags():
	for i in flags:
		if flags[i]["setting"] == "true":
				if flags[i]["result"].has("print"):
					print(flags[i]["result"]["print"])
				if flags[i]["result"].has("animate"):
					var npc := get_tree().get_nodes_in_group(str(flags[i]["result"]["affectedNodeGroup"]))
					for n in npc:
						var animationPlayer : AnimationPlayer = n.get_node(flags[i]["result"]["animate"]["animationPlayerPath"])
						animationPlayer.play(flags[i]["result"]["animate"]["animationName"])
						
	
	
func changeMusic(song, volume):
	music = song
	musicVolume = volume

func playCutscene(cutscene):
	await get_tree().process_frame
	if cutscenePlayer != null:
		cutscenePlayer.current_animation = cutscene
		cutsceneIsActive = true
	
func endCutscene():
	if cutscenePlayer != null:
		await get_tree().process_frame
		cutsceneIsActive = false
	
