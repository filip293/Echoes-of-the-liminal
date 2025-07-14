extends Node

@onready var BaseTime = $/root/Node3D/BaseTime
signal timeend
signal movehead
var playermoveallow: bool = false
var cameramoveallow: bool = false
var collectedbellparts: int = 0
var beginningcutsceneended: bool = false
var mouse_sensitivity = 0.2
var in_screen = false
signal sc1corEND
signal sc2corEND
signal sc3corEND

var scenes = {
	"Village" : false,
	"S2" : false,
	"S3" : false
}

var potatoSwing = true

func emitend(num) -> void:
	if num == 1:
		sc1corEND.emit()
	
func calltime(time) -> void:
	BaseTime.set_wait_time(time)
	BaseTime.start()
	await BaseTime.timeout
	timeend.emit()
	
