extends Node3D

@onready var network_rack = $Sketchfab_Scene2  # adjust path to your NetworkRack node
@onready var diagnostic_panel = $DiagnosticPanel
@onready var horror_overlay = $HorrorOverlay
@onready var resist_overlay = $ResistOverlay

const OPENING_LINES = [
	"Central Command Console. 0300 hours.",
	"Routine maintenance call. Someone flagged an anomaly on Rack 7.",
	"You've done this a hundred times. Pull the module, reseat it, go home.",
	"The server room is quieter than usual.",
]

func _ready():
	# Wire the diagnostic panel into the rack's StaticBody3D script
	# $Sketchfab_Scene2 is the root — the script lives on the StaticBody3D child
	var rack_body = $Sketchfab_Scene2.get_node("StaticBody3D")
	if rack_body:
		rack_body.diagnostic_panel = diagnostic_panel

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
