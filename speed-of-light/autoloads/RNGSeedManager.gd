extends Node

signal main_seed_changed(new_value: String)

var main_seed: String = '':
	set(value):
		main_seed = value
		if value != '':
			main_seed_changed.emit(value)

@onready var rng: RandomNumberGenerator = RandomNumberGenerator.new()
@onready var rng_mutex: Mutex

# Called when the node enters the scene tree for the first time.
func _ready():
	rng_mutex = Mutex.new()
	generate_seeds()

func generate_seeds():
	if (main_seed == ''):
		rng.randomize()
		rng.seed = hash(rng.randi())
		main_seed = str(rng.seed)
		print_debug("Main Seed : ", main_seed)
	else:
		rng.seed = int(main_seed)

func reset_seeds():
	main_seed = ''
	generate_seeds()

func randf_range_safe(from: float, to: float) -> float:
	var rng_value: float = 0.0
	rng_mutex.lock()
	rng_value = rng.randf_range(from, to)
	rng_mutex.unlock()
	return rng_value

func randi_range_safe(from: int, to: int) -> int:
	var rng_value: int = 0
	rng_mutex.lock()
	rng_value = rng.randi_range(from, to)
	rng_mutex.unlock()
	return rng_value