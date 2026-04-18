extends CanvasLayer

@onready var name_label = $Control/Panel/MarginContainer/VBoxContainer/NameLabel
@onready var content_label = $Control/Panel/MarginContainer/VBoxContainer/ContentLabel
@onready var dialogue_audio: AudioStreamPlayer = $DialogueAudio

# Reference the character sprites from your scene tree
@onready var main_char_sprite = $netEng
@onready var net_eng_sprite = $mainChar

@export var dialogue_sounds: Array[AudioStream] = [] 

var _current_lines: Array[String] = []
var _line_index: int = 0
var _is_typing: bool = false

const SYSTEM_SPEED = 0.35
const ENGINEER_SPEED = 1.4
const CORRUPTED_SPEED = 0.15

func _ready():
	hide()
	# Ensure sprites are hidden initially
	main_char_sprite.hide()
	net_eng_sprite.hide()
	DialogueManager.dialogue_box = self

func start_dialogue(lines: Array[String]):
	_current_lines = lines
	_line_index = 0
	show()
	_display_next_line()

func _display_next_line():
	if dialogue_audio.playing:
		dialogue_audio.stop()

	if _line_index < _current_lines.size():
		if _line_index < dialogue_sounds.size() and dialogue_sounds[_line_index]:
			dialogue_audio.stream = dialogue_sounds[_line_index]
			dialogue_audio.play()
			
		_type_text(_current_lines[_line_index])
		_line_index += 1
	else:
		hide()
		main_char_sprite.hide()
		net_eng_sprite.hide()
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
	if text.begins_with("SYSTEM ADMINISTRATOR") or text.begins_with("[TERMINAL") or text.begins_with("[MAINTENANCE"):
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
	var speaker = _get_speaker_name(text)
	print("Speaker identified as: ", speaker)
	name_label.text = speaker
	
	# Logic to show/hide character sprites based on speaker
	if speaker == "ENGINEER":
		net_eng_sprite.show()
		main_char_sprite.hide()
	elif speaker == "[SYSTEM]" or speaker == "[TERMINAL]" or speaker == "[LOG]":
		net_eng_sprite.hide()
		main_char_sprite.show()
	else:
		# Hide both if it's unknown/corrupted "..."
		net_eng_sprite.hide()
		main_char_sprite.hide()

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
