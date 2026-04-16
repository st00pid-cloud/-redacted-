extends CanvasLayer

## EchoCorrelation.gd — All improvements integrated:
## - _vbox stored as instance variable (fixes hardcoded child path)
## - Wave draw signals connected once in _build_ui (not every frame)
## - _target_sync randomized per open (0.55–0.85)
## - 90-second timeout forces verification if player never syncs
## - Feed labels typewriter-reveal when sync crosses threshold
## - Ambient AudioStreamPlayer pitch/volume tracks sync level

signal challenge_completed(success: bool)

var _root_control: Control
var _vbox: VBoxContainer
var _header: Label
var _feedback: Label
var _slider: HSlider
var _wave_a: Control
var _wave_b: Control
var _feed_a_label: Label
var _feed_b_label: Label
var _sync_label: Label
var _confirm_btn: Button
var _ambient_sfx: AudioStreamPlayer
var _phase: int = 0  # 0=adjusting, 1=verification, 2=done

var _slider_value: float = 0.0
var _target_sync: float = 0.0       # randomized each open
var _sync_threshold: float = 0.08
var _wave_timer: float = 0.0
var _reveal_text_shown: bool = false
var _timeout_timer: float = 0.0
const TIMEOUT: float = 90.0

func _ready():
	add_to_group("challenge_echo")
	hide()

func open_challenge() -> void:
	_phase = 0
	_reveal_text_shown = false
	_slider_value = 0.0
	_timeout_timer = 0.0
	# Randomize sweet spot each run
	_target_sync = randf_range(0.55, 0.85)
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
	bg.color = Color(0, 0, 0, 0.8)
	_root_control.add_child(bg)

	var panel = Panel.new()
	panel.clip_contents = true
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(760, 520)
	panel.offset_left = -380
	panel.offset_top = -260
	panel.offset_right = 380
	panel.offset_bottom = 260
	_root_control.add_child(panel)

	# Store vbox as instance variable — fixes hardcoded get_child path
	_vbox = VBoxContainer.new()
	_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vbox.offset_left = 24
	_vbox.offset_top = 24
	_vbox.offset_right = -24
	_vbox.offset_bottom = -24
	_vbox.add_theme_constant_override("separation", 12)
	panel.add_child(_vbox)

	_header = Label.new()
	_header.text = "ECHO CORRELATION — Audio Feed Alignment"
	_header.add_theme_font_size_override("font_size", 16)
	_header.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	_vbox.add_child(_header)

	var instr = Label.new()
	instr.text = "Align the two audio feeds using the slider. Match the waveforms."
	instr.add_theme_font_size_override("font_size", 12)
	instr.autowrap_mode = TextServer.AUTOWRAP_WORD
	_vbox.add_child(instr)

	_feed_a_label = Label.new()
	_feed_a_label.text = "FEED A — Room Microphone: [STATIC]"
	_feed_a_label.add_theme_font_size_override("font_size", 11)
	_vbox.add_child(_feed_a_label)

	_wave_a = Control.new()
	_wave_a.custom_minimum_size = Vector2(680, 60)
	_vbox.add_child(_wave_a)

	_feed_b_label = Label.new()
	_feed_b_label.text = "FEED B — Ventilation Intake: [STATIC]"
	_feed_b_label.add_theme_font_size_override("font_size", 11)
	_vbox.add_child(_feed_b_label)

	_wave_b = Control.new()
	_wave_b.custom_minimum_size = Vector2(680, 60)
	_vbox.add_child(_wave_b)

	_slider = HSlider.new()
	_slider.min_value = 0.0
	_slider.max_value = 1.0
	_slider.step = 0.01
	_slider.custom_minimum_size = Vector2(680, 24)
	_slider.value_changed.connect(_on_slider_changed)
	_vbox.add_child(_slider)

	_sync_label = Label.new()
	_sync_label.text = "Synchronization: 0%"
	_sync_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(_sync_label)

	_feedback = Label.new()
	_feedback.text = ""
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD
	_feedback.add_theme_font_size_override("font_size", 12)
	_feedback.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
	_vbox.add_child(_feedback)

	_confirm_btn = Button.new()
	_confirm_btn.text = "[ LOCK ALIGNMENT ]"
	_confirm_btn.visible = false
	_confirm_btn.pressed.connect(_on_confirm)
	_vbox.add_child(_confirm_btn)

	# Connect wave draw signals once here — not every frame in _process
	_wave_a.draw.connect(_draw_wave_a)
	_wave_b.draw.connect(_draw_wave_b)

	# Ambient audio — pitch and volume track sync level
	_ambient_sfx = AudioStreamPlayer.new()
	_ambient_sfx.name = "AmbientSFX"
	_root_control.add_child(_ambient_sfx)
	var stream = _load_ambient_stream()
	if stream:
		_ambient_sfx.stream = stream
		_ambient_sfx.volume_db = -20.0
		_ambient_sfx.play()

func _load_ambient_stream() -> AudioStream:
	var paths = [
		"res://audio/static_loop.wav",
		"res://audio/static_loop.ogg",
		"res://audio/506220__nucleartape__gross-glitch.wav",
	]
	for path in paths:
		if ResourceLoader.exists(path):
			return load(path)
	return null

