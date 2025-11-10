extends CharacterBody3D

@export_group("Camera Physics")
@export var acceleration: float = 10.0
@export var friction: float = 5.0
@export var rotation_sensitivity: float = 0.1

@export_group("Rotation Clamps")
@export var clamp_up_deg: float = 70.0
@export var clamp_down_deg: float = -90.0

@export_group("Movement")
@export var walk_speed: float = 10.0
@export var sprint_speed: float = 6.0

@export_group("Headbob")
@export var bob_frequency: float = 2.0
@export var bob_amplitude: float = 0.06
@export var headbob_return_speed: float = 8.0

@export_group("FOV")
@export var base_fov: float = 75.0
@export var fov_change: float = 1.5

@export_group("Stamina")
@export var max_stamina: float = 100.0
@export var stamina_drain_rate: float = 15.0
@export var stamina_regen_rate: float = 20.0
@export var stamina_regen_delay: float = 1.0

@onready var neck := $Neck
@onready var camera := $Neck/Camera
@onready var left_foot_audio := $LeftFootAudio
@onready var right_foot_audio := $RightFootAudio
@onready var stamina_bar = $/root/Node3D/InstViewport/Stamina/StaminaBar
@onready var collision_shape := $CollisionShape3D

var post_process = load("res://Scripts/Post.tres")

var current_stamina: float
var stamina_regen_timer: float = 0.0
var footstep_timer = 0.0
var sec_footstep_timer = 0.0
var is_left_foot = false
var Look_Behind = false
var monsterfollowing = false
var walking = true
var sprintlock := true

var internaloverride = false
var village_entered = false
var t_bob: float = 0.0

var mouse_velocity := Vector2.ZERO
var camera_rotation_deg := Vector2.ZERO
var actual_velocity := Vector2.ZERO
var target_velocity := Vector2.ZERO
var camera_original_pos: Vector3

@onready var lantern_body := $LanternBody
@onready var lantern_light := $LanternLight

var dirt_footstep_sounds = [
	preload("res://Sounds/Steps_dirt-001.ogg"),
	preload("res://Sounds/Steps_dirt-002.ogg"),
	preload("res://Sounds/Steps_dirt-006.ogg")
]

var wood_footstep_sounds = [
	preload("res://Sounds/Steps_wood-1.ogg"),
	preload("res://Sounds/Steps_wood-2.ogg"),
	preload("res://Sounds/Steps_wood-3.ogg")
]

var footstep_sounds = dirt_footstep_sounds

# --- NEW ---
# A variable to hold the container for our spawned "eyes"
var eyes_container: Node3D
# --- END NEW ---

func take_control():
	internaloverride = true
	actual_velocity = Vector2.ZERO
	target_velocity = Vector2.ZERO
	
func release_control():
	camera_rotation_deg.y = rad_to_deg(self.global_rotation.y)
	camera_rotation_deg.x = rad_to_deg(neck.global_rotation.x)
	internaloverride = false
	
func _ready():
	# --- NEW ---
	# Create a container for the spawned eyes so we can manage them easily.
	# This node will hold all the duplicated balls.
	eyes_container = Node3D.new()
	eyes_container.name = "EyesContainer"
	add_child(eyes_container)
	# --- END NEW ---

	$/root/Node3D/Houses/house12/house1/Flicker.play("Flicker")
	$/root/Node3D/Houses/house42/house4/house1_door1/Sway.play("Sway")
	$/root/Node3D/Houses/Ranger/OmniLight3D/Flicker.play("Flicker")
	camera_original_pos = camera.position
	current_stamina = max_stamina
	if stamina_bar:
		stamina_bar.visible = false
	
	await Globals.gamestart
	camera_rotation_deg.y = rad_to_deg(self.rotation.y)
	camera_rotation_deg.x = rad_to_deg(neck.rotation.x)
	take_control()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Globals.showingcrosshair = true
	$"../InstViewport/InteractTextWrapper".visible = true
	Globals.cameramoveallow = false
	$Animations.play("RESET")
	await Globals.calltime(4)
	$"../Black/Black".visible = false
	$"../Black".visible = false
	DialogueManager.show_dialogue_balloon(load("res://Dialogue/Shadow.dialogue"), "Shadow")
	await Globals.calltime(1.2)
	$Animations.play("Look_Up")
	await Globals.calltime(6)
	$/root/Node3D/Shadow/AnimationPlayer.play("Sitting")
	await DialogueManager.dialogue_ended
	release_control()
	Globals.playermoveallow = true
	Globals.cameramoveallow = true
	$"../Lantern".visible = true
	await Globals.calltime(10)
	$/root/Node3D/Ground/Ambiance4.play()
	$"../Houses/Ranger/StaticBody3D13/Blink".play("Blink")

