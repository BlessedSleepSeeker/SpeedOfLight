extends GravitationalPuller
class_name Star

@onready var gravity_area: Area3D = %GravityArea

func _ready():
	super()
	gravity_area.body_entered.connect(on_body_entered)

func on_body_entered(body: Node3D) -> void:
	print("body %s entered %s" % [body.name, self.name])