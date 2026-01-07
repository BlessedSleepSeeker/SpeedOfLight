extends StaticBody3D
class_name GravitationalPuller

@export var mass: float = 1
@export var deactivation_time_on_hit: float = 60

@onready var hitbox: Area3D = %Hitbox

func _ready():
	self.add_to_group("GravitationalPullers")
	hitbox.body_entered.connect(on_comet_entered)

func on_comet_entered(body: Node3D) -> void:
	print("puller : removing from group")
	self.remove_from_group("GravitationalPullers")
	await get_tree().create_timer(deactivation_time_on_hit).timeout
	self.add_to_group("GravitationalPullers")