func dissapearanim1() -> void:
	$"../Survival/bonfire/Fire3".play("FireBig")
	await Globals.calltime(1)
	$"../Shadow".visible = false
	await Globals.calltime(1)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and Globals.cameramoveallow == true:
		target_velocity += event.relative

func _physics_process(delta: float) -> void:
	if internaloverride:
		return

	if not Globals.cameramoveallow or Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		target_velocity = Vector2.ZERO
		actual_velocity = lerp(actual_velocity, Vector2.ZERO, friction * delta * 2.0)
	else:
		actual_velocity = lerp(actual_velocity, target_velocity * Globals.mouse_sensitivity, acceleration * delta)
		target_velocity = lerp(target_velocity, Vector2.ZERO, friction * delta)

	camera_rotation_deg.y -= actual_velocity.x * rotation_sensitivity * 0.001667
	camera_rotation_deg.x -= actual_velocity.y * rotation_sensitivity * 0.001667
	
	camera_rotation_deg.x = clamp(camera_rotation_deg.x, clamp_down_deg, clamp_up_deg)
	
	self.rotation.y = deg_to_rad(camera_rotation_deg.y)
	neck.rotation.x = deg_to_rad(camera_rotation_deg.x)
		
	if not is_on_floor():
		velocity.y -= delta * ProjectSettings.get_setting("physics/3d/default_gravity")

	var input_dir := Input.get_vector("Left", "Right", "Forwards", "Back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var target_camera_pos: Vector3
	
	var can_sprint = Input.is_action_pressed("Sprint") and is_on_floor() and direction != Vector3.ZERO and current_stamina > 0
	
	var speed = walk_speed
	if can_sprint and Globals.playermoveallow and !sprintlock:
		speed = sprint_speed
		current_stamina = max(0, current_stamina - stamina_drain_rate * delta)
		stamina_regen_timer = 0
	else:
		if not Input.is_action_pressed("Sprint"):
			stamina_regen_timer += delta
			if stamina_regen_timer >= stamina_regen_delay:
				current_stamina = min(max_stamina, current_stamina + stamina_regen_rate * delta)

	if direction and Globals.playermoveallow:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		walking = true
		
		var footstep_inter = (1.8 / walk_speed) * (walk_speed / speed)
		footstep_timer += delta
		if footstep_timer >= footstep_inter:
			footstep_timer = 0
			play_footstep_sound()
			
		t_bob += delta * velocity.length() * float(is_on_floor())
		target_camera_pos = camera_original_pos + _headbob(t_bob)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		walking = false
		target_camera_pos = camera_original_pos

	camera.position = lerp(camera.position, target_camera_pos, delta * headbob_return_speed)
	
	var velocity_clamped = clamp(velocity.length(), 0.5, sprint_speed * 2)
	var target_fov = base_fov + fov_change * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	if stamina_bar:
		stamina_bar.max_value = max_stamina
		stamina_bar.value = current_stamina

	if Globals.playermoveallow and can_sprint and !sprintlock or current_stamina < max_stamina:
		stamina_bar.visible = true
	else:
		stamina_bar.visible = false

	if monsterfollowing and velocity.x == 0.0 and velocity.z == 0.0:
		sec_footstep_timer = 0
		
	if monsterfollowing and (velocity.x != 0.0 or velocity.z != 0.0):
		sec_footstep_timer += delta
		var footstep_inter = 1.8 / walk_speed
		if sec_footstep_timer >= footstep_inter + 0.78:
			sec_footstep_timer = 0
			
	move_and_slide()

func _headbob(time: float) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bob_frequency) * bob_amplitude
	pos.x = cos(time * bob_frequency / 2) * bob_amplitude
	return pos
		
func play_footstep_sound():
	if Globals.playermoveallow:
		if is_left_foot:
			left_foot_audio.stream = footstep_sounds[randi() % 3]
			left_foot_audio.play()
		else:
			right_foot_audio.stream = footstep_sounds[randi() % 3]
			right_foot_audio.play()

		is_left_foot = !is_left_foot
		
