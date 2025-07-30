extends Node2D

@onready var settingspanel = $"../Settings"

var menuopen = false
var lastinputstate

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ESC") and Globals.startedgame:
		toggle_pause_menu()
		
func returntopausemenu():
	$MainLayer/VBoxContainer.visible = true
	
func toggle_pause_menu():
	if menuopen:
		$MainLayer.visible = false
		if lastinputstate == 0:
			Globals.showingcrosshair = false
		else: 
			Globals.showingcrosshair = true
		Input.set_mouse_mode(lastinputstate)
		get_tree().paused = false
	else:
		$MainLayer.visible = true
		lastinputstate = Input.get_mouse_mode()
		Globals.showingcrosshair = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().paused = true
	
	menuopen = !menuopen

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_settings_pressed() -> void:
	$MainLayer/VBoxContainer.visible = false
	settingspanel.toggle_settings_menu()

func _on_return_pressed() -> void:
	toggle_pause_menu()
