extends Node

# Stocke l'état global partagé entre les scènes et fournit les utilitaires de traduction :
# - langue actuelle et dictionnaire de clés/valeurs
# - mode choisi (solo/multi), nombre/difficulté des bots, nom du joueur
# - liste des personnages disponibles + helpers pour récupérer leurs couleurs/noms
# - mapping des actions d'entrée et résumé lisible des touches.

const LANGUE_FR := "fr"
const LANGUE_EN := "en"
const MODE_JEU_SOLO := "solo"
const MODE_JEU_MULTIJOUEUR := "multiplayer"
const BOT_DIFFICULTE_DEBUTANT := "beginner"
const BOT_DIFFICULTE_NORMAL := "normal"
const BOT_DIFFICULTE_DIFFICILE := "hard"
const NB_BOTS_MIN := 1
const NB_BOTS_MAX := 6
var nom_joueur_humain_force: String = ""
const LIAISONS_ACTIONS := [
	{"id": "ui_up", "label_key": "action_move_forward"},
	{"id": "ui_down", "label_key": "action_move_backward"},
	{"id": "ui_left", "label_key": "action_move_left"},
	{"id": "ui_right", "label_key": "action_move_right"},
	{"id": "toggle_prone", "label_key": "action_prone"},
	{"id": "toggle_pause", "label_key": "action_pause"}
]

