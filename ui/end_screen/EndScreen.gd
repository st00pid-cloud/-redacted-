extends Node2D

@onready var message_label = $CanvasLayer/Control/VBoxContainer/MessageLabel
@onready var sub_label = $CanvasLayer/Control/VBoxContainer/SubLabel
@onready var restart_button = $CanvasLayer/Control/VBoxContainer/RestartButton

const ENDINGS = {
	"engineer_resisted": {
		"message": "R. Vasquez stopped trying.\nThe silence was hers.",
		"sub": "The data is still there. Waiting.\n\n— CONNECTION TERMINATED —",
	},
	"integration_complete": {
		"message": "[SYSTEM]: Integration complete.\nWelcome, R. Vasquez.",
		"sub": "You missed every chance to resist.\nShe is the buffer now.",
	},
	"integration_accelerated": {
		"message": "Integration accelerated.\nYou fed it attention.",
		"sub": "Some anomalies grow stronger when observed.\n\n— HOST ENTITY LOST —",
	},
}

func _ready():
	# Ensure mouse is visible and game is unpaused
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Hide everything from horror overlays that might have carried over
	_cleanup_overlays()

	var reason = EndScreenData.reason

	var ending_data = ENDINGS.get(reason, {
		"message": "— SIGNAL LOST —",
		"sub": "",
	})

	message_label.text = ""
	sub_label.text = ""
	restart_button.hide()

	# Sequence the text reveals
	await get_tree().create_timer(0.8).timeout
	_type_in(message_label, ending_data["message"])
	await get_tree().create_timer(2.5).timeout
	_type_in(sub_label, ending_data["sub"])
	await get_tree().create_timer(2.0).timeout
	restart_button.show()

	restart_button.pressed.connect(_on_restart)

func _type_in(label: Label, text: String) -> void:
	label.text = text
	label.visible_ratio = 0.0
	var tween = create_tween()
	tween.tween_property(label, "visible_ratio", 1.0, 1.8)

func _on_restart() -> void:
	EndScreenData.reason = ""
	EndScreenData.is_game_over = false
	get_tree().change_scene_to_file("res://World/Level_01.tscn")

func _cleanup_overlays() -> void:
	# Remove any lingering horror overlays from the previous scene
	for node in get_tree().get_nodes_in_group("horror_overlay"):
		node.visible = false
	for node in get_tree().get_nodes_in_group("resist_overlay"):
		node.visible = false
