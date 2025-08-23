extends CharacterBody3D

@export_group("Camera Physics")
@export var acceleration: float = 10.0
@export var friction: float = 5.0
@export var rotation_sensitivity: float = 0.1

@export_group("Rotation Clamps")
@export var clamp_up_deg: float = 70.0
@export var clamp_down_deg: float = -90.0


@onready var neck := $Neck
@onready var camera := $Neck/Camera
@onready var left_foot_audio := $LeftFootAudio
@onready var right_foot_audio := $RightFootAudio
@onready var mnst_lf_audio := $MonsterSteps/LeftFootAudio
@onready var mnst_rf_audio := $MonsterSteps/RightFootAudio
const SPEED = 2
const SPRINT_MULTIPLIER = 1.65
var footstep_timer = 0.0
var sec_footstep_timer = 0.0
var is_left_foot = false
var Look_Behind = false
var playerinarea = false
var monsterfollowing = false
var walking = true

var internaloverride = false
var village_entered = false
const FOOTSTEP_INTERVAL = 1.8 / SPEED

var mouse_velocity := Vector2.ZERO
var camera_rotation_deg := Vector2.ZERO
var actual_velocity := Vector2.ZERO
var target_velocity := Vector2.ZERO

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
	
	await Globals.gamestart
	camera_rotation_deg.y = rad_to_deg(self.rotation.y)
	camera_rotation_deg.x = rad_to_deg(neck.rotation.x)
	take_control()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Globals.showingcrosshair = true
	$"../InstViewport/InteractTextWrapper".visible = true
	Globals.cameramoveallow = false
	await Globals.calltime(4)
	DialogueManager.show_dialogue_balloon(load("res://Dialogue/Shadow.dialogue"), "Shadow")
	await Globals.calltime(1.2)
	$Animations.play("Look_Up")
	await Globals.calltime(5)
	#DialogueManager.show_dialogue_balloon(load("res://Dialogue/dialogue.dialogue"), "Potato")
	
	await Globals.calltime(1)
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
		
func _process(delta: float) -> void:
	if internaloverride:
		return
		
	if not Globals.cameramoveallow or Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		target_velocity = Vector2.ZERO
		actual_velocity = lerp(actual_velocity, Vector2.ZERO, friction * delta * 2.0)
	else:
		actual_velocity = lerp(actual_velocity, target_velocity * Globals.mouse_sensitivity, acceleration * delta)
		target_velocity = lerp(target_velocity, Vector2.ZERO, friction * delta)

	camera_rotation_deg.y -= actual_velocity.x * rotation_sensitivity * delta
	camera_rotation_deg.x -= actual_velocity.y * rotation_sensitivity * delta
	
	camera_rotation_deg.x = clamp(camera_rotation_deg.x, clamp_down_deg, clamp_up_deg)
	
	self.rotation.y = deg_to_rad(camera_rotation_deg.y)
	neck.rotation.x = deg_to_rad(camera_rotation_deg.x)
		
	if monsterfollowing and velocity.x == 0.0 and velocity.z == 0.0:
		sec_footstep_timer = 0
		
	if monsterfollowing and (velocity.x != 0.0 or velocity.z != 0.0):
		sec_footstep_timer += delta
		if sec_footstep_timer >= FOOTSTEP_INTERVAL + 0.78:
			sec_footstep_timer = 0
			play_monster_following_footsteps()
		
func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("Left", "Right", "Forwards", "Back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	velocity.y -= delta * ProjectSettings.get_setting("physics/3d/default_gravity")

	if direction and Globals.playermoveallow:
		walking = true
		var current_speed = SPEED
		if Input.is_action_pressed("Sprint"):
			current_speed *= SPRINT_MULTIPLIER
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed

		footstep_timer += delta
		var footstep_inter = FOOTSTEP_INTERVAL * (SPEED / current_speed)
		if footstep_timer >= footstep_inter:
			footstep_timer = 0
			play_footstep_sound()
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		walking = false

	move_and_slide()

func play_monster_following_footsteps():
	if is_left_foot:
		mnst_lf_audio.stream = footstep_sounds[randi() % 3] # Randomly select a sound
		mnst_lf_audio.play()
	else:
		mnst_rf_audio.stream = footstep_sounds[randi() % 3] # Randomly select a sound
		mnst_rf_audio.play()
		
func play_footstep_sound():
	if Globals.playermoveallow:
		if is_left_foot:
			left_foot_audio.stream = footstep_sounds[randi() % 3] # Randomly select a sound
			left_foot_audio.play()
		else:
			right_foot_audio.stream = footstep_sounds[randi() % 3] # Randomly select a sound
			right_foot_audio.play()

		is_left_foot = !is_left_foot # Alternate foot

func _on_look_behind_screen_entered() -> void:
	#if $"../Sitting/LookBehind" != null:
		#Globals.cameramoveallow = false
		#$"../Sitting/LookBehind".queue_free()
		#$"../Sitting/Skeleton3D".queue_free()
		#Globals.potatoSwing = false
		#$/root/Node3D/Sitting/AnimationPlayer.stop()
	await Globals.calltime(1)
	DialogueManager.show_dialogue_balloon(load("res://Dialogue/dialogue.dialogue"), "Look_Behind")
	await DialogueManager.dialogue_ended
	Globals.cameramoveallow = true
	Look_Behind = true
	

#func _on_look_at_potato_screen_entered() -> void:
	#if Look_Behind == true:
		#$"../Sitting/LookAtPotato".queue_free()
		#await Globals.calltime(1)
		#DialogueManager.show_dialogue_balloon(load("res://Dialogue/dialogue.dialogue"), "Potato_gone")
		#Globals.playermoveallow = true
		#await Globals.calltime(8)
		#Globals.beginningcutsceneended = true
		
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
