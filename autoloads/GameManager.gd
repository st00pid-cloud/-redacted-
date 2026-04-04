extends Node

func load_level(level_path: String):
	# For the slice, a simple scene change is sufficient
	get_tree().change_scene_to_file(level_path)
