extends Node2D

@onready var post_effect = $/root/Node3D/PostProcess
@onready var player_cam = $/root/Node3D/CharacterBody3D/Neck/Camera

var settingsfile = "user://settings.cfg"
var defaultsettings = {
	"CA_ENABLED" : true,
	"PIX_ENABLED" : true,
	"VSYNC_ENABLED" : true,
	"BRIGHTNESS" : 1.0,
	"PLAYER_SENSITIVITY" : 0.2,
	"AUDIO_VOLUME" : 40
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
		if data["VSYNC_ENABLED"] == true:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		elif data["VSYNC_ENABLED"] == false:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
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

func loaddefaults():
	post_effect.configuration.ChromaticAberration = true
	post_effect.configuration.Pixelate = true
	post_effect.configuration.GrainPower = 60.0
	player_cam.environment.tonemap_exposure = 1.0
	Globals.mouse_sensitivity = 0.2
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(40))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	Globals.settingsloaded.emit()
