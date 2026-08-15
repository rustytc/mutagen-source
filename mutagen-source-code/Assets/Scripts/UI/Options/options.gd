extends Node2D
var renderer = ProjectSettings.get_setting_with_override("rendering/renderer/rendering_method")

# Called when the node enters the scene tree for the first time.
func _ready():
	if Settings.settingsRaw["modsEnabled"] == true:
		$mainOptions/modsEnabled.button_pressed = true
	match renderer:
		"gl_compatibility":
			$mainOptions/renderer.select(0)
		"forward_plus":
			$mainOptions/renderer.select(1)
		"mobile":
			$mainOptions/renderer.select(2)
	$mainOptions/musicVolume.value = Settings.settingsRaw["musicVolume"]
	$mainOptions/soundVolume.value = Settings.settingsRaw["sfxVolume"]
	match Settings.settingsRaw["textSpeed"]:
		"fast":
			$mainOptions/battleLogSpeed.select(0)
		"slow":
			$mainOptions/battleLogSpeed.select(1)
			


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



# Enabling/Disabling Mods

func _on_cancel_pressed():
	$modsWarning.hide()
	$mainOptions.show()
	$mainOptions/modsEnabled.button_pressed = false
	$mainOptions/renderer.grab_focus()



func _on_confirm_pressed():
	UniversalAudio.playSpecialSound("res://Assets/Sounds/UI/blip.mp3")
	$modsWarning.hide()
	$restartPrompt.show()
	$restartPrompt/No.grab_focus()
	Settings.settingsRaw["modsEnabled"] = true
	Settings.saveSettings()
	
func _on_reset_all_settings_pressed():
	UniversalAudio.playSpecialSound("res://Assets/Sounds/UI/blip.mp3")
	$resetAllSettingsPrompt.show()
	$resetAllSettingsPrompt/No.grab_focus()
	$mainOptions.hide()
	

	
func _on_mods_enabled_toggled(toggled_on):
	if self.visible == true and get_viewport().gui_get_focus_owner() == $mainOptions/modsEnabled:
		if toggled_on == true:
			UniversalAudio.playSpecialSound("res://Assets/Sounds/UI/blip.mp3")
			$modsWarning.show()
			$modsWarning/Cancel.grab_focus()
			$mainOptions.hide()
		else:
			Settings.settingsRaw["modsEnabled"] = false
			Settings.saveSettings()
			$mainOptions.hide()
			$restartPrompt.show()
			$restartPrompt/No.grab_focus()
		
	
func _on_resetSettings_yes_pressed():
	$resetAllSettingsPrompt.hide()
	DirAccess.remove_absolute("user://settings.cfg")
	$restartPrompt.show()
	$restartPrompt/No.grab_focus()
	
# Restarting
func _on_yes_pressed():
	print("SYSTEM: The game is now restarting to apply settings changes.")
	OS.set_restart_on_exit(true)
	get_tree().quit()

func _on_no_pressed():
	$restartPrompt.hide()
	$resetAllSettingsPrompt.hide()
	$mainOptions.show()
	$mainOptions/renderer.grab_focus()



# Changing Graphics Setting
func _on_renderer_item_selected(index):
	match index:
		0: # OpenGL (default/Compatibility)
			if renderer == "gl_compatibility":
				return
			else:
				Settings.settingsRaw["graphics"] = "gl_compatibility"
				Settings.settingsRaw["graphicsOverridden"] = true
				Settings.saveSettings()
				ProjectSettings.set_setting("rendering/renderer/rendering_method", "gl_compatibility")
				ProjectSettings.save()
				$mainOptions/renderer.release_focus()
				$mainOptions.hide()
				$restartPrompt.show()
				$restartPrompt/No.grab_focus()
		1: # Direct3D (Forward+)
			if renderer == "forward_plus":
				return
			else:
				Settings.settingsRaw["graphics"] = "forward_plus"
				Settings.settingsRaw["graphicsOverridden"] = true
				Settings.saveSettings()
				ProjectSettings.set_setting("rendering/renderer/rendering_method", "forward_plus")
				ProjectSettings.save()
				$mainOptions/renderer.release_focus()
				$mainOptions.hide()
				$restartPrompt.show()
				$restartPrompt/No.grab_focus()
		2: # Vulkan (Mobile)
			if renderer == "mobile":
				return
			else:
				Settings.settingsRaw["graphics"] = "mobile"
				Settings.settingsRaw["graphicsOverridden"] = true
				Settings.saveSettings()
				ProjectSettings.set_setting("rendering/renderer/rendering_method", "mobile")
				ProjectSettings.save()
				$mainOptions/renderer.release_focus()
				$mainOptions.hide()
				$restartPrompt.show()
				$restartPrompt/No.grab_focus()

func _on_battle_log_speed_item_selected(index):
	match index:
		0: # Fast text speed
			Settings.settingsRaw["textSpeed"] = "fast"
		1: # Slow text speed
			Settings.settingsRaw["textSpeed"] = "slow"
	Settings.saveSettings()

func _on_back_pressed():
	self.hide()
	get_parent().get_node("menu").show()
	get_parent().get_node("Logo").show()
	get_parent().get_node("menu/options").grab_focus()



# Volume

func _on_music_volume_value_changed(value):
	if visible == true:
		Settings.settingsRaw["musicVolume"] = $mainOptions/musicVolume.value
		Settings.saveSettings()
		UniversalAudio.playSpecialSound("res://Assets/Sounds/UI/blip2.mp3", &"BGM")

func _on_sound_volume_value_changed(value):
	if visible == true:
		Settings.settingsRaw["sfxVolume"] = $mainOptions/soundVolume.value
		Settings.saveSettings()
		UniversalAudio.playSpecialSound("res://Assets/Sounds/UI/blip2.mp3", &"SFX")
