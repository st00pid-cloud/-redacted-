extends CanvasLayer

## MemoryString — Pattern/typing challenge
## A 12-char string flashes for 3 seconds. Player must type it back.
## As they type, the system types its own message in red alongside: I AM BEHIND YOU

signal challenge_completed(success: bool)

var _root_control: Control
var _header: Label
var _feedback: Label
var _display_label: Label  # shows the string to memorize
var _input_label: Label    # player's typed characters
var _system_label: Label   # system's creepy interleaved text
var _phase: int = 0  # 0=showing, 1=typing, 2=verification, 3=done

var _target_string: String = "VASQUEZHELPM"
var _system_message: String = "IAMBEHINDYOU"
var _player_input: String = ""
var _char_index: int = 0
var _show_timer: float = 0.0
var _show_duration: float = 3.5
var _input_active: bool = false

func _ready():
	add_to_group("challenge_memory")
	hide()

func open_challenge() -> void:
	_phase = 0
	_player_input = ""
	_char_index = 0
	_show_timer = 0.0
	_input_active = false

	# Randomize target slightly each time
	var variants = ["VASQUEZHELPM", "RACK7ENTITYX", "PORTISOLATEN", "HELPVASQUEZ0"]
	_target_string = variants[randi() % variants.size()]

	_build_ui()
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	_root_control = Control.new()
	_root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root_control)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.9)
	_root_control.add_child(bg)

	_header = Label.new()
	_header.text = "MEMORY STRING VALIDATION — Memorize the sequence"
	_header.position = Vector2(40, 30)
	_header.add_theme_font_size_override("font_size", 16)
	_header.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	_root_control.add_child(_header)

	var instr = Label.new()
	instr.text = "A string will appear for %.1f seconds. Memorize it, then type it back exactly." % _show_duration
	instr.position = Vector2(40, 58)
	instr.add_theme_font_size_override("font_size", 12)
	instr.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5, 0.7))
	_root_control.add_child(instr)

	# The display string (large, monospace-feel)
	_display_label = Label.new()
	_display_label.text = _format_spaced(_target_string)
	_display_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_display_label.position = Vector2(100, 150)
	_display_label.size = Vector2(900, 60)
	_display_label.add_theme_font_size_override("font_size", 40)
	_display_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1.0))
	_root_control.add_child(_display_label)

	# Countdown label
	_feedback = Label.new()
	_feedback.text = ""
	_feedback.position = Vector2(40, 230)
	_feedback.add_theme_font_size_override("font_size", 14)
	_feedback.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD
	_feedback.size = Vector2(900, 40)
	_root_control.add_child(_feedback)

	# Player input display (green)
	var input_header = Label.new()
	input_header.text = "YOUR INPUT:"
	input_header.position = Vector2(100, 280)
	input_header.add_theme_font_size_override("font_size", 12)
	input_header.add_theme_color_override("font_color", Color(0.4, 0.7, 0.4, 0.6))
	_root_control.add_child(input_header)

	_input_label = Label.new()
	_input_label.text = ""
	_input_label.position = Vector2(100, 305)
	_input_label.size = Vector2(900, 50)
	_input_label.add_theme_font_size_override("font_size", 36)
	_input_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	_root_control.add_child(_input_label)

	# System's creepy text (red, appears alongside)
	var sys_header = Label.new()
	sys_header.text = "SYSTEM INPUT:"
	sys_header.position = Vector2(100, 370)
	sys_header.add_theme_font_size_override("font_size", 12)
	sys_header.add_theme_color_override("font_color", Color(0.7, 0.3, 0.3, 0.6))
	sys_header.visible = false
	sys_header.name = "SysHeader"
	_root_control.add_child(sys_header)

	_system_label = Label.new()
	_system_label.text = ""
	_system_label.position = Vector2(100, 395)
	_system_label.size = Vector2(900, 50)
	_system_label.add_theme_font_size_override("font_size", 36)
	_system_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2, 0.8))
	_root_control.add_child(_system_label)

