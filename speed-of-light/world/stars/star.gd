extends CelestialBody
class_name Star

@export var star_offset_min: Vector3 = Vector3(-400, -400, -400)
@export var star_offset_max: Vector3 = Vector3(400, 400, 400)

var star_offset: Vector3 = Vector3.ZERO

func _ready():
	super()

func randomize_offset() -> void:
	star_offset.x = RngManager.randf_range_safe(star_offset_min.x, star_offset_max.x)
	star_offset.y = RngManager.randf_range_safe(star_offset_min.y, star_offset_max.y)
	star_offset.z = RngManager.randf_range_safe(star_offset_min.z, star_offset_max.z)
	self.position = star_offset

func generate() -> void:
	super()