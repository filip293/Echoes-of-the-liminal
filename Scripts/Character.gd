extends CharacterBody3D

@onready var neck := $Neck
@onready var camera := $Neck/Camera
@onready var left_foot_audio := $LeftFootAudio
@onready var right_foot_audio := $RightFootAudio
@onready var mnst_lf_audio := $MonsterSteps/LeftFootAudio
@onready var mnst_rf_audio := $MonsterSteps/RightFootAudio
const SPEED = 2
const SPRINT_MULTIPLIER = 10
var footstep_timer = 0.0
var sec_footstep_timer = 0.0
var is_left_foot = false
var Look_Behind = false
var playerinarea = false
var monsterfollowing = false
var walking = true

var village_entered = false

const FOOTSTEP_INTERVAL = 1.8 / SPEED

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

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Globals.mouse_sensitivity = 0.005
	Globals.cameramoveallow = false
	await Globals.calltime(4)
	$Animations.play("Look_Up")
	await Globals.calltime(0.3)
	DialogueManager.show_dialogue_balloon(load("res://Dialogue/dialogue.dialogue"), "Potato_Hey")
	await Globals.calltime(5)
	DialogueManager.show_dialogue_balloon(load("res://Dialogue/dialogue.dialogue"), "Potato")
	await Globals.calltime(1)
	$Animations.play("ZoomInConvo")
	await DialogueManager.dialogue_ended
	$Animations.play("ZoomOutConvo")
	Globals.cameramoveallow = true
	Globals.mouse_sensitivity = 0.2

func _process(delta: float) -> void:
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
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and Globals.cameramoveallow == true:
		self.rotate_y(deg_to_rad(event.relative.x * Globals.mouse_sensitivity * -1))
		
		var camera_rot = neck.rotation_degrees
		var rotation_to_apply_on_x_axis = (-event.relative.y * Globals.mouse_sensitivity);
		
		if (camera_rot.x + rotation_to_apply_on_x_axis < -90):
			camera_rot.x = -90
		elif (camera_rot.x + rotation_to_apply_on_x_axis > 70):
			camera_rot.x = 70
		else:
			camera_rot.x += rotation_to_apply_on_x_axis;
			neck.rotation_degrees = camera_rot

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
	if $"../Sitting/LookBehind" != null:
		Globals.cameramoveallow = false
		$"../Sitting/LookBehind".queue_free()
		$"../Sitting/Skeleton3D".queue_free()
	await Globals.calltime(1)
	DialogueManager.show_dialogue_balloon(load("res://Dialogue/dialogue.dialogue"), "Look_Behind")
	await DialogueManager.dialogue_ended
	Globals.cameramoveallow = true
	Look_Behind = true
	Globals.potatoSwing = false

func _on_look_at_potato_screen_entered() -> void:
	if Look_Behind == true:
		$"../Sitting/LookAtPotato".queue_free()
		await Globals.calltime(1)
		DialogueManager.show_dialogue_balloon(load("res://Dialogue/dialogue.dialogue"), "Potato_gone")
		Globals.playermoveallow = true
		await Globals.calltime(8)
		Globals.beginningcutsceneended = true
		
func _on_static_body_3d_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body.name == "CharacterBody3D" and $TempBranchBreak != null:
		playerinarea = true
		$TempBranchBreak.play()
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
		await Globals.sc1corEND
		DialogueManager.show_dialogue_balloon(load("res://Dialogue/dialogue.dialogue"), "InVillage")
		Globals.scenes["Village"] = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		Globals.playermoveallow = true
		Globals.cameramoveallow = true

func _House_Entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.name == "CharacterBody3D":
		footstep_sounds = wood_footstep_sounds

func _House_Exited(body: Node3D) -> void:
	if body is CharacterBody3D and body.name == "CharacterBody3D":
		footstep_sounds = dirt_footstep_sounds
