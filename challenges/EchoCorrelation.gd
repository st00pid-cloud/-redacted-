extends CanvasLayer

## EchoCorrelation.gd — Scene-based version (CORRECTED PATHS)
## Script is attached to the EchoCorrelation (CanvasLayer) node
## All @onready paths are relative to EchoCorrelation

signal challenge_completed(success: bool)

# Scene UI references — paths relative to EchoCorrelation (CanvasLayer root)
@onready var _root_control: Control = $RootControl
@onready var _header: Label = $RootControl/Panel/VBoxContainer/HeaderLabel
@onready var _feedback: Label = $RootControl/Panel/VBoxContainer2/FeedbackLabel
@onready var _slider: HSlider = $RootControl/Panel/VBoxContainer2/AlignSlider
@onready var _wave_a: Control = $RootControl/Panel/VBoxContainer2/WaveAControl
@onready var _wave_b: Control = $RootControl/Panel/VBoxContainer2/WaveBControl
@onready var _feed_a_label: Label = $RootControl/Panel/VBoxContainer2/FeedALabel
@onready var _feed_b_label: Label = $RootControl/Panel/VBoxContainer2/FeedBLabel
@onready var _sync_label: Label = $RootControl/Panel/VBoxContainer2/SyncLabel
@onready var _vbox: VBoxContainer = $RootControl/Panel/VBoxContainer
@onready var _confirm_btn: Button = $RootControl/Panel/VBoxContainer2/ConfirmButton

var _phase: int = 0  # 0=adjusting, 1=verification, 2=done

var _slider_value: float = 0.0
var _target_sync: float = 0.0       # randomized each open
var _sync_threshold: float = 0.08
var _wave_timer: float = 0.0
var _reveal_text_shown: bool = false
var _timeout_timer: float = 0.0
const TIMEOUT: float = 90.0

var _ambient_sfx: AudioStreamPlayer

func _ready():
	add_to_group("challenge_echo")
	hide()
	# Connect signals once in _ready, not in _build_ui
	_slider.value_changed.connect(_on_slider_changed)
	_wave_a.draw.connect(_draw_wave_a)
	_wave_b.draw.connect(_draw_wave_b)
	_confirm_btn.pressed.connect(_on_confirm)

func open_challenge() -> void:
	_phase = 0
	_reveal_text_shown = false
	_slider_value = 0.0
	_timeout_timer = 0.0
	# Randomize sweet spot each run
	_target_sync = randf_range(0.55, 0.85)
	
	# Reset UI state (scene already exists, just reset values)
	_slider.value = 0.0
	_feedback.text = ""
	_sync_label.text = "Sync Status: 0%"
	_reveal_text_shown = false
	_confirm_btn.visible = false
	_header.text = "AUDIO MATCH — Pinpointing Source"
	_feed_a_label.text = "MIC A : Room Floor: [STATIC]"
	_feed_b_label.text = "MIC B : Air Vents: [STATIC]"
	
	# Create or reuse ambient audio
	if not _ambient_sfx:
		_ambient_sfx = AudioStreamPlayer.new()
		_ambient_sfx.name = "AmbientSFX"
		_root_control.add_child(_ambient_sfx)
		var stream = _load_ambient_stream()
		if stream:
			_ambient_sfx.stream = stream
			_ambient_sfx.volume_db = -20.0
	
	if _ambient_sfx:
		_ambient_sfx.play()
	
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

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
	_sync_label.text = "Sync Status: %d%%" % int(sync_pct * 100)

	# Update ambient audio to track sync
	if _ambient_sfx and _ambient_sfx.playing:
		_ambient_sfx.pitch_scale = 0.8 + (sync_pct * 0.4)
		_ambient_sfx.volume_db = lerp(-20.0, -6.0, sync_pct)

	if sync_pct > 0.85 and not _reveal_text_shown:
		_reveal_text_shown = true
		# Typewriter reveal instead of instant assignment
		_typewrite_label(_feed_a_label,
			"MIC A — Room Floor: [TYPING — Sound of your own keyboard]", 0.03)
		_typewrite_label(_feed_b_label,
			"MIC B — Air Vents: [HEAVY BREATHING — Pattern detected]", 0.03)
		_feedback.text = "WARNING: Air vent audio contains a heartbeat.\n You are the only person registered in this sector."
		_confirm_btn.visible = true
	elif sync_pct < 0.8:
		_confirm_btn.visible = false
		if _reveal_text_shown:
			_reveal_text_shown = false
			_feed_a_label.text = "MIC A — Room Floor: [FILTERING...]"
			_feed_b_label.text = "MIC B — Air Vents: [FILTERING...]"
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
	_header.text = "VERIFICATION"
	_feedback.text = "Did you hear something living in the vents?"

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
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
	_feedback.text = "Confirmed. You are not alone down here." if success else "Ignoring the evidence. Proceeding anyway."
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
			_feedback.text = "Time's up. Locking the results in now."
			_on_confirm()
			return

	_wave_timer += delta
	# Queue redraws — signals already connected in _ready, not here
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
