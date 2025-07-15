extends Node

@onready var PlayerVoice = $/root/Node3D/CharacterBody3D/Neck/Voice
@onready var PotatoVoice = $/root/Node3D/Sitting/Voice
var john_current_voiceline = 0
var potatoman_current_voiceline = 0

var john_voicelines = [
	preload("res://Voicelines/J1.mp3"),
	preload("res://Voicelines/J2.mp3"),
	preload("res://Voicelines/J3.mp3"),
	preload("res://Voicelines/J4.mp3"),
	preload("res://Voicelines/J5.mp3"),
	preload("res://Voicelines/J6.mp3"),
	preload("res://Voicelines/J7.mp3"),
	preload("res://Voicelines/J8.mp3"),
	preload("res://Voicelines/JEND1.mp3")
]

var potatoman_voicelines = [
	preload("res://Voicelines/PM1.mp3"),
	preload("res://Voicelines/PM2.mp3"),
	preload("res://Voicelines/PM3.mp3"),
	preload("res://Voicelines/PM4.mp3"),
	preload("res://Voicelines/PMLAST.mp3")
]

func _ready() -> void:
	PotatoVoice.volume_db = -32
	PlayerVoice.volume_db = -67
	
func playvoiceline(chara):
	if PotatoVoice.is_playing() or PlayerVoice.is_playing():
		PotatoVoice.stop()
		PlayerVoice.stop()
		
	if chara == "John":
		PlayerVoice.stream = john_voicelines[john_current_voiceline]
		john_current_voiceline+=1
		PlayerVoice.play()
	elif chara == "Potato":
		PotatoVoice.stream = potatoman_voicelines[potatoman_current_voiceline]
		potatoman_current_voiceline+=1
		PotatoVoice.play()
