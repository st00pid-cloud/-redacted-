extends CanvasLayer

signal diagnostic_completed(success: bool)

@onready var port_container = $Control/Panel/VBoxContainer/PortContainer
@onready var feedback_label = $Control/Panel/VBoxContainer/FeedbackLabel
@onready var header_label = $Control/Panel/VBoxContainer/HeaderLabel

const CORRUPTED_PORT = 2 # 0-indexed, Port 7 is index 2 in our 4-port display
const MAX_WRONG_GUESSES = 2

var wrong_guesses := 0
var port_buttons: Array = []
var ascii_cycle_timer: float = 0.0
var ascii_step: int = 0

# The ASCII values count toward "HUNGRY" (72,85,78,71,82,89)
const ASCII_SEQUENCE = [72, 85, 78, 71, 82, 89]
const DECOY_PORT = 1 # Shows slightly wrong but static values

var port_data = [
	{"label": "PORT 4", "values": ["0xA4F2", "0xA4F2", "0xA4F2"], "normal": true},
	{"label": "PORT 5", "values": ["0xFF01", "0xFF03", "0xFF01"], "normal": false}, # decoy - slightly off but static
	{"label": "PORT 7", "values": ["0x0048", "0x0055", "0x004E"], "normal": false}, # corrupted - cycling ASCII
	{"label": "PORT 9", "values": ["0xB2C1", "0xB2C1", "0xB2C1"], "normal": true},
]

func _ready():
	hide()
	feedback_label.text = ""
	header_label.text = "DIAGNOSTIC INTERFACE v2.3.1\nIdentify the corrupted port. Select carefully."
	_build_port_buttons()

func open_diagnostic():
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _build_port_buttons():
	for i in range(port_data.size()):
		var port = port_data[i]
		var btn = Button.new()
		btn.text = _format_port_display(i)
		btn.name = "Port" + str(i)
		btn.pressed.connect(_on_port_selected.bind(i))
		port_container.add_child(btn)
		port_buttons.append(btn)

func _format_port_display(index: int) -> String:
	var port = port_data[index]
	var vals = port["values"]
	if index == CORRUPTED_PORT:
		# Show current ASCII step
		var current_hex = "0x00%02X" % ASCII_SEQUENCE[ascii_step % ASCII_SEQUENCE.size()]
		return "%s  |  %s  %s  %s" % [port["label"], current_hex, vals[1], vals[2]]
	return "%s  |  %s  %s  %s" % [port["label"], vals[0], vals[1], vals[2]]

func _process(delta: float):
	if not visible:
		return
	ascii_cycle_timer += delta
	if ascii_cycle_timer >= 0.6:
		ascii_cycle_timer = 0.0
		ascii_step += 1
		if port_buttons.size() > CORRUPTED_PORT:
			port_buttons[CORRUPTED_PORT].text = _format_port_display(CORRUPTED_PORT)

func _on_port_selected(index: int):
	if index == CORRUPTED_PORT:
		feedback_label.text = "PORT 7 ISOLATED. Containment... partial."
		await get_tree().create_timer(1.2).timeout
		hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		emit_signal("diagnostic_completed", true)
	else:
		wrong_guesses += 1
		if wrong_guesses >= MAX_WRONG_GUESSES:
			feedback_label.text = "Integration accelerated. You fed it attention."
			await get_tree().create_timer(2.0).timeout
			hide()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			emit_signal("diagnostic_completed", false)
		else:
			feedback_label.text = "Incorrect. The anomaly is spreading. Choose again."
			port_buttons[index].disabled = true
