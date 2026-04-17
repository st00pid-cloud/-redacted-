extends Area3D
 
@export_multiline var dialogue: String = ""
 
func _on_body_entered(body):
	if body is CharacterBody3D:
		var dialogue_ui = get_tree().root.find_child("DialogueUI")
		dialogue_ui.show_dialogue(dialogue)
