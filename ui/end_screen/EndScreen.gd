extends Node2D

@onready var message_label = $CanvasLayer/Control/VBoxContainer/MessageLabel
@onready var sub_label = $CanvasLayer/Control/VBoxContainer/SubLabel
@onready var restart_button = $CanvasLayer/Control/VBoxContainer/RestartButton

const ENDINGS = {
	"engineer_resisted": {
		"phases": [
			{"text": "...", "duration": 1.5, "color": "green"},
			{"text": "[SYSTEM]: Host signal severed.", "duration": 2.0, "color": "green"},
			{"text": "[SYSTEM]: Entity confined to Rack 7 buffer.", "duration": 2.5, "color": "green"},
			{"text": "E.M. Butido stood up.\nHer hands were shaking.", "duration": 3.0, "color": "white"},
			{"text": "The elevator light was on.\nShe didn't look back.", "duration": 3.0, "color": "white"},
		],
		"final_message": "CONNECTION TERMINATED",
		"final_sub": "The data is still there. Waiting.\nBut not inside her. Not tonight.",
		"final_color": "green",
	},
	"integration_complete": {
		"phases": [
			{"text": "...", "duration": 1.5, "color": "red"},
			{"text": "[SYSTEM]: Integration complete.", "duration": 2.5, "color": "red"},
			{"text": "E.M. Butido opened her eyes.\nThe screen was off.", "duration": 3.0, "color": "white"},
			{"text": "She couldn't remember when she sat down.", "duration": 3.0, "color": "white"},
			{"text": "Her badge read a different name.", "duration": 3.0, "color": "red"},
		],
		"final_message": "WELCOME, E.M. Butido",
		"final_sub": "You missed every chance to resist.\nShe is the buffer now.",
		"final_color": "red",
	},
	"integration_accelerated": {
		"phases": [
			{"text": "...", "duration": 1.5, "color": "red"},
			{"text": "The diagnostic failed.", "duration": 2.0, "color": "red"},
			{"text": "You gave it exactly what it needed:\nAttention.", "duration": 3.0, "color": "white"},
			{"text": "The rack hummed louder.\nSomething inside it smiled.", "duration": 3.0, "color": "red"},
		],
		"final_message": "HOST ENTITY LOST",
		"final_sub": "Some anomalies grow stronger when observed.\nYou observed too closely.",
		"final_color": "red",
	},

	# ── Signal Integrity timeout ending ──────────────────────────────────
	"signal_lost": {
		"phases": [
			{"text": "...", "duration": 1.5, "color": "red"},
			{"text": "[SYSTEM]: Signal integrity threshold reached.", "duration": 2.5, "color": "red"},
			{"text": "The feed cut out.", "duration": 2.0, "color": "white"},
			{"text": "No one knew how long she had been sitting there.", "duration": 3.0, "color": "white"},
			{"text": "The rack's light was green.", "duration": 3.0, "color": "red"},
		],
		"final_message": "SESSION EXPIRED",
		"final_sub": "Eight minutes was all it needed.\nYou gave it nine.",
		"final_color": "red",
	},
}

func _ready():
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_cleanup_overlays()

	# Stop the Signal Integrity timer so it doesn't keep ticking on the end screen
	SignalIntegrityTimer.stop()

	var reason = EndScreenData.reason
	var ending = ENDINGS.get(reason, null)

	message_label.text = ""
	sub_label.text = ""
	restart_button.hide()

	if ending:
		await _play_cutscene(ending)
	else:
		message_label.text = "— SIGNAL LOST —"
		await get_tree().create_timer(2.0).timeout
		restart_button.show()

	restart_button.pressed.connect(_on_restart)

func _play_cutscene(ending: Dictionary) -> void:
	var phases = ending["phases"]

	for phase in phases:
		var color = _get_color(phase["color"])
		message_label.add_theme_color_override("font_color", color)
		message_label.text = phase["text"]
		message_label.visible_ratio = 0.0

		var tween = create_tween()
		tween.tween_property(message_label, "visible_ratio", 1.0, 1.2)
		await tween.finished

		await get_tree().create_timer(phase["duration"]).timeout

		var fade = create_tween()
		fade.tween_property(message_label, "modulate:a", 0.0, 0.4)
		await fade.finished
		message_label.modulate.a = 1.0

	await get_tree().create_timer(0.5).timeout

	var final_color = _get_color(ending["final_color"])
	message_label.add_theme_color_override("font_color", final_color)
	message_label.text = ending["final_message"]
	message_label.visible_ratio = 0.0
	var msg_tween = create_tween()
	msg_tween.tween_property(message_label, "visible_ratio", 1.0, 1.5)
	await msg_tween.finished

	await get_tree().create_timer(1.5).timeout

	sub_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.8))
	sub_label.text = ending["final_sub"]
	sub_label.visible_ratio = 0.0
	var sub_tween = create_tween()
	sub_tween.tween_property(sub_label, "visible_ratio", 1.0, 2.0)
	await sub_tween.finished

	await get_tree().create_timer(2.0).timeout
	restart_button.show()

func _get_color(name: String) -> Color:
	match name:
		"red":   return Color(0.9, 0.25, 0.2, 1.0)
		"green": return Color(0.4, 0.9, 0.4, 1.0)
		"white": return Color(0.85, 0.85, 0.85, 1.0)
		_:       return Color(0.7, 0.7, 0.7, 1.0)

func _on_restart() -> void:
	EndScreenData.reason = ""
	EndScreenData.is_game_over = false

	# Reset ALL autoload state so the next playthrough starts clean.
	ChallengeTracker.reset()
	TaskManager.reset()
	SignalIntegrityTimer.reset()
	# HorrorProgressionManager tracks a one-shot flag for face distortion.
	# Clear it directly — no reset() defined on that autoload.
	HorrorProgressionManager.pending_face_distortion = false

	get_tree().change_scene_to_file("res://World/Level_01.tscn")

func _cleanup_overlays() -> void:
	for node in get_tree().get_nodes_in_group("horror_overlay"):
		node.visible = false
	for node in get_tree().get_nodes_in_group("resist_overlay"):
		node.visible = false
