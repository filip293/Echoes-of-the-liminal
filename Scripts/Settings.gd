extends Node2D

@onready var wrapper: CanvasLayer = $SettingsLayer
@onready var sensitivity_slider = $SettingsLayer/Background/Sliderbox/Sensitivity/HSlider
@onready var volume_slider = $SettingsLayer/Background/Sliderbox/Volume/HSlider
@onready var gamma_slider = $SettingsLayer/Background/Sliderbox/Brightness/HSlider
@onready var post_effect = $"../PostProcess"
@onready var ca_check = $SettingsLayer/Background/Checkboxes/CA
@onready var pix_check = $SettingsLayer/Background/Checkboxes/PSX
@onready var vsync_check = $SettingsLayer/Background/Checkboxes/VSYNC
@onready var player_cam = $"../CharacterBody3D/Neck/Camera"
@onready var mainmenu = $"../MainMenu"
@onready var pausemenu = $"../PauseMenu"
var lastinputstate
var menu_open = false

func _ready():
	await Globals.settingsloaded
	importsettings()

func importsettings() -> void:
	ca_check.button_pressed = post_effect.configuration.ChromaticAberration
	pix_check.button_pressed = post_effect.configuration.Pixelate
	gamma_slider.value = player_cam.environment.tonemap_exposure
	sensitivity_slider.value = Globals.mouse_sensitivity
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	if DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED:
		vsync_check.button_pressed = true
	elif DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED:
		vsync_check.button_pressed = false
	
func _process(delta):
	if Input.is_action_just_pressed("ESC") and Globals.startedgame and menu_open:
		toggle_settings_menu()

func toggle_settings_menu():
	if menu_open:
		wrapper.visible = false
		if !Globals.startedgame:
			mainmenu.returntomainmenu()
		elif Globals.startedgame:
			pausemenu.returntopausemenu()
		var to_save = {
			"CA_ENABLED" : ca_check.button_pressed,
			"PIX_ENABLED" : pix_check.button_pressed,
			"VSYNC_ENABLED" : vsync_check.button_pressed,
			"BRIGHTNESS" : gamma_slider.value,
			"PLAYER_SENSITIVITY" : sensitivity_slider.value,
			"AUDIO_VOLUME" : volume_slider.value
		}
		SaveSystem.savedata(to_save)
	else:
		importsettings()
		wrapper.visible = true

	menu_open = !menu_open

func _on_sensitivity_changed(value):
	Globals.mouse_sensitivity = value

func _on_volume_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

func _on_gamma_changed(value):
	player_cam.environment.tonemap_exposure = value

func _on_defaults_pressed() -> void:
	SaveSystem.loaddefaults()
	await Globals.settingsloaded
	importsettings()
	
func _on_save_pressed() -> void:
	var to_save = {
		"CA_ENABLED" : ca_check.button_pressed,
		"PIX_ENABLED" : pix_check.button_pressed,
		"VSYNC_ENABLED" : vsync_check.button_pressed,
		"BRIGHTNESS" : gamma_slider.value,
		"PLAYER_SENSITIVITY" : sensitivity_slider.value,
		"AUDIO_VOLUME" : volume_slider.value
	}
	SaveSystem.savedata(to_save)
	toggle_settings_menu()
		
func _on_v_sync_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func _on_pixelation_toggled(toggled_on: bool) -> void:
	if toggled_on:
		post_effect.configuration.Pixelate = true
		post_effect.configuration.GrainPower = 45.0
	else:
		post_effect.configuration.GrainPower = 60.0
		post_effect.configuration.Pixelate = false

func _on_chromatic_abberation_toggled(toggled_on: bool) -> void:
	if toggled_on:
		post_effect.configuration.ChromaticAberration = true
	else:
		post_effect.configuration.ChromaticAberration = false


func _on_back_pressed() -> void:
	toggle_settings_menu()
