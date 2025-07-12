extends Node

var collectedbellparts: int = 0
var beginningcutsceneended: bool = false
var entered_village = false
var mouse_sensitivity = 0.2

var potatoSwing = true

func temptime(TimeNeeded) -> void: #DUMB SHIT
	await get_tree().create_timer(TimeNeeded, false).timeout 
