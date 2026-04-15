extends Node
class_name LightFlicker

## Attach to an OmniLight3D or SpotLight3D to make it flicker.

@export var flicker_chance: float = 0.02  ## Per-frame chance to flicker
@export var min_energy: float = 0.2
@export var max_energy: float = 1.5
@export var restore_speed: float = 3.0

var _base_energy: float = 1.0
var _target_energy: float = 1.0
var _light: Light3D

func _ready() -> void:
	_light = get_parent() as Light3D
	if _light:
		_base_energy = _light.light_energy
		_target_energy = _base_energy

func _process(delta: float) -> void:
	if not _light:
		return
	
	if randf() < flicker_chance:
		_target_energy = randf_range(min_energy, max_energy)
	else:
		_target_energy = _base_energy
	
	_light.light_energy = lerp(_light.light_energy, _target_energy, delta * restore_speed)
