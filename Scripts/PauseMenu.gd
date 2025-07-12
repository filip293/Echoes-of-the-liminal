extends Node2D

@onready var pause_menu = $PauseMenu
@onready var wrapper: CanvasLayer = $PauseMenuWrapper
@onready var sensitivity_slider = $PauseMenuWrapper/Settings/Sensetivity
@onready var volume_slider = $PauseMenuWrapper/Settings/Volume
@onready var gamma_slider = $PauseMenuWrapper/Settings/Gamma
@onready var quit_button = $PauseMenuWrapper/Settings/Quit
@onready var post_effect = $"../PostProcess"

var menu_open = false

func _ready():
	post_effect.configuration.StrenghtCA = 2.0
	wrapper.visible = true 
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	if Input.is_action_just_pressed("ESC"):
		toggle_pause_menu()

func toggle_pause_menu():
	if menu_open:
		pause_menu.play_backwards("menu")
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_tree().paused = false
	else:
		pause_menu.play("menu")
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().paused = true
	menu_open = !menu_open

func _on_sensitivity_changed(value):
	Globals.mouse_sensitivity = value

func _on_volume_changed(value):
	print("Volume:", value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

func _on_gamma_changed(value):
	print("Gamma:", value)

func _on_quit_pressed():
	get_tree().quit()

func _on_return_pressed() -> void:
	if menu_open:
		toggle_pause_menu()
