extends Node

signal challenge_done(challenge_id: String, success: bool)
signal all_challenges_done
signal milestone_reached(count: int)

var completed: Dictionary = {}
var required_ids: Array[String] = ["echo", "ghost", "thermal", "memory"]

var _player_frozen: bool = false
var _last_milestone: int = 0

func register_result(challenge_id: String, success: bool) -> void:
	completed[challenge_id] = success
	emit_signal("challenge_done", challenge_id, success)

	var count = get_completed_count()

	if count >= 2 and _last_milestone < 2:
		_last_milestone = 2
		emit_signal("milestone_reached", 2)
	if count >= 3 and _last_milestone < 3:
		_last_milestone = 3
		emit_signal("milestone_reached", 3)
	if count >= required_ids.size():
		if _last_milestone < 4:
			_last_milestone = 4
			emit_signal("milestone_reached", 4)
		emit_signal("all_challenges_done")

func get_completed_count() -> int:
	var count = 0
	for id in required_ids:
		if completed.has(id):
			count += 1
	return count

func get_success_count() -> int:
	var count = 0
	for id in required_ids:
		if completed.get(id, false):
			count += 1
	return count

func is_challenge_done(challenge_id: String) -> bool:
	return completed.has(challenge_id)

func all_done() -> bool:
	return get_completed_count() >= required_ids.size()

func reset() -> void:
	completed.clear()
	_last_milestone = 0

## ── Player freeze/unfreeze ───────────────────────────────────────────────

func freeze_player() -> void:
	_player_frozen = true

	# Hide HUD elements that would overlap challenge UIs
	SignalIntegrityTimer.hide()
	_set_task_hud_visible(false)

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		p.set_physics_process(false)
		p.set_process_input(false)

func unfreeze_player() -> void:
	_player_frozen = false

	# Restore timer only if it is still actively counting
	if SignalIntegrityTimer._running:
		SignalIntegrityTimer.show()

	# Restore task HUD only if there is an active task to show
	if TaskManager.active_task != null:
		_set_task_hud_visible(true)

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		p.set_physics_process(true)
		p.set_process_input(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func is_player_frozen() -> bool:
	return _player_frozen

## ── Helpers ──────────────────────────────────────────────────────────────

func _set_task_hud_visible(visible: bool) -> void:
	# TaskHUD is a CanvasLayer in the scene tree, not an autoload.
	# Find it by group so this works regardless of scene structure.
	var nodes = get_tree().get_nodes_in_group("task_hud")
	for node in nodes:
		node.visible = visible
