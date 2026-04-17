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
