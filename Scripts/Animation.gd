extends AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$/root/Node3D/Houses/house52/Flicker.play("Flicker")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if $/root/Node3D/Sitting/AnimationPlayer.is_playing() == false:
		$/root/Node3D/Sitting/AnimationPlayer.play("mixamo_com")
	if $".".is_playing() == false:
		$".".play("Sway")
	if $/root/Node3D/Houses/house22/house2/Hinge/house2_door1/Flicker.is_playing() == false:
		$/root/Node3D/Houses/house22/house2/Hinge/house2_door1/Flicker.play("Flicker")
