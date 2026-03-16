extends Control

@onready var title_label: Label = $CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/Panel/VBoxContainer/SubtitleLabel
@onready var current_language_label: Label = $CenterContainer/Panel/VBoxContainer/CurrentLanguageLabel
@onready var french_button: Button = $CenterContainer/Panel/VBoxContainer/FrenchButton
@onready var english_button: Button = $CenterContainer/Panel/VBoxContainer/EnglishButton
@onready var back_button: Button = $CenterContainer/Panel/VBoxContainer/BackButton

func _ready() -> void:
	_apply_translations()
	french_button.pressed.connect(_on_french_pressed)
	english_button.pressed.connect(_on_english_pressed)
	back_button.pressed.connect(_on_back_pressed)
	MenuAudio.connect_buttons(self)
	MenuMusic.play_menu_music()
	french_button.call_deferred("grab_focus")

func _apply_translations() -> void:
	title_label.text = GameState.tr_key("language_title")
	subtitle_label.text = GameState.tr_key("language_subtitle")
	current_language_label.text = GameState.tr_key("language_current") % GameState.get_language_display_name(GameState.selected_language)
	french_button.text = GameState.tr_key("language_french")
	english_button.text = GameState.tr_key("language_english")
	back_button.text = GameState.tr_key("common_back")
	french_button.disabled = GameState.selected_language == GameState.LANGUAGE_FR
	english_button.disabled = GameState.selected_language == GameState.LANGUAGE_EN

func _on_french_pressed() -> void:
	GameState.set_language(GameState.LANGUAGE_FR)
	_apply_translations()

func _on_english_pressed() -> void:
	GameState.set_language(GameState.LANGUAGE_EN)
	_apply_translations()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu_main.tscn")

