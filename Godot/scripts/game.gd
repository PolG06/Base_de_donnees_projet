extends Node3D

# Coeur du jeu : orchestre les phases sombre/lumière, enchaîne les manches,
# pilote les joueurs (humain + bots), la caméra du joueur, ainsi que l'apparition de transitions,
# et enregistre les scores dans la base de données SQLite.

#constantes des scènes de jeu
const PLAYER_SCENE := preload("res://scenes/player_character.tscn")
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")

#Constantes à propos du déroulement jeu
const DARK_DURATION := 12.0 # Duree de base de la phase deplacement (en secondes)
const LIGHT_SHOT_DELAY := 0.8

# Pour la taille de la plateforme
const START_RADIUS := 10.5
const MIN_RADIUS := 3.5 
const SHRINK_FACTOR := 2.0 / 3.0

 # Hauteur du point de vue de la caméra
const CAMERA_HEIGHT := 2.75

#Pour la distance de la caméra par rapport au joueur:
const CAMERA_DISTANCE_DEFAUT := 4.35 
const CAMERA_DISTANCE_MIN := 2.2
const CAMERA_DISTANCE_MAX := 9.5

const CAMERA_ZOOM_PAS := 0.35 # Pour le zoom de la caméra

#Pour les effets de la caméra
const CAMERA_SMOOTHNESS := 7.0
const CAMERA_SIDE_OFFSET := -0.45

const GAMEPAD_DEADZONE := 0.2

#Constantes pour l'utilisation de d'un manette
const CAMERA_CONTROLLER_YAW_SPEED := 3.4
const CAMERA_CONTROLLER_PITCH_SPEED := 2.3
const CAMERA_CONTROLLER_PITCH_MIN := -0.35
# Autorise un angle plus vertical pour voir davantage le dessus de l'arène.
const CAMERA_CONTROLLER_PITCH_MAX := 1.1

const GYRO_SPEED_SCALE := 55.0 # Intensité de l'effet "gyro" de la souris hors fenêtre
const NETHER_BACKDROP_RADIUS := 62.0
const NETHER_WALL_HEIGHT := 32.0
const NETHER_CEILING_HEIGHT := 28.0
const PRE_LIGHT_OBSERVE_TIME := 6.0 # Délai d'observation avant les tirs
const MOUSE_CAPTURE_BUTTONS := [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]
const DATABASE_USER_PATH := "user://database.db"
const DATABASE_USER_DIR := "user://"

#Pour les transitions de jeu
const ROUND_TRANSITION_FADE_IN := 0.55
const ROUND_TRANSITION_HOLD := 2.6
const ROUND_TRANSITION_FADE_OUT := 0.55

const DATABASE_PATH := "res://Database_sqlite/database.db" #chemin relatif vers le fichier de base de données (export inclus)

enum PhaseJeu { DARK, LIGHT, ROUND_END, GAME_OVER }

# Varibles de la partie
var aleatoire_partie: RandomNumberGenerator = RandomNumberGenerator.new()
var joueurs_partie: Array[PlayerCharacter] = [] #contiendra la liste des joueurs
var ordre_eliminations: Array[PlayerCharacter] = [] #contiendra l'ordre de tir des joueurs
var joueur_humain_principal: PlayerCharacter #permet de gérer qui le joueur
var joueur_spectateur_cible: PlayerCharacter #permet de gérer qui le joueur que l'on va regarder en mode spectateur
var tween_transition_manche: Tween
var centre_arene: Vector3 = Vector3.ZERO
var rayon_arene_courant: float = START_RADIUS
var numero_manche_courant: int = 1
var phase_jeu: PhaseJeu = PhaseJeu.DARK
var temps_phase_restant: float = DARK_DURATION
var file_tirs_ordonnee: Array[PlayerCharacter] = []
var delai_avant_tir: float = LIGHT_SHOT_DELAY
var phase_lumiere_revelee: bool = false
var temps_observation_phase_lumiere: float = 0.0
var mode_camera_libre_actif: bool = false
var lacet_camera_libre: float = 0.0
var tangage_camera_libre: float = 0.0
var cible_camera_suivie: PlayerCharacter
var lacet_camera_souris: float = 0.0
var tangage_camera_souris: float = 0.32
var souris_dans_viewport: bool = true
var gyro_actif: bool = false
var vitesse_lacet_gyro_mode: float = 0.0
var vitesse_tangage_gyro_mode: float = 0.0
var distance_camera_courante: float = CAMERA_DISTANCE_DEFAUT
var materiau_pierre: StandardMaterial3D
var materiau_lave: StandardMaterial3D
var materiau_roche_nether: StandardMaterial3D
var materiau_basalte: StandardMaterial3D
var materiau_pierre_luisante: StandardMaterial3D
var environnement_obscurite: Environment
var environnement_lumiere: Environment
var menu_pause_visible: bool = false
var panneau_parametres_pause_visible: bool = false
var ecran_fin_visible: bool = false
var score_deja_enregistre: bool = false
var action_pause_en_attente: String = ""
var boutons_actions_pause_map: Dictionary = {}
var curseur_volume_general: HSlider
var etiquette_valeur_volume_general: Label
var lacet_camera_manette: float = 0.0
var tangage_camera_manette: float = 0.18
var controle_camera_manette_actif: bool = false
var transition_en_cours: bool = false
var overlay_mort: ColorRect
var etiquette_mort: Label
var overlay_mort_actif: bool = false

#récupération des autres noeuds enfants afin de les manipuler
@onready var camera: Camera3D = $Camera3D
@onready var lumiere_soleil: DirectionalLight3D = $SunLight
@onready var environnement_monde: WorldEnvironment = $WorldEnvironment
@onready var racine_arene: Node3D = $Arena
@onready var racine_joueurs: Node3D = $Players
@onready var racine_projectiles: Node3D = $Projectiles
@onready var etiquette_phase: Label = $CanvasLayer/PhaseLabel
@onready var etiquette_info: Label = $CanvasLayer/InfoLabel
@onready var etiquette_spectateur: Label = $CanvasLayer/SpectatorLabel
@onready var overlay_transition_manche: ColorRect = $CanvasLayer/RoundTransition
@onready var etiquette_transition_manche: Label = $CanvasLayer/RoundTransition/RoundTransitionLabel
@onready var etiquette_survivants_manche: Label = $CanvasLayer/RoundTransition/RoundAliveLabel
@onready var panneau_ordre: Panel = $CanvasLayer/OrderPanel
@onready var liste_ordre: VBoxContainer = $CanvasLayer/OrderPanel/OrderVBox/OrderList
@onready var bouton_quitter_spectateur: Button = $CanvasLayer/SpectatorQuitButton
@onready var etiquette_notification: Label = $CanvasLayer/NotificationLabel
@onready var etiquette_titre_fin: Label = $CanvasLayer/GameOverOverlay/GameOverPanel/GameOverTitle
@onready var overlay_pause: ColorRect = $CanvasLayer/PauseOverlay
@onready var vbox_menu_pause: VBoxContainer = $CanvasLayer/PauseOverlay/PausePanel/PauseMenuVBox
@onready var bouton_reprendre: Button = $CanvasLayer/PauseOverlay/PausePanel/PauseMenuVBox/ResumeButton
@onready var bouton_parametres_pause: Button = $CanvasLayer/PauseOverlay/PausePanel/PauseMenuVBox/PauseSettingsButton
@onready var bouton_quitter: Button = $CanvasLayer/PauseOverlay/PausePanel/PauseMenuVBox/QuitButton
@onready var panneau_parametres_pause: Panel = $CanvasLayer/PauseOverlay/PausePanel/PauseSettingsPanel
@onready var liste_parametres_pause: VBoxContainer = $CanvasLayer/PauseOverlay/PausePanel/PauseSettingsPanel/PauseSettingsMargin/PauseSettingsVBox/PauseSettingsControlsPanel/PauseSettingsControlsMargin/PauseSettingsControlsColumn/PauseSettingsScroll/PauseSettingsControlsList
@onready var etiquette_statut_parametres_pause: Label = $CanvasLayer/PauseOverlay/PausePanel/PauseSettingsPanel/PauseSettingsMargin/PauseSettingsVBox/PauseSettingsStatusPanel/PauseSettingsStatusLabel
@onready var bouton_retour_parametres_pause: Button = $CanvasLayer/PauseOverlay/PausePanel/PauseSettingsPanel/PauseSettingsMargin/PauseSettingsVBox/PauseSettingsBackButton
@onready var overlay_fin: ColorRect = $CanvasLayer/GameOverOverlay
@onready var etiquette_classement: Label = $CanvasLayer/GameOverOverlay/GameOverPanel/RankingLabel
@onready var game_over_bouton_quitter: Button = $CanvasLayer/GameOverOverlay/GameOverPanel/GameOverQuitButton
@onready var bouton_fin_rejouer: Button = $CanvasLayer/GameOverOverlay/GameOverPanel/GameOverRestartButton

var mesh_plateforme: MeshInstance3D
var collision_plateforme: CollisionShape3D
var mesh_lave: MeshInstance3D

# Initialise l'UI, l'environnement, l'audio, l'arene et fait apparaitre les joueurs.
func _ready() -> void:
	# Initialisation des références, UI et environnement de jeu.
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay_pause.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox_menu_pause.process_mode = Node.PROCESS_MODE_ALWAYS
	bouton_reprendre.process_mode = Node.PROCESS_MODE_ALWAYS
	bouton_parametres_pause.process_mode = Node.PROCESS_MODE_ALWAYS
	bouton_quitter.process_mode = Node.PROCESS_MODE_ALWAYS
	panneau_parametres_pause.process_mode = Node.PROCESS_MODE_ALWAYS
	liste_parametres_pause.process_mode = Node.PROCESS_MODE_ALWAYS
	etiquette_statut_parametres_pause.process_mode = Node.PROCESS_MODE_ALWAYS
	bouton_retour_parametres_pause.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay_fin.process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_bouton_quitter.process_mode = Node.PROCESS_MODE_ALWAYS
	MenuMusic.jouer_musique_jeu() #on démarre la musique
	_assurer_bindings_manette() #on prépare le jeu à recevoir des commandes de manettes
	#pour le menu pause (échap)
	_construire_lignes_parametres_pause() 
	_rafraichir_boutons_parametres_pause()
	MenuAudio.connecter_boutons(self)
	etiquette_statut_parametres_pause.text = GameState.cle_traduction("settings_status_default")
	#initialisation du statut des boutons des menus du jeu (click --> conséquence)
	bouton_reprendre.pressed.connect(_sur_reprendre_presse)
	bouton_parametres_pause.pressed.connect(_sur_parametres_pause_presse)
	bouton_quitter.pressed.connect(_sur_quitter_presse)
	bouton_retour_parametres_pause.pressed.connect(_sur_retour_parametres_pause_presse)
	game_over_bouton_quitter.pressed.connect(_sur_fin_quitter_presse)
	bouton_fin_rejouer.pressed.connect(_sur_rejouer_presse)
	bouton_fin_rejouer.text = "Sélection du mode"
	bouton_quitter_spectateur.visible = false
	bouton_quitter_spectateur.disabled = true
	_creer_overlay_mort()
	_capturer_souris()
	overlay_transition_manche.visible = false
	panneau_ordre.visible = false
	etiquette_notification.visible = false
	aleatoire_partie.randomize()
	# création de l'environnement du jeu
	_creer_materiaux()
	_creer_environnement()
	_ajuster_arene_nombre_joueurs()
	_construire_arene()
	_apparaitre_joueurs()
	_synchroniser_camera_manette_joueur()
	_mettre_a_jour_taille_plateforme()
	_demarrer_phase_obscure()
	rafraichir_schema_bdd()

