extends AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$/root/Node3D/Houses/house12/house1/Flicker.play("Flicker")
	$/root/Node3D/Houses/house12/house1/house1_door1/Sway.play("Sway")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if $/root/Node3D/Sitting/AnimationPlayer.is_playing() == false and Globals.potatoSwing == true:
		$/root/Node3D/Sitting/AnimationPlayer.play("mixamo_com")
