extends CanvasLayer

# SceneTransition.gd — autoload
# Provides a fade-to-black transition between any scene changes.
# Usage:
#   await SceneTransition.fade_to(path)   — fades out, loads scene, fades in
#   await SceneTransition.fade_out()      — just fades out
#   await SceneTransition.fade_in()       — just fades in

@onready var overlay: ColorRect = $ColorRect

const FADE_DURATION = 0.5

func _ready() -> void:
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

func fade_out() -> void:
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 1.0, FADE_DURATION)
	await tween.finished

func fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.0, FADE_DURATION)
	await tween.finished
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

func fade_to(scene_path: String) -> void:
	await fade_out()
	get_tree().change_scene_to_file(scene_path)
	# Wait one frame for the new scene to load
	await get_tree().process_frame
	await fade_in()