# Gère les entrées clavier/souris ou manette
func _unhandled_input(event: InputEvent) -> void:
	# Gestion des interactions (pause, spectateur, caméra souris/gyro).
	if overlay_mort_actif:
		return
	if event is InputEventMouseButton:
		_capturer_souris_si_necessaire(event as InputEventMouseButton)
	if action_pause_en_attente != "" and event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			var keycode: Key = key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
			GameState.reaffecter_action(action_pause_en_attente, keycode)
			etiquette_statut_parametres_pause.text = "%s : %s" % [GameState.obtenir_nom_action(action_pause_en_attente), GameState.obtenir_resume_assignation_action(action_pause_en_attente)]
			action_pause_en_attente = ""
			_rafraichir_boutons_parametres_pause()
			get_viewport().set_input_as_handled()
			return
	if phase_jeu == PhaseJeu.GAME_OVER:
		return
	var is_spectating: bool = joueur_humain_principal != null and not joueur_humain_principal.est_vivant
	if event is InputEventMouseMotion and not get_tree().paused:
		var motion_any: InputEventMouseMotion = event as InputEventMouseMotion
		lacet_camera_souris -= motion_any.relative.x * 0.005
		tangage_camera_souris = clamp(tangage_camera_souris + motion_any.relative.y * 0.003, CAMERA_CONTROLLER_PITCH_MIN, CAMERA_CONTROLLER_PITCH_MAX)
		vitesse_lacet_gyro_mode = -motion_any.relative.x * 0.005 * GYRO_SPEED_SCALE
		vitesse_tangage_gyro_mode = motion_any.relative.y * 0.003 * GYRO_SPEED_SCALE
		if is_spectating:
			mode_camera_libre_actif = true
			cible_camera_suivie = joueur_spectateur_cible
			lacet_camera_libre = lacet_camera_souris
			tangage_camera_libre = tangage_camera_souris
		get_viewport().set_input_as_handled()
		return
	if is_spectating and event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and not mouse_event.double_click:
			if mouse_event.button_index == MOUSE_BUTTON_LEFT:
				_alterner_joueur_spectateur_cible(1)
				get_viewport().set_input_as_handled()
				return
			if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
				_alterner_joueur_spectateur_cible(-1)
				get_viewport().set_input_as_handled()
				return
	if event is InputEventMouseButton:
		var wheel: InputEventMouseButton = event as InputEventMouseButton
		if wheel.pressed:
			if wheel.button_index == MOUSE_BUTTON_WHEEL_UP:
				_ajuster_zoom_camera(1)
				get_viewport().set_input_as_handled()
				return
			if wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_ajuster_zoom_camera(-1)
				get_viewport().set_input_as_handled()
				return
	if event.is_action_pressed("toggle_pause"):
		if panneau_parametres_pause_visible:
			_sur_retour_parametres_pause_presse()
		else:
			_basculer_menu_pause()
		get_viewport().set_input_as_handled()

func _capturer_souris_si_necessaire(mouse_event: InputEventMouseButton) -> void:
	if not mouse_event.pressed:
		return
	if menu_pause_visible or panneau_parametres_pause_visible or get_tree().paused or ecran_fin_visible:
		return
	if mouse_event.button_index in MOUSE_CAPTURE_BUTTONS and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		_capturer_souris()

func _capturer_souris() -> void:
	if menu_pause_visible or panneau_parametres_pause_visible or get_tree().paused or ecran_fin_visible:
		return
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
		_capturer_souris()

# Boucle physique : avance la phase en cours (sombre/lumiere/fin), camera et UI.
func _physics_process(delta: float) -> void:
	# Boucle physique : avance la phase_jeu courante, caméra, UI.
	_capturer_souris()
	if overlay_mort_actif:
		_mettre_a_jour_camera(delta)
		_mettre_a_jour_ui()
		return
	if transition_en_cours:
		_mettre_a_jour_camera(delta)
		_mettre_a_jour_ui()
		return
	if get_tree().paused:
		_mettre_a_jour_ui()
		return
	match phase_jeu:
		PhaseJeu.DARK:
			_mettre_a_jour_phase_obscure(delta)
		PhaseJeu.LIGHT:
			_mettre_a_jour_phase_lumineuse(delta)
		PhaseJeu.ROUND_END:
			_mettre_a_jour_fin_manche(delta)
		PhaseJeu.GAME_OVER:
			pass
	_capturer_souris()
	_mettre_a_jour_camera(delta)
	_mettre_a_jour_ui()

# Ouvre ou ferme le menu pause selon l'etat et ignore si ecran de fin.
func _basculer_menu_pause() -> void:
	# Ouvre/ferme le menu pause.
	if ecran_fin_visible:
		return
	if menu_pause_visible:
		_fermer_menu_pause()
	else:
		_ouvrir_menu_pause()

# Met en pause, affiche le menu principal de pause et reinitialise l'etat d'attente de touche.
func _ouvrir_menu_pause() -> void:
	menu_pause_visible = true
	panneau_parametres_pause_visible = false
	action_pause_en_attente = ""
	_rafraichir_boutons_parametres_pause()
	MenuAudio.connecter_boutons(self)
	etiquette_statut_parametres_pause.text = GameState.cle_traduction("settings_status_default")
	overlay_pause.visible = true
	vbox_menu_pause.visible = true
	panneau_parametres_pause.visible = false
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	bouton_reprendre.call_deferred("grab_focus")

# Ferme pause et reprend le jeu.
func _fermer_menu_pause() -> void:
	menu_pause_visible = false
	panneau_parametres_pause_visible = false
	action_pause_en_attente = ""
	overlay_pause.visible = false
	vbox_menu_pause.visible = true
	panneau_parametres_pause.visible = false
	get_tree().paused = false
	_capturer_souris()

# Bouton Reprendre : ferme simplement le menu pause.
func _sur_reprendre_presse() -> void:
	_fermer_menu_pause()

# Bouton Parametres : ouvre la colonne de rebind, remet le texte de statut.
func _sur_parametres_pause_presse() -> void:
	panneau_parametres_pause_visible = true
	action_pause_en_attente = ""
	_rafraichir_boutons_parametres_pause()
	MenuAudio.connecter_boutons(self)
	etiquette_statut_parametres_pause.text = GameState.cle_traduction("settings_status_default")
	vbox_menu_pause.visible = false
	panneau_parametres_pause.visible = true
	if boutons_actions_pause_map.has("ui_up"):
		(boutons_actions_pause_map["ui_up"] as Button).call_deferred("grab_focus")

# Bouton Retour des parametres : revient au menu pause principal.
func _sur_retour_parametres_pause_presse() -> void:
	panneau_parametres_pause_visible = false
	action_pause_en_attente = ""
	panneau_parametres_pause.visible = false
	vbox_menu_pause.visible = true
	bouton_parametres_pause.call_deferred("grab_focus")

# Quand on clique sur une action a reconfigurer, on passe en mode attente de touche.
func _sur_action_parametre_pause_presse(action_id: String) -> void:
	action_pause_en_attente = action_id
	etiquette_statut_parametres_pause.text = GameState.cle_traduction("settings_waiting") % [GameState.obtenir_nom_action(action_id), GameState.obtenir_texte_manette_action(action_id)]
	_rafraichir_boutons_parametres_pause()

# Reconstruit dynamiquement la liste des actions/boutons + le slider de volume.
func _construire_lignes_parametres_pause() -> void:
	for child: Node in liste_parametres_pause.get_children():
		child.queue_free()
	boutons_actions_pause_map.clear()
	curseur_volume_general = null
	etiquette_valeur_volume_general = null
	for binding: Dictionary in GameState.LIAISONS_ACTIONS:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		liste_parametres_pause.add_child(row)

		var label: Label = Label.new()
		label.text = GameState.obtenir_nom_action(binding["id"])
		label.custom_minimum_size = Vector2(280, 46)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(label)

		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(220, 46)
		button.pressed.connect(_sur_action_parametre_pause_presse.bind(binding["id"]))
		row.add_child(button)
		boutons_actions_pause_map[binding["id"]] = button

	var volume_row: HBoxContainer = HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 12)
	liste_parametres_pause.add_child(volume_row)

	var volume_label: Label = Label.new()
	volume_label.text = GameState.cle_traduction("settings_volume")
	volume_label.custom_minimum_size = Vector2(280, 46)
	volume_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	volume_row.add_child(volume_label)

	var volume_box: HBoxContainer = HBoxContainer.new()
	volume_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_box.add_theme_constant_override("separation", 10)
	volume_row.add_child(volume_box)

	curseur_volume_general = HSlider.new()
	curseur_volume_general.min_value = 0.0
	curseur_volume_general.max_value = 1.0
	curseur_volume_general.step = 0.01
	curseur_volume_general.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	curseur_volume_general.custom_minimum_size = Vector2(140, 46)
	curseur_volume_general.value = GameState.obtenir_volume_general()
	curseur_volume_general.value_changed.connect(_sur_volume_pause_change)
	volume_box.add_child(curseur_volume_general)

	etiquette_valeur_volume_general = Label.new()
	etiquette_valeur_volume_general.custom_minimum_size = Vector2(70, 46)
	etiquette_valeur_volume_general.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiquette_valeur_volume_general.text = GameState.obtenir_texte_volume_general()
	volume_box.add_child(etiquette_valeur_volume_general)

	var aim_row: HBoxContainer = HBoxContainer.new()
	aim_row.add_theme_constant_override("separation", 12)
	liste_parametres_pause.add_child(aim_row)

	var aim_label: Label = Label.new()
	aim_label.text = GameState.cle_traduction("controls_aim")
	aim_label.custom_minimum_size = Vector2(280, 46)
	aim_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	aim_row.add_child(aim_label)

	var aim_value: Label = Label.new()
	aim_value.text = "%s | %s" % [GameState.cle_traduction("controls_mouse"), GameState.cle_traduction("controls_right_stick")]
	aim_value.custom_minimum_size = Vector2(220, 46)
	aim_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	aim_row.add_child(aim_value)

	MenuAudio.connecter_boutons(liste_parametres_pause)

