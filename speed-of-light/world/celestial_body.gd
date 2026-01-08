extends StaticBody3D
class_name CelestialBody

@export var verbose_print: bool = false
@export var randomize_rotation_on_load: bool = false
@export_group("ProcGen Parameters")
@export_subgroup("Mass")
@export var mass: float = 1
@export var min_mass: float = 1
@export var max_mass: float = 10

@export_subgroup("Deactivation Time")
@export var deactivation_time_on_hit: float = 60

@export_subgroup("Boids Mechanisms")
@export var min_allowed_distance_from_others: float = 200
@export var max_allowed_distance_from_others: float = 800
@export var boids_tick_displacement_min: float = 1.0
@export var boids_tick_displacement_max: float = 10.0

@export_group("Mouse Management")
@export var highlight_color: Color = Color8(255, 255, 255)
@export var highlight_color_off: Color = Color8(255, 255, 255, 0)
@export var highlight_tween_time: float = 0.4

@onready var hitbox: Area3D = %Hitbox
@onready var mouse_area: Area3D = %MouseArea
@onready var highlight_material: ShaderMaterial = $MeshInstance3D.mesh.material.next_pass
@onready var camera: CameraOrbit = %CameraOrbit
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var is_active: bool = true

var is_selected: bool = false:
	set(value):
		toggle_highlight(value)
		is_selected = value

func _ready():
	self.add_to_group("CelestialBody")
	hitbox.body_entered.connect(on_comet_entered)
	highlight_material.set_shader_parameter("outline_color", highlight_color_off)
	mouse_area.mouse_entered.connect(on_mouse_state_changed.bind(true))
	mouse_area.mouse_exited.connect(on_mouse_state_changed.bind(false))
	if randomize_rotation_on_load:
		randomize_rotation()

func activate_camera() -> void:
	camera.make_current()

#region Collision
func on_comet_entered(_body: Node3D) -> void:
	if verbose_print:
		print_debug("%s : Comet collided !" % name)
	if anim_player:
		anim_player.play("deactivate")
	self.is_active = false
	await get_tree().create_timer(deactivation_time_on_hit).timeout
	if anim_player:
		anim_player.play("reactivate")
	self.is_active = true

func toggle_highlight(direction: bool) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(highlight_material, "shader_parameter/outline_color", highlight_color if direction else highlight_color_off, highlight_tween_time)

func on_mouse_state_changed(value: bool) -> void:
	if is_active:
		is_selected = value
	elif not is_active && is_selected:
		is_selected = false

#endregion


#region Procedural Generation
func generate() -> void:
	mass = roundf(RngManager.randf_range_safe(min_mass, max_mass))

func randomize_rotation() -> void:
	rotation.x = RngManager.randf_range_safe(0, 1)
	rotation.y = RngManager.randf_range_safe(0, 1)
	rotation.z = RngManager.randf_range_safe(0, 1)

func calculate_distance(_position: Vector3) -> float:
	return self.position.distance_to(_position)

func set_random_position() -> void:
	self.position.x = RngManager.randf_range_safe(-max_allowed_distance_from_others, max_allowed_distance_from_others)
	self.position.y = RngManager.randf_range_safe(-max_allowed_distance_from_others, max_allowed_distance_from_others)
	self.position.z = RngManager.randf_range_safe(-max_allowed_distance_from_others, max_allowed_distance_from_others)
	#print("Placed %s at %s" % [self.name, self.position])

func boids_check_distances(celestial_bodies: Array[CelestialBody]) -> bool:
	var distances: Dictionary = {}
	for celestial_body in celestial_bodies:
		if celestial_body.position != self.position:
			var distance: float = calculate_distance(celestial_body.position)
			distances[celestial_body.position] = distance
	var something_happened: bool = false
	for celestial_body_pos: Vector3 in distances:
		var distance: float = distances[celestial_body_pos]
		if distance < min_allowed_distance_from_others:
			boids_get_further_from(celestial_body_pos)
			something_happened = true
		if distance > max_allowed_distance_from_others:
			boids_get_closer_from(celestial_body_pos)
			something_happened = true
	return something_happened

func boids_get_further_from(_position: Vector3) -> void:
	if verbose_print:
		print("Moving %s further from %s" % [self.name, _position])
	var further_dir: Vector3 = (self.position - _position).normalized()
	var displacement_strenght: float = RngManager.randf_range_safe(boids_tick_displacement_min, boids_tick_displacement_max)
	self.position += further_dir * displacement_strenght

func boids_get_closer_from(_position: Vector3) -> void:
	if verbose_print:
		print("Moving %s closer from %s" % [self.name, _position])
	var closer_dir: Vector3 = (_position - self.position).normalized()
	var displacement_strenght: float = RngManager.randf_range_safe(boids_tick_displacement_min, boids_tick_displacement_max)
	self.position += closer_dir * displacement_strenght

#endregion