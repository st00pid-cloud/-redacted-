extends CanvasLayer

signal diagnostic_completed(success: bool)

@onready var port_container = $Control/Panel/VBoxContainer/PortContainer
@onready var feedback_label = $Control/Panel/VBoxContainer/FeedbackLabel
@onready var header_label = $Control/Panel/VBoxContainer/HeaderLabel
@onready var horror_container = $Control/Panel/VBoxContainer/HorrorContainer

const CORRUPTED_PORT = 2
const MAX_WRONG_GUESSES = 2

var wrong_guesses := 0
var port_buttons: Array = []
var ascii_cycle_timer: float = 0.0
var ascii_step: int = 0
var _phase: int = 0  # 0 = port select, 1 = horror question, 2 = done
var _port_success: bool = false  # stored separately — not in the const dict

const ASCII_SEQUENCE = [72, 85, 78, 71, 82, 89]  # HUNGRY

var port_data = [
	{"label": "PORT 4", "values": ["0xA4F2", "0xA4F2", "0xA4F2"], "normal": true},
	{"label": "PORT 5", "values": ["0xFF01", "0xFF03", "0xFF01"], "normal": false},
	{"label": "PORT 7", "values": ["0x0048", "0x0055", "0x004E"], "normal": false},
	{"label": "PORT 9", "values": ["0xB2C1", "0xB2C1", "0xB2C1"], "normal": true},
]

const HORROR_QUESTIONS = [
	{
		"question": "Before containment proceeds:\nDo you believe R. Vasquez is still alone in this room?",
		"answers": ["YES", "NO"],
		"correct": 1,
		"success_text": "Correct. You were never alone.\nContainment proceeding...",
		"fail_text": "Denial noted. Integration preference: willing host.",
	},
	{
		"question": "Verification required:\nThe maintenance logs mention sounds from this rack.\nWhat do machines dream about?",
		"answers": ["NOTHING", "US"],
		"correct": 0,
		"success_text": "Response logged. Rational mind confirmed.\nContainment proceeding...",
		"fail_text": "You listened too closely.\nIt appreciates that.",
	},
	{
		"question": "SYSTEM INTEGRITY CHECK:\nWho authorized your night shift, R. Vasquez?",
		"answers": ["DISPATCH", "I DON'T REMEMBER"],
		"correct": 0,
		"success_text": "Authorization verified. Proceeding...",
		"fail_text": "Memory gaps detected. Integration compatible.",
	},
]

var _current_horror_q: Dictionary = {}
var _horror_buttons: Array = []

func _ready():
	add_to_group("diagnostic_panel")
	hide()
	feedback_label.text = ""
	header_label.text = "DIAGNOSTIC INTERFACE v2.3.1\nIdentify the corrupted port. Select carefully."
	_build_port_buttons()
	if horror_container:
		horror_container.visible = false

func open_diagnostic():
	_phase = 0
	_port_success = false
	wrong_guesses = 0
	ascii_step = 0
	feedback_label.text = ""
	header_label.text = "DIAGNOSTIC INTERFACE v2.3.1\nIdentify the corrupted port. Select carefully."
	for btn in port_buttons:
		btn.disabled = false
	port_container.visible = true
	if horror_container:
		horror_container.visible = false
		_clear_horror_buttons()
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _build_port_buttons():
	for i in range(port_data.size()):
		var port = port_data[i]
		var btn = Button.new()
		btn.text = _format_port_display(i)
		btn.name = "Port" + str(i)
		btn.pressed.connect(_on_port_selected.bind(i))
		btn.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
		btn.add_theme_color_override("font_hover_color", Color(0.9, 1.0, 0.9))
		port_container.add_child(btn)
		port_buttons.append(btn)

func _format_port_display(index: int) -> String:
	var port = port_data[index]
	var vals = port["values"]
	if index == CORRUPTED_PORT:
		var current_hex = "0x00%02X" % ASCII_SEQUENCE[ascii_step % ASCII_SEQUENCE.size()]
		return "%s  |  %s  %s  %s" % [port["label"], current_hex, vals[1], vals[2]]
	return "%s  |  %s  %s  %s" % [port["label"], vals[0], vals[1], vals[2]]

func _process(delta: float):
	if not visible or _phase != 0:
		return
	ascii_cycle_timer += delta
	if ascii_cycle_timer >= 0.6:
		ascii_cycle_timer = 0.0
		ascii_step += 1
		if port_buttons.size() > CORRUPTED_PORT:
			port_buttons[CORRUPTED_PORT].text = _format_port_display(CORRUPTED_PORT)

func _on_port_selected(index: int):
	if _phase != 0:
		return
	if index == CORRUPTED_PORT:
		feedback_label.text = "PORT 7 flagged. Running verification..."
		await get_tree().create_timer(1.0).timeout
		_start_horror_question(true)
	else:
		wrong_guesses += 1
		if wrong_guesses >= MAX_WRONG_GUESSES:
			feedback_label.text = "Too many failures. Integration pathway opened."
			await get_tree().create_timer(1.5).timeout
			_start_horror_question(false)
		else:
			feedback_label.text = "Incorrect. The anomaly shifts. Choose again."
			port_buttons[index].disabled = true

func _start_horror_question(port_was_correct: bool) -> void:
	_phase = 1
	_port_success = port_was_correct  # store as instance var, not in the const dict
	port_container.visible = false

	# Pick a random horror question — duplicate so we have a mutable copy
	_current_horror_q = HORROR_QUESTIONS[randi() % HORROR_QUESTIONS.size()].duplicate()

	header_label.text = ""
	feedback_label.text = ""

	await get_tree().create_timer(0.5).timeout

	header_label.text = _current_horror_q["question"]
	header_label.visible_ratio = 0.0
	var tween = create_tween()
	tween.tween_property(header_label, "visible_ratio", 1.0, 1.5)
	await tween.finished

	await get_tree().create_timer(0.3).timeout

	if horror_container:
		horror_container.visible = true
		_clear_horror_buttons()
		var answers = _current_horror_q["answers"]
		for i in range(answers.size()):
			var btn = Button.new()
			btn.text = "[ " + answers[i] + " ]"
			btn.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
			btn.add_theme_color_override("font_hover_color", Color(1.0, 0.5, 0.5))
			btn.pressed.connect(_on_horror_answer.bind(i))
			horror_container.add_child(btn)
			_horror_buttons.append(btn)

func _on_horror_answer(index: int) -> void:
	if _phase != 1:
		return
	_phase = 2

	var correct_answer: int = _current_horror_q["correct"]
	var horror_success: bool = (index == correct_answer)

	for btn in _horror_buttons:
		btn.disabled = true

	if horror_success:
		feedback_label.text = _current_horror_q["success_text"]
	else:
		feedback_label.text = _current_horror_q["fail_text"]

	feedback_label.visible_ratio = 0.0
	var tween = create_tween()
	tween.tween_property(feedback_label, "visible_ratio", 1.0, 1.2)
	await tween.finished

	await get_tree().create_timer(1.5).timeout

	# Both port AND horror question must succeed
	var overall_success = _port_success and horror_success

	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	emit_signal("diagnostic_completed", overall_success)

func _clear_horror_buttons() -> void:
	for btn in _horror_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	_horror_buttons.clear()
