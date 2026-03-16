extends Control

@onready var title_label: Label = $CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/Panel/VBoxContainer/SubtitleLabel
@onready var bot_count_text_label: Label = $CenterContainer/Panel/VBoxContainer/BotCountRow/BotCountText
@onready var hint_label: Label = $CenterContainer/Panel/VBoxContainer/HintLabel
@onready var difficulty_label: Label = $CenterContainer/Panel/VBoxContainer/DifficultyRow/DifficultyText
@onready var beginner_button: Button = $CenterContainer/Panel/VBoxContainer/DifficultyRow/DifficultyButtons/BeginnerButton
@onready var normal_button: Button = $CenterContainer/Panel/VBoxContainer/DifficultyRow/DifficultyButtons/NormalButton
@onready var hard_button: Button = $CenterContainer/Panel/VBoxContainer/DifficultyRow/DifficultyButtons/HardButton
@onready var bot_count_label: Label = $CenterContainer/Panel/VBoxContainer/BotCountRow/BotCountValue
@onready var minus_button: Button = $CenterContainer/Panel/VBoxContainer/BotCountRow/MinusButton
@onready var plus_button: Button = $CenterContainer/Panel/VBoxContainer/BotCountRow/PlusButton
@onready var continue_button: Button = $CenterContainer/Panel/VBoxContainer/ContinueButton
@onready var back_button: Button = $CenterContainer/Panel/VBoxContainer/BackButton

func _ready() -> void:
	_apply_translations()
	minus_button.pressed.connect(_on_minus_pressed)
	plus_button.pressed.connect(_on_plus_pressed)
	beginner_button.pressed.connect(_on_difficulty_pressed.bind(GameState.BOT_DIFFICULTY_BEGINNER))
	normal_button.pressed.connect(_on_difficulty_pressed.bind(GameState.BOT_DIFFICULTY_NORMAL))
	hard_button.pressed.connect(_on_difficulty_pressed.bind(GameState.BOT_DIFFICULTY_HARD))
	continue_button.pressed.connect(_on_continue_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_refresh_bot_count()
	_refresh_difficulty_buttons()
	MenuAudio.connect_buttons(self)
	MenuMusic.play_menu_music()
	minus_button.call_deferred("grab_focus")

func _apply_translations() -> void:
	title_label.text = GameState.tr_key("solo_title")
	subtitle_label.text = GameState.tr_key("solo_subtitle")
	bot_count_text_label.text = GameState.tr_key("solo_bots_label")
	hint_label.text = GameState.tr_key("solo_hint")
	difficulty_label.text = GameState.tr_key("solo_difficulty_label")
	beginner_button.text = GameState.tr_key("difficulty_beginner")
	normal_button.text = GameState.tr_key("difficulty_normal")
	hard_button.text = GameState.tr_key("difficulty_hard")
	continue_button.text = GameState.tr_key("common_continue")
	back_button.text = GameState.tr_key("common_back")

func _on_minus_pressed() -> void:
	GameState.set_bot_count(GameState.selected_bot_count - 1)
	_refresh_bot_count()

func _on_plus_pressed() -> void:
	GameState.set_bot_count(GameState.selected_bot_count + 1)
	_refresh_bot_count()

func _on_difficulty_pressed(value: String) -> void:
	GameState.set_bot_difficulty(value)
	_refresh_difficulty_buttons()

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/mode_select.tscn")

func _refresh_bot_count() -> void:
	bot_count_label.text = str(GameState.selected_bot_count)
	minus_button.disabled = GameState.selected_bot_count <= GameState.MIN_BOT_COUNT
	plus_button.disabled = GameState.selected_bot_count >= GameState.MAX_BOT_COUNT

func _refresh_difficulty_buttons() -> void:
	beginner_button.disabled = GameState.selected_bot_difficulty == GameState.BOT_DIFFICULTY_BEGINNER
	normal_button.disabled = GameState.selected_bot_difficulty == GameState.BOT_DIFFICULTY_NORMAL
	hard_button.disabled = GameState.selected_bot_difficulty == GameState.BOT_DIFFICULTY_HARD