# Mets a jour libelles des boutons (resume des touches ou message d'attente) et valeurs de volume.
func _rafraichir_boutons_parametres_pause() -> void:
	for binding: Dictionary in GameState.LIAISONS_ACTIONS:
		var action_id: String = binding["id"]
		var button: Button = boutons_actions_pause_map.get(action_id, null)
		if button == null:
			continue
		button.text = GameState.cle_traduction("settings_press_key") if action_id == action_pause_en_attente else GameState.obtenir_resume_assignation_action(action_id)
	if curseur_volume_general != null:
		curseur_volume_general.set_value_no_signal(GameState.obtenir_volume_general())
	if etiquette_valeur_volume_general != null:
		etiquette_valeur_volume_general.text = GameState.obtenir_texte_volume_general()

# Slider volume : met a jour GameState + texte, indique l'etat si pas en rebind.
func _sur_volume_pause_change(value: float) -> void:
	GameState.definir_volume_general(value)
	if etiquette_valeur_volume_general != null:
		etiquette_valeur_volume_general.text = GameState.obtenir_texte_volume_general()
	if action_pause_en_attente == "":
		etiquette_statut_parametres_pause.text = GameState.cle_traduction("settings_volume_status")

# Quitter depuis pause : reprend le jeu et charge menu principal.
func _sur_quitter_presse() -> void:
	_sauvegarder_resultat_partie()
	get_tree().paused = false
	menu_pause_visible = false
	panneau_parametres_pause_visible = false
	action_pause_en_attente = ""
	ecran_fin_visible = false
	get_tree().change_scene_to_file("res://scenes/menu_main.tscn")

# Rejouer (ici redirige vers selection de mode) depuis l'ecran de fin.
func _sur_rejouer_presse() -> void:
	get_tree().paused = false
	menu_pause_visible = false
	panneau_parametres_pause_visible = false
	action_pause_en_attente = ""
	ecran_fin_visible = false
	get_tree().change_scene_to_file("res://scenes/mode_select.tscn")

# Quitter definitif depuis l'ecran de fin : ferme le jeu.
func _sur_fin_quitter_presse() -> void:
	_sauvegarder_resultat_partie()
	get_tree().quit()

# Initialise les materiaux des meshes (plateforme, lave, roches, glowstone).
func _creer_materiaux() -> void:
	materiau_pierre = StandardMaterial3D.new()
	materiau_pierre.albedo_texture = _creer_texture_reference_plateforme()
	materiau_pierre.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	materiau_pierre.uv1_scale = Vector3(8, 8, 8)
	materiau_pierre.roughness = 1.0

	materiau_lave = StandardMaterial3D.new()
	materiau_lave.albedo_texture = _creer_texture_reference_lave()
	materiau_lave.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	materiau_lave.uv1_scale = Vector3(24, 24, 24)
	materiau_lave.emission_enabled = true
	materiau_lave.emission_texture = materiau_lave.albedo_texture
	materiau_lave.emission = Color(1.0, 0.45, 0.1)
	materiau_lave.emission_energy_multiplier = 1.9
	materiau_lave.roughness = 0.78

	materiau_roche_nether = StandardMaterial3D.new()
	materiau_roche_nether.albedo_texture = _creer_texture_roche_nether()
	materiau_roche_nether.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	materiau_roche_nether.uv1_scale = Vector3(10, 10, 10)
	materiau_roche_nether.roughness = 1.0

	materiau_basalte = StandardMaterial3D.new()
	materiau_basalte.albedo_texture = _creer_texture_basalte()
	materiau_basalte.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	materiau_basalte.uv1_scale = Vector3(7, 7, 7)
	materiau_basalte.roughness = 1.0

	materiau_pierre_luisante = StandardMaterial3D.new()
	materiau_pierre_luisante.albedo_texture = _creer_texture_pierre_luisante()
	materiau_pierre_luisante.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	materiau_pierre_luisante.uv1_scale = Vector3(6, 6, 6)
	materiau_pierre_luisante.emission_enabled = true
	materiau_pierre_luisante.emission_texture = materiau_pierre_luisante.albedo_texture
	materiau_pierre_luisante.emission = Color(1.0, 0.72, 0.2)
	materiau_pierre_luisante.emission_energy_multiplier = 2.35

# Configure deux environnements (lumiere/obscurite) et assigne celui de depart.
func _creer_environnement() -> void:
	environnement_lumiere = Environment.new()
	environnement_lumiere.background_mode = Environment.BG_COLOR
	environnement_lumiere.background_color = Color(0.22, 0.03, 0.03)
	environnement_lumiere.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environnement_lumiere.ambient_light_color = Color(0.9, 0.28, 0.18)
	environnement_lumiere.ambient_light_energy = 0.55
	environnement_lumiere.fog_enabled = true
	environnement_lumiere.fog_light_color = Color(0.95, 0.25, 0.12)
	environnement_lumiere.fog_light_energy = 0.7
	environnement_lumiere.fog_density = 0.012
	environnement_lumiere.tonemap_exposure = 1.05

	environnement_obscurite = Environment.new()
	environnement_obscurite.background_mode = Environment.BG_COLOR
	environnement_obscurite.background_color = Color(0.06, 0.01, 0.01)
	environnement_obscurite.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environnement_obscurite.ambient_light_color = Color(0.17, 0.05, 0.05)
	environnement_obscurite.ambient_light_energy = 0.16
	environnement_obscurite.fog_enabled = true
	environnement_obscurite.fog_light_color = Color(0.65, 0.12, 0.05)
	environnement_obscurite.fog_light_energy = 0.35
	environnement_obscurite.fog_density = 0.02

	environnement_monde.environment = environnement_lumiere

# Adapte le rayon de l'arene en fonction du nombre total de joueurs/bots.
func _ajuster_arene_nombre_joueurs() -> void:
	var total_joueurs: int = 1 + GameState.nombre_bots_selectionne
	rayon_arene_courant = START_RADIUS + max(0, total_joueurs - 4) * 1.15

# Cree plateforme, collisions et plan de lave + lumiere de bord pour l'arene jouable.
func _construire_arene() -> void:
	var platform_body: StaticBody3D = StaticBody3D.new()
	platform_body.name = "PlatformBody"
	racine_arene.add_child(platform_body)

	mesh_plateforme = MeshInstance3D.new()
	mesh_plateforme.name = "PlatformMesh"
	var platform_mesh: BoxMesh = BoxMesh.new()
	platform_mesh.size = Vector3(rayon_arene_courant * 2.0, 1.0, rayon_arene_courant * 2.0)
	mesh_plateforme.mesh = platform_mesh
	mesh_plateforme.material_override = materiau_pierre
	mesh_plateforme.position = Vector3(0, 0, 0)
	platform_body.add_child(mesh_plateforme)

	collision_plateforme = CollisionShape3D.new()
	var platform_shape: BoxShape3D = BoxShape3D.new()
	platform_shape.size = Vector3(rayon_arene_courant * 2.0, 1.0, rayon_arene_courant * 2.0)
	collision_plateforme.shape = platform_shape
	platform_body.add_child(collision_plateforme)

	var lava_body: StaticBody3D = StaticBody3D.new()
	lava_body.name = "LavaBody"
	lava_body.position = Vector3(0, -10, 0)
	racine_arene.add_child(lava_body)

	mesh_lave = MeshInstance3D.new()
	mesh_lave.name = "LavaMesh"
	var lava_mesh: BoxMesh = BoxMesh.new()
	lava_mesh.size = Vector3(80, 1, 80)
	mesh_lave.mesh = lava_mesh
	mesh_lave.material_override = materiau_lave
	lava_body.add_child(mesh_lave)

	var lava_collision: CollisionShape3D = CollisionShape3D.new()
	var lava_shape: BoxShape3D = BoxShape3D.new()
	lava_shape.size = Vector3(80, 1, 80)
	lava_collision.shape = lava_shape
	lava_body.add_child(lava_collision)

	var rim_light: OmniLight3D = OmniLight3D.new()
	rim_light.name = "LavaGlow"
	rim_light.position = Vector3(0, -7, 0)
	rim_light.light_color = Color(1.0, 0.38, 0.08)
	rim_light.light_energy = 2.6
	rim_light.omni_range = 42.0
	racine_arene.add_child(rim_light)
	_construire_decor_nether()

