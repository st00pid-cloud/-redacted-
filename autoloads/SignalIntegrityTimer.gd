extends CanvasLayer

## SignalIntegrityTimer — Autoload
## Displays an 8-minute "Signal Integrity" countdown in the top-left HUD.
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
@onready var progress_bar = $PanelContainer/VBoxContainer/ProgressBar
@onready var time_label = $PanelContainer/VBoxContainer/HBoxContainer/TimeLabel
@onready var header_label = $PanelContainer/VBoxContainer/HeaderLabel
@onready var warning_label = $PanelContainer/VBoxContainer/HBoxContainer/TimeLabel

var _blink_timer: float = 0.0 
var _blink_visible: bool = true
var _shake_timer: float = 0.0

const WARN_THRESHOLD: float   = 120.0  # 2 min  — yellow
const DANGER_THRESHOLD: float = 30.0   # 30 sec — red + blink

func _ready() -> void:
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
	time_label.text = "%02d:%02d" % [minutes, seconds]

	var ratio = _time_remaining / TOTAL_TIME
	progress_bar.value = ratio * 100

	if _time_remaining <= DANGER_THRESHOLD:
		progress_bar.tint_progress = Color(0.9, 0.15, 0.15, 0.95) 
		time_label.add_theme_color_override("font_color", Color(0.9, 0.15, 0.15, 0.95))
		header_label.add_theme_color_override("font_color", Color(0.9, 0.15, 0.15, 0.95))
		warning_label.text = "⚠ SIGNAL CRITICAL"
		warning_label.add_theme_color_override("font_color", Color(0.9, 0.15, 0.15, 0.95))
		warning_label.visible = _blink_visible

		_blink_timer += delta
		if _blink_timer >= 0.4:
			_blink_timer = 0.0
			_blink_visible = not _blink_visible

		_shake_timer += delta  
		if _shake_timer >= 0.08:
			_shake_timer = 0.0
			offset = Vector2(randf_range(-2, 2), randf_range(-1, 1))

	elif _time_remaining <= WARN_THRESHOLD:
		progress_bar.tint_progress = Color(0.85, 0.75, 0.2, 0.9)
		time_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.2, 0.9)) 
		header_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.2, 0.7))
		warning_label.text = "⚠ SIGNAL DEGRADING"
		warning_label.visible = true
		offset = Vector2.ZERO

	else:
		progress_bar.tint_progress = Color(0.3, 0.75, 0.3, 0.9)
		time_label.add_theme_color_override("font_color", Color(0.5, 0.85, 0.5, 0.85))
		header_label.add_theme_color_override("font_color", Color(0.4, 0.65, 0.4, 0.6)) 
		warning_label.visible = false
		offset = Vector2.ZERO

func _on_timer_expired() -> void:
	_running = false
	_expired = true
	hide()
	GameManager.trigger_game_over("signal_lost")
