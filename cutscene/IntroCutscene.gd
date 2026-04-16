extends CanvasLayer

## IntroCutscene.gd
## Plays a short typewriter-style story intro, then fades out so gameplay begins.
## Add as the FIRST child of your level scene so it plays on load.

signal cutscene_finished

@onready var text_label: RichTextLabel = $Control/VBox/TextLabel
@onready var bg: ColorRect = $BG

const LINES = [
	"ATONGANG DATA CENTER — Basement Level 3",
	"November 14, 2:47 AM",
	"",
	"Your name is E. M. Butido. You fix things when they break in the middle of the night.",
	"",
	"You're here because of a routine work order. ",
	"Rack 7 has been throwing red lights for six weeks straight. ",
	"Two other techs were assigned to this before you; both quit mid-shift without saying why.",
	"Neither filed a report.",
	"",
	"Your orders: run the scan, find the leak, and go home.",
	"",
	"The elevator is already heading back up.",
]

const CHAR_DELAY = 0.099  # seconds per character
const LINE_PAUSE = 0.3   # pause between lines

var _skip_requested: bool = false

func _ready() -> void:
	text_label.text = ""
	# Pause the game tree so player can't move during cutscene
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	_play_sequence()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		_skip_requested = true

func _play_sequence() -> void:
	for line in LINES:
		if _skip_requested:
			break
		if line == "":
			text_label.text += "\n"
			await _wait(LINE_PAUSE * 0.5)
			continue
		for ch in line:
			if _skip_requested:
				break
			text_label.text += ch
			await _wait(CHAR_DELAY)
		text_label.text += "\n"
		await _wait(LINE_PAUSE)
	
	# Show full text if skipped
	if _skip_requested:
		text_label.text = ""
		for line in LINES:
			text_label.text += line + "\n"
	
	await _wait(1.0)
	
	# Fade out the cutscene
	var tween = create_tween()
	tween.tween_property(bg, "color:a", 0.0, 1.0)
	tween.parallel().tween_property(text_label, "modulate:a", 0.0, 0.8)
	await tween.finished
	
	# Unpause and remove
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	emit_signal("cutscene_finished")
	queue_free()

func _wait(duration: float) -> void:
	await get_tree().create_timer(duration, true, false, true).timeout
