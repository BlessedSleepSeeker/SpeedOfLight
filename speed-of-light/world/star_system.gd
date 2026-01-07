extends Node3D
class_name StarSystem

@onready var comet: Comet = $Comet
@onready var comet_hud: CometHUD = %CometHUDLayer
@onready var camera_selector: CameraSelector = %CameraSelector

@onready var debug_hud: DebugHUD = %DebugHUDLayer

var gravity_pullers: Array[Node] = []

var _physics_on: bool = true:
	set(value):
		_physics_on = value

func _ready():
	register_gravity_pullers()
	camera_selector.entity_selected.connect(_on_entity_selected)
	debug_hud.update_is_paused(!_physics_on)

#region Physics
func register_gravity_pullers() -> void:
	gravity_pullers = get_tree().get_nodes_in_group("GravitationalPullers")

func _physics_process(_delta):
	if _physics_on:
		register_gravity_pullers()
		for gravity_puller: GravitationalPuller in gravity_pullers:
			if gravity_puller.is_visible_in_tree():
				var gravity_pull: Vector3 = comet.calculate_gravity_pull(gravity_puller)
				comet.apply_pull(gravity_pull * _delta * 60)
	debug_hud.update_pfps()

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
#endregion

#region Click
func check_for_click() -> void:
	if comet.is_aiming:
		comet.shoot_self()
		return
	if comet.is_selected:
		_on_entity_selected(comet)
		return
	for entity: Node3D in gravity_pullers:
		if "is_selected" in entity && entity.is_visible_in_tree(): ## Check if the variable exist in the object
			if entity.is_selected:
				_on_entity_selected(entity)

func _on_entity_selected(entity: Node3D) -> void:
	if entity.has_method("activate_camera"):
		entity.activate_camera()

#endregion

func flush_star_system() -> void:
	comet.flush_pools()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("Click"):
		check_for_click()
	if Input.is_action_just_pressed("TogglePhysics"):
		toggle_physics()
	if Input.is_action_just_pressed("ResetScene"):
		flush_star_system()
		get_tree().reload_current_scene()
