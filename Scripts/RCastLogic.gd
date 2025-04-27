extends RayCast3D

@onready var label: RichTextLabel = $"../../../../InstViewport/InteractTextWrapper/InteractText"

func _physics_process(delta: float) -> void:
	if is_colliding():
		var collider = get_collider()
		if collider and collider.has_method('whoami'):
			var idex = collider.whoami()
			label.text = "[E] Interact with: " + idex
	else:
		label.text = ""
	
