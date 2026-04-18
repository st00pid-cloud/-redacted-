extends CanvasLayer

## DiagnosticPanel — Port selection + horror questions.
## On open: checks HorrorProgressionManager.pending_face_distortion and
## fires FaceDistortion if set (milestone 3 scare).

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
var _phase: int = 0  # 0=port, 1=horror, 2=done
var _port_success: bool = false

const ASCII_SEQUENCE = [72, 85, 78, 71, 82, 89]

var port_data = [
	{"label": "PORT 4", "values": ["0xA4F2", "0xA4F2", "0xA4F2"], "normal": true},
	{"label": "PORT 5", "values": ["0xFF01", "0xFF03", "0xFF01"], "normal": false},
	{"label": "PORT 7", "values": ["0x0048", "0x0055", "0x004E"], "normal": false},
	{"label": "PORT 9", "values": ["0xB2C1", "0xB2C1", "0xB2C1"], "normal": true},
]

const HORROR_QUESTIONS = [
	{
		"question": "FINAL VERIFICATION 1/4:\nDo you believe E.M. Butido is still alone in this room?",
		"answers": ["YES", "NO"], "correct": 0,
		"success_text": "Correct. You were never alone.",
		"fail_text": "Denial noted. Integration preference: willing host.",
	},
	{
		"question": "FINAL VERIFICATION 2/4:\nThe maintenance logs mention sounds from this rack.\nWhat do machines dream about?",
		"answers": ["US", "NOTHING"], "correct": 1,
		"success_text": "Response logged. Rational mind confirmed.",
		"fail_text": "You listened too closely. It appreciates that.",
	},
	{
		"question": "FINAL VERIFICATION 3/4:\nWho authorized your night shift,  E.M. Butido?",
		"answers": ["DISPATCH", "I DON'T REMEMBER"], "correct": 0,
		"success_text": "Authorization verified.",
		"fail_text": "Memory gaps detected. Integration compatible.",
	},
	{
		"question": "FINAL VERIFICATION 4/4:\nThe entity requests a name.\nDo you give it one?",
		"answers": ["YES", "NO"], "correct": 1,
		"success_text": "Unnamed things are harder to love.\nContainment holds.",
		"fail_text": "Named things grow. You know that now.",
	},
]

var _horror_buttons: Array = []
var _horror_correct_count: int = 0
var _horror_question_index: int = 0
var _awaiting_horror_answer: bool = false

func _ready():
	add_to_group("diagnostic_panel")
	hide()
	feedback_label.text = ""
	header_label.text = "DIAGNOSTIC INTERFACE v2.3.1\nIdentify the corrupted port."
	_build_port_buttons()
	if horror_container:
		horror_container.visible = false

func open_diagnostic():
	_phase = 0
	_port_success = false
	_horror_correct_count = 0
	_horror_question_index = 0
	_awaiting_horror_answer = false
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

	# ── Milestone 3 face distortion ──────────────────────────────────────
	# If the horror manager has a pending distortion, fire it now.
	# This happens on the frame the panel opens, creating a 1-2 frame
	# corruption flash before the player can interact.
	if HorrorProgressionManager.pending_face_distortion:
		HorrorProgressionManager.emit_signal("face_distortion_requested")
		# The flag is cleared by FaceDistortion._process once it finishes.

func _build_port_buttons():
	for i in range(port_data.size()):
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
		_port_success = true
		feedback_label.text = "PORT 7 flagged. Initiating final verification..."
		await get_tree().create_timer(1.0).timeout
		_begin_horror_sequence()
	else:
		wrong_guesses += 1
		if wrong_guesses >= MAX_WRONG_GUESSES:
			_port_success = false
			feedback_label.text = "Too many failures. Proceeding to verification..."
			await get_tree().create_timer(1.5).timeout
			_begin_horror_sequence()
		else:
			feedback_label.text = "Incorrect. The anomaly shifts. Choose again."
			port_buttons[index].disabled = true

func _begin_horror_sequence() -> void:
	_phase = 1
	_horror_correct_count = 0
	_horror_question_index = 0
	port_container.visible = false
	_show_horror_question()

func _show_horror_question() -> void:
	if _horror_question_index >= HORROR_QUESTIONS.size():
		_finish_sequence()
		return

	var q = HORROR_QUESTIONS[_horror_question_index]
	_clear_horror_buttons()
	header_label.text = ""
	feedback_label.text = ""

	await get_tree().create_timer(0.4).timeout

	header_label.text = q["question"]
	header_label.visible_ratio = 0.0
	var tween = create_tween()
	tween.tween_property(header_label, "visible_ratio", 1.0, 1.2)
	await tween.finished
	await get_tree().create_timer(0.2).timeout

	if horror_container:
		horror_container.visible = true
		var answers = q["answers"]
		for i in range(answers.size()):
			var btn = Button.new()
			btn.text = "[ " + answers[i] + " ]"
			btn.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
			btn.add_theme_color_override("font_hover_color", Color(1.0, 0.5, 0.5))
			btn.pressed.connect(_on_horror_answer.bind(i))
			horror_container.add_child(btn)
			_horror_buttons.append(btn)
		_awaiting_horror_answer = true

func _on_horror_answer(index: int) -> void:
	if not _awaiting_horror_answer:
		return
	_awaiting_horror_answer = false

	var q = HORROR_QUESTIONS[_horror_question_index]
	var success = (index == q["correct"])
	for btn in _horror_buttons:
		btn.disabled = true

	if success:
		_horror_correct_count += 1
		feedback_label.text = q["success_text"]
	else:
		feedback_label.text = q["fail_text"]

	feedback_label.visible_ratio = 0.0
	var tween = create_tween()
	tween.tween_property(feedback_label, "visible_ratio", 1.0, 0.8)
	await tween.finished
	await get_tree().create_timer(1.2).timeout

	_horror_question_index += 1
	_show_horror_question()

func _finish_sequence() -> void:
	_phase = 2
	_clear_horror_buttons()
	if horror_container:
		horror_container.visible = false

	var horror_pass = _horror_correct_count >= 3
	var challenge_pass = ChallengeTracker.get_success_count() >= 3
	var overall = _port_success and horror_pass and challenge_pass

	var c_score = ChallengeTracker.get_success_count()
	var c_total = ChallengeTracker.required_ids.size()

	if overall:
		header_label.text = "CONTAINMENT SEQUENCE INITIATED\nTerminals: %d/%d | Verifications: %d/4 | Port: OK\nAll thresholds met." % [c_score, c_total, _horror_correct_count]
	else:
		var reasons = []
		if not _port_success:
			reasons.append("Port isolation failed")
		if not challenge_pass:
			reasons.append("Terminal score too low (%d/%d)" % [c_score, c_total])
		if not horror_pass:
			reasons.append("Verification score too low (%d/4)" % _horror_correct_count)
		header_label.text = "CONTAINMENT FAILED\n" + "\n".join(reasons)

	feedback_label.text = ""
	header_label.visible_ratio = 0.0
	var tween = create_tween()
	tween.tween_property(header_label, "visible_ratio", 1.0, 1.0)
	await tween.finished
	await get_tree().create_timer(2.0).timeout

	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	emit_signal("diagnostic_completed", overall)

func _clear_horror_buttons() -> void:
	for btn in _horror_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	_horror_buttons.clear()
