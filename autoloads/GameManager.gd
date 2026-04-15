extends Node
 
func load_level(level_path: String) -> void:
	await SceneTransition.fade_to(level_path)
 
func trigger_game_over(reason: String) -> void:
	EndScreenData.reason = reason
	EndScreenData.is_game_over = true
	await SceneTransition.fade_to("res://ui/EndScreen.tscn")
 
func trigger_ending(reason: String) -> void:
	EndScreenData.reason = reason
	EndScreenData.is_game_over = false
	await SceneTransition.fade_to("res://ui/EndScreen.tscn")
