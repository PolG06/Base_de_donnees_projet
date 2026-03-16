extends Control

@onready var title_label: Label = $CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/Panel/VBoxContainer/SubtitleLabel
@onready var solo_button: Button = $CenterContainer/Panel/VBoxContainer/SoloButton
@onready var multiplayer_button: Button = $CenterContainer/Panel/VBoxContainer/MultiplayerButton
@onready var info_label: Label = $CenterContainer/Panel/VBoxContainer/InfoLabel
@onready var back_button: Button = $CenterContainer/Panel/VBoxContainer/BackButton

func _ready() -> void:
	_apply_translations()
	solo_button.pressed.connect(_on_solo_pressed)
	multiplayer_button.pressed.connect(_on_multiplayer_pressed)
	back_button.pressed.connect(_on_back_pressed)
	MenuAudio.connect_buttons(self)
	MenuMusic.play_menu_music()
	solo_button.call_deferred("grab_focus")

func _apply_translations() -> void:
	title_label.text = GameState.tr_key("mode_select_title")
	subtitle_label.text = GameState.tr_key("mode_select_subtitle")
	solo_button.text = "Solo"
	multiplayer_button.text = GameState.tr_key("mode_select_multiplayer")
	back_button.text = GameState.tr_key("common_back")

func _on_solo_pressed() -> void:
	GameState.select_game_mode(GameState.GAME_MODE_SOLO)
	get_tree().change_scene_to_file("res://scenes/solo_setup.tscn")

func _on_multiplayer_pressed() -> void:
	GameState.select_game_mode(GameState.GAME_MODE_MULTIPLAYER)
	info_label.text = GameState.tr_key("mode_select_multiplayer_soon")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu_main.tscn")
