extends Control

@onready var title_label: Label = $CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/Panel/VBoxContainer/SubtitleLabel
@onready var play_button: Button = $CenterContainer/Panel/VBoxContainer/PlayButton
@onready var settings_button: Button = $CenterContainer/Panel/VBoxContainer/SettingsButton
@onready var language_button: Button = $CenterContainer/Panel/VBoxContainer/LanguageButton
@onready var quit_button: Button = $CenterContainer/Panel/VBoxContainer/QuitButton

func _ready() -> void:
	_apply_translations()
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	language_button.pressed.connect(_on_language_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	MenuAudio.connect_buttons(self)
	MenuMusic.play_menu_music()
	play_button.call_deferred("grab_focus")

func _apply_translations() -> void:
	title_label.text = GameState.tr_key("main_title")
	subtitle_label.text = GameState.tr_key("main_subtitle")
	play_button.text = GameState.tr_key("menu_play")
	settings_button.text = GameState.tr_key("menu_settings")
	language_button.text = GameState.tr_key("menu_languages")
	quit_button.text = GameState.tr_key("menu_quit")

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/mode_select.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings_menu.tscn")

func _on_language_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/language_select.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