# Genere le decor du Nether autour de l'arene (boites texturees, piliers, arcs, cascades de lave).
func _construire_decor_nether() -> void:
	var backdrop_root: Node3D = Node3D.new()
	backdrop_root.name = "NetherBackdrop"
	racine_arene.add_child(backdrop_root)

	_ajouter_boite_texturee(backdrop_root, Vector3(0.0, NETHER_CEILING_HEIGHT, 0.0), Vector3(140.0, 16.0, 140.0), materiau_roche_nether)
	_ajouter_boite_texturee(backdrop_root, Vector3(0.0, NETHER_CEILING_HEIGHT - 7.5, 0.0), Vector3(110.0, 5.0, 110.0), materiau_basalte)

	var lava_border_positions: Array[Vector3] = [
		Vector3(0.0, -12.0, -54.0),
		Vector3(0.0, -12.5, 54.0),
		Vector3(-54.0, -11.0, 0.0),
		Vector3(54.0, -11.5, 0.0),
		Vector3(-40.0, -13.0, -40.0),
		Vector3(40.0, -12.5, -42.0),
		Vector3(-42.0, -12.8, 38.0),
		Vector3(41.0, -12.2, 41.0)
	]
	var lava_border_sizes: Array[Vector3] = [
		Vector3(120.0, 10.0, 18.0),
		Vector3(120.0, 9.0, 18.0),
		Vector3(18.0, 12.0, 120.0),
		Vector3(18.0, 11.0, 120.0),
		Vector3(30.0, 8.0, 30.0),
		Vector3(28.0, 9.0, 28.0),
		Vector3(30.0, 8.0, 26.0),
		Vector3(28.0, 8.0, 30.0)
	]
	for i: int in range(lava_border_positions.size()):
		_ajouter_boite_nether(backdrop_root, lava_border_positions[i], lava_border_sizes[i])

	var ring_positions: Array[Vector3] = [
		Vector3(0.0, 7.0, -NETHER_BACKDROP_RADIUS),
		Vector3(0.0, 6.0, NETHER_BACKDROP_RADIUS),
		Vector3(-NETHER_BACKDROP_RADIUS, 8.0, 0.0),
		Vector3(NETHER_BACKDROP_RADIUS, 9.0, 0.0),
		Vector3(-46.0, 10.0, -44.0),
		Vector3(48.0, 8.0, -40.0),
		Vector3(-44.0, 9.0, 42.0),
		Vector3(43.0, 11.0, 44.0)
	]
	var ring_sizes: Array[Vector3] = [
		Vector3(120.0, NETHER_WALL_HEIGHT, 14.0),
		Vector3(120.0, NETHER_WALL_HEIGHT, 14.0),
		Vector3(14.0, NETHER_WALL_HEIGHT, 120.0),
		Vector3(14.0, NETHER_WALL_HEIGHT, 120.0),
		Vector3(26.0, 24.0, 26.0),
		Vector3(24.0, 21.0, 28.0),
		Vector3(28.0, 22.0, 24.0),
		Vector3(26.0, 25.0, 24.0)
	]
	for i: int in range(ring_positions.size()):
		_ajouter_boite_nether(backdrop_root, ring_positions[i], ring_sizes[i])

	for i: int in range(22):
		var pillar_height: float = aleatoire_partie.randf_range(7.0, 22.0)
		var pillar_size: Vector3 = Vector3(aleatoire_partie.randf_range(4.0, 10.0), pillar_height, aleatoire_partie.randf_range(4.0, 10.0))
		var pillar_pos: Vector3 = Vector3(
			aleatoire_partie.randf_range(-52.0, 52.0),
			-5.0 + pillar_height * 0.5,
			aleatoire_partie.randf_range(-52.0, 52.0)
		)
		if pillar_pos.distance_to(Vector3.ZERO) < rayon_arene_courant + 11.0:
			continue
		var pillar_material: StandardMaterial3D = materiau_basalte if i % 3 == 0 else materiau_roche_nether
		_ajouter_boite_texturee(backdrop_root, pillar_pos, pillar_size, pillar_material)
		if aleatoire_partie.randf() < 0.55:
			_ajouter_pique_nether(backdrop_root, pillar_pos + Vector3(0.0, pillar_height * 0.5 + 1.0, 0.0), aleatoire_partie.randf_range(3.0, 8.0), false)

	for i: int in range(12):
		var shelf_size: Vector3 = Vector3(aleatoire_partie.randf_range(12.0, 24.0), aleatoire_partie.randf_range(3.0, 6.0), aleatoire_partie.randf_range(10.0, 20.0))
		var shelf_pos: Vector3 = Vector3(
			aleatoire_partie.randf_range(-56.0, 56.0),
			aleatoire_partie.randf_range(4.0, 16.0),
			aleatoire_partie.randf_range(-56.0, 56.0)
		)
		if shelf_pos.distance_to(Vector3.ZERO) < rayon_arene_courant + 16.0:
			continue
		_ajouter_boite_texturee(backdrop_root, shelf_pos, shelf_size, materiau_basalte)
		if aleatoire_partie.randf() < 0.6:
			_ajouter_agregat_glowstone(backdrop_root, shelf_pos + Vector3(aleatoire_partie.randf_range(-2.0, 2.0), -shelf_size.y * 0.5 - 0.8, aleatoire_partie.randf_range(-2.0, 2.0)))

	var arch_centers: Array[Vector3] = [
		Vector3(-38.0, 7.0, -30.0),
		Vector3(35.0, 6.5, -34.0),
		Vector3(-34.0, 8.0, 32.0),
		Vector3(39.0, 7.0, 30.0)
	]
	for arch_center: Vector3 in arch_centers:
		_ajouter_arc_nether(backdrop_root, arch_center, aleatoire_partie.randf_range(16.0, 24.0), aleatoire_partie.randf_range(12.0, 17.0), aleatoire_partie.randf_range(5.0, 8.0))

	for i: int in range(18):
		var ceiling_spike_pos: Vector3 = Vector3(
			aleatoire_partie.randf_range(-58.0, 58.0),
			NETHER_CEILING_HEIGHT - aleatoire_partie.randf_range(2.0, 6.0),
			aleatoire_partie.randf_range(-58.0, 58.0)
		)
		if ceiling_spike_pos.distance_to(Vector3.ZERO) < rayon_arene_courant + 12.0:
			continue
		_ajouter_pique_nether(backdrop_root, ceiling_spike_pos, aleatoire_partie.randf_range(4.0, 10.0), true)

	for i: int in range(10):
		var lavafall_height: float = aleatoire_partie.randf_range(18.0, 34.0)
		var lavafall_pos: Vector3 = Vector3(
			aleatoire_partie.randf_range(-52.0, 52.0),
			aleatoire_partie.randf_range(10.0, 18.0),
			aleatoire_partie.randf_range(-52.0, 52.0)
		)
		if lavafall_pos.distance_to(Vector3.ZERO) < rayon_arene_courant + 12.0:
			continue
		_ajouter_cascade_lave(backdrop_root, lavafall_pos, lavafall_height)

	var glow_positions: Array[Vector3] = [
		Vector3(-26.0, 20.0, -32.0),
		Vector3(31.0, 22.0, -24.0),
		Vector3(-34.0, 18.0, 27.0),
		Vector3(22.0, 19.0, 36.0),
		Vector3(-9.0, 24.0, 48.0),
		Vector3(8.0, 23.0, -46.0),
		Vector3(-46.0, 15.0, 2.0),
		Vector3(44.0, 17.0, -4.0)
	]
	for glow_pos: Vector3 in glow_positions:
		_ajouter_agregat_glowstone(backdrop_root, glow_pos)

