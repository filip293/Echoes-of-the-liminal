extends Node

var beginningcutsceneended: bool = false

func temptime(TimeNeeded) -> void: #DUMB SHIT
	await get_tree().create_timer(TimeNeeded, false).timeout 
