extends Node

# AmbientSound.gd — autoload
# Attach two AudioStreamPlayer nodes as children in the editor:
#   - $Hum   (load a looping low hum .ogg, e.g. res://audio/hum.ogg)
#   - $Distortion (load a distortion/static .ogg, e.g. res://audio/static.ogg)
# Both should have Autoplay = false and Loop = true on their stream.

@onready var hum: AudioStreamPlayer = $Hum
@onready var distortion: AudioStreamPlayer = $Distortion

func _ready() -> void:
	# Start hum immediately at full volume
	hum.volume_db = 0.0
	hum.play()
	# Distortion starts silent
	distortion.volume_db = -80.0
	distortion.play()

func begin_distortion() -> void:
	# Called after rack interaction — fade hum down, distortion up
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(hum, "volume_db", -20.0, 4.0)
	tween.tween_property(distortion, "volume_db", -10.0, 4.0)

func full_distortion() -> void:
	# Called at bad ending — slam distortion to max
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(hum, "volume_db", -80.0, 0.5)
	tween.tween_property(distortion, "volume_db", 0.0, 0.5)

func silence() -> void:
	# Called at good ending — fade everything out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(hum, "volume_db", -80.0, 1.5)
	tween.tween_property(distortion, "volume_db", -80.0, 1.5)
