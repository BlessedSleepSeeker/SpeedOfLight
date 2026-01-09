extends Node3D
class_name SolarSystemGenerator

@export var use_thread: bool = true
@export var max_boids_loops: int = 100

@export var verbose_print: bool = true

@export_group("Stars Parameters")
@export var star_min_amount: int = 1
@export var star_max_amount: int = 1
@export var star_scene: PackedScene = preload("res://world/stars/Star.tscn")
var star_amount: int = 0
var stars: Array[Star] = []

@export_group("Planets Parameters")
@export var planet_min_amount: int = 5
@export var planet_max_amount: int = 10
@export var planet_scene: PackedScene = preload("res://world/planets/Planet.tscn")
var planet_amount: int = 0
var planets: Array[Planet] = []

@onready var infinite_worlds: bool = not OS.has_feature("web")

var celestial_bodies_without_center_star: Array[CelestialBody] = []

var marked_for_death: bool = false

var gen_thread: Thread
var gen_mutex: Mutex

signal generation_finished
signal can_register_celestial_bodies

func _ready():
	if verbose_print:
		print("Starting Solar System %s ! Using thread ? %s" % [self.name, infinite_worlds])
	if use_thread && infinite_worlds:
		gen_thread = Thread.new()
		gen_mutex = Mutex.new()
		gen_thread.start(generate_system)
	else:
		generate_system()

func generate_system() -> void:
	star_amount = RngManager.randi_range_safe(star_min_amount, star_max_amount)
	planet_amount = RngManager.randi_range_safe(planet_min_amount, planet_max_amount)
	if verbose_print:
		print_debug("Generating Star System with %d stars and %d planets" % [star_amount, planet_amount])
	generate_stars()
	await get_tree().physics_frame
	generate_planets()
	await get_tree().physics_frame
	can_register_celestial_bodies.emit()
	place_stars()
	place_planets()
	await get_tree().physics_frame
	boids_loop(0)
	generation_finished.emit()

func generate_stars() -> void:
	if verbose_print:
		print("Generating Stars for %s !" % self.name)
	var iter: int = 0
	if infinite_worlds:
		gen_mutex.lock()
	for i in range(star_amount):
		var star_inst: Star = star_scene.instantiate()
		star_inst.generate()
		if infinite_worlds:
			stars.append.call_deferred(star_inst)
			self.call_deferred("add_child", star_inst)
		else:
			stars.append(star_inst)
			self.add_child(star_inst)
		if verbose_print:
			print("Generated star %s %d" % [star_inst.name, iter])
		if iter == 0:
			star_inst.randomize_offset()
		else:
			celestial_bodies_without_center_star.append.call_deferred(star_inst)

		iter += 1
	if infinite_worlds:
		gen_mutex.unlock()

func generate_planets() -> void:
	if infinite_worlds:
		gen_mutex.lock()
	for i in range(planet_amount):
		var planet_inst: Planet = planet_scene.instantiate()
		planet_inst.generate()
		if infinite_worlds:
			planets.append.call_deferred(planet_inst)
			celestial_bodies_without_center_star.append.call_deferred(planet_inst)
			self.call_deferred("add_child", planet_inst)
		else:
			planets.append(planet_inst)
			celestial_bodies_without_center_star.append(planet_inst)
			self.add_child(planet_inst)
		var parent_star: Star = stars[RngManager.randi_range_safe(0, stars.size() - 1)]
		planet_inst.orbiting_around = parent_star
		if verbose_print:
			print("Generated planet %s orbiting around %s" % [planet_inst.name, planet_inst.orbiting_around.name])
	if infinite_worlds:
		gen_mutex.unlock()

func place_stars() -> void:
	var i: int = 0
	if infinite_worlds:
		gen_mutex.lock()
	for star: Star in stars:
		if i != 0:
			star.set_random_position()
		i += 1
	if infinite_worlds:
		gen_mutex.unlock()

func place_planets() -> void:
	if infinite_worlds:
		gen_mutex.lock()
	for planet: Planet in planets:
		#await get_tree().create_timer(0.1).timeout
		planet.set_random_position()
	if infinite_worlds:
		gen_mutex.unlock()

func boids_loop(loop_number: int) -> void:
	#await get_tree().create_timer(0.01).timeout
	if verbose_print:
		print("Boids Loop %d" % loop_number)
	if loop_number >= max_boids_loops:
		return
	var loop_again: bool = false
	for celestial_body: CelestialBody in celestial_bodies_without_center_star:
		if celestial_body.boids_check_distances(celestial_bodies_without_center_star):
			loop_again = true
	if loop_again:
		boids_loop(loop_number + 1)

func _exit_tree():
	if infinite_worlds:
		gen_thread.wait_to_finish()
