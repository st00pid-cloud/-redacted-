extends CanvasLayer

@onready var name_label = $Control/Panel/MarginContainer/VBoxContainer/NameLabel
@onready var content_label = $Control/Panel/MarginContainer/VBoxContainer/ContentLabel

var _current_lines: Array[String] = []
var _line_index: int = 0
var _is_typing: bool = false

const SYSTEM_SPEED = 0.35
const ENGINEER_SPEED = 1.4
const CORRUPTED_SPEED = 0.15

func _ready():
	hide()
	DialogueManager.dialogue_box = self
	

func start_dialogue(lines: Array[String]):
	_current_lines = lines
	_line_index = 0
	show()
	_display_next_line()

func _display_next_line():
	if _line_index < _current_lines.size():
		_type_text(_current_lines[_line_index])
		_line_index += 1
	else:
		hide()
		DialogueManager.is_active = false
		DialogueManager.emit_signal("dialogue_finished")

func _get_type_duration(text: String) -> float:
	if text.begins_with("[SYSTEM]") or text.begins_with("[TERMINAL") or text.begins_with("[MAINTENANCE"):
		return SYSTEM_SPEED
	elif text.begins_with("ENGINEER"):
		return ENGINEER_SPEED
	else:
		return CORRUPTED_SPEED

func _get_speaker_name(text: String) -> String:
	if text.begins_with("[SYSTEM]") or text.begins_with("[TERMINAL") or text.begins_with("[MAINTENANCE"):
		return "[SYSTEM]"
	elif text.begins_with("ENGINEER"):
		return "ENGINEER"
	elif text.begins_with("User:") or text.begins_with("Clearance:") or text.begins_with("Last login:") or text.begins_with("Active session") or text.begins_with("Note to"):
		return "[TERMINAL]"
	elif text.begins_with("Week") or text.begins_with("NOTE"):
		return "[LOG]"
	else:
		return "..."

func _type_text(text: String):
	name_label.text = _get_speaker_name(text)
	content_label.text = text
	content_label.visible_ratio = 0.0
	_is_typing = true

	var duration = _get_type_duration(text)
	var tween = create_tween()
	tween.tween_property(content_label, "visible_ratio", 1.0, duration)
	tween.finished.connect(func(): _is_typing = false)

func _input(event):
	if not visible:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		if _is_typing:
			content_label.visible_ratio = 1.0
			_is_typing = false
		else:
			_display_next_line()

func _on_next_pressed():
	if _is_typing:
		content_label.visible_ratio = 1.0
		_is_typing = false
	else:
		_display_next_line()

func _on_next_button_pressed() -> void:
	pass
