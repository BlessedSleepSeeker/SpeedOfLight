extends Node3D
class_name SolarSystemGenerator

@export var use_thread: bool = true
@export var max_distance_before_unloading: float = 10000
@export var max_boids_loops: int = 100

@export var verbose_print: bool = false

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

var celestial_bodies_without_center_star: Array[CelestialBody] = []

var gen_thread: Thread
var gen_mutex: Mutex

signal generation_finished
signal can_register_celestial_bodies

func _ready():
	if print_verbose:
		print("Starting Solar System %s ! Using thread ? %s" % [self.name, use_thread])
	if use_thread:
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
	await get_tree().process_frame
	generate_planets()
	await get_tree().process_frame
	can_register_celestial_bodies.emit()
	place_stars()
	await place_planets()
	stars.front().activate_camera()
	boids_loop(0)
	generation_finished.emit()



func generate_stars() -> void:
	if print_verbose:
		print("Generating Stars for %s !" % self.name)
	var iter: int = 0
	gen_mutex.lock()
	for i in range(star_amount):
		var star_inst: Star = star_scene.instantiate()
		star_inst.generate()
		stars.append.call_deferred(star_inst)
		self.call_deferred("add_child", star_inst)
		#if verbose_print:
		print("Generated star %s %d" % [star_inst.name, iter])
		if iter != 0:
			celestial_bodies_without_center_star.append.call_deferred(star_inst)
		iter += 1
	gen_mutex.unlock()

func generate_planets() -> void:
	gen_mutex.lock()
	for i in range(planet_amount):
		var planet_inst: Planet = planet_scene.instantiate()
		planet_inst.generate()
		planets.append.call_deferred(planet_inst)
		celestial_bodies_without_center_star.append.call_deferred(planet_inst)
		var parent_star: Star = stars[RngManager.randi_range_safe(0, stars.size() - 1)]
		self.call_deferred("add_child", planet_inst)
		planet_inst.orbiting_around = parent_star
		if verbose_print:
			print("Generated planet %s orbiting around %s" % [planet_inst.name, planet_inst.orbiting_around.name])
	gen_mutex.unlock()

func place_stars() -> void:
	var i: int = 0
	gen_mutex.lock()
	for star: Star in stars:
		if i != 0:
			star.set_random_position()
		i += 1
	gen_mutex.unlock()

func place_planets() -> void:
	gen_mutex.lock()
	for planet: Planet in planets:
		await get_tree().create_timer(0.1).timeout
		planet.set_random_position()
	gen_mutex.unlock()

func boids_loop(loop_number: int) -> void:
	#await get_tree().create_timer(0.2).timeout
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
	gen_thread.wait_to_finish()
