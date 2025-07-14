extends Node3D

var head_look_origin: Vector3

func _ready() -> void:
	head_look_origin = rotation_degrees
	Globals.connect("movehead", Callable(self, "_on_move_head"))

func _village_enter(body: Node3D) -> void:
	if !Globals.scenes["Village"] and body is CharacterBody3D:
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
		Globals.playermoveallow = false
		Globals.cameramoveallow = false

		var tween = create_tween()
		tween.tween_property(self, "rotation_degrees:x", 0.0, 0.7).set_trans(Tween.TRANS_SINE)
		await tween.finished

		head_look_origin = rotation_degrees

		Globals.scenes["S1"] = true
		Globals.emitend(1)
		print("Correction finished, sc1corEND emitted.")

func _on_move_head():
	print("Head movement triggered")

	var left = head_look_origin + Vector3(0, -15, 0)
	var right = head_look_origin + Vector3(0, 15, 0)

	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees", left, 0.5).set_trans(Tween.TRANS_SINE)
	await tween.finished
	await get_tree().create_timer(1.5).timeout

	tween = create_tween()
	tween.tween_property(self, "rotation_degrees", right, 0.5).set_trans(Tween.TRANS_SINE)
	await tween.finished
	await get_tree().create_timer(1.0).timeout

	tween = create_tween()
	tween.tween_property(self, "rotation_degrees", head_look_origin, 0.5).set_trans(Tween.TRANS_SINE)
	await tween.finished
