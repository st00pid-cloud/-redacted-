extends CanvasLayer

## MemoryString.gd — Scene-based version (CORRECTED PATHS)
## Script attached to MemoryString (CanvasLayer) node

signal challenge_completed(success: bool)

@onready var _root_control: Control = $RootControl
@onready var _header: Label = $RootControl/HeaderLabel
@onready var _feedback: Label = $RootControl/FeedbackLabel
@onready var _display_label: Label = $RootControl/DisplayLabel
@onready var _input_label: Label = $RootControl/HBoxContainer/InputHeader
@onready var _system_label: Label = $RootControl/HBoxContainer2/SystemLabel

var _phase: int = 0  # 0=showing, 1=typing, 2=verification, 3=done

var _target_string: String = ""
var _system_message: String = "IAMBEHINDYOU"
var _player_input: String = ""
var _char_index: int = 0
var _show_timer: float = 0.0
var _show_duration: float = 3.5
var _input_active: bool = false

var _attempt_count: int = 0

var _glitch_timer: float = 0.0

var _sfx_player: AudioStreamPlayer = null
var _sfx_system: AudioStreamPlayer = null

const STRING_POOL = [
	"MBUTIDOHELPM", "RACK7ENTITYX", "PORTISOLATEN", "HELPEMBUTIDO",
	"CHEN0MISSING", "R0DRIGUEZNOW", "SUBLEVEL3KEY", "BUFFEROVERFL",
	"ITSINSIDEYOU", "RACK7ALIGNED", "NODATAEXISTS", "YOUARESTAYED",
] 
  

func _ready():
	add_to_group("challenge_memory")
	hide()

func open_challenge() -> void:
	_phase = 0
	_player_input = ""
	_char_index = 0
	_show_timer = 0.0
	_input_active = false
	_glitch_timer = 0.0

	var diff = ChallengeTracker.get_difficulty_multiplier()
	_show_duration = max(2.0, (3.5 - (_attempt_count * 0.5)) / diff)
	_attempt_count += 1

	_target_string = STRING_POOL[randi() % STRING_POOL.size()]

	_reset_ui()
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _reset_ui() -> void:
	_display_label.text = _format_spaced(_target_string)
	_display_label.modulate.a = 1.0
	_display_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1.0))

	_input_label.text = ""
	_system_label.text = ""

	_feedback.text = "Memorize now... %.1f s" % _show_duration

	var sys_h = _root_control.get_node_or_null("SystemHeader")
	if sys_h:
		sys_h.visible = false

	if not _sfx_player:
		_sfx_player = AudioStreamPlayer.new()
		_sfx_player.name = "TypingSFX"
		_root_control.add_child(_sfx_player)

	if not _sfx_system:
		_sfx_system = AudioStreamPlayer.new()
		_sfx_system.name = "SystemSFX"
		_sfx_system.pitch_scale = 0.75
		_root_control.add_child(_sfx_system)

	var typing_stream = _load_typing_stream()
	if typing_stream:
		_sfx_player.stream = typing_stream
		_sfx_system.stream = typing_stream

func _load_typing_stream() -> AudioStream:
	var paths = [
		"res://ui/dialogue_box/350884__elmasmalo1__interfacedialogue-typing-soundfx-2nd-variation.wav",
		"res://audio/typing.wav",
		"res://audio/typing.ogg",
	]
	for path in paths:
		if ResourceLoader.exists(path):
			return load(path)
	return null

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

		if remaining < 1.0:
			_display_label.modulate.a = 0.3 + 0.7 * abs(sin(_show_timer * 8.0))

		if _show_timer >= _show_duration:
			_phase = 1
			_input_active = true
			_display_label.text = "? ? ? ? ? ? ? ? ? ? ? ?"
			_display_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 0.4))
			_display_label.modulate.a = 1.0
			_feedback.text = "Type the string from memory. Press ENTER when done."
			var sys_h = _root_control.get_node_or_null("SystemHeader")
			if sys_h:
				sys_h.visible = true

	elif _phase == 1 and _input_active:
		_glitch_timer += delta
		if _glitch_timer >= 0.4:
			_glitch_timer = 0.0
			if _system_label and _char_index > 0 and randf() < 0.3:
				var correct_text = _system_message.substr(0, _char_index)
				var glitch_idx = randi() % _char_index
				var chars = correct_text.split("")
				chars[glitch_idx] = char(randi_range(65, 90))
				var glitched = "".join(chars)
				_system_label.text = _format_spaced(glitched)
				await get_tree().create_timer(0.08).timeout
				if is_instance_valid(_system_label) and _phase == 1:
					_system_label.text = _format_spaced(correct_text)

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

		var ch = _keycode_to_char(event.keycode)
		if ch != "" and _player_input.length() < 12:
			_player_input += ch
			_char_index = _player_input.length()
			_update_display()
			if _sfx_player and not _sfx_player.playing:
				_sfx_player.play()

func _keycode_to_char(keycode: int) -> String:
	if keycode >= KEY_A and keycode <= KEY_Z:
		return char(keycode)
	if keycode >= KEY_0 and keycode <= KEY_9:
		return char(keycode)
	return ""

func _update_display() -> void:
	_input_label.text = _format_spaced(_player_input)

	var sys_len = min(_char_index, _system_message.length())
	var sys_text = _system_message.substr(0, sys_len)
	_system_label.text = _format_spaced(sys_text)

	if _sfx_system and not _sfx_system.playing:
		_sfx_system.play()

func _evaluate() -> void:
	_input_active = false
	_phase = 2

	var correct = (_player_input.to_upper() == _target_string.to_upper())

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
	var success = string_correct and not answered_yes

	if not answered_yes:
		_feedback.text = "Correct. A second input source was active.\nThe string was authored by two."
	else:
		_feedback.text = "The system's characters were not yours.\nYou were never typing alone."

	await get_tree().create_timer(2.0).timeout
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	emit_signal("challenge_completed", success)
