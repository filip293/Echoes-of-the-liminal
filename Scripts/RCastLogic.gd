extends RayCast3D

@onready var label: RichTextLabel = $"../../../../InstViewport/InteractTextWrapper/InteractText"
@onready var SpecialInterAnim = $"../../../../InstViewport/SpecialInteraction/Animations"
@onready var SpecialItemTitle = $"../../../../InstViewport/SpecialInteraction/ITWrapper/ItemTitle"
@onready var SpecialItemDesc = $"../../../../InstViewport/SpecialInteraction/IDWrapper/ItemDesc"

@onready var painting = $/root/Node3D/Frame

var painting_original_position: Vector3 = Vector3(40.745, 2.295, 336.954)
var painting_original_rotation: Vector3
var painting_active: bool = false
var painting_tween: Tween = null

func _ready() -> void:
	painting_original_rotation = painting.rotation_degrees

func _physics_process(delta: float) -> void:
	handle_painting_interaction()
	
	
	if is_colliding():
		var collider = get_collider()
		#if collider and collider.special() and !Globals.in_screen:
			#var it = collider.get_title()
			#var id = collider.get_description()
			#
			#SpecialItemTitle.text = it
			#SpecialItemDesc.text = id
			#SpecialInterAnim.play("fade")
			#
			#
		if collider and collider.has_method('whoami') and !collider.special:
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
		
func handle_painting_interaction() -> void:
	if is_colliding():
		var collider = get_collider()

		if collider == painting and collider.has_method("specialcheck") and collider.specialcheck():
			label.text = "[E] Examine painting"

			if Input.is_action_just_pressed("Interact") and !painting_active:
				var player = get_tree().get_root().get_node("Node3D/CharacterBody3D")
				if player:
					var camera = player.get_node_or_null("Neck/Camera")
					if camera:
						var cam_transform = camera.global_transform

						# Clone camera rotation and apply painting scale
						var new_basis = Basis(cam_transform.basis)
						new_basis = new_basis.scaled(painting.global_transform.basis.get_scale())

						# Finer positioning adjustments
						var offset = -cam_transform.basis.z * 0.42   # closer
						offset += -cam_transform.basis.x * 0.18      # more to the left
						offset += cam_transform.basis.y * 0.02       # slightly higher
						var new_position = cam_transform.origin + offset

						# Apply new transform
						var new_transform = Transform3D(new_basis, new_position)

						# Tween into view
						painting_tween = create_tween()
						painting_tween.tween_property(painting, "global_transform", new_transform, 1.0)\
							.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

						# Disable collisions
						var collider_shape = painting.get_node_or_null("CollisionShape3D")
						if collider_shape:
							collider_shape.disabled = true

						Globals.in_screen = true
						painting_active = true
						Globals.playermoveallow = false
						Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Return painting with E
	elif painting_active and Input.is_action_just_pressed("Interact"):
		var original_basis = Basis().rotated(Vector3(1, 0, 0), deg_to_rad(painting_original_rotation.x))
		original_basis = original_basis.rotated(Vector3(0, 1, 0), deg_to_rad(painting_original_rotation.y))
		original_basis = original_basis.rotated(Vector3(0, 0, 1), deg_to_rad(painting_original_rotation.z))
		original_basis = original_basis.scaled(painting.global_transform.basis.get_scale())

		var original_transform = Transform3D(original_basis, painting_original_position)

		painting_tween = create_tween()
		painting_tween.tween_property(painting, "global_transform", original_transform, 1.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		Globals.in_screen = false
		painting_active = false
		Globals.playermoveallow = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

		# Re-enable collision after delay
		await Globals.calltime(1)
		var collider_shape = painting.get_node_or_null("CollisionShape3D")
		if collider_shape:
			collider_shape.disabled = false
	else:
		label.text = ""
