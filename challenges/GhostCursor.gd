extends CanvasLayer

## GhostCursor.gd — All improvements integrated:
## - Ghost target position derived from viewport size (no hardcoded resolution)
## - Ghost accelerates when player is dragging (GHOST_SPEED_CHASE)
## - Drag icon flashes red when ghost is within 80px (proximity warning)
## - Noise-based wander with random direction changes (not fixed sin/cos)
## - Ghost cursor drawn as a polygon cursor shape (not a plain ColorRect)
## - Difficulty multiplier applied to ghost speed via ChallengeTracker

signal challenge_completed(success: bool)

var _root_control: Control
var _header: Label
var _feedback: Label
var _drag_icon: Control
var _drop_zone: ColorRect
var _ghost_cursor: Control
var _danger_btn_power: Button
var _phase: int = 0  # 0=dragging, 1=verification, 2=done

var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _ghost_pos: Vector2 = Vector2(100, 100)

# Speed constants — base scaled by difficulty multiplier at open
const GHOST_SPEED_BASE: float = 45.0
const GHOST_SPEED_CHASE: float = 90.0
var _ghost_speed_base: float = GHOST_SPEED_BASE
var _ghost_speed_chase: float = GHOST_SPEED_CHASE

var _ghost_target_pos: Vector2 = Vector2.ZERO
var _task_success: bool = false
var _ghost_touched: bool = false
var _timer: float = 0.0
var _time_limit: float = 15.0

# Noise-based wander state
var _wander_offset: Vector2 = Vector2.ZERO
var _wander_change_timer: float = 0.0

func _ready():
	add_to_group("challenge_ghost")
	hide()

func open_challenge() -> void:
	_phase = 0
	_is_dragging = false
	_ghost_touched = false
	_task_success = false
	_timer = 0.0
	_wander_offset = Vector2.ZERO
	_wander_change_timer = 0.0

	# Scale speed by how many challenges are already done
	var diff = ChallengeTracker.get_difficulty_multiplier()
	_ghost_speed_base = GHOST_SPEED_BASE * diff
	_ghost_speed_chase = GHOST_SPEED_CHASE * diff

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

	_feedback = Label.new()
	_feedback.text = "Time: %.1f" % _time_limit
	_feedback.position = Vector2(40, 72)
	_feedback.add_theme_font_size_override("font_size", 13)
	_feedback.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	_root_control.add_child(_feedback)

	# Use viewport size for all layout — no hardcoded resolution
	var vp = get_viewport().get_visible_rect().size

	_drop_zone = ColorRect.new()
	_drop_zone.position = Vector2(vp.x - 200, vp.y * 0.4)
	_drop_zone.size = Vector2(100, 100)
	_drop_zone.color = Color(0.2, 0.5, 0.2, 0.5)
	_root_control.add_child(_drop_zone)

	var drop_label = Label.new()
	drop_label.text = "DROP\nZONE"
	drop_label.position = Vector2(15, 30)
	drop_label.add_theme_font_size_override("font_size", 14)
	drop_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5, 0.8))
	_drop_zone.add_child(drop_label)

	# Danger button — position derived from viewport
	_danger_btn_power = Button.new()
	_danger_btn_power.text = "[ POWER OFF ]"
	_danger_btn_power.position = Vector2(vp.x - 230, vp.y - 140)
	_danger_btn_power.size = Vector2(140, 40)
	_danger_btn_power.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	_root_control.add_child(_danger_btn_power)

	# Ghost target derived from viewport — no hardcoded Vector2(820, 520)
	_ghost_target_pos = Vector2(vp.x - 160, vp.y - 120)

	# Drag icon
	_drag_icon = Control.new()
	_drag_icon.position = Vector2(150, vp.y * 0.45)
	_drag_icon.size = Vector2(60, 60)
	_root_control.add_child(_drag_icon)

	var drag_bg = ColorRect.new()
	drag_bg.size = Vector2(60, 60)
	drag_bg.color = Color(0.3, 0.8, 0.3, 0.9)
	_drag_icon.add_child(drag_bg)

	var icon_label = Label.new()
	icon_label.text = "DIAG\nTOOL"
	icon_label.position = Vector2(5, 12)
	icon_label.add_theme_font_size_override("font_size", 11)
	icon_label.add_theme_color_override("font_color", Color(0, 0, 0))
	_drag_icon.add_child(icon_label)

	# Ghost cursor — polygon cursor shape instead of plain ColorRect
	_ghost_cursor = Control.new()
	_ghost_pos = Vector2(vp.x * 0.5, vp.y * 0.3)
	_ghost_cursor.position = _ghost_pos
	_ghost_cursor.size = Vector2(24, 24)
	_root_control.add_child(_ghost_cursor)

	var cursor_poly = Polygon2D.new()
	cursor_poly.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(0, 20), Vector2(5, 15),
		Vector2(8, 22), Vector2(10, 21), Vector2(7, 14), Vector2(14, 14)
	])
	cursor_poly.color = Color(0.9, 0.15, 0.15, 0.6)
	_ghost_cursor.add_child(cursor_poly)

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

		# Noise-based wander — direction changes randomly every 0.8–2.0 seconds
		_wander_change_timer -= delta
		if _wander_change_timer <= 0.0:
			_wander_change_timer = randf_range(0.8, 2.0)
			_wander_offset = Vector2(randf_range(-60, 60), randf_range(-60, 60))

		var target = _ghost_target_pos + _wander_offset
		var dir = (target - _ghost_pos).normalized()

		# Ghost chases faster when player is actively dragging
		var current_speed = _ghost_speed_chase if _is_dragging else _ghost_speed_base
		_ghost_pos += dir * current_speed * delta
		_ghost_cursor.position = _ghost_pos

		# Proximity warning — drag icon flashes red when ghost is within 80px
		if _is_dragging:
			var dist = _ghost_pos.distance_to(_drag_icon.global_position)
			if dist < 80.0:
				var flash = fmod(Time.get_ticks_msec() * 0.01, 1.0) > 0.5
				var drag_bg = _drag_icon.get_child(0) as ColorRect
				if drag_bg:
					drag_bg.color = Color(0.8, 0.2, 0.2, 0.9) if flash else Color(0.3, 0.8, 0.3, 0.9)

			# Check collision
			var ghost_rect = Rect2(_ghost_pos, _ghost_cursor.size)
			var icon_rect = Rect2(_drag_icon.global_position, _drag_icon.size)
			if ghost_rect.intersects(icon_rect):
				_ghost_touched = true
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

	var success = _task_success and answered_yes
	if answered_yes:
		_feedback.text = "Peripheral anomaly acknowledged.\nThe interface has a second operator."
	else:
		_feedback.text = "Denial logged. The cursor was not yours.\nIt never was."

	await get_tree().create_timer(2.0).timeout
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	emit_signal("challenge_completed", success)
