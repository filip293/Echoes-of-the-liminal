extends Node2D

@onready var post_effect = $/root/Node3D/PostProcess
@onready var player_cam = $/root/Node3D/CharacterBody3D/Neck/Camera

var userpreferredfps
var settingsfile = "user://settings.cfg"
var defaultsettings = {
	"CA_ENABLED" : true,
	"PIX_ENABLED" : true,
	"VSYNC_ENABLED" : true,
	"BRIGHTNESS" : 1.0,
	"PLAYER_SENSITIVITY" : 1.8,
	"AUDIO_VOLUME" : 40,
	"WINDOW_MODE" : 4,
	"FPS_LIMIT" : 0
}

func _ready():
	# Loading all user settings
	if FileAccess.file_exists(settingsfile):
		var loadedsettings = FileAccess.open(settingsfile, FileAccess.READ)
		var data = loadedsettings.get_var()
		post_effect.configuration.ChromaticAberration = data["CA_ENABLED"]
		post_effect.configuration.Pixelate = data["PIX_ENABLED"]
		if data["PIX_ENABLED"]:
			post_effect.configuration.GrainPower = 45.0
		elif !data["PIX_ENABLED"]:
			post_effect.configuration.GrainPower = 60.0
		player_cam.environment.tonemap_exposure = data["BRIGHTNESS"]
		Globals.mouse_sensitivity = data["PLAYER_SENSITIVITY"]
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(data["AUDIO_VOLUME"]))
		DisplayServer.window_set_mode(data["WINDOW_MODE"])
		if data["VSYNC_ENABLED"] == true:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			userpreferredfps = data["FPS_LIMIT"]
			Engine.max_fps = 0
		elif data["VSYNC_ENABLED"] == false:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			userpreferredfps = data["FPS_LIMIT"]
			Engine.max_fps = userpreferredfps
		
	elif !FileAccess.file_exists(settingsfile):
		var firstsave = FileAccess.open(settingsfile, FileAccess.WRITE)
		firstsave.store_var(defaultsettings)
		loaddefaults()
	
	await Globals.gamestart
	Globals.settingsloaded.emit()
	
func getcurrentsettings():
	var loadedsettings = FileAccess.open(settingsfile, FileAccess.READ)
	var data = loadedsettings.get_var()
	return data

func savedata(newdata):
	var settings = FileAccess.open(settingsfile, FileAccess.WRITE)
	settings.store_var(newdata)
	userpreferredfps = newdata["FPS_LIMIT"]

func loaddefaults():
	post_effect.configuration.ChromaticAberration = true
	post_effect.configuration.Pixelate = true
	post_effect.configuration.GrainPower = 60.0
	player_cam.environment.tonemap_exposure = 1.0
	Globals.mouse_sensitivity = 1.8
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(40))
	DisplayServer.window_set_mode(4)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	Engine.max_fps = 0
	userpreferredfps = 0
	Globals.settingsloaded.emit()

func get_user_preferred_fps():
	return userpreferredfps
			