func _ajouter_boite_texturee(target_root: Node3D, position: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.material_override = material
	target_root.add_child(mesh_instance)
	return mesh_instance

func _ajouter_boite_nether(target_root: Node3D, position: Vector3, size: Vector3) -> void:
	_ajouter_boite_texturee(target_root, position, size, materiau_roche_nether)

func _ajouter_arc_nether(target_root: Node3D, center: Vector3, span: float, height: float, thickness: float) -> void:
	_ajouter_boite_texturee(target_root, center + Vector3(-span * 0.5, -2.0, 0.0), Vector3(thickness, height, thickness + 1.5), materiau_basalte)
	_ajouter_boite_texturee(target_root, center + Vector3(span * 0.5, -2.0, 0.0), Vector3(thickness, height, thickness + 1.5), materiau_basalte)
	_ajouter_boite_texturee(target_root, center + Vector3(0.0, height * 0.35, 0.0), Vector3(span + thickness, thickness, thickness + 2.0), materiau_roche_nether)
	_ajouter_boite_texturee(target_root, center + Vector3(0.0, height * 0.12, 0.0), Vector3(span * 0.72, thickness * 0.8, thickness + 0.8), materiau_basalte)

func _ajouter_pique_nether(target_root: Node3D, origin: Vector3, height: float, hanging: bool) -> void:
	var segments: int = max(2, int(round(height / 2.0)))
	for i: int in range(segments):
		var t: float = float(i) / float(max(1, segments - 1))
		var segment_scale: float = lerp(1.8, 0.45, t)
		var y_offset: float = -i * 1.6 if hanging else i * 1.6
		_ajouter_boite_texturee(
			target_root,
			origin + Vector3(0.0, y_offset, 0.0),
			Vector3(segment_scale, 1.8, segment_scale),
			materiau_basalte if i % 2 == 0 else materiau_roche_nether
		)

func _ajouter_cascade_lave(target_root: Node3D, top_position: Vector3, height: float) -> void:
	var lavafall: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(1.6, height, 1.6)
	lavafall.mesh = mesh
	lavafall.position = top_position + Vector3(0.0, -height * 0.5, 0.0)
	lavafall.material_override = materiau_lave
	target_root.add_child(lavafall)

	var splash: MeshInstance3D = MeshInstance3D.new()
	var splash_mesh: CylinderMesh = CylinderMesh.new()
	splash_mesh.top_radius = 2.8
	splash_mesh.bottom_radius = 3.6
	splash_mesh.height = 0.8
	splash.mesh = splash_mesh
	splash.position = Vector3(top_position.x, -9.5, top_position.z)
	splash.material_override = materiau_lave
	target_root.add_child(splash)

	if aleatoire_partie.randf() < 0.7:
		_ajouter_boite_texturee(target_root, Vector3(top_position.x, top_position.y + 0.8, top_position.z), Vector3(3.2, 1.2, 3.2), materiau_roche_nether)

func _ajouter_agregat_glowstone(target_root: Node3D, center: Vector3) -> void:
	var offsets: Array[Vector3] = [
		Vector3.ZERO,
		Vector3(1.5, -0.8, 0.4),
		Vector3(-1.2, -1.0, -0.6),
		Vector3(0.6, -1.7, -1.0),
		Vector3(-0.5, -2.1, 0.9)
	]
	for offset: Vector3 in offsets:
		var glow: MeshInstance3D = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(1.8, 1.8, 1.8)
		glow.mesh = mesh
		glow.position = center + offset
		glow.material_override = materiau_pierre_luisante
		target_root.add_child(glow)

# Instancie les joueurs (humain + bots), choisit leurs skins et place aux positions de spawn.
func _apparaitre_joueurs() -> void:
	var total_joueurs: int = 1 + GameState.nombre_bots_selectionne
	var character_pool: Array[Dictionary] = []
	for option: Dictionary in GameState.OPTIONS_PERSONNAGE:
		character_pool.append(option)

	var selected_character: Dictionary = GameState.obtenir_personnage_selectionne()
	var roster: Array[Dictionary] = [selected_character]
	var bot_index: int = 0
	while roster.size() < total_joueurs:
		var option: Dictionary = character_pool[bot_index % character_pool.size()]
		if option["id"] == selected_character["id"]:
			bot_index += 1
			continue
		roster.append(option)
		bot_index += 1

	var spawn_positions: Array[Vector3] = _generer_positions_spawn(total_joueurs)

	for i: int in range(total_joueurs):
		var player: PlayerCharacter = PLAYER_SCENE.instantiate() as PlayerCharacter
		var character: Dictionary = roster[i]
		player.nom_joueur = GameState.obtenir_nom_joueur_humain() if i == 0 else GameState.obtenir_nom_bot(character)
		player.couleur_joueur = character.get("body_color", player.couleur_joueur)
		player.couleur_peau = character.get("skin_color", character.get("couleur_peau", player.couleur_peau))
		player.couleur_accent = character.get("accent_color", character.get("couleur_accent", player.couleur_accent))
		player.elimine.connect(_sur_joueur_elimine)
		racine_joueurs.add_child(player)
		player.global_position = spawn_positions[i]
		player.look_at(centre_arene, Vector3.UP)
		if i == 0:
			player.definir_controle_humain(true)
			player.definir_visible_dans_obscurite(true)
			joueur_humain_principal = player
		else:
			player.definir_visible_dans_obscurite(false)
		joueurs_partie.append(player)

# Calcule les positions de spawn sur un cercle autour du centre de l'arene.
func _generer_positions_spawn(total_joueurs: int) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var spawn_radius: float = max(3.5, rayon_arene_courant - 2.2)
	for i: int in range(total_joueurs):
		var angle: float = (TAU * float(i) / float(total_joueurs)) - PI * 0.5
		positions.append(centre_arene + Vector3(cos(angle) * spawn_radius, 1.05, sin(angle) * spawn_radius))
	return positions

# Lance la phase sombre: duree decroissante, rend scene sombre et prepare deplacements bots/humain.
func _demarrer_phase_obscure() -> void:
	# phase_jeu déplacement : joueurs_partie bougent, lasers cachés, durée décroissante.
	phase_jeu = PhaseJeu.DARK
	var decay_factor: float = pow(SHRINK_FACTOR, max(0, numero_manche_courant - 1))
	temps_phase_restant = max(5.0, DARK_DURATION * decay_factor)
	environnement_monde.environment = environnement_obscurite
	lumiere_soleil.light_energy = 0.08
	# On ne montre plus d'overlay gris au démarrage de la partie (manche 1) pour éviter l'écran gris au lancement.
	# Les manches suivantes conservent la transition afin de laisser le temps de lire les infos.
	if numero_manche_courant > 1:
		_afficher_transition_manche("Manche %d" % numero_manche_courant, _construire_texte_liste_vivants())
	else:
		transition_en_cours = false
		overlay_transition_manche.visible = false
	_rafraichir_ui_ordre_tir()
	for player: PlayerCharacter in joueurs_partie:
		if player.est_vivant:
			player.planifier_phase_obscure(centre_arene, rayon_arene_courant, aleatoire_partie)
			player.definir_visibilite_phase(true)

# Avance le timer de phase sombre, gere controles humain/bots puis bascule en phase lumiere si ecoule.
func _mettre_a_jour_phase_obscure(delta: float) -> void:
	temps_phase_restant -= delta
	if joueur_humain_principal != null and joueur_humain_principal.est_vivant:
		if Input.is_action_just_pressed("toggle_prone"):
			joueur_humain_principal.basculer_allonge()
		var controller_aim: Vector2 = _obtenir_entree_visee_manette()
		if controller_aim.length() >= GAMEPAD_DEADZONE:
			controle_camera_manette_actif = true
			lacet_camera_manette -= controller_aim.x * CAMERA_CONTROLLER_YAW_SPEED * delta
			tangage_camera_manette = clamp(tangage_camera_manette + controller_aim.y * CAMERA_CONTROLLER_PITCH_SPEED * delta, CAMERA_CONTROLLER_PITCH_MIN, CAMERA_CONTROLLER_PITCH_MAX)
			_mettre_a_jour_visee_manette_depuis_camera()
		elif not controle_camera_manette_actif:
			_mettre_a_jour_visee_souris_depuis_camera()
		var input_vector: Vector2 = _obtenir_vecteur_deplacement()
		joueur_humain_principal.deplacer_humain(input_vector, camera.global_basis, centre_arene, rayon_arene_courant)
	for player: PlayerCharacter in joueurs_partie:
		player.deplacer_en_obscurite(delta, centre_arene, rayon_arene_courant)
	if temps_phase_restant <= 0.0:
		_demarrer_phase_lumineuse()


func _obtenir_rayon_erreur_visee_bot() -> float:
	match GameState.difficulte_bots_selectionnee:
		GameState.BOT_DIFFICULTE_DEBUTANT:
			return 2.4
		GameState.BOT_DIFFICULTE_DIFFICILE:
			return 0.35
		_:
			return 1.1

func _obtenir_point_visee_bot(target: PlayerCharacter) -> Vector3:
	var error_radius: float = _obtenir_rayon_erreur_visee_bot()
	var offset: Vector3 = Vector3(
		aleatoire_partie.randf_range(-error_radius, error_radius),
		target.obtenir_hauteur_focus_camera(),
		aleatoire_partie.randf_range(-error_radius, error_radius)
	)
	return target.global_position + offset

# Configure la phase tir: verrouille directions, ordonne la file, eclaire la scene et stoppe les mouvements.
func _demarrer_phase_lumineuse() -> void:
	# Phase tir : verrouille les directions de tir, affiche ordre et lance transition.
	phase_jeu = PhaseJeu.LIGHT
	delai_avant_tir = 0.3
	phase_lumiere_revelee = false
	temps_observation_phase_lumiere = 0.0
	environnement_monde.environment = environnement_lumiere
	lumiere_soleil.light_energy = 1.8
	for player: PlayerCharacter in joueurs_partie:
		if player != null:
			player.arreter_mouvement()

	file_tirs_ordonnee.clear()
	for player: PlayerCharacter in joueurs_partie:
		if not player.est_vivant:
			continue
		if not player.est_humain:
			var target: Variant = player.choisir_cible(joueurs_partie, aleatoire_partie)
			if target != null:
				player.viser_point(_obtenir_point_visee_bot(target as PlayerCharacter))
		file_tirs_ordonnee.append(player)
	file_tirs_ordonnee.shuffle()
	_afficher_transition_manche("Phase de tir", _construire_texte_liste_vivants())
	var reveal_timer: SceneTreeTimer = get_tree().create_timer(ROUND_TRANSITION_FADE_IN + 0.15)
	reveal_timer.timeout.connect(_reveler_phase_lumineuse)

# Orchestration des tirs sequentiels pendant la lumiere (revele ordre, applique delais et passage fin manche).
func _mettre_a_jour_phase_lumineuse(delta: float) -> void:
	# Gère le tempo des tirs séquentiels pendant la phase_jeu lumière.
	if not phase_lumiere_revelee:
		return
	if temps_observation_phase_lumiere > 0.0:
		temps_observation_phase_lumiere -= delta
		if temps_observation_phase_lumiere > 0.0:
			return
		delai_avant_tir = min(delai_avant_tir, 0.3)
	if file_tirs_ordonnee.is_empty():
		phase_jeu = PhaseJeu.ROUND_END
		temps_phase_restant = 1.2
		await get_tree().create_timer(1.0).timeout
		_afficher_transition_manche("Fin manche %d" % numero_manche_courant, _construire_texte_liste_vivants())
		return

	delai_avant_tir -= delta
	if delai_avant_tir > 0.0:
		return

	var shooter: PlayerCharacter = file_tirs_ordonnee.pop_front() as PlayerCharacter
	if is_instance_valid(shooter) and shooter.est_vivant:
		_tirer_projectile_direction(shooter, shooter.obtenir_direction_tir_verrouillee())
	delai_avant_tir = LIGHT_SHOT_DELAY
	_rafraichir_ui_ordre_tir()

func _reveler_phase_lumineuse() -> void:
	if phase_jeu != PhaseJeu.LIGHT:
		return
	phase_lumiere_revelee = true
	temps_observation_phase_lumiere = PRE_LIGHT_OBSERVE_TIME
	delai_avant_tir = 0.3
	cible_camera_suivie = joueur_humain_principal
	mode_camera_libre_actif = false
	for player: PlayerCharacter in joueurs_partie:
		if not player.est_vivant:
			continue
		player.definir_visibilite_phase(false)
		player.verrouiller_pour_lumiere()
	var queued_joueurs: Array[PlayerCharacter] = []
	for player: PlayerCharacter in file_tirs_ordonnee:
		if is_instance_valid(player) and player.est_vivant:
			queued_joueurs.append(player)
	_appliquer_nameplates_ordre_tir(queued_joueurs)
	_rafraichir_ui_ordre_tir()

# Entre deux manches: timer court, si un seul survivant -> fin, sinon reduit arene et relance phase sombre.
func _mettre_a_jour_fin_manche(delta: float) -> void:
	# Petite pause entre manches, rétrécit l'arène puis relance la phase_jeu sombre.
	_rafraichir_ui_ordre_tir()
	temps_phase_restant -= delta
	if temps_phase_restant > 0.0:
		return

	var joueurs_vivants: Array[PlayerCharacter] = _obtenir_joueurs_vivants()
	if joueurs_vivants.size() <= 1:
		_terminer_partie()
		return

	numero_manche_courant += 1
	rayon_arene_courant = max(MIN_RADIUS, rayon_arene_courant * SHRINK_FACTOR)
	_mettre_a_jour_taille_plateforme()
	_repositionner_hors_joueurs()
	_demarrer_phase_obscure()

# Instancie un projectile et le configure avec position de bouche et direction verrouillee.
func _tirer_projectile_direction(shooter: PlayerCharacter, direction: Vector3) -> void:
	# Instancie et tire un projectile depuis un joueur donné.
	var projectile: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
	racine_projectiles.add_child(projectile)
	projectile.configurer(shooter.obtenir_position_bouche_canon(), direction, shooter)
	projectile.joueur_touche.connect(_sur_projectile_touche)

# Callback projectile: si touche un joueur vivant, affiche notif et elimine la cible.
func _sur_projectile_touche(target: PlayerCharacter, shooter: PlayerCharacter) -> void:
	# Callback sur touche : élimine la cible et notifie.
	if target != null and target.est_vivant:
		if target == joueur_humain_principal and shooter != null and shooter.est_vivant:
			joueur_spectateur_cible = shooter
			_caler_camera_sur_joueur(joueur_spectateur_cible)
			_afficher_overlay_mort()
		var shooter_name: String = shooter.nom_joueur if shooter != null else "?"
		_afficher_notification("%s touche %s" % [shooter_name, target.nom_joueur])
		target.eliminer()

# Met a jour ordre d elimination, camera spectateur et declenche fin de partie si necessaire.
func _sur_joueur_elimine(player: PlayerCharacter) -> void:
	# Gestion de l'ordre d'élimination, spectateur, fin de partie potentielle.
	if not ordre_eliminations.has(player):
		ordre_eliminations.append(player)
	file_tirs_ordonnee.erase(player)
	_afficher_notification("%s est éliminé" % player.nom_joueur)
	if player == joueur_humain_principal:
		if joueur_spectateur_cible == null or not joueur_spectateur_cible.est_vivant:
			joueur_spectateur_cible = _trouver_premier_vivant_sauf(joueur_humain_principal)
		_afficher_notification("Vous \u00EAtes mort")
		_afficher_overlay_mort()
	if joueur_spectateur_cible == player:
		joueur_spectateur_cible = _trouver_premier_vivant_sauf(joueur_humain_principal)
	if joueur_humain_principal != null and not joueur_humain_principal.est_vivant and joueur_spectateur_cible != null:
		_caler_camera_sur_joueur(joueur_spectateur_cible)
	_rafraichir_ui_ordre_tir()
	if _obtenir_joueurs_vivants().size() <= 1 and phase_jeu != PhaseJeu.GAME_OVER:
		_terminer_partie()

func _trouver_premier_vivant_sauf(excluded: PlayerCharacter) -> Variant:
	for player: PlayerCharacter in joueurs_partie:
		if player != excluded and player.est_vivant:
			return player
	return null

# Assure qu'un joueur valide est suivi en mode spectateur quand le joueur humain est mort.
func _assurer_cible_spectateur() -> void:
	# S'assure qu'un joueur valide est suivi en spectateur.
	if joueur_humain_principal != null and joueur_humain_principal.est_vivant:
		return
	if joueur_spectateur_cible == null or not joueur_spectateur_cible.est_vivant:
		joueur_spectateur_cible = _trouver_premier_vivant_sauf(joueur_humain_principal)
		if joueur_spectateur_cible != null:
			_caler_camera_sur_joueur(joueur_spectateur_cible)

# Fait defiler la cible spectateur parmi les survivants (clic gauche/droit).
func _alterner_joueur_spectateur_cible(direction: int) -> void:
	# Parcours des survivants en spectateur (clic gauche/droit).
	var joueurs_vivants: Array[PlayerCharacter] = _obtenir_joueurs_vivants()
	if joueur_humain_principal != null:
		joueurs_vivants.erase(joueur_humain_principal)
	if joueurs_vivants.is_empty():
		return
	var current_index: int = joueurs_vivants.find(joueur_spectateur_cible)
	if current_index == -1:
		current_index = 0
	var next_index: int = wrapi(current_index + direction, 0, joueurs_vivants.size())
	joueur_spectateur_cible = joueurs_vivants[next_index]
	_caler_camera_sur_joueur(joueur_spectateur_cible)

func _caler_camera_sur_joueur(target_player: PlayerCharacter) -> void:
	if target_player == null:
		return
	var focus_point: Vector3 = target_player.global_position + Vector3(0, target_player.obtenir_hauteur_focus_camera(), 0)
	var back_direction: Vector3 = target_player.global_basis.z
	back_direction.y = 0.0
	if back_direction.length() < 0.01:
		back_direction = Vector3.BACK
	back_direction = back_direction.normalized()
	var right_direction: Vector3 = target_player.global_basis.x
	right_direction.y = 0.0
	if right_direction.length() < 0.01:
		right_direction = Vector3.RIGHT
	right_direction = right_direction.normalized()
	var desired_position: Vector3 = focus_point + Vector3(0, target_player.obtenir_offset_hauteur_camera(), 0) + back_direction * distance_camera_courante + right_direction * CAMERA_SIDE_OFFSET
	camera.global_position = desired_position
	camera.look_at(focus_point, Vector3.UP)
	controle_camera_manette_actif = false
	cible_camera_suivie = target_player

func _sur_spectateur_quitter_presse() -> void:
	_sauvegarder_resultat_partie()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/mode_select.tscn")

func _obtenir_joueur_cible_camera() -> Variant:
	if joueur_humain_principal != null and joueur_humain_principal.est_vivant:
		return joueur_humain_principal
	if joueur_spectateur_cible != null and joueur_spectateur_cible.est_vivant:
		return joueur_spectateur_cible
	return _trouver_premier_vivant_sauf(null)

# Ajuste la distance orbitale de la camera selon la molette (borne min/max).
func _ajuster_zoom_camera(direction: int) -> void:
	# direction > 0 : zoom avant, direction < 0 : zoom arrière.
	distance_camera_courante = clamp(distance_camera_courante - float(direction) * CAMERA_ZOOM_PAS, CAMERA_DISTANCE_MIN, CAMERA_DISTANCE_MAX)

func _mettre_a_jour_taille_plateforme() -> void:
	var platform_mesh: BoxMesh = mesh_plateforme.mesh as BoxMesh
	platform_mesh.size = Vector3(rayon_arene_courant * 2.0, 1.0, rayon_arene_courant * 2.0)

	var platform_shape: BoxShape3D = collision_plateforme.shape as BoxShape3D
	platform_shape.size = Vector3(rayon_arene_courant * 2.0, 1.0, rayon_arene_courant * 2.0)

# Camera orbitale: suit humain ou spectateur, integre souris/manette/gyro et distance de zoom.
func _mettre_a_jour_camera(delta: float) -> void:
	# Caméra orbitale : souris par défaut, gyro si la souris sort de l'écran.
	_assurer_cible_spectateur()
	var camera_target: Variant = _obtenir_joueur_cible_camera()
	if camera_target == null:
		return
	var target_player: PlayerCharacter = camera_target as PlayerCharacter
	var focus_point: Vector3 = target_player.global_position + Vector3(0, target_player.obtenir_hauteur_focus_camera(), 0)
	var was_mouse_inside: bool = souris_dans_viewport
	souris_dans_viewport = _souris_dans_viewport()
	if not souris_dans_viewport and was_mouse_inside:
		gyro_actif = true
	if souris_dans_viewport and not was_mouse_inside:
		gyro_actif = false
	if gyro_actif and not souris_dans_viewport:
		lacet_camera_souris += vitesse_lacet_gyro_mode * delta
		tangage_camera_souris = clamp(tangage_camera_souris + vitesse_tangage_gyro_mode * delta, CAMERA_CONTROLLER_PITCH_MIN, CAMERA_CONTROLLER_PITCH_MAX)
		lacet_camera_libre = lacet_camera_souris
		tangage_camera_libre = tangage_camera_souris
	if not souris_dans_viewport:
		lacet_camera_manette = lacet_camera_souris
		tangage_camera_manette = tangage_camera_souris
	if mode_camera_libre_actif and target_player == cible_camera_suivie:
		var use_yaw_fc: float = lacet_camera_libre if not souris_dans_viewport else lacet_camera_souris
		var use_pitch_fc: float = tangage_camera_libre if not souris_dans_viewport else tangage_camera_souris
		var look_basis_fc: Basis = Basis(Vector3.UP, use_yaw_fc) * Basis(Vector3.RIGHT, use_pitch_fc)
		var forward_fc: Vector3 = -look_basis_fc.z
		var right_fc: Vector3 = look_basis_fc.x
		var vertical_offset_fc: float = target_player.obtenir_offset_hauteur_camera() - target_player.obtenir_hauteur_focus_camera()
		var desired_position_fc: Vector3 = focus_point - forward_fc * distance_camera_courante + right_fc * CAMERA_SIDE_OFFSET + Vector3.UP * vertical_offset_fc
		camera.global_position = camera.global_position.lerp(desired_position_fc, clamp(delta * CAMERA_SMOOTHNESS, 0.0, 1.0))
		camera.look_at(focus_point, Vector3.UP)
		return
	if target_player == joueur_humain_principal:
		var use_yaw: float = lacet_camera_manette if (controle_camera_manette_actif or not souris_dans_viewport) else lacet_camera_souris
		var use_pitch: float = tangage_camera_manette if (controle_camera_manette_actif or not souris_dans_viewport) else tangage_camera_souris
		var look_basis: Basis = Basis(Vector3.UP, use_yaw) * Basis(Vector3.RIGHT, use_pitch)
		var forward: Vector3 = -look_basis.z
		var right: Vector3 = look_basis.x
		var vertical_offset: float = target_player.obtenir_offset_hauteur_camera() - target_player.obtenir_hauteur_focus_camera()
		var desired_position: Vector3 = focus_point - forward * distance_camera_courante + right * CAMERA_SIDE_OFFSET + Vector3.UP * vertical_offset
		camera.global_position = camera.global_position.lerp(desired_position, clamp(delta * CAMERA_SMOOTHNESS, 0.0, 1.0))
		camera.look_at(focus_point, Vector3.UP)
		return
	var back_direction: Vector3 = target_player.global_basis.z
	back_direction.y = 0.0
	if back_direction.length() < 0.01:
		back_direction = Vector3.BACK
	back_direction = back_direction.normalized()
	var right_direction: Vector3 = target_player.global_basis.x
	right_direction.y = 0.0
	if right_direction.length() < 0.01:
		right_direction = Vector3.RIGHT
	right_direction = right_direction.normalized()
	var desired_position: Vector3 = focus_point + Vector3(0, target_player.obtenir_offset_hauteur_camera(), 0) + back_direction * distance_camera_courante + right_direction * CAMERA_SIDE_OFFSET
	camera.global_position = camera.global_position.lerp(desired_position, clamp(delta * CAMERA_SMOOTHNESS, 0.0, 1.0))
	camera.look_at(focus_point, Vector3.UP)

# Ramene les joueurs vivants a l'interieur du rayon apres reduction d'arene.
func _repositionner_hors_joueurs() -> void:
	var limit: float = max(1.0, rayon_arene_courant - 0.8)
	for player: PlayerCharacter in joueurs_partie:
		if not player.est_vivant:
			continue
		var local_pos: Vector3 = player.global_position - centre_arene
		local_pos.x = clamp(local_pos.x, -limit, limit)
		local_pos.z = clamp(local_pos.z, -limit, limit)
		player.global_position = centre_arene + local_pos
		player.global_position.y = 1.05

# Met a jour le panneau d'ordre de tir et les nameplates numerotes pendant la phase lumiere.
func _rafraichir_ui_ordre_tir() -> void:
	# Met à jour le panneau d'ordre de tir et les nameplates (#).
	if phase_jeu != PhaseJeu.LIGHT or not phase_lumiere_revelee:
		panneau_ordre.visible = false
		return
	for child: Node in liste_ordre.get_children():
		child.queue_free()
	var queued_joueurs: Array[PlayerCharacter] = []
	for player: PlayerCharacter in file_tirs_ordonnee:
		if is_instance_valid(player) and player.est_vivant:
			queued_joueurs.append(player)
	if queued_joueurs.is_empty():
		panneau_ordre.visible = false
		return
	panneau_ordre.visible = true
	var index: int = 1
	for player: PlayerCharacter in queued_joueurs:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var number_label: Label = Label.new()
		number_label.text = "%d." % index
		var number_color: Color = Color(0.85, 0.85, 0.9)
		if index == 1:
			number_color = Color(1, 1, 1)
		number_label.add_theme_color_override("font_color", number_color)
		row.add_child(number_label)
		var name_label: Label = Label.new()
		name_label.text = player.nom_joueur
		var couleur_joueur: Color = player.couleur_joueur
		if index == 1:
			couleur_joueur = couleur_joueur.lightened(0.35)
		name_label.add_theme_color_override("font_color", couleur_joueur)
		if player == joueur_spectateur_cible:
			name_label.text += " (cam)"
		row.add_child(name_label)
		liste_ordre.add_child(row)
		index += 1
	_appliquer_nameplates_ordre_tir(queued_joueurs)

# Renvoie la liste des noms des survivants pour les overlays.
func _construire_texte_liste_vivants() -> String:
	# Texte pour la transition listant les survivants.
	var names: Array[String] = []
	for player: PlayerCharacter in _obtenir_joueurs_vivants():
		names.append(player.nom_joueur)
	return "Joueurs en vie : %s" % ", ".join(names)

# Affiche un message court avec fondu (duree speciale pour mort du joueur).
func _afficher_notification(text: String) -> void:
	if text == "":
		etiquette_notification.visible = false
		return
	etiquette_notification.text = text
	etiquette_notification.visible = true
	etiquette_notification.modulate.a = 1.0
	var duree_visibilite: float = 1.6
	var duree_fondu: float = 0.4
	if text.to_lower() == "Vous \u00EAtes mort" or text.to_lower() == "Vous \u00EAtes morts":
		duree_visibilite = 3.2
		duree_fondu = 0.8
	var tween := create_tween()
	tween.tween_interval(duree_visibilite)
	tween.tween_property(etiquette_notification, "modulate:a", 0.0, duree_fondu)
	tween.finished.connect(func(): etiquette_notification.visible = false)

# Applique le texte (#ordre) sur chaque nameplate de la file de tir, cache les autres.
func _appliquer_nameplates_ordre_tir(queued_joueurs: Array[PlayerCharacter]) -> void:
	# Affiche pseudo + ordre de tir au-dessus de chaque bot (et des humains adverses éventuels).
	for i: int in range(queued_joueurs.size()):
		var player: PlayerCharacter = queued_joueurs[i]
		if player != null and player.est_vivant:
			player.definir_texte_nameplate("%s (#%d)" % [player.nom_joueur, i + 1])
			player.definir_nameplate_visible(true)
	# Nettoie les autres vivants pour éviter un ordre obsolète.
	for player: PlayerCharacter in _obtenir_joueurs_vivants():
		if not queued_joueurs.has(player):
			player.definir_texte_nameplate(player.nom_joueur)
			var should_show: bool = (phase_jeu == PhaseJeu.LIGHT and phase_lumiere_revelee) or player == joueur_humain_principal
			player.definir_nameplate_visible(should_show)

# Rafraichit HUD (phase, etiquettes spectateur, compteur survivants, visibility nameplates).
func _mettre_a_jour_ui() -> void:
	# Rafraîchit HUD (phase_jeu, spectateur, compteur survivants).
	var alive_names: Array[String] = []
	for player: PlayerCharacter in joueurs_partie:
		if player.est_vivant:
			alive_names.append(player.nom_joueur)

	match phase_jeu:
		PhaseJeu.DARK:
			var secondes_restantes: float = max(0.0, temps_phase_restant)
			etiquette_phase.text = "Déplacement : %.1f s" % secondes_restantes
		PhaseJeu.LIGHT:
			etiquette_phase.text = ""
		PhaseJeu.ROUND_END:
			etiquette_phase.text = ""
		PhaseJeu.GAME_OVER:
			etiquette_phase.text = "Partie terminee"

	var is_spectating: bool = joueur_humain_principal != null and not joueur_humain_principal.est_vivant and phase_jeu != PhaseJeu.GAME_OVER
	etiquette_spectateur.visible = is_spectating
	if is_spectating and joueur_spectateur_cible != null and joueur_spectateur_cible.est_vivant:
		etiquette_spectateur.text = "Spectateur - %s" % joueur_spectateur_cible.nom_joueur
	else:
		etiquette_spectateur.text = "Spectateur"
	if is_spectating and phase_jeu == PhaseJeu.DARK:
		for player: PlayerCharacter in joueurs_partie:
			if player.est_vivant:
				player.definir_visible_dans_obscurite(true)
				player.definir_visibilite_phase(true)
		cible_camera_suivie = joueur_spectateur_cible
		mode_camera_libre_actif = true
		lacet_camera_libre = lacet_camera_souris
		tangage_camera_libre = tangage_camera_souris
	if joueur_humain_principal != null and joueur_humain_principal.est_vivant:
		joueur_humain_principal.definir_texte_nameplate("%s" % joueur_humain_principal.nom_joueur)
		joueur_humain_principal.definir_nameplate_visible(true)
		cible_camera_suivie = joueur_humain_principal
		mode_camera_libre_actif = false

	if ecran_fin_visible:
		etiquette_info.text = ""
	else:
		etiquette_info.text = "Joueurs en vie : %d" % alive_names.size()

# Anime l'overlay de transition de manche (fade in/hold/fade out).
func _afficher_transition_manche(text: String, alive_text: String = "") -> void:
	transition_en_cours = true
	if is_instance_valid(tween_transition_manche):
		tween_transition_manche.kill()
	etiquette_transition_manche.text = text
	etiquette_survivants_manche.text = alive_text
	overlay_transition_manche.modulate.a = 0.0
	overlay_transition_manche.visible = true
	tween_transition_manche = create_tween()
	tween_transition_manche.tween_property(overlay_transition_manche, "modulate:a", 0.8, ROUND_TRANSITION_FADE_IN)
	tween_transition_manche.tween_interval(ROUND_TRANSITION_HOLD)
	tween_transition_manche.tween_property(overlay_transition_manche, "modulate:a", 0.0, ROUND_TRANSITION_FADE_OUT)
	tween_transition_manche.finished.connect(_cacher_transition_manche)

func _cacher_transition_manche() -> void:
	overlay_transition_manche.visible = false
	etiquette_survivants_manche.text = ""
	tween_transition_manche = null
	transition_en_cours = false

func _creer_overlay_mort() -> void:
	var layer: CanvasLayer = $CanvasLayer
	overlay_mort = ColorRect.new()
	overlay_mort.name = "DeathOverlay"
	overlay_mort.color = Color(0, 0, 0, 0.78)
	overlay_mort.visible = false
	overlay_mort.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay_mort.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_mort.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay_mort.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay_mort)

	etiquette_mort = Label.new()
	etiquette_mort.text = "Vous \u00EAtes mort"
	etiquette_mort.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiquette_mort.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiquette_mort.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etiquette_mort.size_flags_vertical = Control.SIZE_EXPAND_FILL
	etiquette_mort.set_anchors_preset(Control.PRESET_FULL_RECT)
	etiquette_mort.set_offsets_preset(Control.PRESET_FULL_RECT)
	etiquette_mort.add_theme_font_size_override("font_size", 64)
	overlay_mort.add_child(etiquette_mort)

