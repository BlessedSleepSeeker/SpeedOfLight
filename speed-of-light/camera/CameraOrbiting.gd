extends Node3D
class_name CameraOrbit

# Simple orbit camera rig control script

# control variables
@export var maxZoom: float = 60
@export var minZoom: float = 4
@export var zoomStep: float = 2
@export var zoomYStep: float = 0.15
@export var verticalSensitivity: float = 0.002
@export var horizontalSensitivity: float = 0.002
@export var camLerpSpeed: float = 16.0

@onready var camera: Camera3D = %Camera3D
# private variables
@onready var _springArm : SpringArm3D = $SpringArm3D
@onready var _curZoom : float = maxZoom
@onready var _is_pressed: bool = false


func _ready() -> void:
	pass

func make_current() -> void:
	camera.make_current()

func _input(event) -> void:
	if event is InputEventMouseMotion && _is_pressed:
		# rotate the rig around the target
		rotation.y -= event.relative.x * horizontalSensitivity
		rotation.y = wrapf(rotation.y, 0.0, TAU)
		
		rotation.x -= event.relative.y * verticalSensitivity
		rotation.x = wrapf(rotation.x, 0.0, TAU)
		
	if event is InputEventMouseButton:
		# change zoom level on mouse wheel rotation
		# this could be refactored to be based on an input action as well
		if Input.is_action_just_pressed("RotateCameraMouse"):
			_is_pressed = true
		if Input.is_action_just_released("RotateCameraMouse"):
			_is_pressed = false
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP and _curZoom > minZoom:
				_curZoom -= zoomStep
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and _curZoom < maxZoom:
				_curZoom += zoomStep

func _physics_process(delta) -> void:
	# zoom the camera accordingly
	_springArm.spring_length = lerp(_springArm.spring_length, _curZoom, delta * camLerpSpeed)
