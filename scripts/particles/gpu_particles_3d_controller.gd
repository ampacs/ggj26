extends GPUParticles3D

func _ready() -> void:
	self.connect("finished", _reset)

func _reset() -> void:
	self.emitting = false

func trigger() -> void:
	self.emitting = true
