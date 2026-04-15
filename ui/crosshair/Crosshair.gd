extends CanvasLayer

@onready var center_dot: ColorRect = $Control/CenterDot
@onready var interact_label: Label = $Control/InteractLabel

var _player: CharacterBody3D = null
var _ray: RayCast3D = null

func _ready() -> void:
	# Find player ray after scene loads
	await get_tree().process_frame
	_find_player_ray()

func _find_player_ray() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]
	# Fallback: search by node path convention
	if not _player:
		_player = get_node_or_null("/root/Level_01/Player")
	if _player:
		_ray = _player.get_node_or_null("HeadPivot/Camera3D/RayCast3D")

func _process(_delta: float) -> void:
	if not _ray:
		_find_player_ray()
		return

	if _ray.is_colliding():
		var collider = _ray.get_collider()
		if collider and collider.is_in_group("interactable"):
			interact_label.text = "[E] Interact"
			center_dot.color = Color(0.9, 1.0, 0.9, 0.9)
			return

	interact_label.text = ""
	center_dot.color = Color(0.5, 0.9, 0.5, 0.5)