func _on_static_body_3d_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body.name == "CharacterBody3D" and $Whisper != null:
		$"../StaticBody3D/Area3D/Sounds".play("TempFade")
		await Globals.calltime(1)
		$"../Ground/Ambiance4".stop()
		$Whisper.play()
		Globals.playermoveallow = false
		Globals.cameramoveallow = false
		await Globals.calltime(0.5)
		spawn_glowing_balls(1000, 2.0, 25.0, 50.0, 3.0)
		post_process.set("Glitch", true)
		post_process.set("StrenghtCA", 5)
		await Globals.calltime(5.5)
		post_process.set("Glitch", false)
		post_process.set("StrenghtCA", 1)
		clear_glowing_balls()
		Globals.playermoveallow = true
		Globals.cameramoveallow = true
		$"../InstViewport/Stamina/Label/LabelFlash".play("Flash")
		sprintlock=false
		$"../Survival".queue_free()
		await Globals.calltime(1)
		await $Whisper.finished
		$Whisper.queue_free()
		await Globals.calltime(2)
		monsterfollowing = true
	
func _cancel_follow(body: Node3D) -> void:
	if body is CharacterBody3D and body.name == "CharacterBody3D" and monsterfollowing:
		monsterfollowing = false
		$"../StaticBody3D/Area3D/Sounds".play("Fade")
		await Globals.calltime(1)
		if $"../StaticBody3D" != null:
			$"../StaticBody3D".queue_free()
		if $MonsterSteps != null:
			$MonsterSteps.queue_free()
		await Globals.calltime(1)
		$"../Ground/Ambiance".stop()
		$"../Ground/Ambiance2".stop()
		$"../Ground/Ambiance3".stop()
		$"../Houses/house32/Sink/StaticBody3D/Drop".play("Drip")

func _Village_enter(body: Node3D) -> void:
	if body is CharacterBody3D and body.name == "CharacterBody3D" and !Globals.scenes["Village"]:
		take_control()
		await Globals.sc1corEND
		DialogueManager.show_dialogue_balloon(load("res://Dialogue/dialogue.dialogue"), "InVillage")
		Globals.scenes["Village"] = true
		await Globals.sc1corEND
		release_control()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _House_Entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.name == "CharacterBody3D":
		footstep_sounds = wood_footstep_sounds

func _House_Exited(body: Node3D) -> void:
	if body is CharacterBody3D and body.name == "CharacterBody3D":
		footstep_sounds = dirt_footstep_sounds

func fall_backwards() -> void:
	if internaloverride:
		return
		
	take_control()
	
	# --- The rest of the player's fall sequence continues as before ---
	var final_body_position = Vector3(42.146, 2.135, 340.46)

	# PHASE 1: Bolt Look
	var look_tween = get_tree().create_tween().set_parallel()
	var look_duration = 0.3
	var look_left_deg = 25.0
	var target_body_rotation_y = rotation.y + deg_to_rad(look_left_deg)
	var look_up_deg = 10.0
	var target_neck_rotation_x = deg_to_rad(look_up_deg)
	look_tween.tween_property(self, "rotation:y", target_body_rotation_y, look_duration).set_trans(Tween.TRANS_SINE)
	look_tween.tween_property(neck, "rotation:x", target_neck_rotation_x, look_duration).set_trans(Tween.TRANS_SINE)
	look_tween.tween_property(camera, "fov", base_fov + 10, 0.1).set_trans(Tween.TRANS_SINE)
	look_tween.chain().tween_property(camera, "fov", base_fov, 0.3)
	await look_tween.finished

	# PHASE 2: Slow Steps Back
	var walk_tween = get_tree().create_tween()
	var walk_distance = 1.5
	var walk_duration = 2.5
	var walk_target_pos = global_position + global_transform.basis.z * walk_distance
	walk_tween.tween_property(self, "global_position", walk_target_pos, walk_duration).set_ease(Tween.EASE_OUT)
	await walk_tween.finished
	
	# PHASE 3: The Fall (Faster & More Impactful)
	var fall_tween = get_tree().create_tween().set_parallel()
	var fall_duration = 0.5
	var final_camera_local_pos = Vector3(camera_original_pos.x, -0.65, -0.499)
	fall_tween.tween_property(camera, "position", final_camera_local_pos, fall_duration).set_ease(Tween.EASE_IN)
	fall_tween.tween_property(neck, "rotation:x", deg_to_rad(20.0), fall_duration).set_ease(Tween.EASE_IN)
	if collision_shape.shape is CapsuleShape3D or collision_shape.shape is CylinderShape3D:
		fall_tween.tween_property(collision_shape.shape, "height", 0.1, fall_duration).set_ease(Tween.EASE_IN)
		$Fall.play()
		if lantern_body and lantern_body.visible:
			# Hide the lantern attached to the player's hand.
			lantern_body.visible = false
			lantern_light.visible = false
		$"../Houses/house12/house1/LanternLight".visible = true
		$"../Houses/house12/house1/LanternBody".visible = true
	fall_tween.tween_property(neck, "position:y", 0.3, fall_duration).set_ease(Tween.EASE_IN)
	fall_tween.tween_property(camera, "rotation:z", deg_to_rad(-8.0), fall_duration).set_ease(Tween.EASE_IN)
	await fall_tween.finished

	var impact_shake_tween = get_tree().create_tween()
	var impact_pos = camera.position + Vector3(0, -0.1, 0)
	impact_shake_tween.tween_property(camera, "position", impact_pos, 0.05)
	impact_shake_tween.tween_property(camera, "position", final_camera_local_pos, 0.1).set_delay(0.05)
	await impact_shake_tween.finished
	
	# PHASE 4: Stunned & Shuffle to Final Position
	var breathing_tween = get_tree().create_tween().set_loops()
	var breath_intensity = 0.02
	breathing_tween.tween_property(camera, "position:y", camera.position.y + breath_intensity, 0.8).set_trans(Tween.TRANS_SINE)
	breathing_tween.tween_property(camera, "position:y", camera.position.y, 1.0).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(2.0).timeout
	
	var shuffle_1_target = global_position.lerp(final_body_position, 0.5)
	var shuffle_tween_1 = get_tree().create_tween()
	shuffle_tween_1.tween_property(self, "global_position", shuffle_1_target, 1.5).set_ease(Tween.EASE_OUT)
	$Drag.play()
	await shuffle_tween_1.finished

	await get_tree().create_timer(0.4).timeout

	var shuffle_tween_2 = get_tree().create_tween()
	shuffle_tween_2.tween_property(self, "global_position", final_body_position, 1.8).set_ease(Tween.EASE_OUT)
	$Drag.play()
	await shuffle_tween_2.finished
	
	breathing_tween.kill()


