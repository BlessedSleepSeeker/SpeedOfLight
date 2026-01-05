extends Node3D
class_name StarSystem

@onready var comet: Comet = $Comet
@onready var comet_hud: CometHUD = %CometHUDLayer

var gravity_pullers: Array[Node] = []

func _ready():
	register_gravity_pullers()

func register_gravity_pullers() -> void:
	gravity_pullers = get_tree().get_nodes_in_group("GravitationalPullers")

func _physics_process(delta):
	for gravity_puller: GravitationalPuller in gravity_pullers:
		if gravity_puller.is_visible_in_tree():
			var gravity_pull: Vector3 = comet.calculate_gravity_pull(gravity_puller)
			comet.apply_pull(gravity_pull)

func _process(_delta):
	comet_hud.update_speed(comet.get_speed())
	comet_hud.update_direction(comet.get_direction())