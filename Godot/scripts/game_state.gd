extends Node

const LANGUAGE_FR := "fr"
const LANGUAGE_EN := "en"
const GAME_MODE_SOLO := "solo"
const GAME_MODE_MULTIPLAYER := "multiplayer"
const BOT_DIFFICULTY_BEGINNER := "beginner"
const BOT_DIFFICULTY_NORMAL := "normal"
const BOT_DIFFICULTY_HARD := "hard"
const MIN_BOT_COUNT := 1
const MAX_BOT_COUNT := 6
var human_player_name_override: String = ""
const ACTION_BINDINGS := [
	{"id": "ui_up", "label_key": "action_move_forward"},
	{"id": "ui_down", "label_key": "action_move_backward"},
	{"id": "ui_left", "label_key": "action_move_left"},
	{"id": "ui_right", "label_key": "action_move_right"},
	{"id": "toggle_prone", "label_key": "action_prone"},
	{"id": "toggle_pause", "label_key": "action_pause"}
]

const TRANSLATIONS := {
	LANGUAGE_FR: {
		"main_title": "Pointe ton Bagay",
		"main_subtitle": "Blind shot en 3D",
		"menu_play": "Jouer",
		"menu_settings": "Parametres",
		"menu_languages": "Langues",
		"menu_quit": "Quitter",
		"language_title": "Langues",
		"language_subtitle": "Choisis la langue du jeu",
		"language_french": "Francais",
		"language_english": "Anglais",
		"language_current": "Langue actuelle : %s",
		"language_name_fr": "Francais",
		"language_name_en": "Anglais",
		"common_back": "Retour",
		"common_continue": "Continuer",
		"mode_select_title": "Choix du mode",
		"mode_select_subtitle": "Selectionne comment tu veux jouer",
		"mode_select_info_default": "Choisis un mode de jeu",
		"mode_select_multiplayer": "Multijoueurs",
		"mode_select_multiplayer_soon": "Le mode multijoueurs sera ajoute plus tard.",
		"solo_title": "Mode solo",
		"solo_subtitle": "Choisis le nombre de bots adverses",
		"solo_bots_label": "Bots :",
		"solo_hint": "Tu peux choisir entre 1 et 6 bots.",
		"solo_difficulty_label": "Difficulte :",
		"difficulty_beginner": "Debutant",
		"difficulty_normal": "Normal",
		"difficulty_hard": "Difficile",
		"character_title": "Choisis ton personnage",
		"character_hint": "Selectionne une couleur pour ton personnage avant de lancer la partie.",
		"character_selected_color": "Couleur choisie : %s",
		"character_start": "Lancer la partie",
		"settings_title": "Parametres",
		"settings_subtitle": "Clique sur une action pour choisir une nouvelle touche",
		"settings_action_header": "Action",
		"settings_binding_header": "Touches",
		"settings_status_default": "Clique sur une action pour changer sa touche clavier.",
		"settings_waiting": "Nouvelle touche clavier pour %s : appuie sur une touche. La touche manette reste %s.",
		"settings_press_key": "Appuie sur une touche...",
		"settings_volume": "Volume",
		"settings_volume_status": "Regle le volume du jeu.",
		"controls_aim": "Viser",
		"controls_mouse": "Souris",
		"controls_right_stick": "Stick droit",
		"unassigned": "Non attribue",
		"joy_start": "Start",
		"joy_back": "Back",
		"joy_dpad_up": "Croix haut",
		"joy_dpad_down": "Croix bas",
		"joy_dpad_left": "Croix gauche",
		"joy_dpad_right": "Croix droite",
		"joy_button": "Bouton %d",
		"action_move_forward": "Avancer",
		"action_move_backward": "Reculer",
		"action_move_left": "Aller a gauche",
		"action_move_right": "Aller a droite",
		"action_prone": "Se coucher",
		"action_pause": "Pause",
		"player_you": "Vous"
	},
	LANGUAGE_EN: {
		"main_title": "Point Your Thing",
		"main_subtitle": "3D blind shot",
		"menu_play": "Play",
		"menu_settings": "Settings",
		"menu_languages": "Languages",
		"menu_quit": "Quit",
		"language_title": "Languages",
		"language_subtitle": "Choose the game language",
		"language_french": "French",
		"language_english": "English",
		"language_current": "Current language: %s",
		"language_name_fr": "French",
		"language_name_en": "English",
		"common_back": "Back",
		"common_continue": "Continue",
		"mode_select_title": "Game mode",
		"mode_select_subtitle": "Choose how you want to play",
		"mode_select_info_default": "Pick a game mode",
		"mode_select_multiplayer": "Multiplayer",
		"mode_select_multiplayer_soon": "Multiplayer mode will be added later.",
		"solo_title": "Solo mode",
		"solo_subtitle": "Choose the number of enemy bots",
		"solo_bots_label": "Bots:",
		"solo_hint": "You can choose between 1 and 6 bots.",
		"solo_difficulty_label": "Difficulty:",
		"difficulty_beginner": "Beginner",
		"difficulty_normal": "Normal",
		"difficulty_hard": "Hard",
		"character_title": "Choose your character",
		"character_hint": "Select a color for your character before starting the match.",
		"character_selected_color": "Selected color: %s",
		"character_start": "Start match",
		"settings_title": "Settings",
		"settings_subtitle": "Click an action to choose a new key",
		"settings_action_header": "Action",
		"settings_binding_header": "Bindings",
		"settings_status_default": "Click an action to change its keyboard key.",
		"settings_waiting": "New keyboard key for %s: press a key. The controller button stays %s.",
		"settings_press_key": "Press a key...",
		"settings_volume": "Volume",
		"settings_volume_status": "Adjust the game volume.",
		"controls_aim": "Aim",
		"controls_mouse": "Mouse",
		"controls_right_stick": "Right stick",
		"unassigned": "Unassigned",
		"joy_start": "Start",
		"joy_back": "Back",
		"joy_dpad_up": "D-pad up",
		"joy_dpad_down": "D-pad down",
		"joy_dpad_left": "D-pad left",
		"joy_dpad_right": "D-pad right",
		"joy_button": "Button %d",
		"action_move_forward": "Move forward",
		"action_move_backward": "Move backward",
		"action_move_left": "Move left",
		"action_move_right": "Move right",
		"action_prone": "Go prone",
		"action_pause": "Pause",
		"player_you": "You"
	}
}

