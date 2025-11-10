extends RayCast3D

@onready var SimpleInterText: RichTextLabel = $"../../../../InstViewport/InteractTextWrapper/InteractText"
@onready var SimpleInterAnim: AnimationPlayer = $"../../../../InstViewport/InteractTextWrapper/SimpleAnim"
@onready var SpecialInterAnim = $"../../../../InstViewport/SpecialInteraction/Animations"
@onready var SpecialItemTitle = $"../../../../InstViewport/SpecialInteraction/ITWrapper/ItemTitle"
@onready var SpecialItemDesc = $"../../../../InstViewport/SpecialInteraction/IDWrapper/ItemDesc"
@onready var CharacterBody = $/root/Node3D/CharacterBody3D

var item_original_transforms: Dictionary = {} # path -> Transform3D
var active_item: Node3D = null
var item_active: bool = false
var item_tween: Tween = null
var first = true
var first2 = true
var first3 = true
var itextvisible = false
var open = false

func _physics_process(delta: float) -> void:
	if item_active and Globals.in_screen:
		if Input.is_action_just_pressed("Interact"):
			SpecialInterAnim.play_backwards("fade")
			if active_item:
				handle_item_interaction(active_item, Vector3.ZERO)
			Globals.in_screen = false
			Globals.showingcrosshair = true
			
			if open:
				await Globals.calltime(0.5)
				CharacterBody.fall_backwards()
				open = false
				await Globals.calltime(15)
				$"../../../../Black/Black/ColorRect2".visible = true
				$"../../../../Black/Black".visible = true
				$"../../../../Ground".queue_free()
				$"../../../../Ground".queue_free()
				$"../../../../Houses".queue_free()
				$"../../../../InstViewport/SpecialInteraction/Crosshair".queue_free()
				
			
	if is_colliding():
		var collider = get_collider()

		if collider and collider.specialcheck():
			SimpleInterText.text = "[E] Examine " + collider.whoami()
			if !itextvisible:
				SimpleInterAnim.play("fade")
				itextvisible = true
			
			if Input.is_action_just_pressed("Interact"):
				CharacterBody.take_control()
				var it = collider.get_title()
				var id = collider.get_description()
				SpecialItemTitle.text = it
				SpecialItemDesc.text = id
				SpecialInterAnim.play("fade")
				

				if collider.has_method("get_interaction_node") and collider.has_method("get_offset"):
					var item_node: Node3D = collider.get_interaction_node()
					var offset: Vector3 = collider.get_offset()

					if item_node:
						handle_item_interaction(item_node, offset)
					else:
						push_warning("get_interaction_node() returned null")

				Globals.in_screen = true
				Globals.showingcrosshair = false
				
				var idex = collider.whoami()
				if idex == "Beer" and Input.is_action_just_pressed("Interact") and first:
					await Globals.calltime(0.5)
					DialogueManager.show_dialogue_balloon(load("res://Dialogue/dialogue.dialogue"), "Beer")
					await DialogueManager.dialogue_ended
					await Globals.calltime(1.5)
					$"../../../../Houses/house42/house4/house1_door1/Sway".play("Slam")
					await Globals.calltime(0.5)
					$"../../../../Houses/house42/house4/house1_door1/StaticBody3D/CollisionShape3D".disabled = false
					await Globals.calltime(0.3)
					$"../../../../Houses/house42/house4/house1_door1/DoorShut".queue_free()
					first = false
				
				if idex == "Walkie-Talkie" and Input.is_action_just_pressed("Interact") and first3:
					await Globals.calltime(0.5)
					$"../../../../Houses/Ranger/StaticBody3D13/TW".play()
					first3 = false
				
				if idex == "Photo" and Input.is_action_just_pressed("Interact"):
					open = true
					print("interact")
					
				if idex == "Locket" and Input.is_action_just_pressed("Interact") and $"../../../../Houses/house32/Locket/Locket2/AnimationPlayer".is_playing() == false:
					await Globals.calltime(1)
					$"../../../../Houses/house32/Locket/Locket2/Click".play()
					$"../../../../Houses/house32/Locket/Locket2/AnimationPlayer".set_speed_scale(2.0)
					$"../../../../Houses/house32/Locket/Locket2/AnimationPlayer".play("Armature|ArmatureAction")
					
					await Globals.calltime(1)
					if first2:
						DialogueManager.show_dialogue_balloon(load("res://Dialogue/dialogue.dialogue"), "Locket")
						first2 = false
					await Globals.calltime(1.5)
					$"../../../../Houses/house32/Locket/Locket2/AnimationPlayer".pause()


		elif collider and collider.has_method('whoami') and !collider.special:
			var idex = collider.whoami()
			if !itextvisible:
				SimpleInterAnim.play("fade")
				itextvisible = true
			
			if idex == "Open Door" and Input.is_action_just_pressed("Interact"):
				var door = collider
				var current_rotation = door.rotation
				var target_rotation = current_rotation + Vector3(0, deg_to_rad(110), 0)
				var tween = create_tween()
				tween.tween_property(door, "rotation", target_rotation, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

				var collision_shape = door.find_child("CollisionShape3D")
				if collision_shape:
					collision_shape.disabled = true

				var door_sound = door.find_child("DoorOpen")
				if door_sound:
					door_sound.play()
			
			if idex == "Open" and Input.is_action_just_pressed("Interact"):
				var sway_anim = $/root/Node3D/Houses/house42/house4/house1_door1/Sway
				var door = $"../../../../Houses/house42/house4/house1_door1"
				var time_pos = sway_anim.current_animation_position
				var sway_anim_data = sway_anim.get_animation("Sway")
				var track_idx = sway_anim_data.find_track("rotation", Animation.TYPE_VALUE)
				var current_rotation = door.rotation
				if track_idx != -1:
					current_rotation = sway_anim_data.track_interpolate(track_idx, time_pos)
				sway_anim.stop()
				if $"../../../../Houses/house42/house4/house1_door1/StaticBody3D/DoorCreak" != null:
					$"../../../../Houses/house42/house4/house1_door1/StaticBody3D/DoorCreak".queue_free()
				door.rotation = current_rotation
				var target_rotation = current_rotation + Vector3(0, deg_to_rad(110), 0)
				var tween = create_tween()
				tween.tween_property(door, "rotation", target_rotation, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				$"../../../../Houses/house42/house4/house1_door1/StaticBody3D/DoorOpen".play()
				$"../../../../Houses/house42/house4/house1_door1/StaticBody3D/CollisionShape3D".disabled = true
				$"../../../../Houses/house42/house4/house1_door1/TempStay/TempReplace".disabled = false
				
			if idex == "Lantern" and Input.is_action_just_pressed("Interact"):
				var lantern: Node3D = $"../../../../Lantern"
				var player = get_tree().get_root().get_node("Node3D/CharacterBody3D")
				var lantern_body = player.get_node("LanternBody")
				
				Globals.playermoveallow = false
				Globals.cameramoveallow = false

				var offset = Vector3(0, 0.2, 0)
				var target_transform = Transform3D(
					lantern_body.global_transform.basis,
					lantern_body.global_transform.origin + offset
				)

				var tween := create_tween()
				tween.tween_property(lantern, "global_transform", target_transform, 1.0)\
					.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

				tween.connect("finished", func():
					if lantern != null:
						lantern.queue_free()
					$"../../../LanternBody".visible = true
					$"../../../LanternLight".visible = true
					Globals.playermoveallow = true
					Globals.cameramoveallow = true
				)
				
	else:
		if itextvisible:
				SimpleInterAnim.play_backwards("fade")
				await SimpleInterAnim.animation_finished
				SimpleInterText.text = "Press E to interact"
				itextvisible = false

func handle_item_interaction(item: Node3D, offset: Vector3) -> void:
	var path_str := str(item.get_path())

	# Save the full transform instead of separate pos/rot
	if !item_original_transforms.has(path_str):
		item_original_transforms[path_str] = item.global_transform

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
		# Restore the saved original transform directly
		var original_transform: Transform3D = item_original_transforms[path_str]

		item_tween = create_tween()
		item_tween.tween_property(item, "global_transform", original_transform, 1.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		Globals.in_screen = false
		CharacterBody.release_control()
		Globals.playermoveallow = true
		Globals.cameramoveallow = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

		await Globals.calltime(1)
		var collider_shape = item.find_child("CollisionShape3D", true, false)
		if collider_shape:
			collider_shape.disabled = false
			
		if active_item.get_path() == $"../../../../Houses/house32/Locket".get_path():
			$"../../../../Houses/house32/Locket/Locket2/AnimationPlayer".set_speed_scale(2.0)
			$"../../../../Houses/house32/Locket/Locket2/AnimationPlayer".play("Armature|ArmatureAction")


		active_item = null
		item_active = false
