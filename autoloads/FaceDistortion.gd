extends CanvasLayer

## FaceDistortion.gd — Autoload
## Triggered when HorrorProgressionManager.face_distortion_requested fires.
## Flashes a procedurally-drawn "corrupted face" for exactly 1-2 frames,
## then vanishes. No image asset required — drawn with primitives.
##
## Register as autoload: FaceDistortion  res://autoloads/FaceDistortion.gd

var _panel: Control = null
var _active: bool = false
var _frame_count: int = 0
const HOLD_FRAMES: int = 2   # exactly how many frames to show it

func _ready() -> void:
	layer = 190   # above DiagnosticPanel (100) and below SceneTransition (200)
	name = "FaceDistortionLayer"
	_build_panel()
	hide()

	# Connect to the horror manager
	HorrorProgressionManager.face_distortion_requested.connect(_on_distortion_requested)

func _build_panel() -> void:
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	# Dark background flash
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.92)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(bg)

	# ── Procedural face — built from ColorRects ──────────────────────────
	# Centered at roughly 640, 360 (1280×720 assumed; anchors keep it relative)
	var face_root = Control.new()
	face_root.set_anchors_preset(Control.PRESET_CENTER)
	face_root.offset_left   = -90.0
	face_root.offset_top    = -120.0
	face_root.offset_right  = 90.0
	face_root.offset_bottom = 120.0
	face_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(face_root)

	# Oval face shape (approximated with a wide rect + corner rects removed via layering)
	var face_bg = ColorRect.new()
	face_bg.size = Vector2(160, 220)
	face_bg.position = Vector2(-80, -110)
	face_bg.color = Color(0.08, 0.04, 0.04, 1.0)
	face_root.add_child(face_bg)

	# Left eye socket — hollow dark rect
	var eye_l = ColorRect.new()
	eye_l.size = Vector2(32, 18)
	eye_l.position = Vector2(-52, -30)
	eye_l.color = Color(0.0, 0.0, 0.0, 1.0)
	face_root.add_child(eye_l)

	# Left eye white (red-tinted sclera)
	var eye_l_inner = ColorRect.new()
	eye_l_inner.size = Vector2(20, 10)
	eye_l_inner.position = Vector2(-46, -25)
	eye_l_inner.color = Color(0.55, 0.08, 0.08, 1.0)
	face_root.add_child(eye_l_inner)

	# Right eye socket
	var eye_r = ColorRect.new()
	eye_r.size = Vector2(32, 18)
	eye_r.position = Vector2(20, -30)
	eye_r.color = Color(0.0, 0.0, 0.0, 1.0)
	face_root.add_child(eye_r)

	# Right eye white — hollow / missing (horror effect)
	var eye_r_inner = ColorRect.new()
	eye_r_inner.size = Vector2(20, 10)
	eye_r_inner.position = Vector2(26, -25)
	eye_r_inner.color = Color(0.0, 0.0, 0.0, 1.0)
	face_root.add_child(eye_r_inner)

	# Mouth — wide, wrong
	var mouth = ColorRect.new()
	mouth.size = Vector2(90, 8)
	mouth.position = Vector2(-45, 40)
	mouth.color = Color(0.0, 0.0, 0.0, 1.0)
	face_root.add_child(mouth)

	# Teeth suggestion — 3 white slivers
	for i in range(3):
		var tooth = ColorRect.new()
		tooth.size = Vector2(18, 12)
		tooth.position = Vector2(-38 + i * 26, 42)
		tooth.color = Color(0.82, 0.78, 0.74, 1.0)
		face_root.add_child(tooth)

	# Glitch horizontal scan line across the face
	var glitch_line = ColorRect.new()
	glitch_line.size = Vector2(200, 3)
	glitch_line.position = Vector2(-100, 10)
	glitch_line.color = Color(0.9, 0.1, 0.1, 0.7)
	face_root.add_child(glitch_line)

	# Second offset glitch line
	var glitch_line2 = ColorRect.new()
	glitch_line2.size = Vector2(140, 2)
	glitch_line2.position = Vector2(-40, -55)
	glitch_line2.color = Color(0.2, 0.9, 0.2, 0.4)
	face_root.add_child(glitch_line2)

	# Static noise bars (simulate digital corruption)
	for i in range(5):
		var noise_bar = ColorRect.new()
		noise_bar.size = Vector2(randi_range(30, 140), 4)
		noise_bar.position = Vector2(randi_range(-80, 20), randi_range(-100, 90))
		noise_bar.color = Color(randf_range(0.5, 1.0), 0.0, 0.0, randf_range(0.3, 0.6))
		face_root.add_child(noise_bar)

	# Label underneath — almost illegible
	var label = Label.new()
	label.text = "IT KNOWS YOUR NAME"
	label.position = Vector2(-130, 130)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.6, 0.1, 0.1, 0.8))
	_panel.add_child(label)

func _on_distortion_requested() -> void:
	if _active:
		return
	_active = true
	_frame_count = 0
	show()

func _process(_delta: float) -> void:
	if not _active:
		return
	_frame_count += 1
	if _frame_count >= HOLD_FRAMES:
		_active = false
		hide()
		# Consume the pending flag
		HorrorProgressionManager.pending_face_distortion = false
