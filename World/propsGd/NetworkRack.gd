extends StaticBody3D

## NetworkRack.gd
## The final interactive prop. After all 4 challenges are complete,
## plays a 3D metal clang sound from BEHIND the player before
## opening the DiagnosticPanel.
##
## Attach to the StaticBody3D inside NetworkRack.tscn.
## The scene must have:
##   - An AudioStreamPlayer3D named "ClangSource" (or it will be created here)
##   - The DiagnosticPanel autoload/CanvasLayer in the scene tree

@onready var _diagnostic_panel = _find_diagnostic_panel()

var _interaction_stage: int = 0   # 0=idle, 1=clang_playing, 2=panel_open, 3=done

# How far behind the player to place the clang source
const CLANG_BEHIND_DIST: float = 4.0
# Delay between clang and dialogue opening (seconds)
const CLANG_DELAY: float = 1.6

func _ready() -> void:
	add_to_group("interactable")

	# Wire up the DiagnosticPanel completion signal
	if _diagnostic_panel:
		if not _diagnostic_panel.diagnostic_completed.is_connected(_on_diagnostic_done):
			_diagnostic_panel.diagnostic_completed.connect(_on_diagnostic_done)

func interact() -> void:
	if _interaction_stage == 3:
		# Already done — show brief system message
		var lines: Array[String] = ["[SYSTEM]: Rack 7 diagnostic session closed."]
		DialogueManager.show_dialogue(lines)
		return

	if _interaction_stage != 0:
		return   # mid-sequence, ignore

	if not ChallengeTracker.all_done():
		# Not ready — guide the player
		var remaining = ChallengeTracker.required_ids.size() - ChallengeTracker.get_completed_count()
		var lines: Array[String] = [
			"[SYSTEM]: Rack 7 — Main diagnostic console.",
			"[SYSTEM]: %d subsystem terminal(s) must be cleared before running the main diagnostic." % remaining,
		]
		DialogueManager.show_dialogue(lines)
		return

	# ── All 4 done — begin the horror pre-sequence ──
	_interaction_stage = 1
	ChallengeTracker.freeze_player()
	_play_clang_behind_player()

func _play_clang_behind_player() -> void:
	# Find the player node
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		_after_clang()
		return

	var player = players[0]

	# Compute a position directly behind the player in world space
	var player_forward = -player.global_transform.basis.z.normalized()
	var behind_pos = player.global_position - player_forward * CLANG_BEHIND_DIST
	behind_pos.y = player.global_position.y + 0.5  # roughly at ear height

	# Create a temporary AudioStreamPlayer3D at that position
	var clang_source = AudioStreamPlayer3D.new()
	clang_source.position = behind_pos
	clang_source.unit_size = 5.0
	clang_source.max_db = 6.0
	clang_source.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE

	# Try to load the clang audio; fall back to silence if not present
	var stream = _load_clang_stream()
	if stream:
		clang_source.stream = stream
	else:
		push_warning("NetworkRack: No clang audio stream found at res://audio/metal_clang.wav (or .ogg). Add one!")

	get_tree().root.add_child(clang_source)

	if stream:
		clang_source.play()

	# Wait for the clang to hit, then continue
	await get_tree().create_timer(CLANG_DELAY).timeout

	# Clean up the temporary audio node
	clang_source.queue_free()

	_after_clang()

func _load_clang_stream() -> AudioStream:
	# Try common paths — you only need ONE of these files in your project
	var paths = [
		"res://audio/metal_clang.wav",
		"res://audio/metal_clang.ogg",
		"res://audio/clang.wav",
		"res://audio/clang.ogg",
		"res://audio/506220__nucleartape__gross-glitch.wav",  # fallback to existing glitch sfx
	]
	for path in paths:
		if ResourceLoader.exists(path):
			return load(path)
	return null

func _after_clang() -> void:
	_interaction_stage = 2

	# Show pre-diagnostic dialogue
	var lines: Array[String] = [
		"[SYSTEM]: Rack 7 — Main diagnostic interface.",
		"[SYSTEM]: All subsystem feeds confirmed.",
		"[SYSTEM]: Initiating final containment sequence...",
	]
	DialogueManager.show_dialogue(lines)
	await DialogueManager.dialogue_finished

	# Open the diagnostic panel
	if _diagnostic_panel:
		_diagnostic_panel.open_diagnostic()
	else:
		push_warning("NetworkRack: Could not find DiagnosticPanel in the scene tree.")
		ChallengeTracker.unfreeze_player()
		_interaction_stage = 0

func _on_diagnostic_done(success: bool) -> void:
	_interaction_stage = 3
	ChallengeTracker.unfreeze_player()

	if success:
		GameManager.trigger_ending("engineer_resisted")
	else:
		GameManager.trigger_ending("integration_complete")

# ── Helpers ──────────────────────────────────────────────────────────────

func _find_diagnostic_panel() -> Node:
	# Search common locations for DiagnosticPanel
	var panel = get_tree().get_first_node_in_group("diagnostic_panel")
	if panel:
		return panel
	# Fallback: check root children
	for child in get_tree().root.get_children():
		if child.name == "DiagnosticPanel" or child.is_in_group("diagnostic_panel"):
			return child
		for sub in child.get_children():
			if sub.name == "DiagnosticPanel" or sub.is_in_group("diagnostic_panel"):
				return sub
	return null
