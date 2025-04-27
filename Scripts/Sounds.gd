extends AudioStreamPlayer3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !$".".is_playing():
		$".".play()
	if Globals.beginningcutsceneended and Globals.entered_village == false:
		if !$"../../../Ground/Ambiance".is_playing():
			$"../../../Ground/Ambiance".play()
			$"../../../Ground/Ambiance2".play()
			$"../../../Ground/Ambiance3".play()
