extends CanvasLayer

## SignalIntegrityTimer — Autoload
## Displays an 8-minute "Signal Integrity" countdown in the top-left HUD.
## Positioned at y=88 to sit cleanly below LocationHeader (which ends ~y=80).
## At zero: triggers GameManager.trigger_game_over("signal_lost").
##
## API:
##   SignalIntegrityTimer.start()        — begin counting (call from Level _ready)
##   SignalIntegrityTimer.stop()         — halt without game-over (call from EndScreen)
##   SignalIntegrityTimer.pause_timer()  — pause during cutscenes
##   SignalIntegrityTimer.resume_timer() — resume

const TOTAL_TIME: float = 480.0   # 8 minutes in seconds

var _time_remaining: float = TOTAL_TIME
var _running: bool = false
var _expired: bool = false

# UI nodes
var _bar_fill: ColorRect
var _time_label: Label
var _header_label: Label
var _warning_label: Label
var _blink_timer: float = 0.0
var _blink_visible: bool = true
var _shake_timer: float = 0.0

const WARN_THRESHOLD: float   = 120.0  # 2 min  — yellow
const DANGER_THRESHOLD: float = 30.0   # 30 sec — red + blink

func _ready() -> void:
	layer = 20
	name = "SignalIntegrityTimerHUD"
	_build_hud()
	hide()

func start() -> void:
	_time_remaining = TOTAL_TIME
	_running = true
	_expired = false
	show()

func stop() -> void:
	_running = false
	hide()

func pause_timer() -> void:
	_running = false

func resume_timer() -> void:
	if not _expired:
		_running = true

# ── HUD construction ─────────────────────────────────────────────────────

func _build_hud() -> void:
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root.offset_right  = 260.0
	root.offset_bottom = 68.0
	# y=88 places this just below LocationHeader (offset_top=16, two labels ~64px tall)
	root.position = Vector2(16, 88)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Panel background
	var panel_bg = ColorRect.new()
	panel_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_bg.color = Color(0.0, 0.03, 0.0, 0.55)
	panel_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel_bg)

	# Header label
	_header_label = Label.new()
	_header_label.text = "SIG INTEGRITY"
	_header_label.position = Vector2(8, 4)
	_header_label.add_theme_font_size_override("font_size", 9)
	_header_label.add_theme_color_override("font_color", Color(0.4, 0.65, 0.4, 0.6))
	root.add_child(_header_label)

	# Time label (right-aligned)
	_time_label = Label.new()
	_time_label.text = "08:00"
	_time_label.position = Vector2(170, 2)
	_time_label.size = Vector2(80, 20)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_time_label.add_theme_font_size_override("font_size", 12)
	_time_label.add_theme_color_override("font_color", Color(0.5, 0.85, 0.5, 0.85))
	root.add_child(_time_label)

	# Progress bar background
	var bar_bg = ColorRect.new()
	bar_bg.position = Vector2(8, 22)
	bar_bg.size = Vector2(244, 6)
	bar_bg.color = Color(0.08, 0.12, 0.08, 0.8)
	root.add_child(bar_bg)

	# Progress bar fill
	_bar_fill = ColorRect.new()
	_bar_fill.position = Vector2(8, 22)
	_bar_fill.size = Vector2(244, 6)
	_bar_fill.color = Color(0.3, 0.75, 0.3, 0.9)
	root.add_child(_bar_fill)

	# Warning label (hidden until danger zone)
	_warning_label = Label.new()
	_warning_label.text = "⚠ SIGNAL DEGRADING"
	_warning_label.position = Vector2(8, 32)
	_warning_label.add_theme_font_size_override("font_size", 9)
	_warning_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.1, 0.9))
	_warning_label.visible = false
	root.add_child(_warning_label)

# ── Update loop ──────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _running or _expired:
		return

	_time_remaining -= delta
	_time_remaining = max(0.0, _time_remaining)
	_update_display(delta)

	if _time_remaining <= 0.0:
		_on_timer_expired()

func _update_display(delta: float) -> void:
	var minutes = int(_time_remaining) / 60
	var seconds = int(_time_remaining) % 60
	_time_label.text = "%02d:%02d" % [minutes, seconds]

	var ratio = _time_remaining / TOTAL_TIME
	_bar_fill.size.x = 244.0 * ratio

	if _time_remaining <= DANGER_THRESHOLD:
		var red = Color(0.9, 0.15, 0.15, 0.95)
		_bar_fill.color = red
		_time_label.add_theme_color_override("font_color", red)
		_header_label.add_theme_color_override("font_color", red)
		_warning_label.text = "⚠ SIGNAL CRITICAL"
		_warning_label.add_theme_color_override("font_color", red)
		_warning_label.visible = _blink_visible

		_blink_timer += delta
		if _blink_timer >= 0.4:
			_blink_timer = 0.0
			_blink_visible = not _blink_visible

		_shake_timer += delta
		if _shake_timer >= 0.08:
			_shake_timer = 0.0
			offset = Vector2(randf_range(-2, 2), randf_range(-1, 1))

	elif _time_remaining <= WARN_THRESHOLD:
		var yellow = Color(0.85, 0.75, 0.2, 0.9)
		_bar_fill.color = yellow
		_time_label.add_theme_color_override("font_color", yellow)
		_header_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.2, 0.7))
		_warning_label.text = "⚠ SIGNAL DEGRADING"
		_warning_label.visible = true
		offset = Vector2.ZERO

	else:
		_bar_fill.color = Color(0.3, 0.75, 0.3, 0.9)
		_time_label.add_theme_color_override("font_color", Color(0.5, 0.85, 0.5, 0.85))
		_header_label.add_theme_color_override("font_color", Color(0.4, 0.65, 0.4, 0.6))
		_warning_label.visible = false
		offset = Vector2.ZERO

func _on_timer_expired() -> void:
	_running = false
	_expired = true
	hide()
	GameManager.trigger_game_over("signal_lost")
