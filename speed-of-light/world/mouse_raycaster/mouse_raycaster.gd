extends Node3D
class_name MouseRaycaster

@export var ray_length: float = 10000

#@onready var ray: RayCast3D = %RayCast3D

signal entity_selected(entity: Node3D)
signal entity_hovered(entity: Node3D)

func update_ray() -> void:
	var space_state = get_world_3d().direct_space_state
	var camera: Camera3D = get_viewport().get_camera_3d()
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()

	var ray_origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var ray_end: Vector3 = ray_origin + camera.project_ray_normal(mouse_pos) * ray_length
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = true
	query.collision_mask = 0b00000000_00000000_00000000_00000010

	var result: Dictionary = space_state.intersect_ray(query)
	if result.has("collider"):
		entity_hovered.emit(result["collider"].get_parent())
	else:
		entity_hovered.emit(null)
	if Input.is_action_just_pressed("Click"):
		entity_selected.emit(result["collider"].get_parent() if result.has("collider") else null)
	# ray.position = ray_origin
	# ray.target_position = ray_direction

func _physics_process(_delta):
	update_ray()
