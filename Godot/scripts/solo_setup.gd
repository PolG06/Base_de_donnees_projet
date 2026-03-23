extends Control

# Configuration du mode solo :
# - ajuste le nombre de bots (slider) et leur difficulté (boutons)
# - enregistre ces choix dans GameState
# - propose de passer à la sélection de personnage ou de revenir en arrière.

@onready var etiquette_titre: Label = $CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var etiquette_sous_titre: Label = $CenterContainer/Panel/VBoxContainer/SubtitleLabel
@onready var etiquette_libelle_bots: Label = $CenterContainer/Panel/VBoxContainer/BotCountRow/BotCountText
@onready var etiquette_conseil: Label = $CenterContainer/Panel/VBoxContainer/HintLabel
@onready var etiquette_difficulte: Label = $CenterContainer/Panel/VBoxContainer/DifficultyRow/DifficultyText
@onready var bouton_debutant: Button = $CenterContainer/Panel/VBoxContainer/DifficultyRow/DifficultyButtons/BeginnerButton
@onready var bouton_normal: Button = $CenterContainer/Panel/VBoxContainer/DifficultyRow/DifficultyButtons/NormalButton
@onready var bouton_difficile: Button = $CenterContainer/Panel/VBoxContainer/DifficultyRow/DifficultyButtons/HardButton
@onready var etiquette_compteur_bots: Label = $CenterContainer/Panel/VBoxContainer/BotCountRow/BotCountValue
@onready var bouton_moins: Button = $CenterContainer/Panel/VBoxContainer/BotCountRow/MinusButton
@onready var bouton_plus: Button = $CenterContainer/Panel/VBoxContainer/BotCountRow/PlusButton
@onready var bouton_continuer: Button = $CenterContainer/Panel/VBoxContainer/ContinueButton
@onready var bouton_retour: Button = $CenterContainer/Panel/VBoxContainer/BackButton

func _ready() -> void:
	# Texte localisé, branche boutons (+/- bots, difficultés, navigation) et synchronise l'état initial.
	_appliquer_traductions()
	bouton_moins.pressed.connect(_sur_moins_presse)
	bouton_plus.pressed.connect(_sur_plus_presse)
	bouton_debutant.pressed.connect(_sur_difficulte_presse.bind(GameState.BOT_DIFFICULTE_DEBUTANT))
	bouton_normal.pressed.connect(_sur_difficulte_presse.bind(GameState.BOT_DIFFICULTE_NORMAL))
	bouton_difficile.pressed.connect(_sur_difficulte_presse.bind(GameState.BOT_DIFFICULTE_DIFFICILE))
	bouton_continuer.pressed.connect(_sur_continuer_presse)
	bouton_retour.pressed.connect(_sur_retour_presse)
	_rafraichir_compteur_bots()
	_rafraichir_boutons_difficulte()
	MenuAudio.connecter_boutons(self)
	MenuMusic.jouer_musique_menu()
	bouton_moins.call_deferred("grab_focus")

func _appliquer_traductions() -> void:
	# Met à jour titres, libellés et boutons selon la langue courante.
	etiquette_titre.text = GameState.cle_traduction("solo_title")
	etiquette_sous_titre.text = GameState.cle_traduction("solo_subtitle")
	etiquette_libelle_bots.text = GameState.cle_traduction("solo_bots_label")
	etiquette_conseil.text = GameState.cle_traduction("solo_hint")
	etiquette_difficulte.text = GameState.cle_traduction("solo_difficulty_label")
	bouton_debutant.text = GameState.cle_traduction("difficulty_beginner")
	bouton_normal.text = GameState.cle_traduction("difficulty_normal")
	bouton_difficile.text = GameState.cle_traduction("difficulty_hard")
	bouton_continuer.text = GameState.cle_traduction("common_continue")
	bouton_retour.text = GameState.cle_traduction("common_back")

func _sur_moins_presse() -> void:
	# Diminue le nombre de bots (GameState gère les bornes).
	GameState.definir_nombre_bots(GameState.nombre_bots_selectionne - 1)
	_rafraichir_compteur_bots()

func _sur_plus_presse() -> void:
	# Augmente le nombre de bots.
	GameState.definir_nombre_bots(GameState.nombre_bots_selectionne + 1)
	_rafraichir_compteur_bots()

func _sur_difficulte_presse(value: String) -> void:
	# Sélectionne la difficulté des bots et rafraîchit l'état des boutons.
	GameState.definir_difficulte_bots(value)
	_rafraichir_boutons_difficulte()

func _sur_continuer_presse() -> void:
	# Passe à la sélection de personnage.
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")

func _sur_retour_presse() -> void:
	# Retour à l'écran de sélection de mode.
	get_tree().change_scene_to_file("res://scenes/mode_select.tscn")

func _rafraichir_compteur_bots() -> void:
	# Met à jour compteur et (dés)active les boutons +/- selon limites.
	etiquette_compteur_bots.text = str(GameState.nombre_bots_selectionne)
	bouton_moins.disabled = GameState.nombre_bots_selectionne <= GameState.NB_BOTS_MIN
	bouton_plus.disabled = GameState.nombre_bots_selectionne >= GameState.NB_BOTS_MAX

func _rafraichir_boutons_difficulte() -> void:
	# Désactive le bouton correspondant à la difficulté actuelle.
	bouton_debutant.disabled = GameState.difficulte_bots_selectionnee == GameState.BOT_DIFFICULTE_DEBUTANT
	bouton_normal.disabled = GameState.difficulte_bots_selectionnee == GameState.BOT_DIFFICULTE_NORMAL
	bouton_difficile.disabled = GameState.difficulte_bots_selectionnee == GameState.BOT_DIFFICULTE_DIFFICILE