func _format_spaced(s: String) -> String:
	var result = ""
	for i in range(s.length()):
		result += s[i]
		if i < s.length() - 1:
			result += "  "
	return result

func _process(delta: float) -> void:
	if not visible:
		return

	if _phase == 0:
		_show_timer += delta
		var remaining = _show_duration - _show_timer
		_feedback.text = "Memorize now... %.1f s" % max(0, remaining)

		# Flash effect near end
		if remaining < 1.0:
			_display_label.modulate.a = 0.3 + 0.7 * abs(sin(_show_timer * 8.0))

		if _show_timer >= _show_duration:
			_phase = 1
			_input_active = true
			_display_label.text = "? ? ? ? ? ? ? ? ? ? ? ?"
			_display_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 0.4))
			_display_label.modulate.a = 1.0
			_feedback.text = "Type the string from memory. Press ENTER when done."

			# Show system header
			var sys_h = _root_control.get_node_or_null("SysHeader")
			if sys_h:
				sys_h.visible = true

func _input(event: InputEvent) -> void:
	if not visible or not _input_active:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_input_active = false
			_evaluate()
			return

		if event.keycode == KEY_BACKSPACE:
			if _player_input.length() > 0:
				_player_input = _player_input.substr(0, _player_input.length() - 1)
				_char_index = max(0, _char_index - 1)
				_update_display()
			return

		# Get the character
		var ch = _keycode_to_char(event.keycode, event.shift_pressed)
		if ch != "" and _player_input.length() < 12:
			_player_input += ch
			_char_index = _player_input.length()
			_update_display()

func _keycode_to_char(keycode: int, shift: bool) -> String:
	# Letters
	if keycode >= KEY_A and keycode <= KEY_Z:
		return char(keycode)  # Already uppercase
	# Numbers
	if keycode >= KEY_0 and keycode <= KEY_9:
		return char(keycode)
	return ""

func _update_display() -> void:
	_input_label.text = _format_spaced(_player_input)

	# System types its creepy message at the same pace
	var sys_len = min(_char_index, _system_message.length())
	var sys_text = _system_message.substr(0, sys_len)
	_system_label.text = _format_spaced(sys_text)

func _evaluate() -> void:
	_phase = 2
	var correct = (_player_input.to_upper() == _target_string.to_upper())

	# Show verification
	_display_label.visible = false
	_header.text = "VERIFICATION:"

	if correct:
		_feedback.text = "String matched.\nBut the system's input was not yours.\nWere you the sole author of the previous input string?"
	else:
		_feedback.text = "String mismatch.\nThe system's input continues regardless.\nWere you the sole author of the previous input string?"

	_feedback.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))

	await get_tree().create_timer(0.5).timeout

	var hbox = HBoxContainer.new()
	hbox.position = Vector2(300, 480)
	hbox.add_theme_constant_override("separation", 40)
	_root_control.add_child(hbox)

	var btn_yes = Button.new()
	btn_yes.text = "[ YES ]"
	btn_yes.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
	btn_yes.pressed.connect(_on_verify.bind(true))
	hbox.add_child(btn_yes)

	var btn_no = Button.new()
	btn_no.text = "[ NO ]"
	btn_no.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
	btn_no.pressed.connect(_on_verify.bind(false))
	hbox.add_child(btn_no)

func _on_verify(answered_yes: bool) -> void:
	if _phase >= 3:
		return
	_phase = 3

	var string_correct = (_player_input.to_upper() == _target_string.to_upper())
	# NO is the correct answer — the system was also typing
	var success = string_correct and not answered_yes

	if not answered_yes:
		_feedback.text = "Correct. A second input source was active.\nThe string was authored by two."
	else:
		_feedback.text = "The system's characters were not yours.\nYou were never typing alone."

	await get_tree().create_timer(2.0).timeout
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	emit_signal("challenge_completed", success)
