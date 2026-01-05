extends StaticBody3D
class_name GravitationalPuller

@export var mass: float = 1

func _ready():
	self.add_to_group("GravitationalPullers")