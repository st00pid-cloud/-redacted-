extends StaticBody3D

var has_been_read: bool = false

const LOG_LINES = [
	"[MAINTENANCE LOG — Rack 7]",
	"Week 1: Intermittent packet loss on Port 7. Reseated module. Resolved.",
	"Week 2: Port 7 flapping again. Replaced cable. Seemed fine.",
	"Week 3: Port 7 reporting impossible throughput values. Flagged for review.",
	"Week 4: Engineers on night shift reporting... sounds from the rack.",
	"Week 5: Chen didn't come in. Rodriguez said he's fine, just tired.",
	"Week 6: Rodriguez didn't come in.",
	"NOTE: Do not assign solo night shifts to Rack 7 bay until further notice.",
	"NOTE (handwritten): it's not the cable.",
]

func interact() -> void:
	if has_been_read:
		return
	has_been_read = true
	var lines: Array[String] = []
	for line in LOG_LINES:
		lines.append(line)
	DialogueManager.show_dialogue(lines)
