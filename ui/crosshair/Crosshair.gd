extends CanvasLayer

@onready var center_dot: ColorRect = $Control/CenterDot
@onready var interact_label: Label = $Control/InteractLabel

var _player: CharacterBody3D = null
var _ray: RayCast3D = null
var _dialogue_active: bool = false

func _ready() -> void:
	await get_tree().process_frame
	_find_player_ray()
	if DialogueManager:
		DialogueManager.dialogue_started.connect(_on_dialogue_started)
		DialogueManager.dialogue_finished.connect(_on_dialogue_finished)

func _find_player_ray() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]
	if not _player:
		_player = get_node_or_null("/root/Level_01/Player")
	if _player:
		_ray = _player.get_node_or_null("HeadPivot/Camera3D/RayCast3D")

func _on_dialogue_started() -> void:
	_dialogue_active = true
	interact_label.text = ""

func _on_dialogue_finished() -> void:
	_dialogue_active = false

func _process(_delta: float) -> void:
	if not _ray:
		_find_player_ray()
		return

	# Never show prompt during dialogue or while a challenge is running
	if _dialogue_active or ChallengeTracker.is_player_frozen():
		interact_label.text = ""
		center_dot.color = Color(0.5, 0.9, 0.5, 0.3)
		return

	if _ray.is_colliding():
		var collider = _ray.get_collider()
		if collider and collider.is_in_group("interactable"):
			if _is_interactable_exhausted(collider):
				interact_label.text = ""
				center_dot.color = Color(0.5, 0.9, 0.5, 0.5)
				return
			interact_label.text = "[E] Interact"
			center_dot.color = Color(0.9, 1.0, 0.9, 0.9)
			return

	interact_label.text = ""
	center_dot.color = Color(0.5, 0.9, 0.5, 0.5)

func _is_interactable_exhausted(node: Node) -> bool:
	# Stage 1 = challenge actively running; stage 2 = completed — both suppress the prompt
	if "_interaction_stage" in node and node._interaction_stage >= 1:
		return true
	# LoginTerminal / MaintenanceLog pattern
	if "has_been_read" in node and node.has_been_read:
		return true
	return false
