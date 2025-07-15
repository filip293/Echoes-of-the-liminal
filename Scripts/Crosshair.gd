extends Label

func _physics_process(delta: float) -> void:
	if Globals.showingcrosshair:
		visible = true
	else: 
		visible = false