func _afficher_overlay_mort() -> void:
	if overlay_mort == null:
		return
	overlay_mort.visible = true
	overlay_mort.modulate.a = 0.0
	if etiquette_mort != null:
		etiquette_mort.scale = Vector2.ONE
	overlay_mort_actif = true
	var tween := create_tween()
	tween.tween_property(overlay_mort, "modulate:a", 0.85, 0.15)
	tween.tween_interval(2.0)
	tween.tween_property(overlay_mort, "modulate:a", 0.0, 0.35)
	tween.finished.connect(_fin_overlay_mort)

func _fin_overlay_mort() -> void:
	if overlay_mort != null:
		overlay_mort.visible = false
		overlay_mort.modulate.a = 0.0
	overlay_mort_actif = false
	_assurer_cible_spectateur()
	if joueur_spectateur_cible != null:
		_caler_camera_sur_joueur(joueur_spectateur_cible)

# Declenche fin de partie: arrete les phases, sauvegarde score, desactive pause.
func _terminer_partie() -> void:
	if ecran_fin_visible:
		return
	phase_jeu = PhaseJeu.GAME_OVER
	_sauvegarder_resultat_partie()
	_afficher_ecran_fin()

# Affiche l'overlay de fin, verrouille le jeu et connecte les boutons de fin.
func _afficher_ecran_fin() -> void:
	# Affiche l'écran de fin (victoire/défaite) et fige la partie.
	ecran_fin_visible = true
	if menu_pause_visible:
		_fermer_menu_pause()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	overlay_fin.visible = true
	panneau_ordre.visible = false
	overlay_transition_manche.visible = false
	var human_alive: bool = joueur_humain_principal != null and joueur_humain_principal.est_vivant
	etiquette_titre_fin.text = "Victoire" if human_alive else "Défaite"
	_afficher_notification(etiquette_titre_fin.text)
	etiquette_classement.text = _construire_texte_classement()
	etiquette_spectateur.visible = false
	MenuAudio.connecter_boutons(overlay_fin)
	bouton_fin_rejouer.call_deferred("grab_focus")

