extends CharacterBody3D

@onready var neck := $Neck
@onready var camera := $Neck/Camera
@onready var left_foot_audio := $LeftFootAudio
@onready var right_foot_audio := $RightFootAudio

const SPEED = 4
var mouse_sensitivity = 0.2
var footstep_timer = 0.0
var is_left_foot = true
var can_move = false
var Look_Behind = false
var playerinarea = false

const FOOTSTEP_INTERVAL = 1.8 / SPEED

# Add 3 footstep sounds for each foot
var footstep_sounds = [preload("res://Sounds//Steps_dirt-001.ogg"), preload("res://Sounds//Steps_dirt-002.ogg"), preload("res://Sounds//Steps_dirt-006.ogg")]

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_sensitivity = 0.005
	await get_tree().create_timer(4).timeout
	$Animations.play("Look_Up")
	await get_tree().create_timer(0.3).timeout
	DialogueManager.show_dialogue_balloon(load("res://Dialogue/dialogue.dialogue"), "Potato_Hey")
	await get_tree().create_timer(5).timeout
	DialogueManager.show_dialogue_balloon(load("res://Dialogue/dialogue.dialogue"), "Potato")
	await get_tree().create_timer(1).timeout
	$Animations.play("ZoomInConvo")
	await DialogueManager.dialogue_ended
	$Animations.play("ZoomOutConvo")
	mouse_sensitivity = 0.2

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_pressed("ESC"):
		get_tree().quit()

	var input_dir := Input.get_vector("Left", "Right", "Forwards", "Back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction and can_move:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		footstep_timer += delta
		if footstep_timer >= FOOTSTEP_INTERVAL:
			footstep_timer = 0
			play_footstep_sound()
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		self.rotate_y(deg_to_rad(event.relative.x * mouse_sensitivity * -1))
		
		var camera_rot = neck.rotation_degrees
		var rotation_to_apply_on_x_axis = (-event.relative.y * mouse_sensitivity);
		
		if (camera_rot.x + rotation_to_apply_on_x_axis < -90):
			camera_rot.x = -90
		elif (camera_rot.x + rotation_to_apply_on_x_axis > 70):
			camera_rot.x = 70
		else:
			camera_rot.x += rotation_to_apply_on_x_axis;
			neck.rotation_degrees = camera_rot

func play_footstep_sound():
	if can_move:
		if is_left_foot:
			left_foot_audio.stream = footstep_sounds[randi() % 3] # Randomly select a sound
			left_foot_audio.play()
		else:
			right_foot_audio.stream = footstep_sounds[randi() % 3] # Randomly select a sound
			right_foot_audio.play()

		is_left_foot = !is_left_foot # Alternate foot

func _on_look_behind_screen_entered() -> void:
	if $"../Sitting/LookBehind" != null:
		$"../Sitting/LookBehind".queue_free()
		$"../Sitting/Skeleton3D".queue_free()
	await get_tree().create_timer(1).timeout
	DialogueManager.show_dialogue_balloon(load("res://Dialogue/dialogue.dialogue"), "Look_Behind")
	Look_Behind = true

func _on_look_at_potato_screen_entered() -> void:
	if Look_Behind == true:
		$"../Sitting/LookAtPotato".queue_free()
		await get_tree().create_timer(1).timeout
		DialogueManager.show_dialogue_balloon(load("res://Dialogue/dialogue.dialogue"), "Potato_gone")
		can_move = true
		await get_tree().create_timer(8).timeout
		Globals.beginningcutsceneended = true
		
func _on_static_body_3d_body_entered(_body: CharacterBody3D) -> void:
	playerinarea = true
	$TempBranchBreak.play()
	await $TempBranchBreak.finished
	$TempBranchBreak.queue_free()
