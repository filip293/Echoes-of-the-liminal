extends Node2D

@onready var wrapper: CanvasLayer = $SettingsLayer
@onready var sensitivity_slider = $SettingsLayer/Background/Sliderbox/Sensitivity/HSlider
@onready var volume_slider = $SettingsLayer/Background/Sliderbox/Volume/HSlider
@onready var gamma_slider = $SettingsLayer/Background/Sliderbox/Brightness/HSlider
@onready var fps_slider = $SettingsLayer/Background/FPSLimit/HSlider
@onready var fps_current = $SettingsLayer/Background/FPSLimit/HSplitContainer/CurrValue
@onready var post_effect = $"../PostProcess"
@onready var ca_check = $SettingsLayer/Background/Checkboxes/CA
@onready var pix_check = $SettingsLayer/Background/Checkboxes/PSX
@onready var vsync_check = $SettingsLayer/Background/Checkboxes/VSYNC
@onready var player_cam = $"../CharacterBody3D/Neck/Camera"
@onready var mode_select = $SettingsLayer/Background/WindowSelect/OptionButton
@onready var mainmenu = $"../MainMenu"
@onready var pausemenu = $"../PauseMenu"


var lastinputstate
var menu_open = false

var fps_steps = [30, 60, 75, 100, 120, 144, 165, 180, 240, 0]
func find_closest_fps(target_rate):
	var smallest_difference = INF
	var closest_value = fps_steps[0]
	
	for step_value in fps_steps:
		var current_difference = abs(step_value - target_rate)
		if current_difference < smallest_difference:
			smallest_difference = current_difference
			closest_value = step_value
	
	return closest_value
	
var windowmode = {
	4: 0, #If DisplayServer reports Ex. Fullscreen, select idx 0
	3: 1, #If DisplayServer reports Fullscreen, select idx 1
	2: 2  #If DisplayServer reports Windowed, select idx 2
}

func _ready():
	await Globals.settingsloaded
	importsettings()

func importsettings() -> void:
	ca_check.button_pressed = post_effect.configuration.ChromaticAberration
	pix_check.button_pressed = post_effect.configuration.Pixelate
	gamma_slider.value = player_cam.environment.tonemap_exposure
	sensitivity_slider.value = Globals.mouse_sensitivity
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	fps_slider.value = fps_steps.find(find_closest_fps(Engine.max_fps))
	if DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED:
		vsync_check.button_pressed = true
		fps_slider.editable = false
		$SettingsLayer/Background/FPSLimit/Disclaimer.visible = true
		fps_current.add_theme_color_override("font_color", String("#a5a5a5"))
	elif DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED:
		vsync_check.button_pressed = false
		fps_slider.editable = true
		$SettingsLayer/Background/FPSLimit/Disclaimer.visible = false
		fps_current.add_theme_color_override("font_color", String("#ffffff"))
	mode_select.select(windowmode[DisplayServer.window_get_mode()])
	
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
			"AUDIO_VOLUME" : volume_slider.value,
			"WINDOW_MODE" : mode_select.get_selected_id(),
			"FPS_LIMIT": fps_steps[fps_slider.value]
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
	importsettings()
	
func _on_save_pressed() -> void:
	var to_save = {
		"CA_ENABLED" : ca_check.button_pressed,
		"PIX_ENABLED" : pix_check.button_pressed,
		"VSYNC_ENABLED" : vsync_check.button_pressed,
		"BRIGHTNESS" : gamma_slider.value,
		"PLAYER_SENSITIVITY" : sensitivity_slider.value,
		"AUDIO_VOLUME" : volume_slider.value,
		"WINDOW_MODE" : mode_select.get_selected_id(),
		"FPS_LIMIT" : fps_steps[fps_slider.value],
	}
	SaveSystem.savedata(to_save)
	toggle_settings_menu()
		
func _on_v_sync_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		fps_slider.value = fps_steps.find(find_closest_fps(DisplayServer.screen_get_refresh_rate()))
		fps_slider.editable = false
		fps_current.add_theme_color_override("font_color", String("#a5a5a5"))
		$SettingsLayer/Background/FPSLimit/Disclaimer.visible = true
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = fps_steps[fps_slider.value]
		fps_slider.editable = true
		fps_current.add_theme_color_override("font_color", String("#ffffff"))
		$SettingsLayer/Background/FPSLimit/Disclaimer.visible = false
		
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

func _on_option_button_item_selected(index: int) -> void:
	DisplayServer.window_set_mode(mode_select.get_selected_id())

func _on_fps_value_changed(value: float) -> void:
	var selected_fps = fps_steps[int(value)]
	
	if selected_fps == 0:
		fps_current.text = "Unlimited"
		Engine.max_fps = 0
	else:
		fps_current.text = str(selected_fps) + " FPS"
		Engine.max_fps = selected_fps
