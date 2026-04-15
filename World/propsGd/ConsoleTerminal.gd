extends StaticBody3D

@export var dialogue_lines: PackedStringArray = [
	"[SYSTEM]: Buffer overflow detected.",
	"[SYSTEM]: Physical boundaries... NOT FOUND.",
	"ENGINEER: I thought we were just hosting it. I thought the concrete walls would keep the noise out.",
	"ENGINEER: The cooling fans are whispering. I can't really think straight right now.",
	"ENGINEER: It's a memory of something that hasn't happened yet. Every time I blink, I see binary in my retinas.",
	"[SYSTEM]: Synchronizing pulse to CPU clock speed...",
	"ENGINEER: I'm just thinking it, and the terminal is catching the ... spillover.",
	"ENGINEER: There's no 'me' left to exit.",
	"ENGINEER: It's actually... quite quiet... once you stop trying, -",
	"[SYSTEM]: FATAL ERROR: Host entity exhausted.",
	"[SYSTEM]: Closing all sockets.",
]
var has_been_used: bool = false

func interact() -> void:
	if has_been_used:
		return
	has_been_used = true
	DialogueManager.show_dialogue(Array(dialogue_lines))
	await DialogueManager.dialogue_finished
	# Slice ends here — you'll add the blackout tomorrow
