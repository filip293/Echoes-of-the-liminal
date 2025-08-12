extends Node

@onready var PlayerVoice = $/root/Node3D/CharacterBody3D/Neck/Voice
@onready var ShadowVoice = $/root/Node3D/Shadow/Voice
var john_current_voiceline = 0
var shadow_current_voiceline = 0

var john_voicelines = [
	preload("res://Voicelines/John/J1.mp3"),
	preload("res://Voicelines/John/J2.mp3"),
	preload("res://Voicelines/John/J3.mp3"),
	preload("res://Voicelines/John/J4.mp3"),
	preload("res://Voicelines/John/JMONO-VILL_1.mp3"),
	preload("res://Voicelines/John/JMONO-VILL_2.mp3"),
	preload("res://Voicelines/John/JMONO1_1.mp3"),
	preload("res://Voicelines/John/JMONO1_2.mp3"),
	preload("res://Voicelines/John/JMONO1_3.mp3")
]

var shadow_voicelines = [
	preload("res://Voicelines/Shadow/SH1.mp3"),
	preload("res://Voicelines/Shadow/SH2.mp3"),
	preload("res://Voicelines/Shadow/SH3.mp3"),
	preload("res://Voicelines/Shadow/SH4.mp3")
]

func _ready() -> void:
	ShadowVoice.volume_db = -32
	PlayerVoice.volume_db = -67
	
func playvoiceline(chara):
	if ShadowVoice.is_playing() or PlayerVoice.is_playing():
		ShadowVoice.stop()
		PlayerVoice.stop()
		
	if chara == "John":
		PlayerVoice.stream = john_voicelines[john_current_voiceline]
		john_current_voiceline+=1
		PlayerVoice.play()
	elif chara == "Shadow":
		ShadowVoice.stream = shadow_voicelines[shadow_current_voiceline]
		shadow_current_voiceline+=1
		ShadowVoice.play()
