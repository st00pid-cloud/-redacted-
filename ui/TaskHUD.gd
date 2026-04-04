extends CanvasLayer


@onready var title_label = $Control/MarginContainer/VBoxContainer/taskTitle
@onready var desc_label = $Control/MarginContainer/VBoxContainer/taskDesc

func _ready():
	# Connect to the TaskManager autoload
	TaskManager.task_updated.connect(update_display)
	update_display() # Initialize empty

func update_display():
	var task = TaskManager.active_task
	if task:
		title_label.text = task.task_name
		desc_label.text = task.description
		show()
	else:
		hide() # Hide HUD when no task is active [cite: 79]
