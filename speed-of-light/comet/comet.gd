extends CharacterBody3D
class_name Comet

@export var mass: float = 200
@export var pause_movement: bool = false
# Speed per tick * delta
@export var speed: float = 10
@export var initial_velocity: Vector3 = Vector3(0.5, -1, 1)

@export var draw_tail: bool = true
@export var tail_mesh: PackedScene = preload("res://comet/TailMesh.tscn")

@export var highlight_color: Color = Color8(255, 255, 255)
@export var highlight_color_off: Color = Color8(255, 255, 255, 0)
@export var highlight_tween_time: float = 0.4

@onready var skin: Node3D = $MeshRotator
@onready var camera: CameraOrbit = %CameraOrbit
@onready var highlight_material: ShaderMaterial = %MeshInstance3D.mesh.material.next_pass

const GRAVITY: float = 6.6743 * pow(10,-1)

var is_selected: bool = false:
	set(value):
		toggle_highlight(value)
		is_selected = value

var _physics_on: bool = true

var is_aiming: bool = true

func _ready():
	self.velocity = initial_velocity
	activate_camera()
	highlight_material.set_shader_parameter("outline_color", highlight_color_off)
	self.mouse_entered.connect(on_mouse_state_changed.bind(true))
	self.mouse_exited.connect(on_mouse_state_changed.bind(false))

#region UI Getters
func get_speed() -> float:
	return abs(self.velocity.x) + abs(self.velocity.y) + abs(self.velocity.z)

func get_direction() -> Vector3:
	return self.velocity
#endregion

#region Gravity Physics
func calculate_gravity_pull(puller: GravitationalPuller) -> Vector3:
	##print("Calculating gravity pull for %s" % puller.name)
	var m1m2: float = self.mass * puller.mass
	#print("mass: %f" % m1m2)
	var distance: float = calculate_distance(puller)
	#print("distance: %f" % distance)
	var grav_before_const: float = m1m2 / distance
	#print("grav_before_const: %f" % grav_before_const)
	var gravity_force: float = GRAVITY * grav_before_const
	#print(gravity_force)
	var pointer_vec: Vector3 = (puller.position - self.position).normalized()
	#print("point_vec: %s" % pointer_vec)
	var integrated_force: Vector3 = pointer_vec * gravity_force
	#print(integrated_force)
	#print("_______")
	return integrated_force

func calculate_distance(entity: Node3D) -> float:
	return self.position.distance_squared_to(entity.position)

func apply_pull(gravity_pull: Vector3) -> void:
	self.velocity += gravity_pull

func _physics_process(_delta):
	if _physics_on:
		skin.look_at(velocity)
		move_and_collide(self.velocity)
		if draw_tail == true:
			var inst = tail_mesh.instantiate()
			get_tree().root.add_child(inst)
			inst.global_position = self.global_position

func set_physics_toggle(value: bool) -> void:
	if is_aiming == false:
		_physics_on = value

#endregion

#region Graphics

func on_mouse_state_changed(value: bool) -> void:
	is_selected = value

func toggle_highlight(direction: bool) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(highlight_material, "shader_parameter/outline_color", highlight_color if direction else highlight_color_off, highlight_tween_time)

func activate_camera() -> void:
	camera.make_current()
#endregion

#region Input

func _unhandled_input(_event):
	if Input.is_action_just_pressed("TogglePhysics"):
		_physics_on = !_physics_on
	if Input.is_action_just_pressed("BulletTime"):
		toggle_bullet_time(true)
	if Input.is_action_just_released("BulletTime"):
		toggle_bullet_time(false)


func toggle_bullet_time(toggle: bool) -> void:
	print("toggled bullet time : %s" % toggle)
	if toggle:
		var tween: Tween = get_tree().create_tween()
		tween.tween_property(Engine, "time_scale", 0.1, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		var tween: Tween = get_tree().create_tween()
		tween.tween_property(Engine, "time_scale", 1.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
