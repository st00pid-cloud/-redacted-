extends Node

signal task_completed(task_id: String)
signal task_updated
signal corruption_tick

var active_task: TaskData
var _corruption_level: float = 0.0
var _corruption_timer: float = 0.0
var _is_corrupting: bool = false

const CORRUPTION_INTERVAL = 3.0 # seconds between corruption ticks
const CORRUPT_CHARS = ["̴", "̸", "͝", "͠", "̡", "̢", "̧", "̨"]

func set_task(task: TaskData) -> void:
	active_task = task
	task_updated.emit()

func complete_task(task_id: String) -> void:
	emit_signal("task_completed", task_id)
	active_task = null
	task_updated.emit()

func begin_corruption() -> void:
	_is_corrupting = true

## Adds a one-time corruption bump (e.g. retry penalty).
## Prefer this over mutating _corruption_level directly from other scripts.
func apply_corruption_penalty(amount: float) -> void:
	_corruption_level = min(_corruption_level + amount, 1.0)
	corruption_tick.emit()
	task_updated.emit()

## Clears all state so a restarted playthrough starts clean.
## Call from EndScreen._on_restart() alongside ChallengeTracker.reset().
func reset() -> void:
	active_task = null
	_corruption_level = 0.0
	_corruption_timer = 0.0
	_is_corrupting = false
	task_updated.emit()

func _process(delta: float) -> void:
	if not _is_corrupting or not active_task:
		return
	_corruption_timer += delta
	if _corruption_timer >= CORRUPTION_INTERVAL:
		_corruption_timer = 0.0
		_corruption_level = min(_corruption_level + 0.2, 1.0)
		corruption_tick.emit()
		task_updated.emit()

func get_corrupted_text(original: String) -> String:
	if _corruption_level <= 0.0:
		return original
	# At full corruption, replace entirely
	if _corruption_level >= 1.0:
		return "̴̡I̸͝t̸͝'̴s̸ ̴a̸l̸r̷e̵a̷d̵y̸ ̶i̸n̸ ̶y̸o̵u̸"
	# Progressively corrupt characters
	var result = ""
	for i in range(original.length()):
		result += original[i]
		if randf() < _corruption_level * 0.4:
			result += CORRUPT_CHARS[randi() % CORRUPT_CHARS.size()]
	return result
