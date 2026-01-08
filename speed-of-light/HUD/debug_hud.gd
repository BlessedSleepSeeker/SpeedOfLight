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

@onready var prev_physics_frame: int = 0

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

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ToggleDebug"):
		self.visible = !self.visible