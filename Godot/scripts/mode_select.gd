extends Control

# �?cran de choix du mode :
# - écrit le mode sélectionné (solo ou multijoueur) dans GameState
# - affiche un rappel de configuration (bots non disponibles en multi)
# - renvoie vers la configuration solo ou le retour menu.

@onready var etiquette_titre: Label = $CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var etiquette_sous_titre: Label = $CenterContainer/Panel/VBoxContainer/SubtitleLabel
@onready var bouton_solo: Button = $CenterContainer/Panel/VBoxContainer/SoloButton
@onready var bouton_multijoueur: Button = $CenterContainer/Panel/VBoxContainer/MultiplayerButton
@onready var etiquette_info: Label = $CenterContainer/Panel/VBoxContainer/InfoLabel
@onready var bouton_retour: Button = $CenterContainer/Panel/VBoxContainer/BackButton

func _ready() -> void:
	# Texte localisé, branche les boutons et joue la musique de menu.
	_appliquer_traductions()
	bouton_solo.pressed.connect(_sur_solo_presse)
	bouton_multijoueur.pressed.connect(_sur_multijoueur_presse)
	bouton_retour.pressed.connect(_sur_retour_presse)
	MenuAudio.connecter_boutons(self)
	MenuMusic.jouer_musique_menu()
	bouton_solo.call_deferred("grab_focus")

func _appliquer_traductions() -> void:
	# Met à jour les libellés selon la langue.
	etiquette_titre.text = GameState.cle_traduction("mode_select_title")
	etiquette_sous_titre.text = GameState.cle_traduction("mode_select_subtitle")
	bouton_solo.text = "Solo"
	bouton_multijoueur.text = GameState.cle_traduction("mode_select_multiplayer")
	bouton_retour.text = GameState.cle_traduction("common_back")

func _sur_solo_presse() -> void:
	# Choisit le mode solo et ouvre la config bots/difficulté.
	GameState.selectionner_mode_jeu(GameState.MODE_JEU_SOLO)
	get_tree().change_scene_to_file("res://scenes/solo_setup.tscn")

func _sur_multijoueur_presse() -> void:
	# Choisit le mode multijoueur (placeholder : message d'info).
	GameState.selectionner_mode_jeu(GameState.MODE_JEU_MULTIJOUEUR)
	etiquette_info.text = GameState.cle_traduction("mode_select_multiplayer_soon")

func _sur_retour_presse() -> void:
	# Retourne au menu principal.
	get_tree().change_scene_to_file("res://scenes/menu_main.tscn")
