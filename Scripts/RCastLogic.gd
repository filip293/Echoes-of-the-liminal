extends RayCast3D

@onready var label: RichTextLabel = $"../../../../InstViewport/InteractTextWrapper/InteractText"

func _physics_process(delta: float) -> void:
	if is_colliding():
		var collider = get_collider()
		if collider and collider.has_method('whoami'):
			var idex = collider.whoami()
			label.text = "[E] To interact"
			
			#FOR DOOR IN CABIN 7
			if idex == "Open" and Input.is_action_just_pressed("Interact"):
				var sway_anim = $"../../../../Houses/house12/house1/house1_door1/Sway"
				var door = $"../../../../Houses/house12/house1/house1_door1"
				var time_pos = sway_anim.current_animation_position
				var sway_anim_data = sway_anim.get_animation("Sway")
				var track_idx = sway_anim_data.find_track("rotation", Animation.TYPE_VALUE)
				var current_rotation = door.rotation
				if track_idx != -1:
					current_rotation = sway_anim_data.track_interpolate(track_idx, time_pos)
				sway_anim.stop()
				$"../../../../Houses/house12/house1/house1_door1/StaticBody3D/DoorCreak".queue_free()
				door.rotation = current_rotation
				var target_rotation = current_rotation + Vector3(0, deg_to_rad(160), 0)
				var tween = create_tween()
				tween.tween_property(door, "rotation", target_rotation, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				$"../../../../Houses/house12/house1/house1_door1/StaticBody3D/DoorOpen".play()
				$"../../../../Houses/house12/house1/house1_door1/StaticBody3D/CollisionShape3D".disabled = true
				$"../../../../Houses/house12/house1/house1_door1/TempStay/TempReplace".disabled = false

			
			
	else:
		label.text = ""
