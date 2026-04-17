extends CanvasLayer

## GhostCursor.gd — Scene-based version (CORRECTED PATHS)
## Script attached to GhostCursor (CanvasLayer) node

signal challenge_completed(success: bool)

@onready var _root_control: Control = $RootControl
@onready var _header: Label = $RootControl/HeaderLabel
@onready var _feedback: Label = $RootControl/FeedbackLabel
@onready var _drag_icon: ColorRect = $RootControl/DragIcon
@onready var _drop_zone: ColorRect = $RootControl/DropZone
@onready var _ghost_cursor: ColorRect = $RootControl/GhostCursor
@onready var _danger_btn_power: Button = $RootControl/DangerButton

var _phase: int = 0  # 0=dragging, 1=verification, 2=done

var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _ghost_pos: Vector2 = Vector2(100, 100)

const GHOST_SPEED_BASE: float = 45.0
const GHOST_SPEED_CHASE: float = 90.0
var _ghost_speed_base: float = GHOST_SPEED_BASE
var _ghost_speed_chase: float = GHOST_SPEED_CHASE

var _ghost_target_pos: Vector2 = Vector2.ZERO
var _task_success: bool = false
var _ghost_touched: bool = false
var _timer: float = 0.0
var _time_limit: float = 5.0

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

	var diff = ChallengeTracker.get_difficulty_multiplier()
	_ghost_speed_base = GHOST_SPEED_BASE * diff
	_ghost_speed_chase = GHOST_SPEED_CHASE * diff

	_header.text = "CONTROLLER RESET — Checking for Input Interference"
	_feedback.text = "Time: %.1f" % _time_limit
	_drag_icon.visible = true
	_ghost_cursor.visible = true
	_drop_zone.visible = true
	_danger_btn_power.visible = true
	
	var vp = get_viewport().get_visible_rect().size
	_ghost_target_pos = Vector2(vp.x - 160, vp.y - 120)
	_ghost_pos = Vector2(vp.x * 0.5, vp.y * 0.3)
	_ghost_cursor.position = _ghost_pos

	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

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

		_wander_change_timer -= delta
		if _wander_change_timer <= 0.0:
			_wander_change_timer = randf_range(0.8, 2.0)
			_wander_offset = Vector2(randf_range(-60, 60), randf_range(-60, 60))

		var target = _ghost_target_pos + _wander_offset
		var dir = (target - _ghost_pos).normalized()

		var current_speed = _ghost_speed_chase if _is_dragging else _ghost_speed_base
		_ghost_pos += dir * current_speed * delta
		_ghost_cursor.position = _ghost_pos

		if _is_dragging:
			var dist = _ghost_pos.distance_to(_drag_icon.global_position)
			if dist < 80.0:
				var flash = fmod(Time.get_ticks_msec() * 0.01, 1.0) > 0.5
				var drag_bg = _drag_icon.get_child(0) as ColorRect
				if drag_bg:
					drag_bg.color = Color(0.8, 0.2, 0.2, 0.9) if flash else Color(0.3, 0.8, 0.3, 0.9)

			var ghost_rect = Rect2(_ghost_pos, _ghost_cursor.size)
			var icon_rect = Rect2(_drag_icon.global_position, _drag_icon.size)
			if ghost_rect.intersects(icon_rect):
				_ghost_touched = true
				_feedback.text = "WARNING: External input detected. Something else is moving your cursor."
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
	_feedback.text = "Did the mouse feel like it was fighting you?"
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
		_feedback.text = "Presence confirmed.\n You are sharing this terminal with someone else."
	else:
		_feedback.text = "Lie detected. You aren't the one moving that cursor anymore."

	await get_tree().create_timer(2.0).timeout
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	emit_signal("challenge_completed", success)
