extends Node

## AudioManager - Persistent music playback across scenes
## Registered as autoload in project.godot

var music_player: AudioStreamPlayer
var current_stream: AudioStream

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)

func play_music(stream: AudioStream, fade_in_duration: float = 1.0) -> void:
	if current_stream == stream and music_player.playing:
		return

	current_stream = stream
	music_player.stream = stream
	music_player.volume_db = -80.0
	music_player.play()

	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", 0.0, fade_in_duration)

func stop_music(fade_out_duration: float = 1.0) -> void:
	if not music_player.playing:
		return

	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -80.0, fade_out_duration)
	tween.tween_callback(music_player.stop)

func set_volume(volume_db: float) -> void:
	music_player.volume_db = volume_db

func crossfade_to(new_stream: AudioStream, duration: float = 2.0) -> void:
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -80.0, duration / 2.0)
	tween.tween_callback(func():
		current_stream = new_stream
		music_player.stream = new_stream
		music_player.play()
	)
	tween.tween_property(music_player, "volume_db", 0.0, duration / 2.0)

func is_playing() -> bool:
	return music_player.playing
