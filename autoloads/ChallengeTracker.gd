extends Node

## ChallengeTracker — Autoload
## All improvements integrated:
## - milestone_reached signal at counts 2, 3, 4
## - get_difficulty_multiplier() for challenge scaling
## - freeze/unfreeze hides SignalIntegrityTimer, TaskHUD, LocationHeader
## - reset() clears milestone and difficulty state

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

## Each completed challenge adds 0.25 to the multiplier.
## 0 done = 1.0x, 1 done = 1.25x, 2 done = 1.5x, 3 done = 1.75x, 4 done = 2.0x
func get_difficulty_multiplier() -> float:
	return 1.0 + (get_completed_count() * 0.25)

func reset() -> void:
	completed.clear()
	_last_milestone = 0

## ── Player freeze/unfreeze ───────────────────────────────────────────────

func freeze_player() -> void:
	_player_frozen = true

	SignalIntegrityTimer.hide()
	_set_task_hud_visible(false)
	_set_location_header_visible(false)

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		p.set_physics_process(false)
		p.set_process_input(false)

func unfreeze_player() -> void:
	_player_frozen = false

	if SignalIntegrityTimer._running:
		SignalIntegrityTimer.show()

	if TaskManager.active_task != null:
		_set_task_hud_visible(true)

	_set_location_header_visible(true)

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
	for node in get_tree().get_nodes_in_group("task_hud"):
		node.visible = visible

func _set_location_header_visible(visible: bool) -> void:
	for node in get_tree().get_nodes_in_group("location_header"):
		if visible:
			node.show_header()
		else:
			node.hide_header()
