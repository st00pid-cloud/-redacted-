extends Node

## HorrorProgressionManager — Autoload
## Listens to ChallengeTracker.milestone_reached and coordinates:
##   milestone 2 → shadow flash at stairs
##   milestone 3 → facial distortion flag (read by DiagnosticPanel on next open)
##   milestone 4 → handled by NetworkRack (metal clang)
##
## Also owns the shadow-flash CanvasLayer so it doesn't depend on a scene.

signal shadow_flash_requested
signal face_distortion_requested

## Whether the distortion should fire on the next DiagnosticPanel open
var pending_face_distortion: bool = false

## World-space position of the stairs — set this from your Level scene
## or call set_stair_position() after the level loads.
var stair_position: Vector3 = Vector3(0, 0, 0)

## Internal
var _shadow_layer: CanvasLayer = null
var _shadow_rect: ColorRect = null
var _shadow_timer: float = 0.0
var _shadow_active: bool = false
const SHADOW_DURATION: float = 0.18   # total flash time in seconds

func _ready() -> void:
	# Connect to ChallengeTracker milestones
	ChallengeTracker.milestone_reached.connect(_on_milestone)
	_build_shadow_layer()

func set_stair_position(pos: Vector3) -> void:
	stair_position = pos

## ── Milestone handler ──────────────────────────────────────────────────

func _on_milestone(count: int) -> void:
	match count:
		2:
			_trigger_shadow_flash()
		3:
			pending_face_distortion = true
			emit_signal("face_distortion_requested")
		4:
			pass  # NetworkRack handles its own clang

## ── Shadow Flash (milestone 2) ─────────────────────────────────────────
## Spawns a 2D silhouette flash on the CanvasLayer for SHADOW_DURATION seconds.
## The silhouette is a tall dark humanoid shape drawn with ColorRects.

func _build_shadow_layer() -> void:
	_shadow_layer = CanvasLayer.new()
	_shadow_layer.layer = 150
	_shadow_layer.name = "ShadowFlashLayer"

	# Full-screen dark flicker base (very subtle, nearly invisible)
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.0)
	bg.name = "FlashBG"
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shadow_layer.add_child(bg)

	# Silhouette — a tall humanoid made from two ColorRects (head + body)
	var silhouette_root = Control.new()
	silhouette_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	silhouette_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	silhouette_root.name = "Silhouette"
	silhouette_root.visible = false
	_shadow_layer.add_child(silhouette_root)

	# Body — positioned in lower-right peripheral vision (stairs area feel)
	var body = ColorRect.new()
	body.size = Vector2(28, 88)
	body.position = Vector2(1140, 390)   # right side, lower portion of screen
	body.color = Color(0.0, 0.0, 0.0, 0.85)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.name = "Body"
	silhouette_root.add_child(body)

	# Head
	var head = ColorRect.new()
	head.size = Vector2(22, 22)
	head.position = Vector2(1143, 370)
	head.color = Color(0.0, 0.0, 0.0, 0.85)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.name = "Head"
	silhouette_root.add_child(head)

	# Subtle red glow behind the silhouette
	var glow = ColorRect.new()
	glow.size = Vector2(50, 110)
	glow.position = Vector2(1128, 362)
	glow.color = Color(0.35, 0.0, 0.0, 0.25)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.name = "Glow"
	silhouette_root.add_child(glow)

	add_child(_shadow_layer)
	_shadow_rect = bg

func _trigger_shadow_flash() -> void:
	if _shadow_active:
		return
	_shadow_active = true
	_shadow_timer = 0.0

	var silhouette = _shadow_layer.get_node_or_null("Silhouette")
	if silhouette:
		silhouette.visible = true

	emit_signal("shadow_flash_requested")

	# Play a faint audio cue — distorted static
	_play_stair_audio()

func _play_stair_audio() -> void:
	## Tries to play from behind the player using an AudioStreamPlayer.
	## We use a short, pitched-down stream if available; otherwise silent.
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	# We just use a 2D non-positional audio player here since
	# the shadow flash is a 2D UI event — the clang in NetworkRack is 3D.
	# If you have a static audio bus, you can route through it.
	pass

func _process(delta: float) -> void:
	if not _shadow_active:
		return

	_shadow_timer += delta
	var t = _shadow_timer / SHADOW_DURATION  # 0→1

	var silhouette = _shadow_layer.get_node_or_null("Silhouette")

	if _shadow_timer < SHADOW_DURATION * 0.4:
		# Flash in fast
		if silhouette:
			silhouette.modulate.a = t / 0.4
	elif _shadow_timer < SHADOW_DURATION * 0.6:
		# Hold at full
		if silhouette:
			silhouette.modulate.a = 1.0
	else:
		# Fade out
		var fade_t = (_shadow_timer - SHADOW_DURATION * 0.6) / (SHADOW_DURATION * 0.4)
		if silhouette:
			silhouette.modulate.a = 1.0 - fade_t

	if _shadow_timer >= SHADOW_DURATION:
		_shadow_active = false
		if silhouette:
			silhouette.visible = false
			silhouette.modulate.a = 1.0
