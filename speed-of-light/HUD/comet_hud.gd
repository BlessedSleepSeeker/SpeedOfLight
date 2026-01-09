extends CanvasLayer
class_name CometHUD

@export var speed_template: String = "%.2f parsec per seconds"
@onready var speed_lbl: RichTextLabel = %SpeedLabel

@export var direction_template: String = "Aiming for (%.2f, %.2f, %.2f)"
@onready var direction_lbl: RichTextLabel = %DirectionLabel

@export var looking_at_template: String = "%s : ~%f"
@onready var looking_at_lbl: RichTextLabel = %LookingAtLabel

@export var focused_on_template: String = "Watching [%s]"
@onready var focused_on_lbl: RichTextLabel = %FocusedOn

func update_speed(spd_value: float) -> void:
	speed_lbl.text = speed_template % spd_value

func update_direction(direction_value: Vector3) -> void:
	direction_lbl.text = direction_template % [direction_value.x, direction_value.y, direction_value.z]

func update_looking_at(body: Node3D, comet_position: Vector3) -> void:
	if body && body is CelestialBody:
		looking_at_lbl.text = looking_at_template % [body.name, body.calculate_distance(comet_position)]
	else:
		looking_at_lbl.text = ""

func update_focused_on(body: Node3D) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(focused_on_lbl, "text", focused_on_template % body.name, 0.5)
	#focused_on_lbl.text = focused_on_template % body.name