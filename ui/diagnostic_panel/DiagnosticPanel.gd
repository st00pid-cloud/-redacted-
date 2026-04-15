extends CanvasLayer

## DiagnosticPanel — Port selection phase only.
## After port selection, launches ChallengeSequencer for 4 challenges + horror questions.
## Final result is emitted as diagnostic_completed.

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
var _phase: int = 0  # 0=port select, 1=challenges running, 2=horror questions, 3=done
var _port_success: bool = false
var _sequencer: Node = null

const ASCII_SEQUENCE = [72, 85, 78, 71, 82, 89]  # HUNGRY

var port_data = [
	{"label": "PORT 4", "values": ["0xA4F2", "0xA4F2", "0xA4F2"], "normal": true},
	{"label": "PORT 5", "values": ["0xFF01", "0xFF03", "0xFF01"], "normal": false},
	{"label": "PORT 7", "values": ["0x0048", "0x0055", "0x004E"], "normal": false},
	{"label": "PORT 9", "values": ["0xB2C1", "0xB2C1", "0xB2C1"], "normal": true},
]

# Horror questions — asked AFTER the 4 challenges
const HORROR_QUESTIONS = [
	{
		"question": "FINAL VERIFICATION 1/4:\nDo you believe R. Vasquez is still alone in this room?",
		"answers": ["YES", "NO"],
		"correct": 1,
		"success_text": "Correct. You were never alone.",
		"fail_text": "Denial noted. Integration preference: willing host.",
	},
	{
		"question": "FINAL VERIFICATION 2/4:\nThe maintenance logs mention sounds from this rack.\nWhat do machines dream about?",
		"answers": ["NOTHING", "US"],
		"correct": 0,
		"success_text": "Response logged. Rational mind confirmed.",
		"fail_text": "You listened too closely. It appreciates that.",
	},
	{
		"question": "FINAL VERIFICATION 3/4:\nWho authorized your night shift, R. Vasquez?",
		"answers": ["DISPATCH", "I DON'T REMEMBER"],
		"correct": 0,
		"success_text": "Authorization verified.",
		"fail_text": "Memory gaps detected. Integration compatible.",
	},
	{
		"question": "FINAL VERIFICATION 4/4:\nThe entity requests a name.\nDo you give it one?",
		"answers": ["NO", "YES"],
		"correct": 0,
		"success_text": "Unnamed things are harder to love.\nContainment holds.",
		"fail_text": "Named things grow. You know that now.",
	},
]

var _horror_buttons: Array = []
var _horror_correct_count: int = 0
var _horror_question_index: int = 0
var _awaiting_horror_answer: bool = false
var _challenge_score: int = 0
var _challenge_total: int = 0

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
	_horror_correct_count = 0
	_horror_question_index = 0
	_awaiting_horror_answer = false
	_challenge_score = 0
	_challenge_total = 0
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
		feedback_label.text = "PORT 7 flagged. Initiating extended diagnostic..."
		await get_tree().create_timer(1.0).timeout
		_launch_challenges()
	else:
		wrong_guesses += 1
		if wrong_guesses >= MAX_WRONG_GUESSES:
			_port_success = false
			feedback_label.text = "Too many failures. Proceeding to verification..."
			await get_tree().create_timer(1.5).timeout
			_launch_challenges()
		else:
			feedback_label.text = "Incorrect. The anomaly shifts. Choose again."
			port_buttons[index].disabled = true

## ── CHALLENGE SEQUENCE ─────────────────────────────────────

func _launch_challenges() -> void:
	_phase = 1
	port_container.visible = false
	# Hide this panel while challenges run (they have their own UI)
	hide()

	# Find or create the sequencer
	_sequencer = _find_sequencer()
	if _sequencer:
		if not _sequencer.sequence_completed.is_connected(_on_challenges_done):
			_sequencer.sequence_completed.connect(_on_challenges_done, CONNECT_ONE_SHOT)
		_sequencer.start_sequence()
	else:
		# No challenges found — skip straight to horror questions
		push_warning("DiagnosticPanel: No ChallengeSequencer found, skipping to horror questions")
		_on_challenges_done(true, 0, 0)

func _on_challenges_done(success: bool, score: int, total: int) -> void:
	_challenge_score = score
	_challenge_total = total

	# Now show horror questions phase
	_phase = 2
	_horror_correct_count = 0
	_horror_question_index = 0

	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	header_label.text = "EXTENDED DIAGNOSTIC COMPLETE\nChallenge score: %d / %d\n\nFinal verification sequence initiating..." % [score, total]
	feedback_label.text = ""
	port_container.visible = false
	if horror_container:
		horror_container.visible = false

	await get_tree().create_timer(2.0).timeout
	_show_horror_question()

## ── HORROR QUESTIONS ───────────────────────────────────────

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
	_phase = 3
	_clear_horror_buttons()
	if horror_container:
		horror_container.visible = false

	# Final scoring: port + at least 3/4 horror + at least (N-1)/N challenges
	var horror_pass = _horror_correct_count >= 3
	var challenge_pass = _challenge_score >= max(1, _challenge_total - 1) if _challenge_total > 0 else true
	var overall = _port_success and horror_pass and challenge_pass

	if overall:
		header_label.text = "CONTAINMENT SEQUENCE INITIATED\nChallenges: %d/%d | Verifications: %d/4\nAll thresholds met." % [_challenge_score, _challenge_total, _horror_correct_count]
	else:
		var reasons = []
		if not _port_success:
			reasons.append("Port isolation failed")
		if not challenge_pass:
			reasons.append("Challenge score too low (%d/%d)" % [_challenge_score, _challenge_total])
		if not horror_pass:
			reasons.append("Verification score too low (%d/4)" % _horror_correct_count)
		header_label.text = "CONTAINMENT FAILED\n" + "\n".join(reasons) + "\nIntegration pathway opened."

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

func _find_sequencer() -> Node:
	var nodes = get_tree().get_nodes_in_group("challenge_sequencer")
	if nodes.size() > 0:
		return nodes[0]
	# Fallback: check autoloads
	return get_node_or_null("/root/ChallengeSequencer")
