extends AudioStreamPlayer3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if $".".is_playing() == false:
		$".".play()
	if $"../../../CharacterBody3D/Ambiance".is_playing() == false:
		$"../../../CharacterBody3D/Ambiance".play()
	if $"../../../CharacterBody3D/Ambiance2".is_playing() == false:
		$"../../../CharacterBody3D/Ambiance2".play()
	if $"../../../CharacterBody3D/Ambiance3".is_playing() == false:
		$"../../../CharacterBody3D/Ambiance3".play()
