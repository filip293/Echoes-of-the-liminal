extends AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if $/root/Node3D/Sitting/AnimationPlayer.is_playing() == false:
		$/root/Node3D/Sitting/AnimationPlayer.play("mixamo_com")
