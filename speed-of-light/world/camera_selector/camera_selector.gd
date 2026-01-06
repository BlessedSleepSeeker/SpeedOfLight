extends Node
class_name CameraSelector

@export var ray_length: float = 1000

@onready var ray: RayCast3D = %RayCast3D

signal entity_selected(entity: Node3D)

func update_ray() -> void:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = get_viewport().get_camera_3d().project_ray_origin(mouse_pos)
	var ray_direction: Vector3 = ray_origin + get_viewport().get_camera_3d().project_ray_normal(mouse_pos) * ray_length
	ray.global_position = ray_origin
	ray.target_position = ray_direction

func is_ray_colliding() -> bool:
	return ray.is_colliding()

func _process(_delta):
	update_ray()
	if Input.is_action_just_pressed("Click") && is_ray_colliding():
		pass#entity_selected.emit(ray.get_collider().get_parent())