extends Node2D

@onready var boot_label: RichTextLabel = $CanvasLayer/Control/VBoxContainer/BootLabel
@onready var title_label: Label = $CanvasLayer/Control/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CanvasLayer/Control/VBoxContainer/SubtitleLabel
@onready var button_container: VBoxContainer = $CanvasLayer/Control/VBoxContainer/ButtonContainer
@onready var start_button: Button = $CanvasLayer/Control/VBoxContainer/ButtonContainer/StartButton
@onready var quit_button: Button = $CanvasLayer/Control/VBoxContainer/ButtonContainer/QuitButton
@onready var scanline: ColorRect = $CanvasLayer/Scanline

const BOOT_LINES = [
	"CYBERBUNKER SYSTEMS — BIOS v4.1.7",
	"Initializing hardware...",
	"RAM: 65536 KB OK",
	"Storage array: ONLINE",
	"Network interfaces: DETECTED",
	"Rack 7 status: [WARNING] anomalous throughput",
	"Loading environment...",
	".",
	"..",
	"...",
]

const BOOT_LINE_DELAY = 0.12
const TITLE = "-REDACTED-"
const SUBTITLE = "Central Command Console — Maintenance Access"
const GLITCH_CHARS = "!@#$%^&*()_+=-[]{};<>?/|0123456789"
var is_glitching: bool = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	button_container.modulate.a = 0.0
	boot_label.text = ""

	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	_run_boot_sequence()

func _run_boot_sequence() -> void:
	await get_tree().create_timer(0.4).timeout

	# Type each boot line
	for line in BOOT_LINES:
		boot_label.text += line + "\n"
		await get_tree().create_timer(BOOT_LINE_DELAY).timeout

	await get_tree().create_timer(0.3).timeout
	
# After the title fades in, start the glitch loop
	_start_glitch_effect()

	# Fade in buttons
	var btn_tween = create_tween()
	btn_tween.tween_property(button_container, "modulate:a", 1.0, 0.4)
	await btn_tween.finished

	# Fade in title
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.6)
	await get_tree().create_timer(0.4).timeout
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.6)
	await tween.finished

	await get_tree().create_timer(0.3).timeout

func _on_start_pressed() -> void:
	await SceneTransition.fade_to("res://World/Level_01.tscn")

func _on_quit_pressed() -> void:
	await SceneTransition.fade_out()
	get_tree().quit()

func _start_glitch_effect() -> void:
	is_glitching = true
	while is_glitching:
		# 1. Randomly decide if we glitch this frame (15% chance)
		if randf() < 0.35:
			var original_text = TITLE
			var glitched_text = ""
			
			# 2. Randomly swap characters
			for i in range(original_text.length()):
				if randf() < 0.60: # 20% chance per character to be "corrupted"
					glitched_text += GLITCH_CHARS[randi() % GLITCH_CHARS.length()]
				else:
					glitched_text += original_text[i]
			
			title_label.text = glitched_text
			
			# 3. Quick offset shake
			title_label.position += Vector2(randf_range(-2, 2), randf_range(-2, 2))
			
			# Hold the glitch for a tiny moment
			await get_tree().create_timer(0.2).timeout
			
			# 4. Reset to normal
			title_label.text = TITLE
			title_label.position = Vector2.ZERO # Assumes centered by Container, adjust if needed
		
		# Random interval between glitch attempts
		await get_tree().create_timer(randf_range(0.1, 1.5)).timeout
