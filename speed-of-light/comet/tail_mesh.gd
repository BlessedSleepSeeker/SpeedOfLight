extends StaticBody3D

@onready var fade_timer: Timer = %FadeTimer

var _physics_on: bool = true:
	set(value):
		_physics_on = value
		toggle_physics(_physics_on)

func _ready():
	fade_timer.timeout.connect(fade_away)


func toggle_physics(value: bool) -> void:
	fade_timer.paused = not value

func fade_away() -> void:
	self.queue_free()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("TogglePhysics"):
		_physics_on = !_physics_on