const CHARACTER_OPTIONS := [
	{
		"id": "red_ranger",
		"name_fr": "Rouge",
		"name_en": "Red",
		"bot_name_fr": "Rouge Foudre",
		"bot_name_en": "Red Thunder",
		"body_color": Color8(211, 84, 84),
		"skin_color": Color8(224, 189, 149),
		"accent_color": Color8(60, 20, 20)
	},
	{
		"id": "blue_guard",
		"name_fr": "Bleu",
		"name_en": "Blue",
		"bot_name_fr": "Bleu Tempete",
		"bot_name_en": "Blue Storm",
		"body_color": Color8(79, 140, 255),
		"skin_color": Color8(198, 170, 130),
		"accent_color": Color8(23, 40, 80)
	},
	{
		"id": "green_scout",
		"name_fr": "Vert",
		"name_en": "Green",
		"bot_name_fr": "Vert Ombre",
		"bot_name_en": "Green Shade",
		"body_color": Color8(80, 179, 107),
		"skin_color": Color8(217, 182, 141),
		"accent_color": Color8(20, 58, 30)
	},
	{
		"id": "gold_hunter",
		"name_fr": "Jaune",
		"name_en": "Yellow",
		"bot_name_fr": "Jaune Braise",
		"bot_name_en": "Yellow Ember",
		"body_color": Color8(240, 210, 75),
		"skin_color": Color8(234, 196, 156),
		"accent_color": Color8(90, 70, 20)
	},
	{
		"id": "violet_striker",
		"name_fr": "Violet",
		"name_en": "Purple",
		"bot_name_fr": "Violet Nova",
		"bot_name_en": "Purple Nova",
		"body_color": Color8(154, 96, 214),
		"skin_color": Color8(220, 187, 150),
		"accent_color": Color8(63, 36, 93)
	},
	{
		"id": "cyan_runner",
		"name_fr": "Cyan",
		"name_en": "Cyan",
		"bot_name_fr": "Cyan Vif",
		"bot_name_en": "Cyan Swift",
		"body_color": Color8(68, 205, 214),
		"skin_color": Color8(210, 184, 146),
		"accent_color": Color8(21, 72, 76)
	},
	{
		"id": "orange_raider",
		"name_fr": "Orange",
		"name_en": "Orange",
		"bot_name_fr": "Orange Flamme",
		"bot_name_en": "Orange Flame",
		"body_color": Color8(236, 136, 56),
		"skin_color": Color8(226, 188, 148),
		"accent_color": Color8(102, 49, 12)
	},
	{
		"id": "white_sentinel",
		"name_fr": "Blanc",
		"name_en": "White",
		"bot_name_fr": "Blanc Givre",
		"bot_name_en": "White Frost",
		"body_color": Color8(219, 224, 232),
		"skin_color": Color8(212, 178, 142),
		"accent_color": Color8(88, 93, 104)
	}
]

var selected_character_index: int = 0
var selected_game_mode: String = GAME_MODE_SOLO
var selected_bot_count: int = 3
var selected_bot_difficulty: String = BOT_DIFFICULTY_NORMAL
var selected_language: String = LANGUAGE_FR
var master_volume: float = 0.75

func _ready() -> void:
	apply_audio_settings()

func get_selected_character() -> Dictionary:
	return CHARACTER_OPTIONS[selected_character_index]

func select_character(index: int) -> void:
	if index < 0 or index >= CHARACTER_OPTIONS.size():
		return
	selected_character_index = index

func select_game_mode(mode: String) -> void:
	if mode != GAME_MODE_SOLO and mode != GAME_MODE_MULTIPLAYER:
		return
	selected_game_mode = mode

func set_bot_count(value: int) -> void:
	selected_bot_count = clamp(value, MIN_BOT_COUNT, MAX_BOT_COUNT)

