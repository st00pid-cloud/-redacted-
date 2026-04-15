extends StaticBody3D

@export var dialogue_lines: PackedStringArray = [
	"Port 7 is flapping. Standard fix — pull the module, reseat it.",
	"...there's black residue on the connector.",
	"It's warm. And it smells organic.",
]
@export var task_to_complete: String = "task_01"
var has_been_used: bool = false

var diagnostic_panel: CanvasLayer = null

func interact() -> void:
	if has_been_used:
		return
	if diagnostic_panel:
		diagnostic_panel.open_diagnostic()
		var success = await diagnostic_panel.diagnostic_completed
		if not success:
			GameManager.trigger_game_over("integration_accelerated")
			return
	has_been_used = true
	var lines: Array[String] = []
	for line in dialogue_lines:
		lines.append(line)
	DialogueManager.show_dialogue(lines)
	await DialogueManager.dialogue_finished
	TaskManager.complete_task(task_to_complete)
	TaskManager.begin_corruption()

	# Trigger ambient distortion
	var ambient = get_tree().root.get_node_or_null("AmbientSound")
	if ambient:
		ambient.begin_distortion()

	_apply_horror_state()

func _apply_horror_state() -> void:
	var overlay = get_tree().get_first_node_in_group("horror_overlay")
	if not overlay:
		push_warning("NetworkRack: horror_overlay group not found in scene")
		return

	var room_light = get_tree().get_first_node_in_group("room_light")
	var world_env = get_tree().get_first_node_in_group("world_environment")

	overlay.modulate.a = 0.0
	overlay.show()

	# Thicken fog slowly
	if world_env:
		var fog_tween = create_tween()
		fog_tween.tween_property(world_env.environment, "fog_density", 0.06, 5.0)

	var tween = create_tween()
	for i in range(6):
		tween.tween_property(overlay, "modulate:a", 0.7, 0.08)
		tween.tween_property(overlay, "modulate:a", 0.0, 0.08)
		if room_light:
			tween.tween_property(room_light, "light_energy", 0.1, 0.04)
			tween.tween_property(room_light, "light_energy", 1.0, 0.04)

	await tween.finished
	overlay.hide()
