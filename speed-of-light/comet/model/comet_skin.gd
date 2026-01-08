extends Node3D
class_name CometSkin

@export var play_animation_on_load: String = ""
@onready var animation_tree: AnimationTree = %AnimationTree
@onready var state_machine : AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

@export var highlight_material: ShaderMaterial = preload("res://camera/shaders/highlight_material.tres")
@export var highlight_color: Color = Color8(255, 255, 255)
@export var highlight_color_off: Color = Color8(255, 255, 255, 0)
@export var highlight_tween_time: float = 0.4

@onready var model: Node3D = %CometMesh

func _ready():
	add_highlight_material_on_next_pass()
	highlight_material.set_shader_parameter("outline_color", highlight_color_off)
	if play_animation_on_load:
		travel(play_animation_on_load)

func travel(state_name: String) -> void:
	state_machine.travel(state_name)

func add_highlight_material_on_next_pass() -> void:
	for child in model.get_children():
		if child is MeshInstance3D:
			var material: Material = child.mesh.get("surface_0/material")
			while material:
				if material.next_pass == null && material != highlight_material:
					material.next_pass = highlight_material
					break
				material = material.next_pass

func toggle_highlight(direction: bool) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(highlight_material, "shader_parameter/outline_color", highlight_color if direction else highlight_color_off, highlight_tween_time)

func look_at_velocity(velocity: Vector3, prev_velocity: Vector3) -> void:
	var _aiming_to: Vector3 = (velocity - prev_velocity)
	#self.rotation = look_at_from_position()
	# var node: Node3D = Node3D.new()
	# if velocity != Vector3.ZERO:
	#self.look_at_from_position(self.global_position, aiming_to, Vector3.MODEL_FRONT, true)
	self.look_at(velocity)
	# var tween: Tween = create_tween()
	# tween.tween_property(self, "rotation", node.rotation, rotation_speed * _delta)
