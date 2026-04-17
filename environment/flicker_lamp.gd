extends OmniLight3D

## Simple Flicker Script
## Randomly fluctuates light energy to create a flickering effect.

@export var min_energy: float = 0.5    # Minimum brightness
@export var max_energy: float = 1.5    # Maximum brightness
@export var flicker_speed: float = 0.05 # How often the light updates (in seconds)

var _timer: float = 0.0

func _process(delta: float) -> void:
	_timer += delta
	
	if _timer >= flicker_speed:
		# Assign a random energy value within our range
		light_energy = randf_range(min_energy, max_energy)
		_timer = 0.0
