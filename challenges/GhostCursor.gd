extends CanvasLayer

## GhostCursor — Input challenge
## Player drags a diagnostic icon to a drop zone.
## A ghost cursor moves independently toward dangerous buttons.
## If ghost cursor touches player's drag icon, they fail.

signal challenge_completed(success: bool)

var _root_control: Control
var _header: Label
var _feedback: Label
var _drag_icon: ColorRect
var _drop_zone: ColorRect
var _ghost_cursor: ColorRect
var _ghost_target_btn: Button
var _danger_btn_power: Button
var _phase: int = 0  # 0=dragging, 1=verification, 2=done

var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _ghost_pos: Vector2 = Vector2(100, 100)
var _ghost_speed: float = 45.0
var _ghost_target_pos: Vector2 = Vector2.ZERO
var _ghost_wander_timer: float = 0.0
var _task_success: bool = false
var _ghost_touched: bool = false
var _timer: float = 0.0
var _time_limit: float = 15.0

func _ready():
	add_to_group("challenge_ghost")
	hide()

func open_challenge() -> void:
	_phase = 0
	_is_dragging = false
	_ghost_touched = false
	_task_success = false
	_timer = 0.0
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
	bg.color = Color(0, 0, 0, 0.85)
	_root_control.add_child(bg)

	# Header
	_header = Label.new()
	_header.text = "GHOST CURSOR CALIBRATION — Peripheral Interface Test"
	_header.position = Vector2(40, 20)
	_header.add_theme_font_size_override("font_size", 16)
	_header.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	_root_control.add_child(_header)

	var instr = Label.new()
	instr.text = "Drag the DIAGNOSTIC TOOL to the DROP ZONE. Do NOT let the ghost cursor touch it."
	instr.position = Vector2(40, 48)
	instr.add_theme_font_size_override("font_size", 12)
	instr.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5, 0.7))
	_root_control.add_child(instr)

	# Timer label
	_feedback = Label.new()
	_feedback.text = "Time: %.1f" % _time_limit
	_feedback.position = Vector2(40, 72)
	_feedback.add_theme_font_size_override("font_size", 13)
	_feedback.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	_root_control.add_child(_feedback)

	# Drop zone (right side)
	_drop_zone = ColorRect.new()
	_drop_zone.position = Vector2(800, 300)
	_drop_zone.size = Vector2(100, 100)
	_drop_zone.color = Color(0.2, 0.5, 0.2, 0.5)
	_root_control.add_child(_drop_zone)

	var drop_label = Label.new()
	drop_label.text = "DROP\nZONE"
	drop_label.position = Vector2(15, 30)
	drop_label.add_theme_font_size_override("font_size", 14)
	drop_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5, 0.8))
	_drop_zone.add_child(drop_label)

	# Danger button (the ghost wants to press this)
	_danger_btn_power = Button.new()
	_danger_btn_power.text = "[ POWER OFF ]"
	_danger_btn_power.position = Vector2(750, 500)
	_danger_btn_power.size = Vector2(140, 40)
	_danger_btn_power.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	_root_control.add_child(_danger_btn_power)
	_ghost_target_pos = Vector2(820, 520)

	# Drag icon (left side)
	_drag_icon = ColorRect.new()
	_drag_icon.position = Vector2(150, 350)
	_drag_icon.size = Vector2(60, 60)
	_drag_icon.color = Color(0.3, 0.8, 0.3, 0.9)
	_root_control.add_child(_drag_icon)

	var icon_label = Label.new()
	icon_label.text = "DIAG\nTOOL"
	icon_label.position = Vector2(5, 12)
	icon_label.add_theme_font_size_override("font_size", 11)
	icon_label.add_theme_color_override("font_color", Color(0, 0, 0))
	_drag_icon.add_child(icon_label)

	# Ghost cursor
	_ghost_cursor = ColorRect.new()
	_ghost_pos = Vector2(500, 200)
	_ghost_cursor.position = _ghost_pos
	_ghost_cursor.size = Vector2(20, 20)
	_ghost_cursor.color = Color(0.8, 0.2, 0.2, 0.35)
	_root_control.add_child(_ghost_cursor)

	var ghost_label = Label.new()
	ghost_label.text = "▶"
	ghost_label.position = Vector2(2, -2)
	ghost_label.add_theme_font_size_override("font_size", 14)
	ghost_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 0.5))
	_ghost_cursor.add_child(ghost_label)

func _input(event: InputEvent) -> void:
	if not visible or _phase != 0:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var mouse = event.position
				var icon_rect = Rect2(_drag_icon.global_position, _drag_icon.size)
				if icon_rect.has_point(mouse):
					_is_dragging = true
					_drag_offset = _drag_icon.global_position - mouse
			else:
				if _is_dragging:
					_is_dragging = false
					_check_drop()

	if event is InputEventMouseMotion and _is_dragging:
		_drag_icon.global_position = event.position + _drag_offset

func _check_drop() -> void:
	var icon_center = _drag_icon.global_position + _drag_icon.size * 0.5
	var zone_rect = Rect2(_drop_zone.global_position, _drop_zone.size)
	if zone_rect.has_point(icon_center):
		_task_success = true
		_phase = 1
		_show_verification()

func _process(delta: float) -> void:
	if not visible or _phase >= 2:
		return

	if _phase == 0:
		_timer += delta
		_feedback.text = "Time: %.1f" % max(0, _time_limit - _timer)

		if _timer >= _time_limit:
			_phase = 1
			_task_success = false
			_feedback.text = "TIME'S UP."
			_show_verification()
			return

		# Move ghost cursor toward its target
		_ghost_wander_timer += delta
		var wander = Vector2(sin(_ghost_wander_timer * 1.5) * 30, cos(_ghost_wander_timer * 0.8) * 20)
		var target = _ghost_target_pos + wander
		var dir = (target - _ghost_pos).normalized()
		_ghost_pos += dir * _ghost_speed * delta
		_ghost_cursor.position = _ghost_pos

		# Check if ghost touches drag icon
		if _is_dragging:
			var ghost_rect = Rect2(_ghost_pos, _ghost_cursor.size)
			var icon_rect = Rect2(_drag_icon.global_position, _drag_icon.size)
			if ghost_rect.intersects(icon_rect):
				_ghost_touched = true
				_drag_icon.color = Color(0.8, 0.2, 0.2, 0.7)
				_feedback.text = "INTERFERENCE DETECTED — Ghost cursor contacted diagnostic tool."
				_phase = 1
				_task_success = false
				await get_tree().create_timer(1.5).timeout
				_show_verification()

func _show_verification() -> void:
	_drag_icon.visible = false
	_ghost_cursor.visible = false
	_drop_zone.visible = false
	_danger_btn_power.visible = false

	_header.text = "VERIFICATION:"
	_feedback.text = "Did you feel resistance in the peripheral interface?"
	_feedback.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))

	await get_tree().create_timer(0.5).timeout

	var hbox = HBoxContainer.new()
	hbox.position = Vector2(300, 400)
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

	# YES is correct — there WAS resistance (the ghost cursor)
	var success = _task_success and answered_yes
	if answered_yes:
		_feedback.text = "Peripheral anomaly acknowledged.\nThe interface has a second operator."
	else:
		_feedback.text = "Denial logged. The cursor was not yours.\nIt never was."

	await get_tree().create_timer(2.0).timeout
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	emit_signal("challenge_completed", success)
