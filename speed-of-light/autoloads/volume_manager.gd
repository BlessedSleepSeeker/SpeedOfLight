extends Node

@export_range(0.1, 10, 0.1) var crossfade_duration: float = 1.0
@export var crossfade_out_volume: float = -40.0
@export var crossfade_in_volume: float = 0.0

@onready var music_player: AudioStreamPlayer = %MusicPlayer

@onready var audio_player1: AudioStreamPlayer = %MusicPlayer
@onready var audio_player2: AudioStreamPlayer = %MusicPlayer2

@onready var current_player: AudioStreamPlayer = %MusicPlayer
@onready var unused_player: AudioStreamPlayer = %MusicPlayer2

func _ready():
	self.process_mode = self.PROCESS_MODE_ALWAYS

func _unhandled_input(_event):
	# if _event.is_action_pressed("ToggleSFX"):
	# 	var bus = AudioServer.get_bus_index("SFX")
	# 	AudioServer.set_bus_mute(bus, not AudioServer.is_bus_mute(bus))
	if _event.is_action_pressed("ToggleBGM"):
		var bus = AudioServer.get_bus_index("BGM")
		AudioServer.set_bus_mute(bus, not AudioServer.is_bus_mute(bus))


func play_bgm(audio_stream: AudioStream, from_position: float = 0, loop: bool = true, loop_delay: float = 0, remaining_loops: int = -1) -> void:
	if audio_stream == current_player.stream && current_player.playing:
		return
	unused_player.stream = audio_stream
	unused_player.play(from_position)
	var fade_current_tween: Tween = create_tween()
	var fade_unused_tween: Tween = create_tween()

	fade_current_tween.tween_property(current_player, "volume_db", crossfade_out_volume, crossfade_duration)
	fade_unused_tween.tween_property(unused_player, "volume_db", crossfade_in_volume, crossfade_duration)

	var switch = current_player
	current_player = unused_player
	unused_player = switch
	if not current_player.finished.is_connected(_on_bgm_finished) && loop:
		current_player.finished.connect(_on_bgm_finished.bind(audio_stream, from_position, loop, loop_delay, remaining_loops), CONNECT_ONE_SHOT)
	if unused_player.finished.is_connected(_on_bgm_finished):
		unused_player.finished.disconnect(_on_bgm_finished)
	fade_current_tween.finished.connect(stop_unused)

func _on_bgm_finished(bgm: AudioStream, from_position: float = 0, loop: bool = true, loop_delay: float = 0, remaining_loops: int = -1) -> void:
	remaining_loops = remaining_loops - 1
	if loop_delay > 0:
		await get_tree().create_timer(loop_delay).timeout
	if loop && remaining_loops != 0:
		play_bgm(bgm, from_position, loop, loop_delay, remaining_loops)

func stop_unused() -> void:
	unused_player.stop()