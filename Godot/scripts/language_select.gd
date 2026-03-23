extends Control

@onready var etiquette_titre: Label = $CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var etiquette_sous_titre: Label = $CenterContainer/Panel/VBoxContainer/SubtitleLabel
@onready var etiquette_langue_actuelle: Label = $CenterContainer/Panel/VBoxContainer/CurrentLanguageLabel
@onready var bouton_francais: Button = $CenterContainer/Panel/VBoxContainer/FrenchButton
@onready var bouton_anglais: Button = $CenterContainer/Panel/VBoxContainer/EnglishButton
@onready var bouton_retour: Button = $CenterContainer/Panel/VBoxContainer/BackButton

func _ready() -> void:
	_appliquer_traductions()
	bouton_francais.pressed.connect(_sur_francais_presse)
	bouton_anglais.pressed.connect(_sur_anglais_presse)
	bouton_retour.pressed.connect(_sur_retour_presse)
	MenuAudio.connecter_boutons(self)
	MenuMusic.jouer_musique_menu()
	bouton_francais.call_deferred("grab_focus")

func _appliquer_traductions() -> void:
	etiquette_titre.text = GameState.cle_traduction("language_title")
	etiquette_sous_titre.text = GameState.cle_traduction("language_subtitle")
	etiquette_langue_actuelle.text = GameState.cle_traduction("language_current") % GameState.obtenir_nom_langue(GameState.langue_selectionnee)
	bouton_francais.text = GameState.cle_traduction("language_french")
	bouton_anglais.text = GameState.cle_traduction("language_english")
	bouton_retour.text = GameState.cle_traduction("common_back")
	bouton_francais.disabled = GameState.langue_selectionnee == GameState.LANGUE_FR
	bouton_anglais.disabled = GameState.langue_selectionnee == GameState.LANGUE_EN

func _sur_francais_presse() -> void:
	GameState.definir_langue(GameState.LANGUE_FR)
	_appliquer_traductions()

func _sur_anglais_presse() -> void:
	GameState.definir_langue(GameState.LANGUE_EN)
	_appliquer_traductions()

func _sur_retour_presse() -> void:
	get_tree().change_scene_to_file("res://scenes/menu_main.tscn")
