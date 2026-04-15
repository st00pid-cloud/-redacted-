extends Node

signal dialogue_started
signal dialogue_finished

var dialogue_box: CanvasLayer
var is_active: bool = false

func show_dialogue(lines: Array[String]) -> void:
	if dialogue_box:
		is_active = true
		emit_signal("dialogue_started")
		dialogue_box.start_dialogue(lines)

func _on_dialogue_box_finished() -> void:
	is_active = false
