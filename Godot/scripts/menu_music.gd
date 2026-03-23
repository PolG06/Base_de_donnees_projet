extends Node

const MUSIQUE_MENU := preload("res://assets/menu_music.mp3")
const MUSIQUE_JEU := preload("res://assets/game_music.mp3")

var lecteur_musique: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	lecteur_musique = AudioStreamPlayer.new()
	lecteur_musique.bus = "Master"
	lecteur_musique.volume_db = -10.0
	lecteur_musique.autoplay = false
	lecteur_musique.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(lecteur_musique)

func jouer_musique_menu() -> void:
	_lancer_piste(MUSIQUE_MENU)

func jouer_musique_jeu() -> void:
	_lancer_piste(MUSIQUE_JEU)

func arreter_musique() -> void:
	if lecteur_musique == null:
		return
	lecteur_musique.stop()

func _lancer_piste(piste: AudioStream) -> void:
	if lecteur_musique == null or piste == null:
		return
	if lecteur_musique.stream != piste:
		lecteur_musique.stop()
		lecteur_musique.stream = piste
	lecteur_musique.stream_paused = false
	if not lecteur_musique.playing:
		lecteur_musique.play()
