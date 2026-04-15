extends CanvasLayer

@onready var location_label = $Control/VBoxContainer/LocationLabel
@onready var condition_label = $Control/VBoxContainer/ConditionLabel

# Condition stages — updates as game progresses
const CONDITIONS = [
	"01% Integration",
	"24% Integration",
	"51% Integration",
	"78% Integration",
	"99% Integration Complete",
]

var _condition_index: int = 0
var _blink_timer: float = 0.0
var _blink_visible: bool = true

func _ready() -> void:
	location_label.text = "Location: Central Command Console"
	condition_label.text = "Condition: Nominal"
	TaskManager.corruption_tick.connect(_on_corruption_tick)

func _process(delta: float) -> void:
	# Blink the condition label after corruption starts
	if _condition_index > 0:
		_blink_timer += delta
		if _blink_timer >= 0.8:
			_blink_timer = 0.0
			_blink_visible = not _blink_visible
			condition_label.visible = _blink_visible

func _on_corruption_tick() -> void:
	if _condition_index < CONDITIONS.size():
		condition_label.visible = true
		condition_label.text = "Condition: " + CONDITIONS[_condition_index]
		_condition_index += 1
