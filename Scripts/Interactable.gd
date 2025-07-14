extends StaticBody3D

@export var whoami_value = "Name"
@export var special = false
@export var title = ""
@export var description = ""

func whoami():
	return whoami_value

func specialcheck():
	return special

func get_title():
	return title

func get_description():
	return description
