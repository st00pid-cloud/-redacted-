extends Node

signal dialogue_finished

var _lines: Array[String] = []
var _index: int = 0
var dialogue_box: CanvasLayer

func show_dialogue(lines: Array[String]) -> void:
	if dialogue_box:
		dialogue_box.start_dialogue(lines) 

func _display_next():
	if _index < _lines.size():
		# Update UI text here
		_index += 1
	else:
		emit_signal("dialogue_finished")
