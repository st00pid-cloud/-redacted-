extends CanvasLayer

signal challenge_completed(success: bool)

var _root_control: Control
var _header: Label
var _feedback: Label
var _grid_container: Control
var _phase: int = 0
var _leaks_patched: int = 0
var _total_leaks: int = 5
var _silhouette_hovered: bool = false
var _silhouette_visible: bool = true
var _silhouette_node: ColorRect = null
var _player_icon: ColorRect = null

const GRID_SIZE = Vector2(480, 360)
const GRID_OFFSET = Vector2(180, 110)
const CELL_SIZE = 24

# Leak positions (grid coords)
var _leak_positions = [
	Vector2(3, 4), Vector2(12, 8), Vector2(7, 2), Vector2(16, 11), Vector2(10, 6),
]
# Silhouette position — right behind the player icon
var _silhouette_pos = Vector2(9, 10)
var _player_pos = Vector2(9, 12)
var _leak_nodes: Array = []

func _ready():
	add_to_group("challenge_thermal")
	hide()

func open_challenge() -> void:
	_phase = 0
	_leaks_patched = 0
	_silhouette_hovered = false
	_silhouette_visible = true
	_build_ui()
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	_leak_nodes.clear()

	_root_control = Control.new()
	_root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root_control)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.85)
	_root_control.add_child(bg)

	_header = Label.new()
	_header.text = "THERMAL SILHOUETTE SCAN — Click heat leaks to patch them"
	_header.position = Vector2(40, 20)
	_header.add_theme_font_size_override("font_size", 16)
	_header.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	_root_control.add_child(_header)

	_feedback = Label.new()
	_feedback.text = "Leaks patched: 0 / %d" % _total_leaks
	_feedback.position = Vector2(40, 50)
	_feedback.add_theme_font_size_override("font_size", 13)
	_feedback.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5, 0.8))
	_root_control.add_child(_feedback)

	# Grid background (dark with grid lines)
	_grid_container = Control.new()
	_grid_container.position = GRID_OFFSET
	_grid_container.size = GRID_SIZE
	_root_control.add_child(_grid_container)

	var grid_bg = ColorRect.new()
	grid_bg.position = Vector2.ZERO
	grid_bg.size = GRID_SIZE
	grid_bg.color = Color(0.05, 0.02, 0.1, 0.9)
	_grid_container.add_child(grid_bg)

	# Draw grid lines
	for x in range(0, int(GRID_SIZE.x), CELL_SIZE):
		var line = ColorRect.new()
		line.position = Vector2(x, 0)
		line.size = Vector2(1, GRID_SIZE.y)
		line.color = Color(0.1, 0.15, 0.1, 0.3)
		_grid_container.add_child(line)
	for y in range(0, int(GRID_SIZE.y), CELL_SIZE):
		var line = ColorRect.new()
		line.position = Vector2(0, y)
		line.size = Vector2(GRID_SIZE.x, 1)
		line.color = Color(0.1, 0.15, 0.1, 0.3)
		_grid_container.add_child(line)

	# Player icon (cyan dot)
	_player_icon = ColorRect.new()
	_player_icon.position = _player_pos * CELL_SIZE
	_player_icon.size = Vector2(CELL_SIZE, CELL_SIZE * 2)
	_player_icon.color = Color(0.2, 0.6, 0.8, 0.7)
	_grid_container.add_child(_player_icon)

	var p_label = Label.new()
	p_label.text = "YOU"
	p_label.position = Vector2(-4, -14)
	p_label.add_theme_font_size_override("font_size", 9)
	p_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 0.8))
	_player_icon.add_child(p_label)

	# Heat leaks (square blobs, warm colors)
	for i in range(_leak_positions.size()):
		var leak = ColorRect.new()
		leak.position = _leak_positions[i] * CELL_SIZE
		leak.size = Vector2(CELL_SIZE * 2, CELL_SIZE * 2)
		leak.color = Color(0.9, 0.5, 0.1, 0.6)
		leak.mouse_filter = Control.MOUSE_FILTER_STOP
		_grid_container.add_child(leak)
		_leak_nodes.append(leak)

		# Make clickable via input
		leak.gui_input.connect(_on_leak_clicked.bind(i))

	# Silhouette — humanoid shape (taller, reddish)
	_silhouette_node = ColorRect.new()
	_silhouette_node.position = _silhouette_pos * CELL_SIZE
	_silhouette_node.size = Vector2(CELL_SIZE, CELL_SIZE * 3)
	_silhouette_node.color = Color(0.8, 0.15, 0.1, 0.45)
	_silhouette_node.mouse_filter = Control.MOUSE_FILTER_STOP
	_grid_container.add_child(_silhouette_node)
	_silhouette_node.mouse_entered.connect(_on_silhouette_hover)

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
	# The shape "ducks away" — animate it sliding off
	if _silhouette_node and is_instance_valid(_silhouette_node):
		var tween = create_tween()
		tween.tween_property(_silhouette_node, "modulate:a", 0.0, 0.2)
		tween.tween_callback(func():
			if not is_instance_valid(_silhouette_node):
				return
				_silhouette_node.position += Vector2(-CELL_SIZE * 4, -CELL_SIZE * 2)
				_silhouette_node.modulate.a = 0.2
			)
func _show_verification() -> void:
	_header.text = "VERIFICATION:"
	if _silhouette_hovered:
		_feedback.text = "Anomalous heat signature detected and evaded scan.\nIs the ambient temperature consistent with a single occupant?"
	else:
		_feedback.text = "All leaks patched.\nIs the ambient temperature consistent with a single occupant?"
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

	# NO is correct — there's a second heat source
	var success = not answered_yes
	if not answered_yes:
		_feedback.text = "Correct. Thermal anomaly logged.\nSomething warm stood behind you."
	else:
		_feedback.text = "Temperature data contradicts your answer.\nThe second signature remains."

	await get_tree().create_timer(2.0).timeout
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	emit_signal("challenge_completed", success)
