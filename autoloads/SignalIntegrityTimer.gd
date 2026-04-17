extends CanvasLayer

## SignalIntegrityTimer — Autoload
## Displays an 8-minute "Signal Integrity" countdown.

const TOTAL_TIME: float = 480.0 

var _time_remaining: float = TOTAL_TIME
var _running: bool = false
var _expired: bool = false

# UI nodes
@onready var main_container: PanelContainer = $CenterContainer/PanelContainer
@onready var progress_bar = $CenterContainer/PanelContainer/VBoxContainer/ProgressBar
@onready var time_label = $CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/TimeLabel
@onready var header_label = $CenterContainer/PanelContainer/VBoxContainer/HeaderLabel
@onready var warning_label = $CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/WarningLabel

var _blink_timer: float = 0.0
var _blink_visible: bool = true
var _shake_timer: float = 0.0

const WARN_THRESHOLD: float   = 120.0
const DANGER_THRESHOLD: float = 30.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

func start() -> void:
	_time_remaining = TOTAL_TIME
	_running = true
	_expired = false
	show()

func stop() -> void:
	_running = false
	hide()

func reset() -> void:
	_time_remaining = TOTAL_TIME
	_running = false
	_expired = false
	_blink_timer = 0.0
	_blink_visible = true
	_shake_timer = 0.0
	if is_instance_valid(main_container):
		main_container.position = Vector2.ZERO
	hide()

func pause_timer() -> void:
	_running = false

func resume_timer() -> void:
	if not _expired:
		_running = true

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
		# Danger styling (red)
		var danger_color = Color(0.9, 0.15, 0.15, 0.95)
		progress_bar.self_modulate = danger_color
		time_label.add_theme_color_override("font_color", danger_color)
		header_label.add_theme_color_override("font_color", danger_color)

		warning_label.text = "⚠ SIGNAL CRITICAL"
		warning_label.add_theme_color_override("font_color", danger_color)

		_blink_timer += delta
		if _blink_timer >= 0.4:
			_blink_timer = 0.0
			_blink_visible = not _blink_visible
		warning_label.visible = _blink_visible

		# SHAKE FIX: We shake around (0,0) because the Anchor handles the centering.
		_shake_timer += delta
		if _shake_timer >= 0.08:
			_shake_timer = 0.0
			main_container.position = Vector2(randf_range(-3, 3), randf_range(-3, 3))

	elif _time_remaining <= WARN_THRESHOLD:
		var warn_color = Color(0.85, 0.75, 0.2, 0.9)
		progress_bar.self_modulate = warn_color
		time_label.add_theme_color_override("font_color", warn_color)
		header_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.2, 0.7))

		warning_label.text = "⚠ SIGNAL DEGRADING"
		warning_label.visible = true
		# Return to true center
		main_container.position = Vector2.ZERO

	else:
		# Healthy styling
		progress_bar.self_modulate = Color(0.3, 0.75, 0.3, 0.9)
		time_label.add_theme_color_override("font_color", Color(0.5, 0.85, 0.5, 0.85))
		header_label.add_theme_color_override("font_color", Color(0.4, 0.65, 0.4, 0.6))
		warning_label.visible = false
		# Return to true center
		main_container.position = Vector2.ZERO

func _on_timer_expired() -> void:
	_running = false
	_expired = true
	hide()
	GameManager.trigger_game_over("signal_lost")
