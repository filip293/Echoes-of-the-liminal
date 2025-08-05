extends Node

@onready var BaseTime = $/root/Node3D/BaseTime
@onready var CharaScript = $/root/Node3D/CharacterBody3D
signal timeend
signal movehead
var playermoveallow: bool = false
var cameramoveallow: bool = false
var collectedbellparts: int = 0
var beginningcutsceneended: bool = false
var showingcrosshair: bool = true
var mouse_sensitivity = 0.2
var in_screen = false
var on_special_object = false
var startedgame = false
signal gamestart
signal sc1corEND
signal sc2corEND
signal sc3corEND
signal settingsloaded

var scenes = {
	"Village" : false,
	"S2" : false,
	"S3" : false
}

var potatoSwing = true

func showshadow() -> void:
	$"/root/Node3D/Shadow/AnimationPlayer".play("FazeIn")
	
func campanim() -> void:
	CharaScript.dissapearanim1()
	
func emitend(num) -> void:
	if num == 1:
		sc1corEND.emit()
	
func calltime(time) -> void:
	BaseTime.set_wait_time(time)
	BaseTime.start()
	await BaseTime.timeout
	timeend.emit()
	