func set_bot_difficulty(value: String) -> void:
	if value != BOT_DIFFICULTY_BEGINNER and value != BOT_DIFFICULTY_NORMAL and value != BOT_DIFFICULTY_HARD:
		return
	selected_bot_difficulty = value

func set_language(language: String) -> void:
	if language != LANGUAGE_FR and language != LANGUAGE_EN:
		return
	selected_language = language

func tr_key(key: String) -> String:
	var language_table: Dictionary = TRANSLATIONS.get(selected_language, TRANSLATIONS[LANGUAGE_FR])
	if language_table.has(key):
		return language_table[key]
	return TRANSLATIONS[LANGUAGE_FR].get(key, key)

func get_language_display_name(language: String) -> String:
	if language == LANGUAGE_EN:
		return tr_key("language_name_en")
	return tr_key("language_name_fr")

func get_bot_difficulty_display_name(value: String) -> String:
	match value:
		BOT_DIFFICULTY_BEGINNER:
			return tr_key("difficulty_beginner")
		BOT_DIFFICULTY_HARD:
			return tr_key("difficulty_hard")
		_:
			return tr_key("difficulty_normal")

func get_character_display_name(character: Dictionary) -> String:
	return character.get("name_en", "Character") if selected_language == LANGUAGE_EN else character.get("name_fr", "Personnage")

func get_bot_display_name(character: Dictionary) -> String:
	return character.get("bot_name_en", "Bot") if selected_language == LANGUAGE_EN else character.get("bot_name_fr", "Bot")

func set_human_player_name(name: String) -> void:
	human_player_name_override = name.strip_edges()

func get_human_player_name() -> String:
	return human_player_name_override if human_player_name_override != "" else tr_key("player_you")

func get_action_display_name(action_id: String) -> String:
	for binding: Dictionary in ACTION_BINDINGS:
		if binding["id"] == action_id:
			return tr_key(binding["label_key"])
	return action_id

func get_action_key_text(action_id: String) -> String:
	var events: Array[InputEvent] = InputMap.action_get_events(action_id)
	for event: InputEvent in events:
		if event is InputEventKey:
			var key_event: InputEventKey = event as InputEventKey
			var keycode: Key = key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
			return OS.get_keycode_string(keycode)
	return tr_key("unassigned")

func get_action_gamepad_text(action_id: String) -> String:
	var events: Array[InputEvent] = InputMap.action_get_events(action_id)
	for event: InputEvent in events:
		if event is InputEventJoypadButton:
			return _get_joy_button_name((event as InputEventJoypadButton).button_index)
	return tr_key("unassigned")

func get_action_binding_summary(action_id: String) -> String:
	return "%s | %s" % [get_action_key_text(action_id), get_action_gamepad_text(action_id)]

func build_controls_text() -> String:
	var lines: Array[String] = []
	for binding: Dictionary in ACTION_BINDINGS:
		lines.append("%s : %s" % [get_action_display_name(binding["id"]), get_action_binding_summary(binding["id"])])
	lines.append("%s : %s | %s" % [tr_key("controls_aim"), tr_key("controls_mouse"), tr_key("controls_right_stick")])
	return "\n".join(lines)

func rebind_action(action_id: String, keycode: Key) -> void:
	if not InputMap.has_action(action_id):
		return
	var preserved_events: Array[InputEvent] = []
	for event: InputEvent in InputMap.action_get_events(action_id):
		if not (event is InputEventKey):
			preserved_events.append(event)
	InputMap.action_erase_events(action_id)
	var input_event: InputEventKey = InputEventKey.new()
	input_event.physical_keycode = keycode
	input_event.keycode = keycode
	InputMap.action_add_event(action_id, input_event)
	for event: InputEvent in preserved_events:
		InputMap.action_add_event(action_id, event)
	var saved_events: Array[InputEvent] = [input_event]
	for event: InputEvent in preserved_events:
		saved_events.append(event)
	ProjectSettings.set_setting("input/%s" % action_id, {
		"deadzone": 0.5,
		"events": saved_events
	})
	ProjectSettings.save()

func set_master_volume(value: float) -> void:
	master_volume = clamp(value, 0.0, 1.0)
	apply_audio_settings()

func get_master_volume() -> float:
	return master_volume

func get_master_volume_text() -> String:
	return "%d%%" % int(round(master_volume * 100.0))

func apply_audio_settings() -> void:
	var bus_index: int = AudioServer.get_bus_index("Master")
	if bus_index < 0:
		return
	if master_volume <= 0.001:
		AudioServer.set_bus_volume_db(bus_index, -80.0)
	else:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(master_volume))

func _get_joy_button_name(button_index: int) -> String:
	match button_index:
		0:
			return "A"
		1:
			return "B"
		2:
			return "X"
		3:
			return "Y"
		4:
			return "LB"
		5:
			return "RB"
		6:
			return tr_key("joy_start")
		7:
			return tr_key("joy_back")
		11:
			return tr_key("joy_dpad_up")
		12:
			return tr_key("joy_dpad_down")
		13:
			return tr_key("joy_dpad_left")
		14:
			return tr_key("joy_dpad_right")
		_:
			return tr_key("joy_button") % button_index


