extends StaticBody3D

var has_been_read: bool = false

const LOGIN_LINES = [
	"[TERMINAL LOGIN — Session Active]",
	"User: R.VASQUEZ",
	"Clearance: Level 2 — Infrastructure",
	"Last login: 03:14 AM — Today",
	"Active session duration: 00:47:12",
	"...",
	"Note to self: finish this, go home, sleep.",
	"Note to self: stop hearing things.",
]

func interact() -> void:
	if has_been_read:
		return
	has_been_read = true
	var lines: Array[String] = []
	for line in LOGIN_LINES:
		lines.append(line)
	DialogueManager.show_dialogue(lines)
