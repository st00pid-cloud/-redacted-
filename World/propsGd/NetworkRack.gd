extends StaticBody3D

@export var dialogue_lines: Array[String] = [
	"Port 7 is flapping. Standard fix — pull the module, reseat it.",
	"...there's black residue on the connector.",
	"It's warm. And it smells organic.",
]
@export var task_to_complete: String = "task_01"
var has_been_used: bool = false

func interact() -> void:
	if has_been_used:
		return
	has_been_used = true
	DialogueManager.show_dialogue(Array(dialogue_lines))
	await DialogueManager.dialogue_finished
	TaskManager.complete_task(task_to_complete)
	_apply_horror_state()

func _apply_horror_state() -> void:
	# You'll add the flickering/material swap tomorrow
	pass

func _ready() -> void:
	add_to_group("interactable")
