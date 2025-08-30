extends Node2D

@onready var MainMenuCam = $MainLayer/Camera3D
@onready var PlayerCam = $"../CharacterBody3D/Neck/Camera"
@onready var FireplaceEmitter = $"../Survival/bonfire/Fire2"
@onready var SettingsPanel = $"../Settings"

func returntomainmenu():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$MainLayer/VBoxContainer.visible = true
	get_tree().paused = true
	MainMenuCam.current = true
	Globals.showingcrosshair = false
	if !$Music.playing:
		$Music.play()
	
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$MainLayer.visible = true
	get_tree().paused = true
	MainMenuCam.current = true
	Globals.showingcrosshair = false
	$Music.play()
	
func _on_start_new_pressed() -> void:
	get_tree().paused = false
	$Music.stop()
	Globals.startedgame = true
	$"../Nigger/Black2".play("Black")
	$MainLayer.visible = false
	await Globals.calltime(1)
	$"../Nigger/Black2".play_backwards("Black")
	Globals.gamestart.emit()
	PlayerCam.current = true
	await Globals.calltime(1.1)
	FireplaceEmitter.volume_db = -17.0

func _on_settings_pressed() -> void:
	$MainLayer/VBoxContainer.visible = false
	SettingsPanel.toggle_settings_menu()

func _on_quit_pressed() -> void:
	get_tree().quit()
