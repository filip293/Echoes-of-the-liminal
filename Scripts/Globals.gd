extends Node

@onready var BaseTime = $/root/Node3D/BaseTime
signal timeend
var collectedbellparts: int = 0
var beginningcutsceneended: bool = false
var entered_village = false
var mouse_sensitivity = 0.2

var scenes = {
	"S1" : false,
	"S2" : false,
	"S3" : false
}

var potatoSwing = true

func calltime(time) -> void:
	BaseTime.set_wait_time(time)
	BaseTime.start()
	await BaseTime.timeout
	timeend.emit()
