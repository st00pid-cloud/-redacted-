extends Node
 
func load_level(level_path: String):
	get_tree().change_scene_to_file(level_path)
 
func trigger_game_over(reason: String) -> void:
	# Store reason so EndScreen can read it
	EndScreenData.reason = reason
	EndScreenData.is_game_over = true
	get_tree().change_scene_to_file("res://ui/EndScreen.tscn")
 
func trigger_ending(reason: String) -> void:
	EndScreenData.reason = reason
	EndScreenData.is_game_over = false
	get_tree().change_scene_to_file("res://ui/EndScreen.tscn")
