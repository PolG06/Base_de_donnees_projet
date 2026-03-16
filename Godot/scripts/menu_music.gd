extends Node

const MENU_MUSIC := preload("res://assets/menu_music.mp3")
const GAME_MUSIC := preload("res://assets/game_music.mp3")

var music_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.volume_db = -10.0
	music_player.autoplay = false
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_player)

func play_menu_music() -> void:
	_play_track(MENU_MUSIC)

func play_game_music() -> void:
	_play_track(GAME_MUSIC)

func stop_music() -> void:
	if music_player == null:
		return
	music_player.stop()

func _play_track(track: AudioStream) -> void:
	if music_player == null or track == null:
		return
	if music_player.stream != track:
		music_player.stop()
		music_player.stream = track
	music_player.stream_paused = false
	if not music_player.playing:
		music_player.play()
