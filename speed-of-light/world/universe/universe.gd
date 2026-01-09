extends Node3D
class_name Universe

@export_group("ProcGen Parameters")
@export var chunk_size: Vector3 = Vector3(1280 * 3, 1280 * 3, 1280 * 3)
@export var chunk_scene: PackedScene = preload("res://world/procgen/SolarSystemGenerator.tscn")
@export var chunk_name_template: String = "%d %d %d"
@export var max_distance_before_unloading_chunk: float = 10000

@export_group("Debug")
@export var debug_line_scene: PackedScene = preload("res://world/universe/debug/DebugLine.tscn")

@onready var comet: Comet = $Comet
@onready var comet_hud: CometHUD = %CometHUDLayer
@onready var debug_hud: DebugHUD = %DebugHUDLayer
@onready var mouse_raycaster: MouseRaycaster = %MouseRaycaster

@onready var chroma_abberation_node: ColorRect = %ChromaAbberation

@export var bgm_stream: AudioStream = preload("res://sound/music/We're Finally Landing.mp3")

var current_chunk: SolarSystemGenerator = null:
	set(value):
		current_chunk = value
		#print("Entering chunk %s" % current_chunk)
		load_chunks(current_chunk.position)
		unload_far_chunks()

var chunks: Array[SolarSystemGenerator] = []
var celestial_bodies: Array[CelestialBody] = []

var _physics_on: bool = true:
	set(value):
		_physics_on = value
		tween_chroma_abberation(!_physics_on, 0.3)

var chunk_mutex: Mutex = Mutex.new()

func _ready():
	VolumeManager.play_bgm(bgm_stream, 0, true, 30)
	load_chunks(self.position)
	debug_hud.update_is_paused(!_physics_on)
	debug_hud.draw_line_to.connect(draw_debug_line_to)
	mouse_raycaster.entity_hovered.connect(_on_entity_hovered)
	mouse_raycaster.entity_selected.connect(_on_click)
	comet.aiming_start.connect(_on_aiming_start)
	comet.aiming_end.connect(_on_aiming_end)
	comet.is_aiming = true

func change_camera_to(entity: Node3D) -> void:
	if entity.has_method("activate_camera"):
		entity.activate_camera()
		comet_hud.update_focused_on(entity)

#region Physics
func _physics_process(_delta):
	## Trigger Chunkload if needed
	var cur_chunk = find_current_chunk()
	if cur_chunk != current_chunk:
		current_chunk = cur_chunk

	## Apply gravity
	var grav_sources: Dictionary[CelestialBody, Vector3] = {}
	for celestial_body: CelestialBody in celestial_bodies:
		if celestial_body && celestial_body.is_active && celestial_body.is_visible_in_tree():
			var gravity_pull: Vector3 = comet.calculate_gravity_pull(celestial_body)
			if _physics_on:
				comet.apply_pull(gravity_pull * _delta * 60)
			if gravity_pull != Vector3.ZERO:
				grav_sources[celestial_body] = gravity_pull * _delta * 60

	if _physics_on:
		comet.delegated_physics(_delta)
	debug_hud.update_gravity(grav_sources)
	debug_hud.update_pfps()
	debug_hud.update_position(comet.global_position)

func toggle_physics():
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
	comet_hud.update_looking_at(body, comet.global_position)
	if body != null && body.has_method("on_mouse_state_changed"):
		body.on_mouse_state_changed(true)
		highlighted = body
	elif highlighted != null:
		highlighted.on_mouse_state_changed(false)
		highlighted = null

func draw_debug_line_to(line_end_position: Vector3, gravity_value: float) -> void:
	if debug_hud.visible:
		gravity_value *= 1000
		DebugDraw3D.draw_line(comet.position, line_end_position, Color(gravity_value, gravity_value, gravity_value))

func tween_chroma_abberation(direction: bool, tween_speed: float):
	var tween: Tween = create_tween()
	tween.tween_property(chroma_abberation_node, "modulate:a", 1 if direction else 0, tween_speed)

func _on_aiming_start() -> void:
	toggle_physics()

func _on_aiming_end() -> void:
	toggle_physics()

#endregion

#region Click
func _on_click(entity_selected: Node3D) -> void:
	if comet.is_aiming:
		comet.shoot_self()
	elif entity_selected:
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
	var origin_chunk_coordinates: Vector3 = Vector3(int(origin.x / chunk_size.x), int(origin.y / chunk_size.y), int(origin.z / chunk_size.z))
	for i in range(-1, 2):
		for j in range(-1, 2):
			for k in range(-1, 2):
				var chunk_pos: Vector3 = origin + Vector3(i * chunk_size.x, j * chunk_size.y, k * chunk_size.z)
				var chunk = find_chunk_at_pos(chunk_pos)
				if chunk == null:
					var chunk_inst: SolarSystemGenerator = chunk_scene.instantiate()
					chunk_inst.name = chunk_name_template % [i + origin_chunk_coordinates.x, j + origin_chunk_coordinates.y, k + origin_chunk_coordinates.z]
					add_child(chunk_inst)
					chunk_inst.position = chunk_pos
					chunks.append(chunk_inst)
					chunk_inst.can_register_celestial_bodies.connect(register_celestial_bodies)
					chunk_inst.generation_finished.connect(_on_chunk_generation_finished)

func unload_far_chunks() -> void:
	for chunk: SolarSystemGenerator in chunks:
		if chunk && comet.global_position.distance_to(chunk.global_position) > max_distance_before_unloading_chunk:
			chunk.queue_free()


func find_current_chunk() -> SolarSystemGenerator:
	var chunk_pos_x: float = comet.global_position.x / chunk_size.x
	var chunk_pos_y: float = comet.global_position.y / chunk_size.y
	var chunk_pos_z: float = comet.global_position.z / chunk_size.z

	var chunk_pos: Vector3 = Vector3(int(chunk_pos_x), int(chunk_pos_y), int(chunk_pos_z))
	return find_chunk_at_pos(chunk_pos * chunk_size)

func find_chunk_at_pos(looking_for: Vector3) -> SolarSystemGenerator:
	for chunk: SolarSystemGenerator in chunks:
		if chunk && chunk.position == looking_for:
			chunk_mutex.unlock()
			return chunk
	return null

func register_celestial_bodies() -> void:
	celestial_bodies.assign(get_tree().get_nodes_in_group("CelestialBody"))

var total_chunk_generated: int = 0
func _on_chunk_generation_finished() -> void:
	total_chunk_generated += 1
	if total_chunk_generated == 27:
		comet.name = "CO M3T307"
		comet.max_distance_for_gravity = chunk_size.x * 3
		change_camera_to(comet)
		debug_hud.hide()
#endregion