func _calculer_classement_final() -> Array[PlayerCharacter]:
	var ranking: Array[PlayerCharacter] = []
	for survivor: PlayerCharacter in _obtenir_joueurs_vivants():
		if not ranking.has(survivor):
			ranking.append(survivor)
	for index: int in range(ordre_eliminations.size() - 1, -1, -1):
		var elimine_player: PlayerCharacter = ordre_eliminations[index]
		if not ranking.has(elimine_player):
			ranking.append(elimine_player)
	for player: PlayerCharacter in joueurs_partie:
		if not ranking.has(player):
			ranking.append(player)
	return ranking

func _obtenir_rang_joueur(target_player: PlayerCharacter, ranking: Array[PlayerCharacter]) -> int:
	if target_player == null:
		return -1
	var index: int = ranking.find(target_player)
	return index + 1 if index != -1 else -1

func _construire_texte_classement() -> String:
	var ranking: Array[PlayerCharacter] = _calculer_classement_final()
	var lines: Array[String] = []
	for i: int in range(ranking.size()):
		var player: PlayerCharacter = ranking[i]
		lines.append("%d. %s" % [i + 1, player.nom_joueur])
	return "\n".join(lines)

# Persiste le resultat de partie en SQLite (rang, skin, difficulte, bots, mode).
func _sauvegarder_resultat_partie() -> void:
	if score_deja_enregistre:
		return
	if joueur_humain_principal == null:
		return
	var ranking: Array[PlayerCharacter] = _calculer_classement_final()
	var player_rank: int = _obtenir_rang_joueur(joueur_humain_principal, ranking)
	if player_rank <= 0:
		return
	# On enregistre rank 1 = vainqueur, 2 = second, etc.
	var rang_en_base: int = player_rank
	var selected_character: Dictionary = GameState.obtenir_personnage_selectionne()
	var skin_id: String = selected_character.get("id", "unknown")
	var difficulty_for_db: String = _mapper_difficulte_bd(GameState.difficulte_bots_selectionnee)
	enregistrer_score_bdd(
		joueur_humain_principal.nom_joueur,
		rang_en_base,
		skin_id,
		difficulty_for_db,
		GameState.nombre_bots_selectionne,
		GameState.mode_jeu_selectionne
	)
	score_deja_enregistre = true

func _mapper_difficulte_bd(value: String) -> String:
	var normalized: String = value.to_lower()
	match normalized:
		GameState.BOT_DIFFICULTE_DEBUTANT, "easy", "debutant":
			return "easy"
		GameState.BOT_DIFFICULTE_DIFFICILE, "hard", "difficile":
			return "hard"
		GameState.BOT_DIFFICULTE_NORMAL, "normal":
			return "normal"
		_:
			return "normal"

func _obtenir_joueurs_vivants() -> Array[PlayerCharacter]:
	var alive: Array[PlayerCharacter] = []
	for player: PlayerCharacter in joueurs_partie:
		if player.est_vivant:
			alive.append(player)
	return alive

# Combine clavier et stick gauche pour un vecteur de deplacement normalise.
func _obtenir_vecteur_deplacement() -> Vector2:
	# Combine clavier/manette pour le déplacement du joueur humain.
	var keyboard_input: Vector2 = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	)
	var gamepad_input: Vector2 = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
		-Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	)
	if gamepad_input.length() < GAMEPAD_DEADZONE:
		gamepad_input = Vector2.ZERO
	var combined: Vector2 = keyboard_input if keyboard_input.length() >= gamepad_input.length() else gamepad_input
	return combined.limit_length(1.0)

# Lit le stick droit (avec deadzone) pour la vis�e manette normalis�e.
func _obtenir_entree_visee_manette() -> Vector2:
	var aim_input: Vector2 = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		-Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)
	if aim_input.length() < GAMEPAD_DEADZONE:
		return Vector2.ZERO
	return aim_input.limit_length(1.0)

func _synchroniser_camera_manette_joueur() -> void:
	# Aligne la caméra de contrôle (manette/souris) sur l'orientation du joueur.
	if joueur_humain_principal == null:
		return
	var facing: Vector3 = -joueur_humain_principal.global_basis.z
	facing.y = 0.0
	if facing.length() < 0.01:
		facing = Vector3.FORWARD
	facing = facing.normalized()
	lacet_camera_manette = atan2(-facing.x, -facing.z)
	tangage_camera_manette = 0.25
	lacet_camera_souris = lacet_camera_manette
	tangage_camera_souris = tangage_camera_manette
	distance_camera_courante = CAMERA_DISTANCE_DEFAUT

