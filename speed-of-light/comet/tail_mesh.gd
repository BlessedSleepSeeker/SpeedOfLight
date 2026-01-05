extends StaticBody3D

func _ready():
	await get_tree().create_timer(60).timeout
	queue_free()