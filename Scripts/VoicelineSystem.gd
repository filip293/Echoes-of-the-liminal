extends Node

@onready var PlayerVoice = $/root/Node3D/CharacterBody3D/Neck/Voice
@onready var ShadowVoice = $/root/Node3D/Shadow/Voice
var john_current_voiceline = 0
var shadow_current_voiceline = 0

var john_voicelines = [
	preload("res://Voicelines/John/J1.mp3"),
	preload("res://Voicelines/John/J2.mp3"),
	preload("res://Voicelines/John/J3.mp3"),
	#preload("res://Voicelines/John/J4.mp3"), #UNUSED AUDIO FILE, DO NOT TOUCH
	preload("res://Voicelines/John/JMONO-VILL_1.mp3"),
	preload("res://Voicelines/John/JMONO-VILL_2.mp3"),
	preload("res://Voicelines/John/JMONO1_1.mp3"),
	preload("res://Voicelines/John/JMONO1_2.mp3"),
	preload("res://Voicelines/John/JMONO1_3.mp3"),
	preload("res://Voicelines/John/JMONO-AMULET_1.mp3"),
	preload("res://Voicelines/John/JMONO-AMULET_2.mp3"),
	preload("res://Voicelines/John/JMONO-AMULET_3.mp3"),
	preload("res://Voicelines/John/JS-FINAL_1 Part1.mp3"),
	preload("res://Voicelines/John/JS-FINAL_1 Part2.mp3"),
	preload("res://Voicelines/John/JS-FINAL_1 Part3.mp3"),
	preload("res://Voicelines/John/JS-FINAL_1 Part4.mp3")
]

var shadow_voicelines = [
	preload("res://Voicelines/Shadow/SH1.mp3"),
	preload("res://Voicelines/Shadow/SH2.mp3"),
	preload("res://Voicelines/Shadow/SH3.mp3"),
	preload("res://Voicelines/Shadow/SH4.mp3"),
	preload("res://Voicelines/Shadow/SDW-FINAL_1 Part1.mp3"),
	preload("res://Voicelines/Shadow/SDW-FINAL_1 Part2.mp3"),
	preload("res://Voicelines/Shadow/SDW-FINAL_1 Part3.mp3")
]

func _ready() -> void:
	ShadowVoice.volume_db = -20
	PlayerVoice.volume_db = -50

func setidx(idx, chara):
	if chara == "John": 
		john_current_voiceline = idx
	elif chara == "Shadow":
		shadow_current_voiceline = idx
	else:
		print("INCORRECT CHARA ON IDX SETTING")
	
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
