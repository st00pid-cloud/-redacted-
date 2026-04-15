extends StaticBody3D

# Lines where RESIST prompts appear (0-indexed into dialogue_lines)
const RESIST_TRIGGER_LINES = [4, 6, 8]
const RESIST_WINDOW = 1.5 # seconds to press E

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

@export var corrupted_lines: PackedStringArray = [
	"[SYSTEM]: Memory at address 0x00FF — overwritten.",
	"[SYSTEM]: Organic substrate... ACCEPTED.",
	"[SYSTEM]: Host compliance confirmed.",
]

var has_been_used: bool = false
var _resist_misses: int = 0
var _current_resist_index: int = 0
var _waiting_for_resist: bool = false
var _resist_timer: float = 0.0
var _resist_overlay: Control = null

func interact() -> void:
	if has_been_used:
		return
	has_been_used = true
	_resist_overlay = get_tree().get_first_node_in_group("resist_overlay")
	_run_dialogue_with_resist()

func _run_dialogue_with_resist() -> void:
	var dialogue_box = DialogueManager.dialogue_box
	if not dialogue_box:
		return

	var lines_to_play: Array[String] = []
	for i in range(dialogue_lines.size()):
		lines_to_play.append(dialogue_lines[i])

	# We'll play line by line manually to intercept resist moments
	for i in range(lines_to_play.size()):
		DialogueManager.show_dialogue([lines_to_play[i]])
		await DialogueManager.dialogue_finished

		if i in RESIST_TRIGGER_LINES:
			var resisted = await _show_resist_prompt()
			if not resisted:
				_resist_misses += 1
				# Replace next engineer line with corrupted version
				if _current_resist_index < corrupted_lines.size():
					DialogueManager.show_dialogue([corrupted_lines[_current_resist_index]])
					await DialogueManager.dialogue_finished
				_current_resist_index += 1

	_play_ending()

func _show_resist_prompt() -> bool:
	if _resist_overlay:
		_resist_overlay.show()
	_waiting_for_resist = true
	_resist_timer = RESIST_WINDOW

	# Wait for either input or timeout
	while _waiting_for_resist and _resist_timer > 0:
		await get_tree().process_frame

	if _resist_overlay:
		_resist_overlay.hide()
	return not _waiting_for_resist # true = player pressed in time

func _process(delta: float) -> void:
	if not _waiting_for_resist:
		return
	_resist_timer -= delta
	if _resist_timer <= 0:
		_waiting_for_resist = false # timed out = missed

func _input(event: InputEvent) -> void:
	if _waiting_for_resist and event.is_action_pressed("interact"):
		_waiting_for_resist = false # pressed in time

func _play_ending() -> void:
	var horror_overlay = get_tree().get_first_node_in_group("horror_overlay")

	if _resist_misses >= 3:
		# BAD ENDING
		if horror_overlay:
			horror_overlay.show()
			var tween = create_tween()
			tween.tween_property(horror_overlay, "modulate:a", 1.0, 0.05)
		DialogueManager.show_dialogue(["[SYSTEM]: Integration complete. Welcome."])
		await DialogueManager.dialogue_finished
		GameManager.trigger_game_over("integration_complete")
	else:
		# GOOD ENDING — hard cut
		if horror_overlay:
			horror_overlay.show()
			var tween = create_tween()
			tween.tween_property(horror_overlay, "modulate:a", 1.0, 0.05)
		await get_tree().create_timer(0.5).timeout
		GameManager.trigger_ending("engineer_resisted")
