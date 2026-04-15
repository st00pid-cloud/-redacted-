extends Node3D

@onready var horror_overlay = $HorrorOverlay
@onready var resist_overlay = $ResistOverlay

const OPENING_LINES = [
	"Central Command Console. 0300 hours.",
	"Routine maintenance call. Someone flagged an anomaly on Rack 7.",
	"You've done this a hundred times. Pull the module, reseat it, go home.",
	"The server room is quieter than usual.",
]

func _ready():
	# Set opening task
	var task = TaskData.new()
	task.task_id = "task_01"
	task.task_name = "Maintenance Call"
	task.description = "Investigate anomalous buffer overflow — Server Rack 7."
	TaskManager.set_task(task)

	# Play opening dialogue after a short delay
	await get_tree().create_timer(1.2).timeout
	var lines: Array[String] = []
	for line in OPENING_LINES:
		lines.append(line)
	DialogueManager.show_dialogue(lines)
