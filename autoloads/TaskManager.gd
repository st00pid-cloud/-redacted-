extends Node

signal task_completed(task_id: String)
signal task_updated # Added for HUD synchronization

var active_task: TaskData

func set_task(task: TaskData) -> void:
	active_task = task
	task_updated.emit() # Tell the HUD to refresh [cite: 78]

func complete_task(task_id: String) -> void:
	emit_signal("task_completed", task_id)
	active_task = null
	task_updated.emit() # Hide the HUD [cite: 79]
