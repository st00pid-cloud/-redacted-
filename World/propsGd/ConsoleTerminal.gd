extends StaticBody3D

@export var dialogue_lines: PackedStringArray = [
	"The terminal is still active. Running a diagnostic...",
	"These aren't standard log entries.",
	"The buffer is filling with symbols you don't recognize.",
	"The screen flickers. For a moment, it looks like the symbols are moving.",
]
var has_been_used: bool = false

func interact() -> void:
	if has_been_used:
		return
	has_been_used = true
	DialogueManager.show_dialogue(Array(dialogue_lines))
	await DialogueManager.dialogue_finished
	# Slice ends here — you'll add the blackout tomorrow
