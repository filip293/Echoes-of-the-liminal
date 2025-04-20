extends RayCast3D

@onready var raycast: RayCast3D = self
@onready var label: RichTextLabel = $"../../../../InstViewport/InteractTextWrapper/InteractText"

func _physics_process(delta: float) -> void:
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.has_method('whoami'):
			var idex = collider.whoami()
			label.text = "[E] Interact with: " + idex
	else:
		label.text = ""
	
