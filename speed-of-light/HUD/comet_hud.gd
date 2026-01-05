extends CanvasLayer
class_name CometHUD

@export var speed_template: String = "%.2f parsec per seconds"
@onready var speed_lbl: RichTextLabel = %SpeedLabel

@export var direction_template: String = "Aiming for (%.2f, %.2f, %.2f)"
@onready var direction_lbl: RichTextLabel = %DirectionLabel

func update_speed(spd_value: float) -> void:
	speed_lbl.text = speed_template % spd_value

func update_direction(direction_value: Vector3) -> void:
	direction_lbl.text = direction_template % [direction_value.x, direction_value.y, direction_value.z]