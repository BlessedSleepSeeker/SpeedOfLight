extends StaticBody3D
class_name TailEntity

@onready var fade_timer: Timer = %FadeTimer
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var _physics_on: bool = true:
	set(value):
		_physics_on = value
		toggle_physics(_physics_on)

func _ready():
	fade_timer.timeout.connect(fade_away)

func reset() -> void:
	fade_timer.start()
	self.show()
	anim_player.stop()
	anim_player.play("idle")

func toggle_physics(value: bool) -> void:
	fade_timer.paused = not value

func fade_away() -> void:
	anim_player.play("fade_away")
	await anim_player.animation_finished
	self.hide()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("TogglePhysics"):
		_physics_on = !_physics_on
