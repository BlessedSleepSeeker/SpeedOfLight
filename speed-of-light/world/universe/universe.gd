extends Node3D
class_name Universe

@export_group("ProcGen Parameters")
@export var chunk_size: Vector3 = Vector3(1280 * 3, 1280 * 3, 1280 * 3)
@export var chunk_scene: PackedScene = preload("res://world/procgen/SolarSystemGenerator.tscn")
@export var chunk_name_template: String = "%d %d %d"

@onready var comet: Comet = $Comet
@onready var comet_hud: CometHUD = %CometHUDLayer
@onready var debug_hud: DebugHUD = %DebugHUDLayer
@onready var mouse_raycaster: MouseRaycaster = %MouseRaycaster

var chunks: Array[SolarSystemGenerator] = []
var current_chunk: SolarSystemGenerator = null
var celestial_bodies: Array[CelestialBody] = []


var _physics_on: bool = true:
	set(value):
		_physics_on = value

func _ready():
	load_chunks(self.position)
	debug_hud.update_is_paused(!_physics_on)
	mouse_raycaster.entity_hovered.connect(_on_entity_hovered)
	mouse_raycaster.entity_selected.connect(_on_click)

func change_camera_to(entity: Node3D) -> void:
	print("changing cmaera")
	if entity.has_method("activate_camera"):
		entity.activate_camera()
		comet_hud.update_focused_on(entity)

#region Physics
func _physics_process(_delta):
	if _physics_on:
		var grav_sources: Dictionary[CelestialBody, Vector3] = {}
		for celestial_body: CelestialBody in celestial_bodies:
			if celestial_body.is_active && celestial_body.is_visible_in_tree():
				var gravity_pull: Vector3 = comet.calculate_gravity_pull(celestial_body)
				comet.apply_pull(gravity_pull * _delta * 60)
				grav_sources[celestial_body] = gravity_pull * _delta * 60
		debug_hud.update_gravity(grav_sources)
	debug_hud.update_pfps()
	debug_hud.update_position(comet.global_position)

func toggle_physics():
	if comet.is_aiming:
		return
	_physics_on = !_physics_on
	debug_hud.update_is_paused(!_physics_on)
#endregion


#region HUD
func _process(_delta):
	comet_hud.update_speed(comet.get_speed())
	comet_hud.update_direction(comet.get_direction())
	debug_hud.update_fps()

var highlighted: Node3D = null
func _on_entity_hovered(body: Node3D) -> void:
	comet_hud.update_looking_at(body, comet.position)
	if body != null && body.has_method("on_mouse_state_changed"):
		body.on_mouse_state_changed(true)
		highlighted = body
	elif highlighted != null:
		highlighted.on_mouse_state_changed(false)
		highlighted = null
#endregion

#region Click
func _on_click(entity_selected: Node3D) -> void:
	if comet.is_aiming:
		comet.shoot_self()
	if entity_selected:
		change_camera_to(entity_selected)

#endregion

func flush_star_system() -> void:
	comet.flush_pools()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ReturnToComet"):
		change_camera_to(comet)
	if Input.is_action_just_pressed("TogglePhysics"):
		toggle_physics()
	if Input.is_action_just_pressed("ResetScene"):
		flush_star_system()
		get_tree().reload_current_scene()

#region ProcGen
func load_chunks(origin: Vector3) -> void:
	for i in range(-1, 2):
		for j in range(-1, 2):
			for k in range(-1, 2):
				var chunk_pos: Vector3 = origin + Vector3(i * chunk_size.x, j * chunk_size.y, k * chunk_size.z)
				var chunk = find_chunk_at_pos(chunk_pos)
				if chunk == null:
					var chunk_inst: SolarSystemGenerator = chunk_scene.instantiate()
					chunk_inst.name = chunk_name_template % [i, j, k]
					add_child(chunk_inst)
					chunk_inst.position = chunk_pos
					chunks.append(chunk_inst)
					chunk_inst.can_register_celestial_bodies.connect(register_celestial_bodies)
					#await get_tree().create_timer(3).timeout
					chunk_inst.generation_finished.connect(_on_chunk_generation_finished)

func find_chunk_at_pos(looking_for: Vector3) -> SolarSystemGenerator:
	for chunk: SolarSystemGenerator in chunks:
		if chunk.position == looking_for:
			return chunk
	return null

func register_celestial_bodies() -> void:
	celestial_bodies.assign(get_tree().get_nodes_in_group("CelestialBody"))

var total_chunk_generated: int = 0
func _on_chunk_generation_finished() -> void:
	total_chunk_generated += 1
	if total_chunk_generated == 27:
		comet.name = "CO M3T307"
		change_camera_to(comet)
#endregion