# Convertit l'orientation camera manette en point de visee pour le joueur humain.
func _mettre_a_jour_visee_manette_depuis_camera() -> void:
	# Convertit la caméra manette en vecteur d'aim pour le joueur.
	if joueur_humain_principal == null or not joueur_humain_principal.est_vivant:
		return
	var look_basis: Basis = Basis(Vector3.UP, lacet_camera_manette) * Basis(Vector3.RIGHT, tangage_camera_manette)
	var forward: Vector3 = -look_basis.z
	forward.y = 0.0
	if forward.length() < 0.01:
		return
	joueur_humain_principal.viser_point(joueur_humain_principal.global_position + forward.normalized() * 20.0)

# Convertit l'orientation camera souris en point de visee pour le joueur humain.
func _mettre_a_jour_visee_souris_depuis_camera() -> void:
	# Convertit la caméra souris en vecteur d'aim pour le joueur.
	if joueur_humain_principal == null or not joueur_humain_principal.est_vivant:
		return
	var look_basis: Basis = Basis(Vector3.UP, lacet_camera_souris) * Basis(Vector3.RIGHT, tangage_camera_souris)
	var forward: Vector3 = -look_basis.z
	forward.y = 0.0
	if forward.length() < 0.01:
		return
	joueur_humain_principal.viser_point(joueur_humain_principal.global_position + forward.normalized() * 20.0)

func _assurer_bindings_manette() -> void:
	_assurer_action_bouton_manette("toggle_prone", JOY_BUTTON_B)
	_assurer_action_bouton_manette("toggle_pause", JOY_BUTTON_START)
	_assurer_action_bouton_manette("ui_accept", JOY_BUTTON_A)
	_assurer_action_bouton_manette("ui_cancel", JOY_BUTTON_B)
	_assurer_action_bouton_manette("ui_up", JOY_BUTTON_DPAD_UP)
	_assurer_action_bouton_manette("ui_down", JOY_BUTTON_DPAD_DOWN)
	_assurer_action_bouton_manette("ui_left", JOY_BUTTON_DPAD_LEFT)
	_assurer_action_bouton_manette("ui_right", JOY_BUTTON_DPAD_RIGHT)

# Garantit un binding manette par action si manquant.
func _assurer_action_bouton_manette(action_id: String, button_index: JoyButton) -> void:
	if not InputMap.has_action(action_id):
		InputMap.add_action(action_id)
	for event: InputEvent in InputMap.action_get_events(action_id):
		if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == button_index:
			return
	var joy_event: InputEventJoypadButton = InputEventJoypadButton.new()
	joy_event.button_index = button_index
	InputMap.action_add_event(action_id, joy_event)

func _creer_texture_pixel(palette: Array[Color], size: int) -> ImageTexture:
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(palette[0])
	for x: int in range(size):
		for y: int in range(size):
			var index: int = int((x * 7 + y * 11 + x * y) % palette.size())
			image.set_pixel(x, y, palette[index])
	return ImageTexture.create_from_image(image)

func _creer_texture_reference_plateforme() -> ImageTexture:
	var image: Image = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	var palette: Array[Color] = [
		Color8(86, 16, 18),
		Color8(104, 28, 30),
		Color8(122, 44, 43),
		Color8(138, 63, 60),
		Color8(76, 11, 14),
		Color8(153, 82, 78)
	]
	for y: int in range(12):
		for x: int in range(12):
			var idx: int = int((x * 3 + y * 5 + (x * y) % 7) % palette.size())
			var pixel: Color = palette[idx]
			if x % 4 == 0 and y % 3 == 0:
				pixel = pixel.lightened(0.12)
			elif x % 5 == 0 or y % 5 == 0:
				pixel = pixel.darkened(0.1)
			elif (x + y) % 4 == 0:
				pixel = pixel.lightened(0.05)
			image.set_pixel(x, y, pixel)
	return ImageTexture.create_from_image(image)

func _creer_texture_roche_nether() -> ImageTexture:
	var image: Image = Image.create(14, 14, false, Image.FORMAT_RGBA8)
	var palette: Array[Color] = [
		Color8(62, 8, 10),
		Color8(79, 13, 15),
		Color8(97, 25, 24),
		Color8(116, 39, 36),
		Color8(132, 60, 55),
		Color8(151, 83, 76),
		Color8(103, 10, 18)
	]
	for y: int in range(14):
		for x: int in range(14):
			var idx: int = int((x * 5 + y * 7 + (x * y) % 13) % palette.size())
			var pixel: Color = palette[idx]
			if x % 6 == 0 or y % 5 == 0:
				pixel = pixel.darkened(0.12)
			elif (x + y) % 7 == 0:
				pixel = pixel.lightened(0.08)
			elif (x - y) % 5 == 0:
				pixel = pixel.darkened(0.05)
			image.set_pixel(x, y, pixel)
	return ImageTexture.create_from_image(image)

func _creer_texture_basalte() -> ImageTexture:
	var image: Image = Image.create(14, 14, false, Image.FORMAT_RGBA8)
	for y: int in range(14):
		for x: int in range(14):
			var stripe: int = (x + y * 2) % 6
			var pixel: Color = Color8(48, 44, 49)
			if stripe == 0:
				pixel = Color8(70, 65, 70)
			elif stripe == 1:
				pixel = Color8(58, 53, 58)
			elif stripe == 3:
				pixel = Color8(41, 38, 43)
			elif stripe == 4:
				pixel = Color8(80, 74, 78)
			if y % 4 == 0:
				pixel = pixel.darkened(0.14)
			if x % 5 == 0:
				pixel = pixel.lightened(0.04)
			image.set_pixel(x, y, pixel)
	return ImageTexture.create_from_image(image)

func _creer_texture_pierre_luisante() -> ImageTexture:
	var image: Image = Image.create(10, 10, false, Image.FORMAT_RGBA8)
	var palette: Array[Color] = [
		Color8(255, 226, 139),
		Color8(255, 208, 98),
		Color8(247, 181, 62),
		Color8(232, 150, 44),
		Color8(255, 239, 172)
	]
	for y: int in range(10):
		for x: int in range(10):
			var idx: int = int((x * 7 + y * 9 + (x * y) % 5) % palette.size())
			var pixel: Color = palette[idx]
			if (x + y) % 3 == 0:
				pixel = pixel.lightened(0.1)
			elif x % 4 == 0 or y % 4 == 0:
				pixel = pixel.darkened(0.08)
			image.set_pixel(x, y, pixel)
	return ImageTexture.create_from_image(image)

func _creer_texture_reference_lave() -> ImageTexture:
	var image: Image = Image.create(10, 10, false, Image.FORMAT_RGBA8)
	var palette: Array[Color] = [
		Color8(214, 76, 0),
		Color8(224, 92, 5),
		Color8(235, 120, 20),
		Color8(246, 149, 39),
		Color8(198, 52, 0),
		Color8(255, 177, 62)
	]
	for y: int in range(10):
		for x: int in range(10):
			var idx: int = int((x * 11 + y * 5 + (x * y) % 9) % palette.size())
			var pixel: Color = palette[idx]
			if (x + y) % 4 == 0:
				pixel = pixel.lightened(0.09)
			elif x % 3 == 0 and y % 2 == 0:
				pixel = pixel.darkened(0.08)
			image.set_pixel(x, y, pixel)
	return ImageTexture.create_from_image(image)

# Indique si la souris est toujours dans le viewport courant (utile pour activer le gyro fallback).
func _souris_dans_viewport() -> bool:
	var pos: Vector2 = get_viewport().get_mouse_position()
	var size: Vector2 = get_viewport().get_visible_rect().size
	return pos.x >= 0.0 and pos.y >= 0.0 and pos.x <= size.x and pos.y <= size.y

# Ouvre/cree la base SQLite et s'assure de la presence de la table Resultats.
func rafraichir_schema_bdd() -> void:
	if OS.has_feature("web"):
		return
	var db: SQLite = SQLite.new()
	db.path = _obtenir_chemin_bdd()
	if not db.open_db():
		printerr("Impossible d'ouvrir ou de créer la base SQLite à l'emplacement %s" % db.path)
		return
	_assurer_table_resultats(db)
	db.close_db()

# Insere une ligne de score dans SQLite (nom, rang, skin, difficulte, bots, mode).
func enregistrer_score_bdd(name, position, skin, difficulty_selected, number_of_bots, mode: String = "solo") -> void:
	if OS.has_feature("web"):
		return
	var db: SQLite = SQLite.new()
	db.path = _obtenir_chemin_bdd()
	if not db.open_db():
		printerr("Impossible d'ouvrir la base SQLite à l'emplacement %s" % db.path)
		return
	_assurer_table_resultats(db)
	var row := {
		"name": name,
		"position": position,
		"skin": skin,
		"difficulty_selected": _mapper_difficulte_bd(str(difficulty_selected)),
		"mode_selected": mode,
		"number_of_bots": number_of_bots
	}
	db.insert_row("Resultats", row)
	db.close_db()

# Convertit le chemin relatif de la BDD en chemin global (ProjectSettings).
func _obtenir_chemin_bdd() -> String:
	# Priorité à une copie locale en lecture/écriture (utile pour les exports .exe/.pck).
	var user_dir := ProjectSettings.globalize_path(DATABASE_USER_DIR)
	DirAccess.make_dir_recursive_absolute(user_dir)
	if not FileAccess.file_exists(DATABASE_USER_PATH):
		if FileAccess.file_exists(DATABASE_PATH):
			var src := FileAccess.open(DATABASE_PATH, FileAccess.READ)
			if src:
				var dst := FileAccess.open(DATABASE_USER_PATH, FileAccess.WRITE)
				if dst:
					dst.store_buffer(src.get_buffer(src.get_length()))
					dst.close()
				src.close()
	# Si aucune copie, on crée un fichier vide côté user pour permettre open_db().
	if not FileAccess.file_exists(DATABASE_USER_PATH):
		var touch := FileAccess.open(DATABASE_USER_PATH, FileAccess.WRITE)
		if touch:
			touch.close()
	# On renvoie toujours le user:// (lecture/écriture); fallback res:// si tout a échoué.
	if FileAccess.file_exists(DATABASE_USER_PATH):
		return ProjectSettings.globalize_path(DATABASE_USER_PATH)
	return ProjectSettings.globalize_path(DATABASE_PATH)

# Cree la table Resultats si elle n'existe pas (schema colonnes/contrainte).
func _assurer_table_resultats(db: SQLite) -> void:
	db.query("""
		CREATE TABLE IF NOT EXISTS Resultats (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			name TEXT NOT NULL,
			position INT,
			skin VARCHAR(30),
			difficulty_selected TEXT CHECK (difficulty_selected IN ('easy', 'normal', 'hard')),
			mode_selected TEXT CHECK (mode_selected IN ('solo', 'multiplayer', 'difficile')),
			number_of_bots INT
		)
	""")
