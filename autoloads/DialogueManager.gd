extends Node

signal dialogue_finished

var dialogue_box: CanvasLayer

func show_dialogue(lines: Array[String]) -> void:
	if dialogue_box:
		dialogue_box.start_dialogue(lines)
