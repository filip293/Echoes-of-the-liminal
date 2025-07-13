extends Node3D

func _village_enter(body: Node3D) -> void:
	if !Globals.scenes["Village"] and body is CharacterBody3D:
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
		Globals.playermoveallow = false
		Globals.cameramoveallow = false
		var tween = create_tween()
		tween.tween_property(self, "rotation_degrees:x", 0.0, 0.7).set_trans(Tween.TRANS_SINE)
		await tween.finished
		Globals.scenes["S1"] = true
		Globals.emitend(1)
		print("Correction finished, sc1corEND emitted.")
