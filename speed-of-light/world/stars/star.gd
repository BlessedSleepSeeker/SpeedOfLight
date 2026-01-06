extends GravitationalPuller
class_name Star

@export var highlight_color: Color = Color8(255, 255, 255)
@export var highlight_color_off: Color = Color8(255, 255, 255, 0)
@export var highlight_tween_time: float = 0.4

@onready var mouse_area: Area3D = $%MouseArea
@onready var highlight_material: ShaderMaterial = $MeshInstance3D.mesh.material.next_pass
@onready var camera: CameraOrbit = %CameraOrbit

var is_selected: bool = false:
	set(value):
		toggle_highlight(value)
		is_selected = value

func _ready():
	super()
	highlight_material.set_shader_parameter("outline_color", highlight_color_off)
	mouse_area.mouse_entered.connect(on_mouse_state_changed.bind(true))
	mouse_area.mouse_exited.connect(on_mouse_state_changed.bind(false))

func toggle_highlight(direction: bool) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(highlight_material, "shader_parameter/outline_color", highlight_color if direction else highlight_color_off, highlight_tween_time)

func activate_camera() -> void:
	camera.make_current()

func on_mouse_state_changed(value: bool) -> void:
	is_selected = value