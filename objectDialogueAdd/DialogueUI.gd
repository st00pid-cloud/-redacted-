extends CanvasLayer

@onready var panel = $Panel
@onready var label = $Panel/Label
@onready var next_button = $Panel/NextButton
@onready var close_button = $Panel/CloseButton

var dialogue = []
var dialogue_index = 0

func _ready():
	panel.visible = false

func show_dialogue(text):
	dialogue = text.split("\n")
	dialogue_index = 0
	_display_text()
	panel.visible = true
	
func _display_text():
	label.text = dialogue[dialogue_index]
	
func _on_NextButton_pressed():
	dialogue_index += 1
	if dialogue_index < dialogue.size():
		_display_text()
	else:
		panel.visible = false

func _on_CloseButton_pressed():
	panel.visible = false
	dialogue_index = 0
