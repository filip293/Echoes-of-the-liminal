extends Node2D

@onready var pause_menu = $PauseMenu
@onready var wrapper: CanvasLayer = $PauseMenuWrapper
@onready var sensitivity_slider = $PauseMenuWrapper/Settings/Sensetivity
@onready var volume_slider = $PauseMenuWrapper/Settings/Volume
@onready var gamma_slider = $PauseMenuWrapper/Settings/Gamma
@onready var quit_button = $PauseMenuWrapper/Settings/Quit
@onready var post_effect = $"../PostProcess"
@onready var ca_check = $"PauseMenuWrapper/Settings/Chromatic Abberation"
@onready var pix_check = $"PauseMenuWrapper/Settings/Pixelation"
@onready var vsync_check = $"PauseMenuWrapper/Settings/V-Sync"
@onready var player_cam = $"../CharacterBody3D/Neck/Camera"

var lastinputstate
var menu_open = false
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
	if FileAccess.file_exists(settingsfile):
		var loadedsettings = FileAccess.open(settingsfile, FileAccess.READ)
		var data = loadedsettings.get_var()
		post_effect.configuration.ChromaticAberration = data["CA_ENABLED"]
		ca_check.button_pressed = post_effect.configuration.ChromaticAberration
		post_effect.configuration.Pixelate = data["PIX_ENABLED"]
		if data["PIX_ENABLED"]:
			post_effect.configuration.GrainPower = 45.0
		elif !data["PIX_ENABLED"]:
			post_effect.configuration.GrainPower = 60.0
		pix_check.button_pressed = post_effect.configuration.Pixelate
		player_cam.environment.tonemap_exposure = data["BRIGHTNESS"]
		gamma_slider.value = player_cam.environment.tonemap_exposure
		Globals.mouse_sensitivity = data["PLAYER_SENSITIVITY"]
		sensitivity_slider.value = Globals.mouse_sensitivity
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(data["AUDIO_VOLUME"]))
		volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
		if data["VSYNC_ENABLED"] == true:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			vsync_check.button_pressed = true
		elif data["VSYNC_ENABLED"] == false:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			vsync_check.button_pressed = false
	
	elif !FileAccess.file_exists(settingsfile):
		var firstsave = FileAccess.open(settingsfile, FileAccess.WRITE)
		firstsave.store_var(defaultsettings)
		ca_check.button_pressed = defaultsettings["CA_ENABLED"]
		pix_check.button_pressed = defaultsettings["PIX_ENABLED"]
		vsync_check.button_pressed = defaultsettings["VSYNC_ENABLED"]
		gamma_slider.value = defaultsettings["BRIGHTNESS"]
		volume_slider.value = defaultsettings["AUDIO_VOLUME"]
		sensitivity_slider.value = defaultsettings["PLAYER_SENSITIVITY"]
	wrapper.visible = true 
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func savedata(newdata):
	var settings = FileAccess.open(settingsfile, FileAccess.WRITE)
	settings.store_var(newdata)
	
func _process(delta):
	if Input.is_action_just_pressed("ESC"):
		toggle_pause_menu()

func toggle_pause_menu():
	if menu_open:
		pause_menu.play_backwards("menu")
		Input.set_mouse_mode(lastinputstate)
		get_tree().paused = false
		var to_save = {
			"CA_ENABLED" : ca_check.button_pressed,
			"PIX_ENABLED" : pix_check.button_pressed,
			"VSYNC_ENABLED" : vsync_check.button_pressed,
			"BRIGHTNESS" : gamma_slider.value,
			"PLAYER_SENSITIVITY" : sensitivity_slider.value,
			"AUDIO_VOLUME" : volume_slider.value
		}
		savedata(to_save)
	else:
		lastinputstate = Input.get_mouse_mode()
		pause_menu.play("menu")
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().paused = true
	menu_open = !menu_open

func _on_sensitivity_changed(value):
	Globals.mouse_sensitivity = value

func _on_volume_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

func _on_gamma_changed(value):
	player_cam.environment.tonemap_exposure = value

func _on_quit_pressed():
	var to_save = {
			"CA_ENABLED" : ca_check.button_pressed,
			"PIX_ENABLED" : pix_check.button_pressed,
			"VSYNC_ENABLED" : vsync_check.button_pressed,
			"BRIGHTNESS" : gamma_slider.value,
			"PLAYER_SENSITIVITY" : sensitivity_slider.value,
			"AUDIO_VOLUME" : volume_slider.value
		}
	savedata(to_save)
	get_tree().quit()

func _on_return_pressed() -> void:
	if menu_open:
		toggle_pause_menu()
		var to_save = {
			"CA_ENABLED" : ca_check.button_pressed,
			"PIX_ENABLED" : pix_check.button_pressed,
			"VSYNC_ENABLED" : vsync_check.button_pressed,
			"BRIGHTNESS" : gamma_slider.value,
			"PLAYER_SENSITIVITY" : sensitivity_slider.value,
			"AUDIO_VOLUME" : volume_slider.value
		}
		savedata(to_save)

func _on_v_sync_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func _on_chromatic_abberation_toggled(toggled_on: bool) -> void:
	if toggled_on:
		post_effect.configuration.ChromaticAberration = true
	else:
		post_effect.configuration.ChromaticAberration = false

func _on_pixelation_toggled(toggled_on: bool) -> void:
	if toggled_on:
		post_effect.configuration.Pixelate = true
		post_effect.configuration.GrainPower = 45.0
	else:
		post_effect.configuration.GrainPower = 60.0
		post_effect.configuration.Pixelate = false
