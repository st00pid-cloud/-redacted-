extends CanvasLayer

@onready var name_label = $Control/Panel/MarginContainer/VBoxContainer/NameLabel
@onready var content_label = $Control/Panel/MarginContainer/VBoxContainer/ContentLabel

var _current_lines: Array[String] = []
var _line_index: int = 0
var _is_typing: bool = false

func _ready():
	hide()
	# Connect to the autoload manager
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
		DialogueManager.emit_signal("dialogue_finished")

func _type_text(text: String):
	content_label.text = text
	content_label.visible_ratio = 0.0
	_is_typing = true
	
	var tween = create_tween()
	tween.tween_property(content_label, "visible_ratio", 1.0, 1.0) # 1 second duration
	tween.finished.connect(func(): _is_typing = false)

func _input(event):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_interact"):
		if _is_typing:
			# Skip typewriter animation
			content_label.visible_ratio = 1.0
			_is_typing = false
		else:
			_display_next_line()
