extends GravitationalPuller
class_name Star

@export var randomize_rotation_on_load: bool = false

@export var highlight_color: Color = Color8(255, 255, 255)
@export var highlight_color_off: Color = Color8(255, 255, 255, 0)
@export var highlight_tween_time: float = 0.4

@onready var mouse_area: Area3D = %MouseArea
@onready var highlight_material: ShaderMaterial = $MeshInstance3D.mesh.material.next_pass
@onready var camera: CameraOrbit = %CameraOrbit
@onready var anim_player: AnimationPlayer = $AnimationPlayer

@onready var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var is_active: bool = true

var is_selected: bool = false:
	set(value):
		toggle_highlight(value)
		is_selected = value

func _ready():
	super()
	highlight_material.set_shader_parameter("outline_color", highlight_color_off)
	mouse_area.mouse_entered.connect(on_mouse_state_changed.bind(true))
	mouse_area.mouse_exited.connect(on_mouse_state_changed.bind(false))
	if randomize_rotation_on_load:
		randomize_rotation()

func toggle_highlight(direction: bool) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(highlight_material, "shader_parameter/outline_color", highlight_color if direction else highlight_color_off, highlight_tween_time)

func activate_camera() -> void:
	camera.make_current()

func on_mouse_state_changed(value: bool) -> void:
	if is_active:
		is_selected = value
	elif not is_active && is_selected:
		is_selected = false

func on_comet_entered(body: Node3D) -> void:
	print("star : comet entered")
	anim_player.play("deactivate")
	await super(body)
	anim_player.play("reactivate")

func randomize_rotation() -> void:
	rotation.x = randf()
	rotation.y = randf()
	rotation.z = randf()
