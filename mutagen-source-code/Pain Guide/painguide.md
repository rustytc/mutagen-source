# Mutagen: Lock and Load PAIN GUIDE

## Quick Note for Modders
Put all of your mod data and scripts in their own autoloads and folders. If you really have to, you can modify existing 
scripts and folders, but that could cause problems down the line with updates and data conflicts. It's best for compatability
to keep all of your stuff in its own place, and also makes it possible for more than one mod to run at once.

## So, where does everything live?
This project, like many Godot projects, has many 'autoload' singleton scripts that run constantly to handle universal game logic.
This is essential to handling game loops and variables that run constantly throughout the game.
Below is a structural guide to what each one does:


## Autoload Jobs
Symbols:
	
\* = Modder-friendly. Just drag and drop data.

@ = Modder-friendly, but avoid changing functions or important-looking data. Check descriptions for stuff you might want to tweak.

! = Modder-unfriendly, should only be modified by experienced developers.

## ModLoaderStore (!) and ModLoader (!)
These two autoloads come directly from the Godot Mod Loader plugin. They read the mods directory, and compile data from installed mod files.
The code and rights to these plugins belong to their original developers, and most questions regarding their functionality can be quenched by
checking https://github.com/GodotModding/godot-mod-loader and https://wiki.godotmodding.com/

## PlayerDb (*)
PlayerDb, or 'player database' as the name suggests, handles the player's save file. As of 3/23/26, its main feature is the 'playerData' dictionary,
which stores the player's save data. This save file is converted to json format upon saving, and then imported every time they load a save file.
This autoload is referenced basically everywhere where something happens in-game that alters the player's save, or when their data
has to be modified to account for a stat change.

## Global (@)
The 'Global' autoload handles general code that is applicable project-wide. This includes data such as flags, which are minor variables that trigger
changes in things such as actor behavior, and also global variable references such as the player object. Many autoloads originally were extensions
of the Global autoload that got put into their own specialized scripts for the sake of readability.

## EnemyDb (*)
EnemyDb, or 'enemyDatabase,' keeps track of important enemy data and behavior across the game world and battle system. This includes basic stats,
attacks, and behaviors. This gets referenced a lot in the battle system as the system must account for many variables which are kept
inside of the 'enemies' dictionary.

## DialogueLoader (@)
DialogueLoader, as the name suggests, loads NPC dialogue from respective JSONs, usually kept at res://Assets/Data/Dialogue/ but stored
in NPC objects' data. This autoload has various functions that handle data manipulation and dialogue cycling that are relayed from JSON data.
This autoload is probably also the most sensitive, because, if modified maliciously, it could be abused to execute dangerous code.
For this reason it is only limited to access specific defined functions in a whitelist, so if you are having trouble getting something to execute,
you'd have to mod the game to define it there, first. This assures the only real way to execute malicious code would be going out of your way
to install a bad mod that changes the whitelist, and that people cannot be fooled by simple json repacks or translations. ALWAYS BE CAREFUL WHAT YOU INSTALL,
IT IS NOT MY RESPONSIBILITY TO CONTROL WHAT YOU DO AND DO NOT INSTALL ON YOUR OWN COMPUTER FROM OTHER PEOPLE

## UniversalAudio (!)
UniversalAudio is an autoload that handles simple audio functions, such as 'playSpecialSound', which will play any audio file that it points to.
It also handles default UI sound effects automatically, such as hovering over a button or clicking something.

## CowTools (!)
CowTools, named after a Gary Larson "Far Side" cartoon of the same name, handles simplistic UI or navigational functions that are applicable project wide,
such as functions that automatically populate ItemLists or Dials, or read or clear data from ItemLists. If you are looking at a UI element
and thinking to yourself "I don't know what to do now, there's no default function that can do my task..." then it would be a good idea
to look at CowTools and see if there's a helper function for that already.

## GlobalDb (*)
GlobalDb, not to be confused with PlayerDb, stores dictionary data for important global objects such as items, armor, and weapons.
This is used throughout the project for many purposes such as calculating damage, defense, item healing, reading descriptions, etc.

## BattleSystem (!)
You can probably already tell what this does by its name. This autoload handles many important functions and systems derived from the battle system,
such as turn order, enemy decisionmaking and behavior, enemy data loading, etc.

## ActionProcessor (!)
The action processor is a singleton that handles the processing and queueing of 'actions,' dictionaries that carry various data that tell the game what to do,
usually relaying this information to the player in some sort of text or announcement in the context of item usage or turn-based combat.
Basically the data stream of any turn based rpg.

## InventoryHelper (!)
InventoryHelper, as the name suggests, carries various helper functions for the player's inventory data. These functions handle tasks such as
removing or adding items, and also reloading weapons and identifying specific equipped items.

## ActorHelper (@)
ActorHelper contains helper functions which change the state of actor nodes, such as NPCs or interactable objects. Usually these functions get triggered
by a reference inside of a dialogue JSON, and they're crucial for things such as animation changes. It's a viable alternative to handling interactions
inside of a million flags

## Settings (@)
Settings handles saving and loading the player's settings config file, and toggles options such as volume settings, graphics settings, and if mods are
enabled or disabled.

## GameplayActions (@)
GameplayActions handles logic and actions pertaining to basic gameplay, such as item actions (when items are used), and object actions (when objects are triggered)

## LevelDb (*)
LevelDb stores dictionary data for levels, and their variables which determine how they are loaded by the game.
'Variant' determines the specific node variant loaded by the game.
After the player's game is saved, levelDatabase is copied to the player's save data, and on load, it is copied from playerDb into levelDatabase.
