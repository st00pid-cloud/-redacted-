extends Node3D

@onready var horror_overlay: ColorRect = $HorrorOverlay

var _player: CharacterBody3D = null
var _resist_active: bool = false
var _resist_presses_needed: int = 8
var _resist_presses: int = 0
var _ending_in_progress: bool = false
var _resist_time_remaining: float = 0.0
var _resist_time_total: float = 8.0

var _resist_progress_bar: ColorRect = null
var _resist_progress_bg: ColorRect = null
var _resist_counter_label: Label = null
var _resist_timer_label: Label = null
var _resist_instruction_label: Label = null
var _resist_ui_container: CanvasLayer = null
var _resist_pulse_timer: float = 0.0

const OPENING_LINES = [
	"Hey, EM. You're up.",
	"Got a weird blip on Rack 7. Standard maintenance, you know the drill. ",
	"You've done this a hundred times. Pop the component out, plug it back in, and call it a night.",
	"[YOU] The server room is quieter than usual.",
	"...",
	"The main computer is locked out. You'll need to hit the local stations first to run a health check.",
	"Find the terminals, clear the errors, then head back to Rack 7.",
]

func _ready() -> void:
	if horror_overlay:
		horror_overlay.visible = false
		horror_overlay.modulate.a = 0.0
	# Hide any legacy resist overlay
	var old_resist = get_node_or_null("ResistOverlay")
	if old_resist:
		old_resist.visible = false

	# Reset challenge tracker for fresh game
	if ChallengeTracker:
		ChallengeTracker.reset()

	await get_tree().process_frame
	_player = _find_player()
	if _player:
		_player.set_physics_process(false)
		_player.set_process_input(false)

	# Set opening task
	var task = TaskData.new()
	task.task_id = "task_01"
	task.task_name = "Maintenance Call"
	task.description = "Investigate Server Rack 7."
	TaskManager.set_task(task)

	await get_tree().create_timer(1.2).timeout
	var lines: Array[String] = []
	for line in OPENING_LINES:
		lines.append(line)
	DialogueManager.show_dialogue(lines)
	await DialogueManager.dialogue_finished

	if _player:
		_player.set_physics_process(true)
		_player.set_process_input(true)

	# Set task to find terminals
	var t = TaskData.new()
	t.task_id = "find_terminals"
	t.task_name = "Subsystem Diagnostics"
	t.description = "Locate and complete 4 terminal diagnostics throughout the data center."
	TaskManager.set_task(t)

	SignalIntegrityTimer.start()


func _process(delta: float) -> void:
	if not _resist_active:
		return
	_resist_time_remaining -= delta
	if _resist_time_remaining <= 0.0:
		_resist_time_remaining = 0.0
		_resist_active = false
		_cleanup_all_overlays()
		_trigger_ending("integration_complete", true)
		return
	_update_resist_ui(delta)

## ── RESIST ───────────────────────────────────────────────────

func start_resist_sequence() -> void:
	if _ending_in_progress:
		return
	_ending_in_progress = true

	# Ensure player is frozen
	ChallengeTracker.freeze_player()

	if horror_overlay:
		horror_overlay.visible = true
		var tween = create_tween()
		tween.tween_property(horror_overlay, "modulate:a", 0.55, 0.4)
		await tween.finished

	_build_resist_ui()
	_resist_active = true
	_resist_presses = 0
	_resist_time_remaining = _resist_time_total

func _input(event: InputEvent) -> void:
	if not _resist_active:
		return
	if event.is_action_pressed("interact"):
		_resist_presses += 1
		if horror_overlay:
			var flash_tween = create_tween()
			var target_a = max(0.0, horror_overlay.modulate.a - 0.07)
			flash_tween.tween_property(horror_overlay, "modulate:a", target_a, 0.08)
		if _player:
			var cam = _player.get_node_or_null("HeadPivot/Camera3D")
			if cam:
				var shake_tween = create_tween()
				var orig_pos = cam.position
				shake_tween.tween_property(cam, "position",
					orig_pos + Vector3(randf_range(-0.1, 0.1), randf_range(-0.05, 0.05), 0), 0.03)
				shake_tween.tween_property(cam, "position", orig_pos, 0.03)
		if _resist_presses >= _resist_presses_needed:
			_resist_active = false
			_on_resist_success()

func _on_resist_success() -> void:
	_cleanup_all_overlays()
	var lines: Array[String] = [
		"Integration rejected. Host signal unstable.",
		"[Entity retreating to secondary buffer.",
		"...",
	]
	DialogueManager.show_dialogue(lines)
	await DialogueManager.dialogue_finished
	await get_tree().create_timer(1.0).timeout
	_trigger_ending("engineer_resisted", false)

func _trigger_ending(reason: String, is_game_over: bool) -> void:
	_cleanup_all_overlays()
	if is_game_over:
		GameManager.trigger_game_over(reason)
	else:
		GameManager.trigger_ending(reason)

## ── RESIST UI ────────────────────────────────────────────────

