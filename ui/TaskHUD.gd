extends CanvasLayer

@onready var title_label = $Control/MarginContainer/VBoxContainer/taskTitle
@onready var desc_label = $Control/MarginContainer/VBoxContainer/taskDesc

func _ready():
	TaskManager.task_updated.connect(update_display)
	update_display()

func update_display():
	var task = TaskManager.active_task
	if task:
		title_label.text = TaskManager.get_corrupted_text(task.task_name)
		desc_label.text = TaskManager.get_corrupted_text(task.description)
		show()
	else:
		hide()
