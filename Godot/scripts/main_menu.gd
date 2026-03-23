extends Control

@onready var etiquette_titre: Label = $CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var etiquette_sous_titre: Label = $CenterContainer/Panel/VBoxContainer/SubtitleLabel
@onready var bouton_jouer: Button = $CenterContainer/Panel/VBoxContainer/PlayButton
@onready var bouton_parametres: Button = $CenterContainer/Panel/VBoxContainer/SettingsButton
@onready var bouton_langues: Button = $CenterContainer/Panel/VBoxContainer/LanguageButton
@onready var bouton_scores: Button = $CenterContainer/Panel/VBoxContainer/ScoresButton
@onready var bouton_quitter: Button = $CenterContainer/Panel/VBoxContainer/QuitButton

func _ready() -> void:
	_appliquer_traductions()
	bouton_jouer.pressed.connect(_sur_jouer_presse)
	bouton_parametres.pressed.connect(_sur_parametres_presse)
	bouton_langues.pressed.connect(_sur_langues_presse)
	bouton_scores.pressed.connect(_sur_scores_presse)
	bouton_quitter.pressed.connect(_sur_quitter_presse)
	MenuAudio.connecter_boutons(self)
	MenuMusic.jouer_musique_menu()
	bouton_jouer.call_deferred("grab_focus")

func _appliquer_traductions() -> void:
	etiquette_titre.text = GameState.cle_traduction("main_title")
	etiquette_sous_titre.text = GameState.cle_traduction("main_subtitle")
	bouton_jouer.text = GameState.cle_traduction("menu_play")
	bouton_parametres.text = GameState.cle_traduction("menu_settings")
	bouton_langues.text = GameState.cle_traduction("menu_languages")
	bouton_scores.text = GameState.cle_traduction("menu_scores")
	bouton_quitter.text = GameState.cle_traduction("menu_quit")

func _sur_jouer_presse() -> void:
	get_tree().change_scene_to_file("res://scenes/mode_select.tscn")

func _sur_parametres_presse() -> void:
	get_tree().change_scene_to_file("res://scenes/settings_menu.tscn")

func _sur_langues_presse() -> void:
	get_tree().change_scene_to_file("res://scenes/language_select.tscn")

func _sur_scores_presse() -> void:
	get_tree().change_scene_to_file("res://scenes/scores_menu.tscn")

func _sur_quitter_presse() -> void:
	get_tree().quit()
