extends Node3D

func scene1() -> void:
	pass
	
func _physics_process(delta: float) -> void:
	if Globals.entered_village and Globals.scenes["S1"]:
		pass