const TRADUCTIONS := {
	LANGUE_FR: {
		"main_title": "Pointe ton Bagay",
		"main_subtitle": "Blind shot en 3D",
		"menu_play": "Jouer",
		"menu_settings": "Parametres",
		"menu_languages": "Langues",
		"menu_scores": "Scores",
		"menu_quit": "Quitter",
		"scores_title": "Scores",
		"scores_subtitle": "Consulte les scores enregistres",
		"scores_header_name": "Nom",
		"scores_header_position": "Position",
		"scores_header_mode": "Mode",
		"scores_header_difficulty": "Difficulte",
		"scores_header_bots": "Bots",
		"scores_header_skin": "Skin",
		"scores_empty": "Aucun score enregistre pour le moment.",
		"scores_error_db": "Impossible de charger les scores (base introuvable).",
		"scores_back": "Quitter",
		"scores_mode_solo": "Solo",
		"scores_mode_multiplayer": "Multijoueur",
		"scores_mode_hardcore": "Difficile",
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
		"settings_mouse_sens": "Sensibilite souris",
		"settings_mouse_sens_status": "Regle la sensibilite de la camera a la souris.",
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
	LANGUE_EN: {
		"main_title": "Point Your Thing",
		"main_subtitle": "3D blind shot",
		"menu_play": "Play",
		"menu_settings": "Settings",
		"menu_languages": "Languages",
		"menu_scores": "Scores",
		"menu_quit": "Quit",
		"scores_title": "Scores",
		"scores_subtitle": "Browse the stored scores",
		"scores_header_name": "Name",
		"scores_header_position": "Place",
		"scores_header_mode": "Mode",
		"scores_header_difficulty": "Difficulty",
		"scores_header_bots": "Bots",
		"scores_header_skin": "Skin",
		"scores_empty": "No scores recorded yet.",
		"scores_error_db": "Unable to load scores (database missing).",
		"scores_back": "Back",
		"scores_mode_solo": "Solo",
		"scores_mode_multiplayer": "Multiplayer",
		"scores_mode_hardcore": "Hard",
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
		"settings_mouse_sens": "Mouse sensitivity",
		"settings_mouse_sens_status": "Adjust mouse look sensitivity.",
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

const OPTIONS_PERSONNAGE := [
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

var indice_personnage_selectionne: int = 0
var mode_jeu_selectionne: String = MODE_JEU_SOLO
var nombre_bots_selectionne: int = 3
var difficulte_bots_selectionnee: String = BOT_DIFFICULTE_NORMAL
var langue_selectionnee: String = LANGUE_FR
var volume_general: float = 0.75
var sensibilite_souris: float = 1.0

# Initialise la langue par defaut (FR).
func _ready() -> void:
	appliquer_parametres_audio()

# Retourne le dictionnaire du personnage actuellement selectionne.
func obtenir_personnage_selectionne() -> Dictionary:
	return OPTIONS_PERSONNAGE[indice_personnage_selectionne]

# Change l'index de skin selectionne.
func selectionner_personnage(index: int) -> void:
	if index < 0 or index >= OPTIONS_PERSONNAGE.size():
		return
	indice_personnage_selectionne = index

# Enregistre le mode de jeu choisi (solo/multi).
func selectionner_mode_jeu(mode: String) -> void:
	if mode != MODE_JEU_SOLO and mode != MODE_JEU_MULTIJOUEUR:
		return
	mode_jeu_selectionne = mode

# Met a jour le nombre de bots en respectant les bornes.
func definir_nombre_bots(value: int) -> void:
	nombre_bots_selectionne = clamp(value, NB_BOTS_MIN, NB_BOTS_MAX)

# Met a jour la difficulte des bots.
func definir_difficulte_bots(value: String) -> void:
	if value != BOT_DIFFICULTE_DEBUTANT and value != BOT_DIFFICULTE_NORMAL and value != BOT_DIFFICULTE_DIFFICILE:
		return
	difficulte_bots_selectionnee = value

# Change la langue globale et applique aux traductions.
func definir_langue(language: String) -> void:
	if language != LANGUE_FR and language != LANGUE_EN:
		return
	langue_selectionnee = language

# Renvoie une cle de traduction si elle existe, sinon la cle brute.
func cle_traduction(key: String) -> String:
	var language_table: Dictionary = TRADUCTIONS.get(langue_selectionnee, TRADUCTIONS[LANGUE_FR])
	if language_table.has(key):
		return language_table[key]
	return TRADUCTIONS[LANGUE_FR].get(key, key)

# Texte lisible pour une langue donnee.
func obtenir_nom_langue(language: String) -> String:
	if language == LANGUE_EN:
		return cle_traduction("language_name_en")
	return cle_traduction("language_name_fr")

# Texte lisible pour une difficulte de bots.
func obtenir_nom_difficulte_bots(value: String) -> String:
	match value:
		BOT_DIFFICULTE_DEBUTANT:
			return cle_traduction("difficulty_beginner")
		BOT_DIFFICULTE_DIFFICILE:
			return cle_traduction("difficulty_hard")
		_:
			return cle_traduction("difficulty_normal")

# Libelle d'un personnage (nom localise si defini).
func obtenir_nom_personnage(character: Dictionary) -> String:
	return character.get("name_en", "Character") if langue_selectionnee == LANGUE_EN else character.get("name_fr", "Personnage")

# Construit un nom automatique pour un bot a partir du skin.
func obtenir_nom_bot(character: Dictionary) -> String:
	return character.get("bot_name_en", "Bot") if langue_selectionnee == LANGUE_EN else character.get("bot_name_fr", "Bot")

# Force le nom du joueur humain (champ pseudo).
func definir_nom_joueur_humain(name: String) -> void:
	nom_joueur_humain_force = name.strip_edges()

# Retourne le nom courant du joueur humain (valeur forcee si renseignee).
func obtenir_nom_joueur_humain() -> String:
	return nom_joueur_humain_force if nom_joueur_humain_force != "" else cle_traduction("player_you")

# Libelle lisible d'une action (pour les menus).
func obtenir_nom_action(action_id: String) -> String:
	for binding: Dictionary in LIAISONS_ACTIONS:
		if binding["id"] == action_id:
			return cle_traduction(binding["label_key"])
	return action_id

# Retourne le texte clavier associe a une action.
func obtenir_texte_touche_action(action_id: String) -> String:
	var events: Array[InputEvent] = InputMap.action_get_events(action_id)
	for event: InputEvent in events:
		if event is InputEventKey:
			var key_event: InputEventKey = event as InputEventKey
			var keycode: Key = key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
			return OS.get_keycode_string(keycode)
	return cle_traduction("unassigned")

# Retourne le texte manette associe a une action.
func obtenir_texte_manette_action(action_id: String) -> String:
	var events: Array[InputEvent] = InputMap.action_get_events(action_id)
	for event: InputEvent in events:
		if event is InputEventJoypadButton:
			return _obtenir_nom_bouton_joy((event as InputEventJoypadButton).button_index)
	return cle_traduction("unassigned")

# R�sume la touche/manette assign�e � une action.
func obtenir_resume_assignation_action(action_id: String) -> String:
	return "%s | %s" % [obtenir_texte_touche_action(action_id), obtenir_texte_manette_action(action_id)]

# Concatene un r�sum� de toutes les actions et assignations.
func construire_texte_controles() -> String:
	var lines: Array[String] = []
	for binding: Dictionary in LIAISONS_ACTIONS:
		lines.append("%s : %s" % [obtenir_nom_action(binding["id"]), obtenir_resume_assignation_action(binding["id"])])
	lines.append("%s : %s | %s" % [cle_traduction("controls_aim"), cle_traduction("controls_mouse"), cle_traduction("controls_right_stick")])
	return "\n".join(lines)

# Reconfigure une action avec une nouvelle touche (supprime les anciennes).
func reaffecter_action(action_id: String, keycode: Key) -> void:
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

# Stocke le volume global (0..1) et applique l'audio.
func definir_volume_general(value: float) -> void:
	volume_general = clamp(value, 0.0, 1.0)
	appliquer_parametres_audio()

# Retourne la valeur de volume stockee.
func obtenir_volume_general() -> float:
	return volume_general

# Retourne le volume formate en pourcentage.
func obtenir_texte_volume_general() -> String:
	return "%d%%" % int(round(volume_general * 100.0))

# Applique le volume sur le bus audio principal.
func appliquer_parametres_audio() -> void:
	var bus_index: int = AudioServer.get_bus_index("Master")
	if bus_index < 0:
		return
	if volume_general <= 0.001:
		AudioServer.set_bus_volume_db(bus_index, -80.0)
	else:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume_general))

# Stocke la sensibilite souris (facteur multiplicatif).
func definir_sensibilite_souris(value: float) -> void:
	sensibilite_souris = clamp(value, 0.5, 2.0)

# Retourne la sensibilite souris courante.
func obtenir_sensibilite_souris() -> float:
	return sensibilite_souris

# Retourne la sensibilite formatee (ex : x1.20).
func obtenir_texte_sensibilite_souris() -> String:
	return "x%.2f" % sensibilite_souris

# Nom lisible d'un bouton de manette.
func _obtenir_nom_bouton_joy(button_index: int) -> String:
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
			return cle_traduction("joy_start")
		7:
			return cle_traduction("joy_back")
		11:
			return cle_traduction("joy_dpad_up")
		12:
			return cle_traduction("joy_dpad_down")
		13:
			return cle_traduction("joy_dpad_left")
		14:
			return cle_traduction("joy_dpad_right")
		_:
			return cle_traduction("joy_button") % button_index
