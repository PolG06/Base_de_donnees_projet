extends Node

const SON_CLIC := preload("res://assets/ui_click.mp3")

var lecteur_clic: AudioStreamPlayer

func _ready() -> void:
	lecteur_clic = AudioStreamPlayer.new()
	lecteur_clic.stream = SON_CLIC
	lecteur_clic.bus = "Master"
	add_child(lecteur_clic)

func connecter_boutons(racine: Node) -> void:
	if racine == null:
		return
	if racine is Button:
		_connecter_bouton(racine as Button)
	for child: Node in racine.get_children():
		connecter_boutons(child)

func _connecter_bouton(bouton: Button) -> void:
	if bouton.has_meta("menu_audio_connected"):
		return
	bouton.set_meta("menu_audio_connected", true)
	bouton.pressed.connect(_jouer_clic)

func _jouer_clic() -> void:
	if lecteur_clic == null:
		return
	lecteur_clic.stop()
	lecteur_clic.play()
