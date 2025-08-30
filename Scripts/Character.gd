extends CharacterBody3D

@export_group("Camera Physics")
@export var acceleration: float = 10.0
@export var friction: float = 5.0
@export var rotation_sensitivity: float = 0.1

@export_group("Rotation Clamps")
@export var clamp_up_deg: float = 70.0
@export var clamp_down_deg: float = -90.0

@export_group("Movement")
@export var walk_speed: float = 3.0
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
@onready var mnst_lf_audio := $MonsterSteps/LeftFootAudio
@onready var mnst_rf_audio := $MonsterSteps/RightFootAudio
@onready var stamina_bar = $/root/Node3D/InstViewport/Stamina/StaminaBar

var current_stamina: float
var stamina_regen_timer: float = 0.0
var footstep_timer = 0.0
var sec_footstep_timer = 0.0
var is_left_foot = false
var Look_Behind = false
var playerinarea = false
var monsterfollowing = false
var walking = true

var internaloverride = false
var village_entered = false
var t_bob: float = 0.0

var mouse_velocity := Vector2.ZERO
var camera_rotation_deg := Vector2.ZERO
var actual_velocity := Vector2.ZERO
var target_velocity := Vector2.ZERO
var camera_original_pos: Vector3

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

func take_control():
	internaloverride = true
	actual_velocity = Vector2.ZERO
	target_velocity = Vector2.ZERO
	
func release_control():
	camera_rotation_deg.y = rad_to_deg(self.global_rotation.y)
	camera_rotation_deg.x = rad_to_deg(neck.global_rotation.x)
	internaloverride = false
	
func _ready():
	$/root/Node3D/Houses/house12/house1/Flicker.play("Flicker")
	$/root/Node3D/Houses/house42/house4/house1_door1/Sway.play("Sway")
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
	$"../Nigger/Black".visible = false
	$"../Nigger".visible = false
	DialogueManager.show_dialogue_balloon(load("res://Dialogue/Shadow.dialogue"), "Shadow")
	await Globals.calltime(1.2)
	$Animations.play("Look_Up")
	await Globals.calltime(6)
	$/root/Node3D/Shadow/AnimationPlayer.play("Sitting")
	await DialogueManager.dialogue_ended
	release_control()
	Globals.playermoveallow = true
	Globals.cameramoveallow = true

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

	# Camera rotation logic moved here
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
	if can_sprint and Globals.playermoveallow:
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

	if Globals.playermoveallow and can_sprint or current_stamina < max_stamina:
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
			play_monster_following_footsteps()
			
	move_and_slide()

func _headbob(time: float) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bob_frequency) * bob_amplitude
	pos.x = cos(time * bob_frequency / 2) * bob_amplitude
	return pos

func play_monster_following_footsteps():
	if is_left_foot:
		mnst_lf_audio.stream = footstep_sounds[randi() % 3]
		mnst_lf_audio.play()
	else:
		mnst_rf_audio.stream = footstep_sounds[randi() % 3]
		mnst_rf_audio.play()
		
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
	if body is CharacterBody3D and body.name == "CharacterBody3D" and $TempBranchBreak != null:
		playerinarea = true
		$TempBranchBreak.play()
		$"../Survival".queue_free()
		await $TempBranchBreak.finished
		$TempBranchBreak.queue_free()
		await Globals.calltime(2)
		monsterfollowing = true
	
func _cancel_follow(body: Node3D) -> void:
	if body is CharacterBody3D and body.name == "CharacterBody3D" and monsterfollowing:
		monsterfollowing = false
		$/root/Node3D/Ground/Ambiance.stop()
		$/root/Node3D/Ground/Ambiance2.stop()
		$/root/Node3D/Ground/Ambiance3.stop()
		await Globals.calltime(1)
		if $"../StaticBody3D" != null:
			$"../StaticBody3D".queue_free()
		if $MonsterSteps != null:
			$MonsterSteps.queue_free()


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
