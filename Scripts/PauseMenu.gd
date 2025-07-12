extends Node2D

@onready var pause_menu = $PauseMenu
@onready var wrapper: CanvasLayer = $PauseMenuWrapper
@onready var sensitivity_slider = $PauseMenuWrapper/ColorRect/Sensetivity
@onready var volume_slider = $PauseMenuWrapper/ColorRect/Volume
@onready var gamma_slider = $PauseMenuWrapper/ColorRect/Gamma
@onready var quit_button = $PauseMenuWrapper/ColorRect/Gamma

var menu_open = false

func _ready():
	
	wrapper.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	if Input.is_action_just_pressed("ESC"):
		toggle_pause_menu()

func toggle_pause_menu():
	if menu_open:
		pause_menu.play("close")
		wrapper.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_tree().paused = false
	else:
		pause_menu.play("open")
		wrapper.visible = true
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
