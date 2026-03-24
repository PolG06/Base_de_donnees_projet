extends Control

# Sélection de personnage :
# - instancie un PlayerCharacter dans un SubViewport 3D pour l'aperçu rotatif
# - remplit la grille des skins à partir de GameState.OPTIONS_PERSONNAGE
# - permet de saisir le pseudo, de choisir un skin et lance la scène de jeu
#   (ou retour aux menus) en conservant les choix dans GameState.

const PREVIEW_PLAYER_SCENE := preload("res://scenes/player_character.tscn")

@onready var etiquette_titre: Label = $MarginContainer/RootColumn/MainRow/PreviewPanel/PreviewMargin/PreviewColumn/TitleLabel
@onready var etiquette_nom_apercu: Label = $MarginContainer/RootColumn/MainRow/PreviewPanel/PreviewMargin/PreviewColumn/SelectedNameLabel
@onready var viewport_apercu: SubViewport = $MarginContainer/RootColumn/MainRow/PreviewPanel/PreviewMargin/PreviewColumn/ViewportFrame/SubViewportContainer/SubViewport
@onready var etiquette_conseil: Label = $MarginContainer/RootColumn/MainRow/OptionsPanel/OptionsMargin/OptionsColumn/HintLabel
@onready var grille_options: GridContainer = $MarginContainer/RootColumn/MainRow/OptionsPanel/OptionsMargin/OptionsColumn/ScrollContainer/OptionsGrid
@onready var champ_pseudo: LineEdit = $MarginContainer/RootColumn/PseudoRow/PseudoLineEdit
@onready var bouton_commencer: Button = $MarginContainer/RootColumn/BottomRow/StartButton
@onready var bouton_retour: Button = $MarginContainer/RootColumn/BottomRow/BackButton

var joueur_apercu: PlayerCharacter
var boutons_options: Array[Button] = []

func _ready() -> void:
	# Applique la langue, construit l'aperçu 3D, liste les options et connecte les boutons.
	_appliquer_traductions()
	_construire_apercu()
	_construire_boutons_options()
	bouton_commencer.pressed.connect(_sur_commencer_presse)
	bouton_retour.pressed.connect(_sur_retour_presse)
	champ_pseudo.text = GameState.obtenir_nom_joueur_humain()
	champ_pseudo.text_changed.connect(_sur_pseudo_change)
	_rafraichir_selection()
	MenuAudio.connecter_boutons(self)
	MenuMusic.jouer_musique_menu()
	_prendre_focus_option_selectionnee()

func _process(delta: float) -> void:
	# Fait lentement tourner le modèle d'aperçu.
	if joueur_apercu != null:
		joueur_apercu.rotate_y(delta * 0.9)

func _appliquer_traductions() -> void:
	# Met à jour les libellés de l'écran de sélection.
	etiquette_titre.text = GameState.cle_traduction("character_title")
	etiquette_conseil.text = GameState.cle_traduction("character_hint")
	bouton_commencer.text = GameState.cle_traduction("character_start")
	bouton_retour.text = GameState.cle_traduction("common_back")

func _construire_apercu() -> void:
	# Instancie un SubViewport 3D (caméra, lumières, sol) et un PlayerCharacter d'aperçu.
	var root: Node3D = Node3D.new()
	viewport_apercu.add_child(root)

	var camera: Camera3D = Camera3D.new()
	camera.current = true
	root.add_child(camera)
	# look_at_from_position ne nécessite pas que le n�"ud soit déjà dans l'arbre.
	camera.look_at_from_position(Vector3(0, 1.8, 4.8), Vector3(0, 1.2, 0), Vector3.UP)

	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 30, 0)
	light.light_energy = 2.0
	root.add_child(light)

	var fill: OmniLight3D = OmniLight3D.new()
	fill.position = Vector3(0, 2.0, 2.2)
	fill.light_energy = 1.5
	root.add_child(fill)

	var floor: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(4, 0.2, 4)
	floor.mesh = mesh
	floor.position = Vector3(0, -0.1, 0)
	var floor_material: StandardMaterial3D = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.35, 0.35, 0.38)
	floor.material_override = floor_material
	root.add_child(floor)

	joueur_apercu = PREVIEW_PLAYER_SCENE.instantiate() as PlayerCharacter
	joueur_apercu.nom_joueur = "Preview"
	root.add_child(joueur_apercu)
	joueur_apercu.global_position = Vector3(0, 0, 0)

func _construire_boutons_options() -> void:
	# Remplit la grille avec un bouton par skin disponible.
	for child: Node in grille_options.get_children():
		child.queue_free()
	boutons_options.clear()

	for i: int in range(GameState.OPTIONS_PERSONNAGE.size()):
		var option: Dictionary = GameState.OPTIONS_PERSONNAGE[i]
		var button: Button = Button.new()
		button.text = GameState.obtenir_nom_personnage(option)
		button.custom_minimum_size = Vector2(0, 64)
		button.modulate = option["body_color"]
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_sur_option_presse.bind(i))
		grille_options.add_child(button)
		boutons_options.append(button)

func _sur_option_presse(index: int) -> void:
	# Sélectionne le skin, actualise l'aperçu et reprend le focus sur le bouton choisi.
	GameState.selectionner_personnage(index)
	_rafraichir_selection()
	MenuAudio.connecter_boutons(self)
	MenuMusic.jouer_musique_menu()
	_prendre_focus_option_selectionnee()

func _rafraichir_selection() -> void:
	# Met à jour l'aperçu 3D (nom/couleurs) et l'état des boutons selon la sélection.
	var selected: Dictionary = GameState.obtenir_personnage_selectionne()
	var selected_name: String = GameState.obtenir_nom_personnage(selected)
	etiquette_nom_apercu.text = GameState.cle_traduction("character_selected_color") % selected_name
	joueur_apercu.nom_joueur = selected_name
	joueur_apercu.couleur_joueur = selected["body_color"]
	joueur_apercu.couleur_peau = selected.get("skin_color", selected.get("couleur_peau", Color.WHITE))
	joueur_apercu.couleur_accent = selected.get("accent_color", selected.get("couleur_accent", Color.WHITE))
	joueur_apercu.reconstruire_visuels()
	for i: int in range(boutons_options.size()):
		boutons_options[i].disabled = i == GameState.indice_personnage_selectionne
		boutons_options[i].text = GameState.obtenir_nom_personnage(GameState.OPTIONS_PERSONNAGE[i])

func _sur_pseudo_change(text: String) -> void:
	# Sauvegarde le pseudo saisi dans GameState.
	GameState.definir_nom_joueur_humain(text)

func _prendre_focus_option_selectionnee() -> void:
	# Donne le focus clavier au bouton du skin sélectionné.
	if GameState.indice_personnage_selectionne >= 0 and GameState.indice_personnage_selectionne < boutons_options.size():
		boutons_options[GameState.indice_personnage_selectionne].call_deferred("grab_focus")

func _sur_commencer_presse() -> void:
	# Lance la scène de jeu principale.
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _sur_retour_presse() -> void:
	# Retour à l'écran précédent selon le mode choisi.
	if GameState.mode_jeu_selectionne == GameState.MODE_JEU_SOLO:
		get_tree().change_scene_to_file("res://scenes/solo_setup.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/mode_select.tscn")
