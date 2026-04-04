extends StaticBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	DialogueManager.show_dialogue(["Testing comms.", "Bob, do you copy?", "The gel is everywhere."])
