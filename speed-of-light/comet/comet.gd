extends CharacterBody3D
class_name Comet

@export var mass: float = 200
@export var pause_movement: bool = false
# Speed per tick * delta
@export var speed: float = 10
@export var initial_velocity: Vector3 = Vector3(0.5, -1, 1)

@export var draw_tail: bool = true
@export var tail_mesh: PackedScene = preload("res://comet/TailMesh.tscn")

@onready var skin: Node3D = $MeshRotator

const GRAVITY: float = 6.6743 * pow(10,-1)

func _ready():
	self.velocity = initial_velocity

func get_speed() -> float:
	return abs(self.velocity.x) + abs(self.velocity.y) + abs(self.velocity.z)

func get_direction() -> Vector3:
	return self.velocity

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
	#self.velocity = self.transform.basis.z * delta * speed
	skin.look_at(velocity)
	move_and_collide(self.velocity)
	if draw_tail == true:
		var inst = tail_mesh.instantiate()
		get_tree().root.add_child(inst)
		inst.global_position = self.global_position
