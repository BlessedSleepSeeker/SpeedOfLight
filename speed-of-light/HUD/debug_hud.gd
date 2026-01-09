extends CanvasLayer
class_name DebugHUD

@export var fps_template: String = "%04d FPS"
@onready var fps_label: RichTextLabel = %FPSLabel

@export var physic_ticks_template: String = "%04d Physics Tick Past Second"
@onready var physic_ticks_label: RichTextLabel = %PFPSLabel

@export var is_paused_template: String = "%s"
@onready var is_paused_label: RichTextLabel = %IsPausedLabel

@export var position_template: String = "Position [%.02f : %.02f : %.02f]"
@onready var position_label: RichTextLabel = %PositionLabel

@export var gravity_template: String = "%s = [%f : %f : %f]\n"
@onready var gravity_label: RichTextLabel = %GravityAppliedByLabel

@onready var prev_physics_frame: int = 0

signal draw_line_to(body_position: Vector3)

func update_fps() -> void:
	fps_label.text = fps_template % Engine.get_frames_per_second()

func update_pfps() -> void:
	if Engine.get_physics_frames() % 60 == 0:
		physic_ticks_label.text = physic_ticks_template % (Engine.get_physics_frames() - prev_physics_frame)
		prev_physics_frame = Engine.get_physics_frames()

func update_is_paused(value: bool) -> void:
	if value:
		is_paused_label.text = "[color=dark_red]SIMULATION PAUSED[/color]"
	else:
		is_paused_label.text = "[color=forest_green]SIMULATION RUNNING[/color]"

func update_position(value: Vector3) -> void:
	position_label.text = position_template % [value.x, value.y, value.z]

func update_gravity(source: Dictionary) -> void:
	var max_line: int = 20
	var gravity_string: String = ""
	var ordered_values: Array = source.values().map(get_distance)
	ordered_values.sort()
	ordered_values.reverse()
	var i: int = 0
	for value in ordered_values:
		for c_body: CelestialBody in source:
			if get_distance(source[c_body]) == value:
				#gravity_string += gravity_template % [c_body.name, source[c_body].x, source[c_body].y, source[c_body].z]
				gravity_string += "%s (%f) = %f\n" % [c_body.name, c_body.mass, value]
				draw_line_to.emit(c_body.global_position, value)
		if i == max_line:
			break
		i += 1
	gravity_label.text = gravity_string

func get_distance(vector: Vector3) -> float:
	return vector.distance_to(Vector3.ZERO)


func _unhandled_input(_event):
	if Input.is_action_just_pressed("ToggleDebug"):
		self.visible = !self.visible