func _build_resist_ui() -> void:
	_resist_ui_container = CanvasLayer.new()
	_resist_ui_container.layer = 150
	add_child(_resist_ui_container)

	var root_control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resist_ui_container.add_child(root_control)

	_resist_instruction_label = Label.new()
	_resist_instruction_label.text = "THE ENTITY IS TAKING HOLD"
	_resist_instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_resist_instruction_label.add_theme_font_size_override("font_size", 28)
	_resist_instruction_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	_resist_instruction_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_resist_instruction_label.position = Vector2(-200, 80)
	_resist_instruction_label.size = Vector2(400, 40)
	root_control.add_child(_resist_instruction_label)

	var action_label = Label.new()
	action_label.text = "PRESS  [ E ]  REPEATEDLY TO RESIST"
	action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_label.add_theme_font_size_override("font_size", 36)
	action_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	action_label.set_anchors_preset(Control.PRESET_CENTER)
	action_label.position = Vector2(-300, -30)
	action_label.size = Vector2(600, 50)
	root_control.add_child(action_label)

	_resist_counter_label = Label.new()
	_resist_counter_label.text = "0 / %d" % _resist_presses_needed
	_resist_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_resist_counter_label.add_theme_font_size_override("font_size", 22)
	_resist_counter_label.add_theme_color_override("font_color", Color(0.8, 0.9, 0.8, 0.9))
	_resist_counter_label.set_anchors_preset(Control.PRESET_CENTER)
	_resist_counter_label.position = Vector2(-100, 30)
	_resist_counter_label.size = Vector2(200, 30)
	root_control.add_child(_resist_counter_label)

	_resist_progress_bg = ColorRect.new()
	_resist_progress_bg.color = Color(0.2, 0.2, 0.2, 0.7)
	_resist_progress_bg.set_anchors_preset(Control.PRESET_CENTER)
	_resist_progress_bg.position = Vector2(-200, 70)
	_resist_progress_bg.size = Vector2(400, 16)
	_resist_progress_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(_resist_progress_bg)

	_resist_progress_bar = ColorRect.new()
	_resist_progress_bar.color = Color(0.3, 1.0, 0.3, 0.9)
	_resist_progress_bar.position = Vector2(-200, 70)
	_resist_progress_bar.size = Vector2(0, 16)
	_resist_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(_resist_progress_bar)

	_resist_timer_label = Label.new()
	_resist_timer_label.text = "%.1f s" % _resist_time_total
	_resist_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_resist_timer_label.add_theme_font_size_override("font_size", 18)
	_resist_timer_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3, 0.8))
	_resist_timer_label.set_anchors_preset(Control.PRESET_CENTER)
	_resist_timer_label.position = Vector2(-60, 95)
	_resist_timer_label.size = Vector2(120, 24)
	root_control.add_child(_resist_timer_label)

func _update_resist_ui(delta: float) -> void:
	if not _resist_ui_container:
		return
	if _resist_counter_label:
		_resist_counter_label.text = "%d / %d" % [_resist_presses, _resist_presses_needed]
	if _resist_progress_bar:
		var ratio = clampf(float(_resist_presses) / float(_resist_presses_needed), 0.0, 1.0)
		_resist_progress_bar.size.x = 400.0 * ratio
		_resist_progress_bar.color = Color(1.0 - ratio, ratio, 0.3, 0.9)
	if _resist_timer_label:
		_resist_timer_label.text = "%.1f s" % _resist_time_remaining
		if _resist_time_remaining < 3.0:
			_resist_timer_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))
	_resist_pulse_timer += delta * 4.0
	if _resist_instruction_label:
		_resist_instruction_label.modulate.a = 0.6 + 0.4 * sin(_resist_pulse_timer)
		var msgs = ["THE ENTITY IS TAKING HOLD", "DON'T LET IT IN", "FIGHT BACK — PRESS E", "IT'S INSIDE THE SIGNAL", "RESIST OR BECOME THE BUFFER"]
		_resist_instruction_label.text = msgs[int(_resist_pulse_timer * 0.5) % msgs.size()]

func _destroy_resist_ui() -> void:
	if _resist_ui_container and is_instance_valid(_resist_ui_container):
		_resist_ui_container.queue_free()
		_resist_ui_container = null
	_resist_progress_bar = null
	_resist_progress_bg = null
	_resist_counter_label = null
	_resist_timer_label = null
	_resist_instruction_label = null

func _cleanup_all_overlays() -> void:
	_destroy_resist_ui()
	if horror_overlay:
		horror_overlay.visible = false
		horror_overlay.modulate.a = 0.0
	for node in get_tree().get_nodes_in_group("horror_overlay"):
		node.visible = false
	for node in get_tree().get_nodes_in_group("resist_overlay"):
		node.visible = false
	var old_resist = get_node_or_null("ResistOverlay")
	if old_resist:
		old_resist.visible = false

func _find_player() -> CharacterBody3D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	for child in get_children():
		if child is CharacterBody3D:
			return child
	return null
