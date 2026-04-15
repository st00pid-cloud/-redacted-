extends CanvasLayer

@onready var header_label = $Control/MarginContainer/VBoxContainer/taskHeader
@onready var title_label = $Control/MarginContainer/VBoxContainer/taskTitle
@onready var desc_label = $Control/MarginContainer/VBoxContainer/taskDesc
@onready var container = $Control/MarginContainer

var _base_offset: Vector2 = Vector2.ZERO

func _ready():
	TaskManager.task_updated.connect(update_display)
	TaskManager.corruption_tick.connect(_on_corruption_tick)
	_base_offset = container.position
	update_display()

func update_display():
	var task = TaskManager.active_task
	if task:
		title_label.text = TaskManager.get_corrupted_text(task.task_name)
		desc_label.text = TaskManager.get_corrupted_text(task.description)
		show()
	else:
		hide()

func _on_corruption_tick() -> void:
	# Glitch shake
	var tween = create_tween()
	var s = 4.0
	tween.tween_property(container, "position",
		_base_offset + Vector2(randf_range(-s, s), randf_range(-s, s)), 0.05)
	tween.tween_property(container, "position",
		_base_offset + Vector2(randf_range(-s, s), randf_range(-s, s)), 0.05)
	tween.tween_property(container, "position",
		_base_offset + Vector2(randf_range(-s, s), randf_range(-s, s)), 0.05)
	tween.tween_property(container, "position", _base_offset, 0.05)
	# Briefly corrupt the header too
	header_label.text = "[ A̸C̷T̵I̶V̸E̷ ̴T̵A̷S̵K̶ ]" if randf() > 0.5 else "[ ACTIVE TASK ]"