func spawn_glowing_balls(amount: int, time_up: float, min_distance: float, max_distance: float, vertical_scatter: float = 1.5):
	# Ensure the template node exists before trying to use it
	if not has_node("Eyes"):
		push_error("The '$Eyes' node is missing and is required for spawn_glowing_balls().")
		return
		
	# Prevent division by zero if amount is 0 or 1.
	if amount <= 1:
		time_up = 0.0 # If only one, spawn instantly.
	
	# --- TIMER CORRECTION LOGIC ---
	var spawn_delay = time_up / float(amount)
	var start_time_msec = Time.get_ticks_msec()
	# --- END TIMER CORRECTION LOGIC ---
	
	var eye_level_height = neck.position.y

	for i in range(amount):
		# Get a random distance between the min and max values
		var random_distance = randf_range(min_distance, max_distance)
		
		# Get a random angle to position the ball anywhere around the player
		var random_angle = randf() * TAU # TAU is a full circle (2 * PI)
		
		# Calculate the X and Z position on that circle
		var x = cos(random_angle) * random_distance
		var z = sin(random_angle) * random_distance
		
		# Calculate the Y position based on eye level plus random scatter
		var y = eye_level_height + randf_range(-vertical_scatter, vertical_scatter)
		
		# Combine into the final spawn position (relative to the player)
		var spawn_position = Vector3(x, y, z)
		
		# Duplicate the template node.
		var new_eye = $Eyes.duplicate(DUPLICATE_USE_INSTANTIATION)
		
		# Set its properties
		new_eye.position = spawn_position
		new_eye.visible = true # Make the duplicated node visible
		
		# Add it to our container
		eyes_container.add_child(new_eye)
		
		# --- TIMER CORRECTION LOGIC ---
		if time_up > 0:
			# Calculate the absolute target time for the *next* spawn.
			var target_next_spawn_msec = start_time_msec + (i + 1) * spawn_delay * 1000.0
			
			# Get the current time *after* doing all the work above.
			var current_time_msec = Time.get_ticks_msec()
			
			# Calculate how long we actually need to wait to hit our target.
			var time_to_wait_sec = (target_next_spawn_msec - current_time_msec) / 1000.0
			
			# Only wait if we are not already behind schedule.
			if time_to_wait_sec > 0:
				await get_tree().create_timer(time_to_wait_sec).timeout


## Immediately removes all glowing balls that were previously spawned.
func clear_glowing_balls():
	if is_instance_valid(eyes_container):
		for child in eyes_container.get_children():
			child.queue_free()
