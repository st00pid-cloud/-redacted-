extends CanvasLayer

@onready var header_label = $Control/MarginContainer/HBoxContainer/VBoxContainer/taskHeader
@onready var title_label = $Control/MarginContainer/HBoxContainer/VBoxContainer/taskTitle
@onready var desc_label = $Control/MarginContainer/HBoxContainer/VBoxContainer/taskDesc
@onready var container = $Control/MarginContainer

var _base_offset: Vector2 = Vector2.ZERO
var is_expanded: bool = false
var _current_x_offset: float = 0.0

@onready var ui_width: float = container.size.x

# Adjust this based on how wide your UI is
const COLLAPSED_X = -300.0 
const EXPANDED_X = 0.0

func _ready():
	TaskManager.task_updated.connect(update_display)
	TaskManager.corruption_tick.connect(_on_corruption_tick)
	_base_offset = container.position
	_current_x_offset = COLLAPSED_X
	container.position.x = COLLAPSED_X
	update_display()

func _input(event):
	if event.is_action_pressed("toggle_task_view"):
		toggle_expand()

func toggle_expand():
	is_expanded = !is_expanded
	
	# Determine where the box should be
	# 0 is fully visible on the left, -ui_width is fully hidden
	var target_x = 0 if is_expanded else -ui_width + 40 # Leave 40px visible as a "tab"
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(container, "position:x", target_x, 0.3)

func update_display():
	var task = TaskManager.active_task
	if task:
		title_label.text = TaskManager.get_corrupted_text(task.task_name)
		desc_label.text = TaskManager.get_corrupted_text(task.description)
		show()
	else:
		hide()

func _on_corruption_tick() -> void:
	var tween = create_tween()
	var s = 4.0
	# We shake relative to _current_x_offset so it works while collapsed OR expanded
	var current_base = Vector2(_base_offset.x + _current_x_offset, _base_offset.y)
	
	for i in range(3):
		var noise = Vector2(randf_range(-s, s), randf_range(-s, s))
		tween.tween_property(container, "position", current_base + noise, 0.05)
	
	tween.tween_property(container, "position", current_base, 0.05)
	header_label.text = "[ A̸C̷T̵I̶V̸E̷ ̴T̵A̷S̵K̶ ]" if randf() > 0.5 else "[ ACTIVE TASK ]"
