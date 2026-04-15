extends Node

## ChallengeTracker — Autoload
## Tracks which challenges the player has completed.
## NetworkRack checks this before allowing the final diagnostic.

signal challenge_done(challenge_id: String, success: bool)
signal all_challenges_done

var completed: Dictionary = {}  # { "echo": true, "ghost": false, ... }
var required_ids: Array[String] = ["echo", "ghost", "thermal", "memory"]

var _player_frozen: bool = false

func register_result(challenge_id: String, success: bool) -> void:
	completed[challenge_id] = success
	emit_signal("challenge_done", challenge_id, success)
	if get_completed_count() >= required_ids.size():
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

## ── Player freeze/unfreeze during challenges ──

func freeze_player() -> void:
	_player_frozen = true
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		p.set_physics_process(false)
		p.set_process_input(false)

func unfreeze_player() -> void:
	_player_frozen = false
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		p.set_physics_process(true)
		p.set_process_input(true)
	# Re-capture mouse for FPS
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func is_player_frozen() -> bool:
	return _player_frozen
