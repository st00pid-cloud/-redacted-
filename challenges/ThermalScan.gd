extends CanvasLayer

signal challenge_completed(success: bool)

@onready var _root_control: Control = $RootControl
@onready var _header: Label = $RootControl/HeaderLabel
@onready var _feedback: Label = $RootControl/FeedbackLabel
@onready var _grid_container: Control = $RootControl/GridContainer
@onready var _player_icon: ColorRect = $RootControl/GridContainer/PlayerIcon
@onready var _silhouette_node: ColorRect = $RootControl/GridContainer/SilhouetteRect

var _phase: int = 0
var _leaks_patched: int = 0
var _total_leaks: int = 5
var _silhouette_hovered: bool = false
var _silhouette_visible: bool = true

const GRID_SIZE = Vector2(480, 360)
const GRID_OFFSET = Vector2(180, 110)
const CELL_SIZE = 24

const LEAK_POOL = [
	Vector2(3, 4),  Vector2(12, 8), Vector2(7, 2),  Vector2(16, 11),
	Vector2(10, 6), Vector2(2, 9),  Vector2(14, 3),  Vector2(5, 12),
	Vector2(18, 7), Vector2(8, 14), Vector2(1, 5),   Vector2(15, 10),
]
var _leak_positions: Array = []
var _leak_nodes: Array = []

var _silhouette_pos: Vector2 = Vector2(9, 10)
var _player_pos: Vector2 = Vector2(9, 12)

var _silhouette_drift_timer: float = 0.0
var _drift_interval: float = 3.0

func _ready():
	add_to_group("challenge_thermal")
	hide()
	_silhouette_node.mouse_entered.connect(_on_silhouette_hover)

func open_challenge() -> void:
	_phase = 0
	_leaks_patched = 0
	_silhouette_hovered = false
	_silhouette_visible = true
	_silhouette_drift_timer = 0.0

	_drift_interval = 3.0 / ChallengeTracker.get_difficulty_multiplier()

	var pool = LEAK_POOL.duplicate()
	pool.shuffle()
	_leak_positions = pool.slice(0, 5)

	_reset_ui()
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _reset_ui() -> void:
	# Clean up old leaks
	for leak in _leak_nodes:
		if is_instance_valid(leak):
			leak.queue_free()
	_leak_nodes.clear()

	_feedback.text = "Leaks patched: 0 / %d" % _total_leaks
	_leaks_patched = 0

	_silhouette_visible = true
	_silhouette_hovered = false
	_silhouette_node.visible = true
	_silhouette_node.modulate.a = 1.0
	_silhouette_node.position = _silhouette_pos * CELL_SIZE
	_silhouette_node.mouse_filter = Control.MOUSE_FILTER_STOP

	# Recreate leaks at randomized positions
	for i in range(_leak_positions.size()):
		var leak = ColorRect.new()
		leak.position = _leak_positions[i] * CELL_SIZE
		leak.size = Vector2(CELL_SIZE * 2, CELL_SIZE * 2)
		leak.color = Color(0.9, 0.5, 0.1, 0.6)
		leak.mouse_filter = Control.MOUSE_FILTER_STOP
		_grid_container.add_child(leak)
		_leak_nodes.append(leak)
		leak.gui_input.connect(_on_leak_clicked.bind(i))

func _on_leak_clicked(event: InputEvent, index: int) -> void:
	if _phase != 0:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if index < _leak_nodes.size() and is_instance_valid(_leak_nodes[index]):
			_leak_nodes[index].color = Color(0.1, 0.3, 0.1, 0.3)
			_leak_nodes[index].mouse_filter = Control.MOUSE_FILTER_IGNORE
			_leaks_patched += 1
			_feedback.text = "Leaks patched: %d / %d" % [_leaks_patched, _total_leaks]
			if _leaks_patched >= _total_leaks:
				_phase = 1
				await get_tree().create_timer(0.5).timeout
				_show_verification()

func _on_silhouette_hover() -> void:
	if _phase != 0 or not _silhouette_visible:
		return
	_silhouette_hovered = true
	_silhouette_visible = false
	if _silhouette_node and is_instance_valid(_silhouette_node):
		var tween = create_tween()
		tween.tween_property(_silhouette_node, "modulate:a", 0.0, 0.2)
		tween.tween_callback(func():
			if not is_instance_valid(_silhouette_node):
				return
			_silhouette_node.position += Vector2(-CELL_SIZE * 4, -CELL_SIZE * 2)
			_silhouette_node.modulate.a = 0.2
		)

func _process(delta: float) -> void:
	if not visible or _phase != 0:
		return

	if _silhouette_visible and is_instance_valid(_silhouette_node):
		_silhouette_drift_timer += delta
		if _silhouette_drift_timer >= _drift_interval:
			_silhouette_drift_timer = 0.0
			var dir = (_player_pos - _silhouette_pos)
			if dir.length() > 1.0:
				dir = dir.normalized()
				_silhouette_pos += dir
				_silhouette_pos.x = clamp(_silhouette_pos.x, 0, 19)
				_silhouette_pos.y = clamp(_silhouette_pos.y, 0, 14)
				_silhouette_node.position = _silhouette_pos * CELL_SIZE

func _show_verification() -> void:
	_header.text = "VERIFICATION:"

	if _silhouette_hovered:
		_feedback.text = "A heat signature vanished before you could patch it."
	else:
		_feedback.text = "Does the room feel warmer than it should for just one person?"

	_feedback.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))

	var hbox = HBoxContainer.new()
	hbox.position = Vector2(300, 500)
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
	if _phase >= 2:
		return
	_phase = 2

	var success = answered_yes

	if answered_yes:
		if _silhouette_hovered:
			_feedback.text = "You saw it move."
		else:
			_feedback.text = "You’re right, that wasn't a glitch in the sensor. It was real."
	else:
		if _silhouette_hovered:
			_feedback.text = "Confirmed. Thermal spike logged.\nAnd still said nothing was there."
		else:
			_feedback.text = "Temperature data contradicts your answer.\nSomething warm is standing directly behind you."

	await get_tree().create_timer(2.0).timeout
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	emit_signal("challenge_completed", success)
