extends OmniLight3D

var ler = RandomNumberGenerator.new()
var randt = RandomNumberGenerator.new()

func _ready() -> void:
	self.light_energy = 3.575
	
func _process(delta: float) -> void:
	var ng_le = ler.randf_range(2.212, 3.713)
	var randtim = randt.randf_range(0.38, 0.71)
	self.light_energy = lerp(self.light_energy, ng_le, 0.2)
	await get_tree().create_timer(randtim).timeout
	
	
	
