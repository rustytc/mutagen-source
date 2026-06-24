extends Node2D
var skipped := false
var fadeInMusic = null
var renderer = null
var sandboxedOS := false
var time = Time.get_datetime_dict_from_system()
var engineVersion : Dictionary = {}
var gameName : String = ""
# Called when the node enters the scene tree for the first time.
func _ready():
	renderer = RenderingServer.get_video_adapter_vendor()
	if renderer == "NVIDIA" and ProjectSettings.get_setting_with_override("rendering/renderer/rendering_method") == "gl_compatibility" and not OS.is_debug_build() and not Settings.settingsRaw["graphicsOverridden"]:
		ProjectSettings.set_setting("rendering/renderer/rendering_method", "mobile")
		ProjectSettings.save()
		print("SYSTEM: NVIDIA graphics detected! Falling back on Vulkan graphics renderer, can be changed back in the game's settings. Sorry!")
		OS.set_restart_on_exit(true)
		get_tree().quit()
	elif renderer != "NVIDIA" and ProjectSettings.get_setting_with_override("rendering/renderer/rendering_method") == "mobile" and not OS.is_debug_build() and not Settings.settingsRaw["graphicsOverridden"]:
		print("SYSTEM: Undoing NVIDIA graphics hack. Sorry!")
		ProjectSettings.set_setting("rendering/renderer/rendering_method", "gl_compatibility")
		ProjectSettings.save()
		OS.set_restart_on_exit(true)
		get_tree().quit()
		
		# If the renderer is compatability and the user is running nvidia drivers, there is a highly likely
		# chance that their screen will be completely blacked out due to a driver overwriting scaling settings.
		# it is for that reason that by default the game doesnt let nvidia users use this renderer
		# (otherwise, its turned ON because it works well with older intel integrated gpus)
		
		
	# Setting up the screen
	get_window().transparent = true
	# prevent black background
	get_viewport().transparent_bg = true
	
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	
	# OS Specific Settings
	if Settings.operatingSystem != "Windows" and Settings.operatingSystem != "Linux" and Settings.operatingSystem != "macOS" and Settings.operatingSystem != "FreeBSD" and Settings.operatingSystem != "NetBSD" and Settings.operatingSystem != "OpenBSD" and Settings.operatingSystem != "BSD":
		sandboxedOS = true # NOTE TO SELF: DO NOT, FOR THE LOVE OF GOD, LEAVE THE MODLOADER'S FILES INSIDE
		# THE MOBILE PORTS. THAT WILL GET YOU BANNED REAAAAL QUICK
	
	
	
	# These are pretty trendy
	var tomcatTexts = [
	"A game by Rusty Tincan",
	"A GAME BY TECHNIGAMES", 
	"A GAME BY TOMCAT",
	"a game by a rusty tin can",
	"Thank you for playing <3", 
	"These are pretty trendy!", 
	"How'd you find me?", 
	"This font is Open Source!", 
	"Unfinished and broken!", 
	"In progress since 2025!", 
	"Da da da da duh duh",  
	"I hope this game gets finished.",
	"And most importantly,\n\nTHANK YOU",
	"With peculiar music taste.",
	"No!!! Don't decompile my game!!!",
	"Inspired by many games.",
	"Issued under the GNU Public License v3.0.",
	"[color=white]Don't get comfortable.[/color]",
	"Hey, you!",
	"Hope you're having a good day.",
	]
	
	for i in range(50):
		tomcatTexts.append("A game by Rusty Tincan")

	# bonus lines
	engineVersion = Engine.get_version_info()
	if engineVersion["major"] != 4 or engineVersion["minor"] != 3:
		tomcatTexts.append("Do not make a PR.")
	gameName = ProjectSettings.get_setting_with_override("application/config/name")
	if gameName != "Mutagen: Lock and Load":
		tomcatTexts.append("Nice fork you got.")
	
	
	var distro = distroDetect()
	if distro.contains("Arch"):
		tomcatTexts.append("I use Arch, BTW.")
	if distro.contains("Mint"):
		tomcatTexts.append("Freshly picked off the Mint!")
	if distro.contains("Ubuntu"):
		tomcatTexts.append("Bonus Canonical telemetry not detected... Installed Successfully!")
	if distro.contains("Fedora"):
		tomcatTexts.append("Red Hat? Take that off.")
	if distro.contains("Gentoo"):
		tomcatTexts.append("Time to recompile your web browser, creep.")
	if distro.contains("openSUSE"):
		tomcatTexts.append("What's your car insurance plan?")
	if distro.contains("SteamOS"):
		tomcatTexts.append("Steam Deck Verified!")
	if distro.contains("Montana"):
		tomcatTexts.append("Sweet niblets!")
	if distro.contains("Suicide"):
		tomcatTexts.append("I just mistyped something into your terminal. For fun! x3")
	if distro.contains("AmogOS"):
		tomcatTexts.append("Sussy.")
	if distro.contains("Lindows"):
		tomcatTexts.append("Luts lup, lussy lat?")
	if distro.contains("Red Star"):
		tomcatTexts.append("Glory to our supreme leader!")
	if distro.contains("Bieber"):
		tomcatTexts.append("And I was like...")
	if distro.contains("kisser"):
		tomcatTexts.append("Hey, kiddo. We need to have a talk about your internet usage.")
	if distro.contains("UwUntu"):
		tomcatTexts.append("OwO")
	if distro.contains("Void"):
		tomcatTexts.append("If you stare long enough into the Void...")
	if distro.contains("Kali"):
		tomcatTexts.append("M4573R H4CK3R!!11!")
	if distro.contains("Qubes"):
		tomcatTexts.append("Where are your VMs, coward?")
	if distro.contains("ChromeOS"):
		tomcatTexts.append("Sorry, buddy.")
	if distro.contains("Manjaro"):
		tomcatTexts.append("Awwwwww... Awe you scawed of Arch Linux???")
	if OS.get_name() == "FreeBSD":
		tomcatTexts.append("Wait... You run FreeBSD??? What are you? A nerd?")
	if OS.get_name() == "OpenBSD":
		tomcatTexts.append("Wait... You run OpenBSD??? What are you? A pufferfish?")
	if OS.get_name() == "NetBSD":
		tomcatTexts.append("You're... Using NetBSD to play video games?")
	if OS.get_name() == "macOS":
		tomcatTexts.append("Designed by tomcat in Illinois.")
	if OS.get_name() == "Windows":
		tomcatTexts.append("Updates are underway. Please do not turn off your computer.")
	if OS.get_name() == "Android":
		tomcatTexts.append("When the world doesn't, tomcat does.")
	if OS.get_name() == "iOS":
		tomcatTexts.append("Freshly jailbroken. Secrets, unc0vered.")
	
	var tomcatText : String = "[center]"+tomcatTexts.pick_random()
	var specialText : String = ""
	# special texts
	

	
	if Global.rng.randi() % 1000 == 0:
		specialText = ["Hello, Michael.", "Hello, John.", "[color=red]HEY, FRANK! I SEE YOU!", "Hi, Aidan.", "Hiya, Mary!", "Hey, Patricia!", "heyyyy Jennifer heyyy girlll", "Morning Linda."].pick_random()
		# between you and me these are completely random names im just gonna mess with these people lol
			
	if specialText != "":
		tomcatText = "[center]"+specialText
		
	# bbcode stuff
	if time.hour == 3 and not tomcatText.contains("color"):
		tomcatText = "[color=red][center]" + tomcatText
		
	if ( time.month == 6 or engineVersion["major"] < 4 ) and not tomcatText.contains("color"):
		tomcatText = "[rainbow freq=0.5 sat=1.0 val=0.8][center]" + tomcatText
		
	if time.month == 10 and not tomcatText.contains("color"):
		tomcatText = "[color=orange][center]" + tomcatText
	
	if time.month == 10 and time.day == 31:
		tomcatText = "[center]Happy Halloween!"
	
	if isHanukkah(time):
		tomcatText = "[center][color=yellow]Happy Hanukkah!"
	
	if time.month == 12 and time.day == 25 and not isHanukkah:
		tomcatText = "[center][color=red]M[/color][color=green]e[/color][color=red]r[/color][color=green]r[/color][color=red]y[/color] [color=green]C[/color][color=red]h[/color][color=green]r[/color][color=red]i[/color][color=green]s[/color][color=red]t[/color][color=green]m[/color][color=red]a[/color][color=green]s[color=red]!"
		
	if (time.month == 12 and time.day >= 26) or (time.month == 1 and time.day <= 1):
		tomcatText = "[center][color=red]H[/color][color=#404040]a[/color][color=green]p[/color][color=red]p[/color][color=#404040]y[/color] [color=green]K[/color][color=red]w[/color][color=#404040]a[/color][color=green]n[/color][color=red]z[/color][color=#404040]a[/color][color=green]a[/color][color=red]![/color]"
	
	if isHanukkah(time) and time.day >= 25:
		tomcatText = "[center][color=yellow]Happy Holidays!"
	
	if time.month == 1 and time.day == 1:
		tomcatText = [
		"[center][color=yellow]Happy %s![/color]" % time.year,
		"[center][color=red]H[/color][color=#404040]a[/color][color=green]p[/color][color=red]p[/color][color=#404040]y[/color] [color=green]K[/color][color=red]w[/color][color=#404040]a[/color][color=green]n[/color][color=red]z[/color][color=#404040]a[/color][color=green]a[/color][color=red]![/color]"
		].pick_random()
		
	if distro.contains("Yellow") and not tomcatText.contains("color"):
		tomcatText = "[color=yellow][center]" + tomcatText
		
	if distro.contains("Tails"):
		tomcatText = "[center]Why are you on Tails? What are you doing?"
		
	if time.hour == 9:
		if time.minute == 41:
			tomcatText = "[center]Good morning."
		
	if distro.contains("Puppy"):
		$technigamesTune.stream = load("res://Assets/Sounds/UI/tomdogtune.ogg")
		
	if time.month == 10 and time.day == 31:
		$technigamesTune.stream = load("res://Assets/Sounds/Random/laugh.mp3")
		
	if (time.hour == 11 or time.hour == 23) and time.minute == 11:
		tomcatText = "[center]11:11, make a wish."
		
	if Global.rng.randi() % 1000 == 0:
		$technigamesTune.stream = load("res://Assets/Sounds/Random/quack quack.ogg")
	$agamebytomcat.text = tomcatText
	
	
	
	# Transition
	
	var fadeInCredit = create_tween()
	fadeInCredit.tween_property($agamebytomcat, "modulate:a", 1, 0.5).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	fadeInCredit.tween_property($background, "modulate:a", 1, 0.5).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	if not skipped:
		await get_tree().create_timer(0.5).timeout
	else:
		return
		
	if not skipped:
		$technigamesTune.play()
	
	if not skipped:
		await get_tree().create_timer(2).timeout
	else:
		return
	
	if not skipped:
		var fadeInCredit2 = create_tween()
		fadeInCredit2.tween_property($agamebytomcat, "modulate:a", 0, 0.5).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
		fadeInCredit2.tween_property($background, "modulate:a", 0, 0.5).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
		
	if not skipped:
		await get_tree().create_timer(1).timeout
	else:
		return
	
	var fadeInVisualLogo = create_tween()
	var fadeInVisualList = create_tween()
	var fadeInVisualPointer = create_tween()
	fadeInMusic = create_tween()
	fadeInVisualLogo.tween_property($Logo, "modulate:a", 1, 2.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	fadeInVisualList.tween_property($menu, "modulate:a", 1, 2.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	fadeInVisualPointer.tween_property($Pointer, "modulate:a", 1, 2.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	$Pointer.hide()
	$Music.play()
	fadeInMusic.tween_property($Music, "volume_db", 0, 2.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	skipped = true # has to be true or else it will loop over again on input
	$menu/continue.show()
	$menu/newGame.show()
	$background.z_index = -1
	$background.modulate.a = 1
	if not sandboxedOS:
		$menu/options.show()
		$menu/quit.show()
	if Settings.settingsRaw["modsEnabled"] != false and not sandboxedOS:
		$menu/mods.show()
	$menu/continue.grab_focus() # this has to be before anything is shown otherwise signals break and sounds wont play
	

func hurryUp():
	skipped = true
	$background.z_index = -1
	$agamebytomcat.queue_free()
	$Logo.modulate.a = 1
	$menu.modulate.a = 1
	$Pointer.modulate.a = 1
	$Pointer.hide()
	$technigamesTune.queue_free() 
	$Music.play()
	$Music.volume_db = 0
	$menu/continue.show()
	$menu/newGame.show()
	$menu/options.show()
	if Settings.settingsRaw["modsEnabled"] != false:
		$menu/mods.show()
	$menu/quit.show()
	$menu/continue.grab_focus() # this has to be before anything is shown otherwise signals break and sounds wont play

func _process(delta):
	if Input.is_action_just_pressed("Accept") and not skipped and $timer.is_stopped():
		hurryUp()
		



# Menu Functions

func _on_continue_pressed():
	if FileAccess.file_exists("user://saveFilesIndex.json"):
		loadSaveFiles()
	else:
		UniversalAudio.playSpecialSound("res://Assets/Sounds/UI/error.mp3")
func loadSaveFiles():
	print('done')




func _on_quit_pressed():
	$deathEffect.visible = true
	$deathEffect.triggered = true
	$Logo.play("Goodbye")
	if fadeInMusic != null and fadeInMusic.is_valid():
		fadeInMusic.kill()
	var fadeOutB = create_tween()
	var fadeOutL = create_tween()
	var fadeOutM = create_tween()
	var fadeOutV = create_tween()
	var fadeOutVideoP = create_tween()
	var fadeOutVideoR = create_tween()
	fadeOutB.tween_property($background, "modulate:a", 0, 1).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	fadeOutL.tween_property($Logo, "modulate:a", 0, 4).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	fadeOutM.tween_property($menu, "modulate:a", 0, 4).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	fadeOutV.tween_property($Music, "volume_db", -80, 4).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	$VideoStreamPlayer.material.set_shader_parameter("on", true)
	fadeOutVideoP.tween_property($VideoStreamPlayer.material, "shader_parameter/pickup_range", 1, 3)
	fadeOutVideoR.tween_property($VideoStreamPlayer.material, "shader_parameter/fade_amount", 1, 3)
	await get_tree().create_timer(4).timeout
	get_tree().quit()


func _on_options_pressed():
	$options.show()
	$options/mainOptions/renderer.grab_focus()
	$Logo.hide()
	$menu.hide()

# Easter egg functions
var hanukkahDates = { # gleaned from https://menorah.jakesamuelson.me/hanukkah-dates.html
	2026 : {
		"monthStart" : 12,
		"dateStart" : 4,
		"monthEnd" : 12,
		"dateEnd" : 12,
		"yearStart" : 2026,
		"yearEnd" : 2026,
		},
	2027 : {
		"monthStart" : 12,
		"dateStart" : 24,
		"monthEnd" : 1,
		"dateEnd" : 1,
		"yearStart" : 2027,
		"yearEnd" : 2028,
		},
	2028 : {
		"monthStart" : 12,
		"dateStart" : 12,
		"monthEnd" : 12,
		"dateEnd" : 20,
		"yearStart" : 2028,
		"yearEnd" : 2028,
		},
	2029 : {
		"monthStart" : 12,
		"dateStart" : 1,
		"monthEnd" : 12,
		"dateEnd" : 9,
		"yearStart" : 2029,
		"yearEnd" : 2029,
		},
	2030 : {
		"monthStart" : 12,
		"dateStart" : 20,
		"monthEnd" : 12,
		"dateEnd" : 28,
		"yearStart" : 2030,
		"yearEnd" : 2030,
		},
	2031 : {
		"monthStart" : 12,
		"dateStart" : 10,
		"monthEnd" : 12,
		"dateEnd" : 18,
		"yearStart" : 2031,
		"yearEnd" : 2031,
		},
	2032 : {
		"monthStart" : 11,
		"dateStart" : 28,
		"monthEnd" : 12,
		"dateEnd" : 6,
		"yearStart" : 2032,
		"yearEnd" : 2032,
		},
	2033 : {
		"monthStart" : 12,
		"dateStart" : 17,
		"monthEnd" : 12,
		"dateEnd" : 25,
		"yearStart" : 2033,
		"yearEnd" : 2033,
		},
	2034 : {
		"monthStart" : 12,
		"dateStart" : 7,
		"monthEnd" : 12,
		"dateEnd" : 15,
		"yearStart" : 2034,
		"yearEnd" : 2034,
		},
	2035 : {
		"monthStart" : 12,
		"dateStart" : 26,
		"monthEnd" : 1,
		"dateEnd" :3,
		"yearStart" : 2035,
		"yearEnd" : 2036,
		},
}
func isHanukkah(date): # return of the yandev
	for i in hanukkahDates:
		var year = hanukkahDates[i]
		if date.year == year["yearStart"] and date.month == year["monthStart"] and date.day >= year["dateStart"] and date.day <= year["dateEnd"] and date.month == year["monthEnd"] and date.year <= year["yearEnd"]:
			return true
		elif date.year == year["yearStart"] and date.month > year["monthStart"] and date.year < year["yearEnd"]:
			return true
		elif date.year == year["yearEnd"] and date.month == year["monthEnd"] and date.day <= year["dateEnd"]:
			return true
	return false
func distroDetect():
	if not FileAccess.file_exists("/etc/os-release"):
		return ""
	else:
		return( FileAccess.open("/etc/os-release", FileAccess.READ).get_as_text())
