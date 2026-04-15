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

	# Fade in title
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.6)
	await get_tree().create_timer(0.4).timeout
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.6)
	await tween.finished

	await get_tree().create_timer(0.3).timeout

	# Fade in buttons
	var btn_tween = create_tween()
	btn_tween.tween_property(button_container, "modulate:a", 1.0, 0.4)
	await btn_tween.finished

func _on_start_pressed() -> void:
	await SceneTransition.fade_to("res://World/Level_01.tscn")

func _on_quit_pressed() -> void:
	await SceneTransition.fade_out()
	get_tree().quit()
