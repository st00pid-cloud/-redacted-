extends Node
class_name Interactable

func interact() -> void:
	push_warning("Interactable.interact() not overridden on " + get_parent().name)
