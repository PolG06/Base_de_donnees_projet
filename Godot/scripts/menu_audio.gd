extends Node

# Utilitaires sonores pour les menus :
# - centralise la lecture du son de clic UI
# - fournit une fonction `connecter_boutons` pour brancher automatiquement le son
#   sur chaque bouton d'une scène.

const SON_CLIC := preload("res://assets/ui_click.mp3")

var lecteur_clic: AudioStreamPlayer

func _ready() -> void:
	# Instancie le lecteur audio de clic et l'attache à la scène.
	lecteur_clic = AudioStreamPlayer.new()
	lecteur_clic.stream = SON_CLIC
	lecteur_clic.bus = "Master"
	add_child(lecteur_clic)

func connecter_boutons(racine: Node) -> void:
	# Parcourt récursivement la hiérarchie et connecte tous les boutons trouvés.
	if racine == null:
		return
	if racine is Button:
		_connecter_bouton(racine as Button)
	for child: Node in racine.get_children():
		connecter_boutons(child)

func _connecter_bouton(bouton: Button) -> void:
	# Ajoute le signal pressed -> son de clic, avec un meta pour éviter les doublons.
	if bouton.has_meta("menu_audio_connected"):
		return
	bouton.set_meta("menu_audio_connected", true)
	bouton.pressed.connect(_jouer_clic)

func _jouer_clic() -> void:
	# Joue un clic court (redémarre si déjà en cours).
	if lecteur_clic == null:
		return
	lecteur_clic.stop()
	lecteur_clic.play()
