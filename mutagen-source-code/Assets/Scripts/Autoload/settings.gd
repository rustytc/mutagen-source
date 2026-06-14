extends Node
var operatingSystem = OS.get_name()
var settingsRaw := {
	
	# Graphical Settings
	"graphics" : "gl_compatability", # can be toggled between forward+, mobile, and compatability
	# should display a notification that this should only be toggled if issues are encountered on a particular renderer, especially driver errors
	# should also warn that changing this setting is known to cause issues on NVIDIA drivers
	"graphicsOverridden": false,
	
	# Audio Settings
	"musicVolume" : 100,
	"sfxVolume" : 100,
	
	# Gameplay Settings
	"textSpeed" : "fast",
	
	# Technical Settings
	"modsEnabled" : false,
	"modsDetected" : false,
	
}


func saveSettings():
	var config = ConfigFile.new()

	config.set_value("settings", "graphics", settingsRaw["graphics"])
	config.set_value("settings", "textSpeed", settingsRaw["textSpeed"])
	config.set_value("settings", "graphicsOverridden", settingsRaw["graphicsOverridden"])
	config.set_value("settings", "musicVolume", settingsRaw["musicVolume"])
	config.set_value("settings", "sfxVolume", settingsRaw["sfxVolume"])
	config.set_value("settings", "modsEnabled", settingsRaw["modsEnabled"])

	config.save("user://settings.cfg")



# Called when the node enters the scene tree for the first time.
func _init():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err != OK:
		print('SYSTEM: Failed to load default settings, creating new config file. This is where system settings will be stored.')
		saveSettings()
	else:
		for settings in config.get_sections():
			settingsRaw["graphics"] = config.get_value(settings, "graphics")
			settingsRaw["graphicsOverridden"] = config.get_value(settings, "graphicsOverridden")
			settingsRaw["musicVolume"] = config.get_value(settings, "musicVolume")
			settingsRaw["sfxVolume"] = config.get_value(settings, "sfxVolume")
			settingsRaw["textSpeed"] = config.get_value(settings, "textSpeed")
			settingsRaw["modsEnabled"] = config.get_value(settings, "modsEnabled")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
