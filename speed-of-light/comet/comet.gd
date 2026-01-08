extends CharacterBody3D
class_name Comet

@export var mass: float = 200
@export var pause_movement: bool = false
# Speed per tick * delta
@export var speed: float = 10
@export var initial_velocity: Vector3 = Vector3(2, -2, 2)
@export var max_distance_for_gravity: float = 10000000

@export var draw_tail: bool = true
@export var tail_mesh: PackedScene = preload("res://comet/TailMesh.tscn")
@export var tail_max_amount: int = 1200

@export var ray_length: float = 60
@export var ray_direction_amount: int = 60
@export var aiming_mesh: PackedScene = preload("res://comet/AimingMesh.tscn")

@onready var skin: CometSkin = $CometSkin
@onready var hitbox: Area3D = $Hitbox
@onready var camera: CameraOrbit = %CameraOrbit
@onready var direction_raycast: RayCast3D = %DirectionRaycast

const GRAVITY: float = 6.6743 * pow(10,-1)

var is_selected: bool = false:
	set(value):
		toggle_highlight(value)
		is_selected = value

var _physics_on: bool = true

var is_aiming: bool = true:
	set(value):
		is_aiming = value
		_physics_on = !is_aiming
		change_ray_visibility(is_aiming)
		if is_aiming:
			activate_camera()
			camera._curZoom = camera.minZoom

var prev_velocity: Vector3 = Vector3.ZERO

func _ready():
	is_aiming = true
	self.velocity = initial_velocity
	activate_camera()
	setup_ray_pool()
	setup_tail_pool()
	hitbox.area_entered.connect(_on_entity_collided)
	self.mouse_entered.connect(on_mouse_state_changed.bind(true))
	self.mouse_exited.connect(on_mouse_state_changed.bind(false))

#region UI Getters
func get_speed() -> float:
	return abs(self.velocity.x) + abs(self.velocity.y) + abs(self.velocity.z)

func get_direction() -> Vector3:
	return self.velocity
#endregion

#region Gravity Physics
func calculate_gravity_pull(puller: CelestialBody) -> Vector3:
	##print("Calculating gravity pull for %s" % puller.name)
	var m1m2: float = self.mass * puller.mass
	#print("mass: %f" % m1m2)
	var distance: float = calculate_distance(puller)
	if distance > max_distance_for_gravity:
		return Vector3.ZERO
	#print("distance: %f" % distance)
	var grav_before_const: float = m1m2 / (distance ** 2)
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
	return self.position.distance_to(entity.position)

func apply_pull(gravity_pull: Vector3) -> void:
	if _physics_on:
		self.velocity += gravity_pull

func _physics_process(_delta):
	if is_aiming:
		update_ray()
	if _physics_on:
		skin.look_at_velocity(velocity, prev_velocity)
		move_and_collide(self.velocity)
		prev_velocity = self.velocity
		if draw_tail == true:
			draw_tail_from_pool()

func set_physics_toggle(value: bool) -> void:
	if is_aiming == false:
		_physics_on = value

func shoot_self() -> void:
	is_aiming = false
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var new_direction: Vector3 = get_viewport().get_camera_3d().project_ray_normal(mouse_pos)
	apply_current_velocity_to_new_direction(new_direction)

func apply_current_velocity_to_new_direction(new_direction: Vector3):
	var current_speed: float = get_speed() / 3
	self.velocity = new_direction * current_speed
#endregion

#region Game Mechanics
var ray_dir_visuals: Array[StaticBody3D] = []
func setup_ray_pool() -> void:
	for i in range(ray_direction_amount):
		var inst = aiming_mesh.instantiate()
		get_tree().root.add_child.call_deferred(inst)
		ray_dir_visuals.append(inst)

func change_ray_visibility(visibility: bool) -> void:
	for ray_part: StaticBody3D in ray_dir_visuals:
		ray_part.visible = visibility


func update_ray() -> void:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	#var ray_origin: Vector3 = get_viewport().get_camera_3d().project_ray_origin(mouse_pos)
	#print(get_viewport().get_camera_3d().project_ray_normal(mouse_pos))
	var ray_target: Vector3 = self.global_position + (get_viewport().get_camera_3d().project_ray_normal(mouse_pos) * ray_length)
	direction_raycast.target_position = ray_target
	var ray_direction = get_viewport().get_camera_3d().project_ray_normal(mouse_pos)#direction_raycast.target_position.normalized()
	var i = 1
	for node: StaticBody3D in ray_dir_visuals:
		if node.is_inside_tree():
			node.global_position = self.global_position + (ray_direction * (i * (ray_length / ray_direction_amount)))
		i += 1

func _on_entity_collided(_area: Area3D) -> void:
	is_aiming = true

#endregion

#region Graphics

func on_mouse_state_changed(value: bool) -> void:
	is_selected = value

func toggle_highlight(direction: bool) -> void:
	skin.toggle_highlight(direction)

func activate_camera() -> void:
	camera.make_current()

var tail_visuals: Array[TailEntity] = []
func setup_tail_pool() -> void:
	for i in range(tail_max_amount):
		var inst: TailEntity = tail_mesh.instantiate()
		get_tree().root.add_child.call_deferred(inst)
		tail_visuals.append(inst)
		inst.hide()

func draw_tail_from_pool() -> void:
	var tail_entity: TailEntity = tail_visuals.pop_front()
	if not tail_entity:
		return
	tail_entity.global_position = self.global_position
	tail_entity.reset()
	tail_visuals.append(tail_entity)

func flush_pools() -> void:
	for entity: TailEntity in tail_visuals:
		entity.queue_free()
	for entity: StaticBody3D in ray_dir_visuals:
		entity.queue_free()

#endregion

#region Input

func _unhandled_input(_event):
	if Input.is_action_just_pressed("TogglePhysics"):
		if !self.is_aiming:
			_physics_on = !_physics_on
	if Input.is_action_just_pressed("BulletTime"):
		toggle_bullet_time(true)
	if Input.is_action_just_released("BulletTime"):
		toggle_bullet_time(false)
	if Input.is_action_just_pressed("ReturnToComet"):
		activate_camera()


func toggle_bullet_time(toggle: bool) -> void:
	if toggle:
		var tween: Tween = get_tree().create_tween()
		tween.tween_property(Engine, "time_scale", 0.1, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		var tween: Tween = get_tree().create_tween()
		tween.tween_property(Engine, "time_scale", 1.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
