extends RayCast3D

@onready var label: RichTextLabel = $"../../../../InstViewport/InteractTextWrapper/InteractText"
@onready var SpecialInterAnim = $"../../../../InstViewport/SpecialInteraction/Animations"
@onready var SpecialItemTitle = $"../../../../InstViewport/SpecialInteraction/ITWrapper/ItemTitle"
@onready var SpecialItemDesc = $"../../../../InstViewport/SpecialInteraction/IDWrapper/ItemDesc"

var item_original_transforms: Dictionary = {} # path -> {position, rotation}
var active_item: Node3D = null
var item_active: bool = false
var item_tween: Tween = null

func _physics_process(delta: float) -> void:
	if item_active and Globals.in_screen:
		if Input.is_action_just_pressed("Interact"):
			SpecialInterAnim.play_backwards("fade")
			if active_item:
				handle_item_interaction(active_item, Vector3.ZERO)
			Globals.in_screen = false
			Globals.showingcrosshair = true
			
	if is_colliding():
		var collider = get_collider()

		if collider and collider.specialcheck():
			label.text = "[E] Examine " + collider.whoami()

			if Input.is_action_just_pressed("Interact"):
				var it = collider.get_title()
				var id = collider.get_description()
				SpecialItemTitle.text = it
				SpecialItemDesc.text = id
				SpecialInterAnim.play("fade")

				if collider.has_method("get_interaction_node") and collider.has_method("get_offset"):
					var item_node: Node3D = collider.get_interaction_node()
					var offset: Vector3 = collider.get_offset()

					print("Interacting with:", collider)
					print("Moving node:", item_node)
					print("Offset:", offset)

					if item_node:
						handle_item_interaction(item_node, offset)
					else:
						push_warning("get_interaction_node() returned null")

				Globals.in_screen = true
				Globals.showingcrosshair = false

		elif collider and collider.has_method('whoami') and !collider.special:
			var idex = collider.whoami()
			label.text = "[E] To interact"
			
			# Door interaction example
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

func handle_item_interaction(item: Node3D, offset: Vector3) -> void:
	if item == null:
		push_warning("Item passed to handle_item_interaction is null")
		return

	var path_str := str(item.get_path())

	if !item_original_transforms.has(path_str):
		item_original_transforms[path_str] = {
			"position": item.global_transform.origin,
			"rotation": item.rotation_degrees
		}

	if !item_active:
		var player = get_tree().get_root().get_node("Node3D/CharacterBody3D")
		if player:
			var camera = player.get_node_or_null("Neck/Camera")
			if camera:
				var cam_transform = camera.global_transform

				var new_basis = Basis(cam_transform.basis)
				new_basis = new_basis.scaled(item.global_transform.basis.get_scale())

				var new_position = cam_transform.origin
				new_position += -cam_transform.basis.z * offset.z
				new_position += -cam_transform.basis.x * offset.x
				new_position += cam_transform.basis.y * offset.y

				var new_transform = Transform3D(new_basis, new_position)

				print("Tweening item to:", new_transform.origin)

				item_tween = create_tween()
				item_tween.tween_property(item, "global_transform", new_transform, 1.0)\
					.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

				var collider_shape = item.find_child("CollisionShape3D", true, false)
				if collider_shape:
					collider_shape.disabled = true

				Globals.in_screen = true
				Globals.playermoveallow = false
				Globals.cameramoveallow = false
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

				active_item = item
				item_active = true

	elif item_active and active_item == item:
		var orig = item_original_transforms[path_str]
		var orig_rot: Vector3 = orig["rotation"]
		var orig_pos: Vector3 = orig["position"]

		var original_basis = Basis().rotated(Vector3(1, 0, 0), deg_to_rad(orig_rot.x))
		original_basis = original_basis.rotated(Vector3(0, 1, 0), deg_to_rad(orig_rot.y))
		original_basis = original_basis.rotated(Vector3(0, 0, 1), deg_to_rad(orig_rot.z))
		original_basis = original_basis.scaled(item.global_transform.basis.get_scale())

		var original_transform = Transform3D(original_basis, orig_pos)

		item_tween = create_tween()
		item_tween.tween_property(item, "global_transform", original_transform, 1.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		Globals.in_screen = false
		Globals.playermoveallow = true
		Globals.cameramoveallow = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

		await Globals.calltime(1)
		var collider_shape = item.find_child("CollisionShape3D", true, false)
		if collider_shape:
			collider_shape.disabled = false

		active_item = null
		item_active = false
