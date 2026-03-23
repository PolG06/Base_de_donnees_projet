extends Node

# Gestionnaire unique des musiques de menu et de jeu :
# - conserve un AudioStreamPlayer persistant (process_mode ALWAYS)
# - propose `jouer_musique_menu` et `jouer_musique_jeu` pour lancer la bonne piste
# - s'assure qu'une seule musique tourne à la fois en changeant le stream courant.

const MUSIQUE_MENU := preload("res://assets/menu_music.mp3")
const MUSIQUE_JEU := preload("res://assets/game_music.mp3")

var lecteur_musique: AudioStreamPlayer

func _ready() -> void:
	# Crée un lecteur persistant (process ALWAYS) pour les musiques de menu/jeu.
	process_mode = Node.PROCESS_MODE_ALWAYS
	lecteur_musique = AudioStreamPlayer.new()
	lecteur_musique.bus = "Master"
	lecteur_musique.volume_db = -10.0
	lecteur_musique.autoplay = false
	lecteur_musique.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(lecteur_musique)

func jouer_musique_menu() -> void:
	# Démarre la piste de menu si nécessaire.
	_lancer_piste(MUSIQUE_MENU)

func jouer_musique_jeu() -> void:
	# Démarre la piste de jeu si nécessaire.
	_lancer_piste(MUSIQUE_JEU)

func arreter_musique() -> void:
	# Stoppe toute lecture en cours.
	if lecteur_musique == null:
		return
	lecteur_musique.stop()

func _lancer_piste(piste: AudioStream) -> void:
	# Change de piste proprement et lance la lecture.
	if lecteur_musique == null or piste == null:
		return
	if lecteur_musique.stream != piste:
		lecteur_musique.stop()
		lecteur_musique.stream = piste
	lecteur_musique.stream_paused = false
	if not lecteur_musique.playing:
		lecteur_musique.play()