func _on_slider_changed(value: float) -> void:
	_slider_value = value
	var sync_pct = _get_sync_percent()
	_sync_label.text = "Synchronization: %d%%" % int(sync_pct * 100)

	# Update ambient audio to track sync
	if _ambient_sfx and _ambient_sfx.playing:
		_ambient_sfx.pitch_scale = 0.8 + (sync_pct * 0.4)
		_ambient_sfx.volume_db = lerp(-20.0, -6.0, sync_pct)

	if sync_pct > 0.85 and not _reveal_text_shown:
		_reveal_text_shown = true
		# Typewriter reveal instead of instant assignment
		_typewrite_label(_feed_a_label,
			"FEED A — Room Microphone: [KEYBOARD TYPING — IDENTIFIED AS LOCAL INPUT]", 0.03)
		_typewrite_label(_feed_b_label,
			"FEED B — Ventilation Intake: [BIOLOGICAL — RESPIRATORY PATTERN DETECTED]", 0.03)
		_feedback.text = "WARNING: Feed B contains a respiratory signature.\nThis does not match the room's registered occupant count."
		_confirm_btn.visible = true
	elif sync_pct < 0.8:
		_confirm_btn.visible = false
		if _reveal_text_shown:
			_reveal_text_shown = false
			_feed_a_label.text = "FEED A — Room Microphone: [RESOLVING...]"
			_feed_b_label.text = "FEED B — Ventilation Intake: [RESOLVING...]"
			_feedback.text = ""

func _typewrite_label(label: Label, text: String, speed: float) -> void:
	label.text = ""
	var tween = create_tween()
	for i in range(text.length()):
		tween.tween_callback(func(): label.text += text[i])
		tween.tween_interval(speed)

func _get_sync_percent() -> float:
	var dist = abs(_slider_value - _target_sync)
	return clampf(1.0 - (dist / 0.5), 0.0, 1.0)

func _on_confirm() -> void:
	if _phase != 0:
		return
	_phase = 1
	_slider.editable = false
	_confirm_btn.visible = false
	_header.text = "VERIFICATION:"
	_feedback.text = "Did the audio signature in Feed B match a known biological entity?"

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	# Use stored _vbox reference — no hardcoded child path
	_vbox.add_child(hbox)

	var btn_yes = Button.new()
	btn_yes.text = "[ YES ]"
	btn_yes.pressed.connect(_on_verify.bind(true))
	hbox.add_child(btn_yes)

	var btn_no = Button.new()
	btn_no.text = "[ NO ]"
	btn_no.pressed.connect(_on_verify.bind(false))
	hbox.add_child(btn_no)

func _on_verify(answered_yes: bool) -> void:
	if _phase != 1:
		return
	_phase = 2
	var success = answered_yes
	_feedback.text = "Acknowledged. Anomalous presence confirmed." if success else "Denial logged. The feed continues."
	await get_tree().create_timer(2.0).timeout
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	emit_signal("challenge_completed", success)

func _process(delta: float) -> void:
	if not visible or _phase >= 2:
		return

	# 90-second timeout — forces verification if player never syncs
	if _phase == 0:
		_timeout_timer += delta
		if _timeout_timer >= TIMEOUT and not _reveal_text_shown:
			_feedback.text = "Feed alignment window expired. Proceeding to verification."
			_on_confirm()
			return

	_wave_timer += delta
	# Queue redraws — signals already connected in _build_ui, not here
	if _wave_a:
		_wave_a.queue_redraw()
	if _wave_b:
		_wave_b.queue_redraw()

func _draw_wave_a() -> void:
	if not _wave_a:
		return
	var w = _wave_a.size.x
	var h = _wave_a.size.y
	var mid = h * 0.5
	var sync_pct = _get_sync_percent()
	for i in range(int(w)):
		var t = float(i) / w * 12.0 + _wave_timer * 3.0
		var amp = mid * 0.6 * (0.3 + 0.7 * sync_pct)
		var val = sin(t * 2.0) * amp * (0.5 + 0.5 * sin(t * 7.0))
		val += randf_range(-1, 1) * mid * 0.4 * (1.0 - sync_pct)
		_wave_a.draw_rect(Rect2(i, clamp(mid + val, 0, h), 1, 1), Color(0.3, 0.8, 0.3, 0.7))

func _draw_wave_b() -> void:
	if not _wave_b:
		return
	var w = _wave_b.size.x
	var h = _wave_b.size.y
	var mid = h * 0.5
	var sync_pct = _get_sync_percent()
	var phase_offset = _slider_value * 10.0
	for i in range(int(w)):
		var t = float(i) / w * 6.0 + _wave_timer * 1.2 + phase_offset
		var amp = mid * 0.5 * (0.3 + 0.7 * sync_pct)
		var val = sin(t) * amp * (0.8 + 0.2 * sin(t * 0.3))
		val += randf_range(-1, 1) * mid * 0.5 * (1.0 - sync_pct)
		var color = Color(0.8, 0.3, 0.3, 0.6) if sync_pct > 0.7 else Color(0.5, 0.5, 0.3, 0.5)
		_wave_b.draw_rect(Rect2(i, clamp(mid + val, 0, h), 1, 1), color)
