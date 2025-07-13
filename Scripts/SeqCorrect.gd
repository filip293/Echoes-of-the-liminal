extends Node3D

var scene1notfinished = false
var scene2notfinished = false

func scene1() -> void:
	pass
	
func _physics_process(delta: float) -> void:
	if Globals.entered_village and !scene1notfinished:
		pass
