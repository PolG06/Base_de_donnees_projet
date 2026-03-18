extends Node3D

# Script principal qui orchestre une partie : phases, joueurs, caméra, UI.

const PLAYER_SCENE := preload("res://scenes/player_character.tscn")
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")

const DARK_DURATION := 12.0 # Durée de base de la phase déplacement (décroît ensuite)
const LIGHT_SHOT_DELAY := 0.8
const START_RADIUS := 10.5 # Rayon initial de l'arène
const MIN_RADIUS := 3.5
const SHRINK_FACTOR := 2.0 / 3.0
const CAMERA_HEIGHT := 2.75 # Hauteur cible de la caméra
const CAMERA_DISTANCE := 4.35 # Distance orbite caméra
const CAMERA_SMOOTHNESS := 7.0
const CAMERA_SIDE_OFFSET := -0.45
const GAMEPAD_DEADZONE := 0.2
const CAMERA_CONTROLLER_YAW_SPEED := 3.4 # Vitesse rotation manette
const CAMERA_CONTROLLER_PITCH_SPEED := 2.3
const CAMERA_CONTROLLER_PITCH_MIN := -0.35
const CAMERA_CONTROLLER_PITCH_MAX := 0.6
const GYRO_SPEED_SCALE := 55.0 # Intensité du fallback gyro hors fenêtre
const NETHER_BACKDROP_RADIUS := 62.0
const NETHER_WALL_HEIGHT := 32.0
const NETHER_CEILING_HEIGHT := 28.0
const PRE_LIGHT_OBSERVE_TIME := 6.0 # Délai d'observation avant les tirs
const ROUND_TRANSITION_FADE_IN := 0.35
const ROUND_TRANSITION_HOLD := 1.6
const ROUND_TRANSITION_FADE_OUT := 0.45
const DATABASE_PATH := "res://../Database_sqlite/database.db"

enum Phase { DARK, LIGHT, ROUND_END, GAME_OVER }

# État global de la partie
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var players: Array[PlayerCharacter] = []
var elimination_order: Array[PlayerCharacter] = []
var human_player: PlayerCharacter
var spectated_player: PlayerCharacter
var round_transition_tween: Tween
var arena_center: Vector3 = Vector3.ZERO
var arena_radius: float = START_RADIUS
var round_number: int = 1
var phase: Phase = Phase.DARK
var phase_time_left: float = DARK_DURATION
var shot_queue: Array[PlayerCharacter] = []
var shot_delay_left: float = LIGHT_SHOT_DELAY
var light_phase_revealed: bool = false
var pre_light_observe_left: float = 0.0
var free_camera_active: bool = false
var free_camera_yaw: float = 0.0
var free_camera_pitch: float = 0.0
var free_camera_target: PlayerCharacter
var mouse_camera_yaw: float = 0.0
var mouse_camera_pitch: float = 0.32
var last_mouse_inside: bool = true
var gyro_active: bool = false
var gyro_yaw_speed: float = 0.0
var gyro_pitch_speed: float = 0.0
var stone_material: StandardMaterial3D
var lava_material: StandardMaterial3D
var nether_rock_material: StandardMaterial3D
var basalt_material: StandardMaterial3D
var glowstone_material: StandardMaterial3D
var darkness_environment: Environment
var daylight_environment: Environment
var is_pause_menu_open: bool = false
var is_pause_settings_open: bool = false
var is_game_over_screen_open: bool = false
var has_saved_match: bool = false
var pause_waiting_action_id: String = ""
var pause_action_buttons: Dictionary = {}
var pause_volume_slider: HSlider
var pause_volume_value_label: Label
var controller_camera_yaw: float = 0.0
var controller_camera_pitch: float = 0.18
var is_controller_camera_active: bool = false

@onready var camera: Camera3D = $Camera3D
@onready var sun_light: DirectionalLight3D = $SunLight
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var arena_root: Node3D = $Arena
@onready var players_root: Node3D = $Players
@onready var projectiles_root: Node3D = $Projectiles
@onready var phase_label: Label = $CanvasLayer/PhaseLabel
@onready var info_label: Label = $CanvasLayer/InfoLabel
@onready var spectator_label: Label = $CanvasLayer/SpectatorLabel
@onready var round_transition_overlay: ColorRect = $CanvasLayer/RoundTransition
@onready var round_transition_label: Label = $CanvasLayer/RoundTransition/RoundTransitionLabel
@onready var round_transition_alive_label: Label = $CanvasLayer/RoundTransition/RoundAliveLabel
@onready var order_panel: Panel = $CanvasLayer/OrderPanel
@onready var order_list: VBoxContainer = $CanvasLayer/OrderPanel/OrderVBox/OrderList
@onready var spectator_quit_button: Button = $CanvasLayer/SpectatorQuitButton
@onready var notification_label: Label = $CanvasLayer/NotificationLabel
@onready var game_over_title_label: Label = $CanvasLayer/GameOverOverlay/GameOverPanel/GameOverTitle
@onready var pause_overlay: ColorRect = $CanvasLayer/PauseOverlay
@onready var pause_menu_vbox: VBoxContainer = $CanvasLayer/PauseOverlay/PausePanel/PauseMenuVBox
@onready var resume_button: Button = $CanvasLayer/PauseOverlay/PausePanel/PauseMenuVBox/ResumeButton
@onready var pause_settings_button: Button = $CanvasLayer/PauseOverlay/PausePanel/PauseMenuVBox/PauseSettingsButton
@onready var quit_button: Button = $CanvasLayer/PauseOverlay/PausePanel/PauseMenuVBox/QuitButton
@onready var pause_settings_panel: Panel = $CanvasLayer/PauseOverlay/PausePanel/PauseSettingsPanel
@onready var pause_settings_list: VBoxContainer = $CanvasLayer/PauseOverlay/PausePanel/PauseSettingsPanel/PauseSettingsMargin/PauseSettingsVBox/PauseSettingsControlsPanel/PauseSettingsControlsMargin/PauseSettingsControlsColumn/PauseSettingsScroll/PauseSettingsControlsList
@onready var pause_settings_status_label: Label = $CanvasLayer/PauseOverlay/PausePanel/PauseSettingsPanel/PauseSettingsMargin/PauseSettingsVBox/PauseSettingsStatusPanel/PauseSettingsStatusLabel
@onready var pause_settings_back_button: Button = $CanvasLayer/PauseOverlay/PausePanel/PauseSettingsPanel/PauseSettingsMargin/PauseSettingsVBox/PauseSettingsBackButton
@onready var game_over_overlay: ColorRect = $CanvasLayer/GameOverOverlay
@onready var ranking_label: Label = $CanvasLayer/GameOverOverlay/GameOverPanel/RankingLabel
@onready var game_over_quit_button: Button = $CanvasLayer/GameOverOverlay/GameOverPanel/GameOverQuitButton
@onready var game_over_restart_button: Button = $CanvasLayer/GameOverOverlay/GameOverPanel/GameOverRestartButton

var platform_mesh_instance: MeshInstance3D
var platform_collision: CollisionShape3D
var lava_mesh_instance: MeshInstance3D

func _ready() -> void:
	# Initialisation des références, UI et environnement de jeu.
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu_vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_settings_button.process_mode = Node.PROCESS_MODE_ALWAYS
	quit_button.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_settings_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_settings_list.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_settings_status_label.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_settings_back_button.process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_quit_button.process_mode = Node.PROCESS_MODE_ALWAYS
	MenuMusic.play_game_music()
	_ensure_gamepad_bindings()
	_build_pause_settings_rows()
	_refresh_pause_settings_buttons()
	MenuAudio.connect_buttons(self)
	pause_settings_status_label.text = GameState.tr_key("settings_status_default")
	resume_button.pressed.connect(_on_resume_pressed)
	pause_settings_button.pressed.connect(_on_pause_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	pause_settings_back_button.pressed.connect(_on_pause_settings_back_pressed)
	game_over_quit_button.pressed.connect(_on_game_over_quit_pressed)
	game_over_restart_button.pressed.connect(_on_restart_pressed)
	spectator_quit_button.pressed.connect(_on_spectator_quit_pressed)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	round_transition_overlay.visible = false
	order_panel.visible = false
	notification_label.visible = false
	rng.randomize()
	_create_materials()
	_create_environment()
	_adjust_arena_for_player_count()
	_build_arena()
	_spawn_players()
	_sync_controller_camera_to_player()
	_update_platform_size()
	_start_dark_phase()
	refresh_database_schema()

func _unhandled_input(event: InputEvent) -> void:
	# Gestion des interactions (pause, spectateur, caméra souris/gyro).
	if pause_waiting_action_id != "" and event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			var keycode: Key = key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
			GameState.rebind_action(pause_waiting_action_id, keycode)
			pause_settings_status_label.text = "%s : %s" % [GameState.get_action_display_name(pause_waiting_action_id), GameState.get_action_binding_summary(pause_waiting_action_id)]
			pause_waiting_action_id = ""
			_refresh_pause_settings_buttons()
			get_viewport().set_input_as_handled()
			return
	if phase == Phase.GAME_OVER:
		return
	var is_spectating: bool = human_player != null and not human_player.is_alive
	if event is InputEventMouseMotion and not get_tree().paused:
		var motion_any: InputEventMouseMotion = event as InputEventMouseMotion
		mouse_camera_yaw -= motion_any.relative.x * 0.005
		mouse_camera_pitch = clamp(mouse_camera_pitch + motion_any.relative.y * 0.003, CAMERA_CONTROLLER_PITCH_MIN, CAMERA_CONTROLLER_PITCH_MAX)
		gyro_yaw_speed = -motion_any.relative.x * 0.005 * GYRO_SPEED_SCALE
		gyro_pitch_speed = motion_any.relative.y * 0.003 * GYRO_SPEED_SCALE
		if is_spectating:
			free_camera_active = true
			free_camera_target = spectated_player
			free_camera_yaw = mouse_camera_yaw
			free_camera_pitch = mouse_camera_pitch
		get_viewport().set_input_as_handled()
		return
	if is_spectating and event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and not mouse_event.double_click:
			if mouse_event.button_index == MOUSE_BUTTON_LEFT:
				_cycle_spectated_player(1)
				get_viewport().set_input_as_handled()
				return
			if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
				_cycle_spectated_player(-1)
				get_viewport().set_input_as_handled()
				return
	if event.is_action_pressed("toggle_pause"):
		if is_pause_settings_open:
			_on_pause_settings_back_pressed()
		else:
			_toggle_pause_menu()
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	# Boucle physique : avance la phase courante, caméra, UI.
	if get_tree().paused:
		_update_ui()
		return
	match phase:
		Phase.DARK:
			_update_dark_phase(delta)
		Phase.LIGHT:
			_update_light_phase(delta)
		Phase.ROUND_END:
			_update_round_end(delta)
		Phase.GAME_OVER:
			pass
	_update_camera(delta)
	_update_ui()

func _toggle_pause_menu() -> void:
	# Ouvre/ferme le menu pause.
	if is_game_over_screen_open:
		return
	if is_pause_menu_open:
		_close_pause_menu()
	else:
		_open_pause_menu()

func _open_pause_menu() -> void:
	is_pause_menu_open = true
	is_pause_settings_open = false
	pause_waiting_action_id = ""
	_refresh_pause_settings_buttons()
	MenuAudio.connect_buttons(self)
	pause_settings_status_label.text = GameState.tr_key("settings_status_default")
	pause_overlay.visible = true
	pause_menu_vbox.visible = true
	pause_settings_panel.visible = false
	get_tree().paused = true
	resume_button.call_deferred("grab_focus")

func _close_pause_menu() -> void:
	is_pause_menu_open = false
	is_pause_settings_open = false
	pause_waiting_action_id = ""
	pause_overlay.visible = false
	pause_menu_vbox.visible = true
	pause_settings_panel.visible = false
	get_tree().paused = false

func _on_resume_pressed() -> void:
	_close_pause_menu()

func _on_pause_settings_pressed() -> void:
	is_pause_settings_open = true
	pause_waiting_action_id = ""
	_refresh_pause_settings_buttons()
	MenuAudio.connect_buttons(self)
	pause_settings_status_label.text = GameState.tr_key("settings_status_default")
	pause_menu_vbox.visible = false
	pause_settings_panel.visible = true
	if pause_action_buttons.has("ui_up"):
		(pause_action_buttons["ui_up"] as Button).call_deferred("grab_focus")

func _on_pause_settings_back_pressed() -> void:
	is_pause_settings_open = false
	pause_waiting_action_id = ""
	pause_settings_panel.visible = false
	pause_menu_vbox.visible = true
	pause_settings_button.call_deferred("grab_focus")

func _on_pause_setting_action_pressed(action_id: String) -> void:
	pause_waiting_action_id = action_id
	pause_settings_status_label.text = GameState.tr_key("settings_waiting") % [GameState.get_action_display_name(action_id), GameState.get_action_gamepad_text(action_id)]
	_refresh_pause_settings_buttons()

func _build_pause_settings_rows() -> void:
	for child: Node in pause_settings_list.get_children():
		child.queue_free()
	pause_action_buttons.clear()
	pause_volume_slider = null
	pause_volume_value_label = null

	for binding: Dictionary in GameState.ACTION_BINDINGS:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		pause_settings_list.add_child(row)

		var label: Label = Label.new()
		label.text = GameState.get_action_display_name(binding["id"])
		label.custom_minimum_size = Vector2(280, 46)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(label)

		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(220, 46)
		button.pressed.connect(_on_pause_setting_action_pressed.bind(binding["id"]))
		row.add_child(button)
		pause_action_buttons[binding["id"]] = button

	var volume_row: HBoxContainer = HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 12)
	pause_settings_list.add_child(volume_row)

	var volume_label: Label = Label.new()
	volume_label.text = GameState.tr_key("settings_volume")
	volume_label.custom_minimum_size = Vector2(280, 46)
	volume_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	volume_row.add_child(volume_label)

	var volume_box: HBoxContainer = HBoxContainer.new()
	volume_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_box.add_theme_constant_override("separation", 10)
	volume_row.add_child(volume_box)

	pause_volume_slider = HSlider.new()
	pause_volume_slider.min_value = 0.0
	pause_volume_slider.max_value = 1.0
	pause_volume_slider.step = 0.01
	pause_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pause_volume_slider.custom_minimum_size = Vector2(140, 46)
	pause_volume_slider.value = GameState.get_master_volume()
	pause_volume_slider.value_changed.connect(_on_pause_volume_changed)
	volume_box.add_child(pause_volume_slider)

	pause_volume_value_label = Label.new()
	pause_volume_value_label.custom_minimum_size = Vector2(70, 46)
	pause_volume_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pause_volume_value_label.text = GameState.get_master_volume_text()
	volume_box.add_child(pause_volume_value_label)

	var aim_row: HBoxContainer = HBoxContainer.new()
	aim_row.add_theme_constant_override("separation", 12)
	pause_settings_list.add_child(aim_row)

	var aim_label: Label = Label.new()
	aim_label.text = GameState.tr_key("controls_aim")
	aim_label.custom_minimum_size = Vector2(280, 46)
	aim_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	aim_row.add_child(aim_label)

	var aim_value: Label = Label.new()
	aim_value.text = "%s | %s" % [GameState.tr_key("controls_mouse"), GameState.tr_key("controls_right_stick")]
	aim_value.custom_minimum_size = Vector2(220, 46)
	aim_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	aim_row.add_child(aim_value)

	MenuAudio.connect_buttons(pause_settings_list)

func _refresh_pause_settings_buttons() -> void:
	for binding: Dictionary in GameState.ACTION_BINDINGS:
		var action_id: String = binding["id"]
		var button: Button = pause_action_buttons.get(action_id, null)
		if button == null:
			continue
		button.text = GameState.tr_key("settings_press_key") if action_id == pause_waiting_action_id else GameState.get_action_binding_summary(action_id)
	if pause_volume_slider != null:
		pause_volume_slider.set_value_no_signal(GameState.get_master_volume())
	if pause_volume_value_label != null:
		pause_volume_value_label.text = GameState.get_master_volume_text()

func _on_pause_volume_changed(value: float) -> void:
	GameState.set_master_volume(value)
	if pause_volume_value_label != null:
		pause_volume_value_label.text = GameState.get_master_volume_text()
	if pause_waiting_action_id == "":
		pause_settings_status_label.text = GameState.tr_key("settings_volume_status")

func _on_quit_pressed() -> void:
	get_tree().paused = false
	is_pause_menu_open = false
	is_pause_settings_open = false
	pause_waiting_action_id = ""
	is_game_over_screen_open = false
	get_tree().change_scene_to_file("res://scenes/menu_main.tscn")

func _on_restart_pressed() -> void:
	get_tree().paused = false
	is_pause_menu_open = false
	is_pause_settings_open = false
	pause_waiting_action_id = ""
	is_game_over_screen_open = false
	get_tree().change_scene_to_file("res://scenes/mode_select.tscn")

func _on_game_over_quit_pressed() -> void:
	get_tree().quit()

func _create_materials() -> void:
	stone_material = StandardMaterial3D.new()
	stone_material.albedo_texture = _make_platform_reference_texture()
	stone_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	stone_material.uv1_scale = Vector3(8, 8, 8)
	stone_material.roughness = 1.0

	lava_material = StandardMaterial3D.new()
	lava_material.albedo_texture = _make_lava_reference_texture()
	lava_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	lava_material.uv1_scale = Vector3(24, 24, 24)
	lava_material.emission_enabled = true
	lava_material.emission_texture = lava_material.albedo_texture
	lava_material.emission = Color(1.0, 0.45, 0.1)
	lava_material.emission_energy_multiplier = 1.9
	lava_material.roughness = 0.78

	nether_rock_material = StandardMaterial3D.new()
	nether_rock_material.albedo_texture = _make_nether_rock_texture()
	nether_rock_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	nether_rock_material.uv1_scale = Vector3(10, 10, 10)
	nether_rock_material.roughness = 1.0

	basalt_material = StandardMaterial3D.new()
	basalt_material.albedo_texture = _make_basalt_texture()
	basalt_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	basalt_material.uv1_scale = Vector3(7, 7, 7)
	basalt_material.roughness = 1.0

	glowstone_material = StandardMaterial3D.new()
	glowstone_material.albedo_texture = _make_glowstone_texture()
	glowstone_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	glowstone_material.uv1_scale = Vector3(6, 6, 6)
	glowstone_material.emission_enabled = true
	glowstone_material.emission_texture = glowstone_material.albedo_texture
	glowstone_material.emission = Color(1.0, 0.72, 0.2)
	glowstone_material.emission_energy_multiplier = 2.35

func _create_environment() -> void:
	daylight_environment = Environment.new()
	daylight_environment.background_mode = Environment.BG_COLOR
	daylight_environment.background_color = Color(0.22, 0.03, 0.03)
	daylight_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	daylight_environment.ambient_light_color = Color(0.9, 0.28, 0.18)
	daylight_environment.ambient_light_energy = 0.55
	daylight_environment.fog_enabled = true
	daylight_environment.fog_light_color = Color(0.95, 0.25, 0.12)
	daylight_environment.fog_light_energy = 0.7
	daylight_environment.fog_density = 0.012
	daylight_environment.tonemap_exposure = 1.05

	darkness_environment = Environment.new()
	darkness_environment.background_mode = Environment.BG_COLOR
	darkness_environment.background_color = Color(0.06, 0.01, 0.01)
	darkness_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	darkness_environment.ambient_light_color = Color(0.17, 0.05, 0.05)
	darkness_environment.ambient_light_energy = 0.16
	darkness_environment.fog_enabled = true
	darkness_environment.fog_light_color = Color(0.65, 0.12, 0.05)
	darkness_environment.fog_light_energy = 0.35
	darkness_environment.fog_density = 0.02

	world_environment.environment = daylight_environment

func _adjust_arena_for_player_count() -> void:
	var total_players: int = 1 + GameState.selected_bot_count
	arena_radius = START_RADIUS + max(0, total_players - 4) * 1.15

func _build_arena() -> void:
	var platform_body: StaticBody3D = StaticBody3D.new()
	platform_body.name = "PlatformBody"
	arena_root.add_child(platform_body)

	platform_mesh_instance = MeshInstance3D.new()
	platform_mesh_instance.name = "PlatformMesh"
	var platform_mesh: BoxMesh = BoxMesh.new()
	platform_mesh.size = Vector3(arena_radius * 2.0, 1.0, arena_radius * 2.0)
	platform_mesh_instance.mesh = platform_mesh
	platform_mesh_instance.material_override = stone_material
	platform_mesh_instance.position = Vector3(0, 0, 0)
	platform_body.add_child(platform_mesh_instance)

	platform_collision = CollisionShape3D.new()
	var platform_shape: BoxShape3D = BoxShape3D.new()
	platform_shape.size = Vector3(arena_radius * 2.0, 1.0, arena_radius * 2.0)
	platform_collision.shape = platform_shape
	platform_body.add_child(platform_collision)

	var lava_body: StaticBody3D = StaticBody3D.new()
	lava_body.name = "LavaBody"
	lava_body.position = Vector3(0, -10, 0)
	arena_root.add_child(lava_body)

	lava_mesh_instance = MeshInstance3D.new()
	lava_mesh_instance.name = "LavaMesh"
	var lava_mesh: BoxMesh = BoxMesh.new()
	lava_mesh.size = Vector3(80, 1, 80)
	lava_mesh_instance.mesh = lava_mesh
	lava_mesh_instance.material_override = lava_material
	lava_body.add_child(lava_mesh_instance)

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
	arena_root.add_child(rim_light)

	_build_nether_backdrop()

func _build_nether_backdrop() -> void:
	var backdrop_root: Node3D = Node3D.new()
	backdrop_root.name = "NetherBackdrop"
	arena_root.add_child(backdrop_root)

	_add_textured_box(backdrop_root, Vector3(0.0, NETHER_CEILING_HEIGHT, 0.0), Vector3(140.0, 16.0, 140.0), nether_rock_material)
	_add_textured_box(backdrop_root, Vector3(0.0, NETHER_CEILING_HEIGHT - 7.5, 0.0), Vector3(110.0, 5.0, 110.0), basalt_material)

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
		_add_nether_box(backdrop_root, lava_border_positions[i], lava_border_sizes[i])

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
		_add_nether_box(backdrop_root, ring_positions[i], ring_sizes[i])

	for i: int in range(22):
		var pillar_height: float = rng.randf_range(7.0, 22.0)
		var pillar_size: Vector3 = Vector3(rng.randf_range(4.0, 10.0), pillar_height, rng.randf_range(4.0, 10.0))
		var pillar_pos: Vector3 = Vector3(
			rng.randf_range(-52.0, 52.0),
			-5.0 + pillar_height * 0.5,
			rng.randf_range(-52.0, 52.0)
		)
		if pillar_pos.distance_to(Vector3.ZERO) < arena_radius + 11.0:
			continue
		var pillar_material: StandardMaterial3D = basalt_material if i % 3 == 0 else nether_rock_material
		_add_textured_box(backdrop_root, pillar_pos, pillar_size, pillar_material)
		if rng.randf() < 0.55:
			_add_nether_spike(backdrop_root, pillar_pos + Vector3(0.0, pillar_height * 0.5 + 1.0, 0.0), rng.randf_range(3.0, 8.0), false)

	for i: int in range(12):
		var shelf_size: Vector3 = Vector3(rng.randf_range(12.0, 24.0), rng.randf_range(3.0, 6.0), rng.randf_range(10.0, 20.0))
		var shelf_pos: Vector3 = Vector3(
			rng.randf_range(-56.0, 56.0),
			rng.randf_range(4.0, 16.0),
			rng.randf_range(-56.0, 56.0)
		)
		if shelf_pos.distance_to(Vector3.ZERO) < arena_radius + 16.0:
			continue
		_add_textured_box(backdrop_root, shelf_pos, shelf_size, basalt_material)
		if rng.randf() < 0.6:
			_add_glowstone_cluster(backdrop_root, shelf_pos + Vector3(rng.randf_range(-2.0, 2.0), -shelf_size.y * 0.5 - 0.8, rng.randf_range(-2.0, 2.0)))

	var arch_centers: Array[Vector3] = [
		Vector3(-38.0, 7.0, -30.0),
		Vector3(35.0, 6.5, -34.0),
		Vector3(-34.0, 8.0, 32.0),
		Vector3(39.0, 7.0, 30.0)
	]
	for arch_center: Vector3 in arch_centers:
		_add_nether_arch(backdrop_root, arch_center, rng.randf_range(16.0, 24.0), rng.randf_range(12.0, 17.0), rng.randf_range(5.0, 8.0))

	for i: int in range(18):
		var ceiling_spike_pos: Vector3 = Vector3(
			rng.randf_range(-58.0, 58.0),
			NETHER_CEILING_HEIGHT - rng.randf_range(2.0, 6.0),
			rng.randf_range(-58.0, 58.0)
		)
		if ceiling_spike_pos.distance_to(Vector3.ZERO) < arena_radius + 12.0:
			continue
		_add_nether_spike(backdrop_root, ceiling_spike_pos, rng.randf_range(4.0, 10.0), true)

	for i: int in range(10):
		var lavafall_height: float = rng.randf_range(18.0, 34.0)
		var lavafall_pos: Vector3 = Vector3(
			rng.randf_range(-52.0, 52.0),
			rng.randf_range(10.0, 18.0),
			rng.randf_range(-52.0, 52.0)
		)
		if lavafall_pos.distance_to(Vector3.ZERO) < arena_radius + 12.0:
			continue
		_add_lavafall(backdrop_root, lavafall_pos, lavafall_height)

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
		_add_glowstone_cluster(backdrop_root, glow_pos)

func _add_textured_box(target_root: Node3D, position: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.material_override = material
	target_root.add_child(mesh_instance)
	return mesh_instance

func _add_nether_box(target_root: Node3D, position: Vector3, size: Vector3) -> void:
	_add_textured_box(target_root, position, size, nether_rock_material)

func _add_nether_arch(target_root: Node3D, center: Vector3, span: float, height: float, thickness: float) -> void:
	_add_textured_box(target_root, center + Vector3(-span * 0.5, -2.0, 0.0), Vector3(thickness, height, thickness + 1.5), basalt_material)
	_add_textured_box(target_root, center + Vector3(span * 0.5, -2.0, 0.0), Vector3(thickness, height, thickness + 1.5), basalt_material)
	_add_textured_box(target_root, center + Vector3(0.0, height * 0.35, 0.0), Vector3(span + thickness, thickness, thickness + 2.0), nether_rock_material)
	_add_textured_box(target_root, center + Vector3(0.0, height * 0.12, 0.0), Vector3(span * 0.72, thickness * 0.8, thickness + 0.8), basalt_material)

func _add_nether_spike(target_root: Node3D, origin: Vector3, height: float, hanging: bool) -> void:
	var segments: int = max(2, int(round(height / 2.0)))
	for i: int in range(segments):
		var t: float = float(i) / float(max(1, segments - 1))
		var segment_scale: float = lerp(1.8, 0.45, t)
		var y_offset: float = -i * 1.6 if hanging else i * 1.6
		_add_textured_box(
			target_root,
			origin + Vector3(0.0, y_offset, 0.0),
			Vector3(segment_scale, 1.8, segment_scale),
			basalt_material if i % 2 == 0 else nether_rock_material
		)

func _add_lavafall(target_root: Node3D, top_position: Vector3, height: float) -> void:
	var lavafall: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(1.6, height, 1.6)
	lavafall.mesh = mesh
	lavafall.position = top_position + Vector3(0.0, -height * 0.5, 0.0)
	lavafall.material_override = lava_material
	target_root.add_child(lavafall)

	var splash: MeshInstance3D = MeshInstance3D.new()
	var splash_mesh: CylinderMesh = CylinderMesh.new()
	splash_mesh.top_radius = 2.8
	splash_mesh.bottom_radius = 3.6
	splash_mesh.height = 0.8
	splash.mesh = splash_mesh
	splash.position = Vector3(top_position.x, -9.5, top_position.z)
	splash.material_override = lava_material
	target_root.add_child(splash)

	if rng.randf() < 0.7:
		_add_textured_box(target_root, Vector3(top_position.x, top_position.y + 0.8, top_position.z), Vector3(3.2, 1.2, 3.2), nether_rock_material)

func _add_glowstone_cluster(target_root: Node3D, center: Vector3) -> void:
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
		glow.material_override = glowstone_material
		target_root.add_child(glow)

func _spawn_players() -> void:
	var total_players: int = 1 + GameState.selected_bot_count
	var character_pool: Array[Dictionary] = []
	for option: Dictionary in GameState.CHARACTER_OPTIONS:
		character_pool.append(option)

	var selected_character: Dictionary = GameState.get_selected_character()
	var roster: Array[Dictionary] = [selected_character]
	var bot_index: int = 0
	while roster.size() < total_players:
		var option: Dictionary = character_pool[bot_index % character_pool.size()]
		if option["id"] == selected_character["id"]:
			bot_index += 1
			continue
		roster.append(option)
		bot_index += 1

	var spawn_positions: Array[Vector3] = _generate_spawn_positions(total_players)

	for i: int in range(total_players):
		var player: PlayerCharacter = PLAYER_SCENE.instantiate() as PlayerCharacter
		var character: Dictionary = roster[i]
		player.player_name = GameState.get_human_player_name() if i == 0 else GameState.get_bot_display_name(character)
		player.player_color = character["body_color"]
		player.skin_color = character["skin_color"]
		player.accent_color = character["accent_color"]
		player.eliminated.connect(_on_player_eliminated)
		players_root.add_child(player)
		player.global_position = spawn_positions[i]
		player.look_at(arena_center, Vector3.UP)
		if i == 0:
			player.set_human_controlled(true)
			player.set_revealed_in_darkness(true)
			human_player = player
		else:
			player.set_revealed_in_darkness(false)
		players.append(player)

func _generate_spawn_positions(total_players: int) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var spawn_radius: float = max(3.5, arena_radius - 2.2)
	for i: int in range(total_players):
		var angle: float = (TAU * float(i) / float(total_players)) - PI * 0.5
		positions.append(arena_center + Vector3(cos(angle) * spawn_radius, 1.05, sin(angle) * spawn_radius))
	return positions

func _start_dark_phase() -> void:
	# Phase déplacement : joueurs bougent, lasers cachés, durée décroissante.
	phase = Phase.DARK
	var decay_factor: float = pow(SHRINK_FACTOR, max(0, round_number - 1))
	phase_time_left = max(5.0, DARK_DURATION * decay_factor)
	world_environment.environment = darkness_environment
	sun_light.light_energy = 0.08
	_show_round_transition("Manche %d" % round_number, _build_alive_list_text())
	_refresh_shot_order_ui()
	for player: PlayerCharacter in players:
		if player.is_alive:
			player.plan_dark_phase(arena_center, arena_radius, rng)
			player.set_phase_visibility(true)

func _update_dark_phase(delta: float) -> void:
	phase_time_left -= delta
	if human_player != null and human_player.is_alive:
		if Input.is_action_just_pressed("toggle_prone"):
			human_player.toggle_prone()
		var controller_aim: Vector2 = _get_controller_aim_input()
		if controller_aim.length() >= GAMEPAD_DEADZONE:
			is_controller_camera_active = true
			controller_camera_yaw -= controller_aim.x * CAMERA_CONTROLLER_YAW_SPEED * delta
			controller_camera_pitch = clamp(controller_camera_pitch + controller_aim.y * CAMERA_CONTROLLER_PITCH_SPEED * delta, CAMERA_CONTROLLER_PITCH_MIN, CAMERA_CONTROLLER_PITCH_MAX)
			_update_controller_aim_from_camera()
		elif not is_controller_camera_active:
			_update_mouse_aim_from_camera()
		var input_vector: Vector2 = _get_movement_input_vector()
		human_player.move_human(input_vector, camera.global_basis, arena_center, arena_radius)
	for player: PlayerCharacter in players:
		player.move_in_darkness(delta, arena_center, arena_radius)
	if phase_time_left <= 0.0:
		_start_light_phase()


func _get_bot_aim_error_radius() -> float:
	match GameState.selected_bot_difficulty:
		GameState.BOT_DIFFICULTY_BEGINNER:
			return 2.4
		GameState.BOT_DIFFICULTY_HARD:
			return 0.35
		_:
			return 1.1

func _get_bot_aim_point(target: PlayerCharacter) -> Vector3:
	var error_radius: float = _get_bot_aim_error_radius()
	var offset: Vector3 = Vector3(
		rng.randf_range(-error_radius, error_radius),
		0.0,
		rng.randf_range(-error_radius, error_radius)
	)
	return target.global_position + offset

func _start_light_phase() -> void:
	# Phase tir : verrouille les directions de tir, affiche ordre et lance transition.
	phase = Phase.LIGHT
	shot_delay_left = 0.3
	light_phase_revealed = false
	pre_light_observe_left = 0.0
	world_environment.environment = daylight_environment
	sun_light.light_energy = 1.8

	shot_queue.clear()
	for player: PlayerCharacter in players:
		if not player.is_alive:
			continue
		if not player.is_human:
			var target: Variant = player.choose_target(players, rng)
			if target != null:
				player.aim_at_point(_get_bot_aim_point(target as PlayerCharacter))
		shot_queue.append(player)
	shot_queue.shuffle()
	_show_round_transition("Phase de tir", _build_alive_list_text())
	var reveal_timer: SceneTreeTimer = get_tree().create_timer(ROUND_TRANSITION_FADE_IN + 0.15)
	reveal_timer.timeout.connect(_reveal_light_phase)

func _update_light_phase(delta: float) -> void:
	# Gère le tempo des tirs séquentiels pendant la phase lumière.
	if not light_phase_revealed:
		return
	if pre_light_observe_left > 0.0:
		pre_light_observe_left -= delta
		if pre_light_observe_left > 0.0:
			return
		shot_delay_left = min(shot_delay_left, 0.3)
	if shot_queue.is_empty():
		phase = Phase.ROUND_END
		phase_time_left = 1.2
		_show_round_transition("Fin manche %d" % round_number, _build_alive_list_text())
		return

	shot_delay_left -= delta
	if shot_delay_left > 0.0:
		return

	var shooter: PlayerCharacter = shot_queue.pop_front() as PlayerCharacter
	if is_instance_valid(shooter) and shooter.is_alive:
		_fire_projectile_in_direction(shooter, shooter.get_locked_shot_direction())
	shot_delay_left = LIGHT_SHOT_DELAY
	_refresh_shot_order_ui()

func _reveal_light_phase() -> void:
	if phase != Phase.LIGHT:
		return
	light_phase_revealed = true
	pre_light_observe_left = PRE_LIGHT_OBSERVE_TIME
	shot_delay_left = 0.3
	free_camera_target = human_player
	free_camera_active = false
	for player: PlayerCharacter in players:
		if not player.is_alive:
			continue
		player.set_phase_visibility(false)
		player.lock_for_light()
	var queued_players: Array[PlayerCharacter] = []
	for player: PlayerCharacter in shot_queue:
		if is_instance_valid(player) and player.is_alive:
			queued_players.append(player)
	_apply_shot_order_nameplates(queued_players)
	_refresh_shot_order_ui()

func _update_round_end(delta: float) -> void:
	# Petite pause entre manches, rétrécit l'arène puis relance la phase sombre.
	_refresh_shot_order_ui()
	phase_time_left -= delta
	if phase_time_left > 0.0:
		return

	var alive_players: Array[PlayerCharacter] = _get_alive_players()
	if alive_players.size() <= 1:
		_end_match()
		return

	round_number += 1
	arena_radius = max(MIN_RADIUS, arena_radius * SHRINK_FACTOR)
	_update_platform_size()
	_reposition_outside_players()
	_start_dark_phase()

func _fire_projectile_in_direction(shooter: PlayerCharacter, direction: Vector3) -> void:
	# Instancie et tire un projectile depuis un joueur donné.
	var projectile: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
	projectiles_root.add_child(projectile)
	projectile.configure(shooter.get_muzzle_position(), direction, shooter)
	projectile.hit_player.connect(_on_projectile_hit)

func _on_projectile_hit(target: PlayerCharacter, shooter: PlayerCharacter) -> void:
	# Callback sur touche : élimine la cible et notifie.
	if target != null and target.is_alive:
		if target == human_player and shooter != null and shooter.is_alive:
			spectated_player = shooter
			_snap_camera_to_player(spectated_player)
		var shooter_name: String = shooter.player_name if shooter != null else "?"
		_show_notification("%s touche %s" % [shooter_name, target.player_name])
		target.eliminate()

func _on_player_eliminated(player: PlayerCharacter) -> void:
	# Gestion de l'ordre d'élimination, spectateur, fin de partie potentielle.
	if not elimination_order.has(player):
		elimination_order.append(player)
	shot_queue.erase(player)
	_show_notification("%s est éliminé" % player.player_name)
	if player == human_player:
		if spectated_player == null or not spectated_player.is_alive:
			spectated_player = _find_first_alive_player_except(human_player)
		_show_notification("Vous êtes mort")
	if spectated_player == player:
		spectated_player = _find_first_alive_player_except(human_player)
	if human_player != null and not human_player.is_alive and spectated_player != null:
		_snap_camera_to_player(spectated_player)
	_refresh_shot_order_ui()
	if _get_alive_players().size() <= 1 and phase != Phase.GAME_OVER:
		_end_match()

func _find_first_alive_player_except(excluded: PlayerCharacter) -> Variant:
	for player: PlayerCharacter in players:
		if player != excluded and player.is_alive:
			return player
	return null

func _ensure_spectated_target() -> void:
	# S'assure qu'un joueur valide est suivi en spectateur.
	if human_player != null and human_player.is_alive:
		return
	if spectated_player == null or not spectated_player.is_alive:
		spectated_player = _find_first_alive_player_except(human_player)
		if spectated_player != null:
			_snap_camera_to_player(spectated_player)

func _cycle_spectated_player(direction: int) -> void:
	# Parcours des survivants en spectateur (clic gauche/droit).
	var alive_players: Array[PlayerCharacter] = _get_alive_players()
	if human_player != null:
		alive_players.erase(human_player)
	if alive_players.is_empty():
		return
	var current_index: int = alive_players.find(spectated_player)
	if current_index == -1:
		current_index = 0
	var next_index: int = wrapi(current_index + direction, 0, alive_players.size())
	spectated_player = alive_players[next_index]
	_snap_camera_to_player(spectated_player)

func _snap_camera_to_player(target_player: PlayerCharacter) -> void:
	if target_player == null:
		return
	var focus_point: Vector3 = target_player.global_position + Vector3(0, target_player.get_camera_focus_height(), 0)
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
	var desired_position: Vector3 = focus_point + Vector3(0, target_player.get_camera_height_offset(), 0) + back_direction * CAMERA_DISTANCE + right_direction * CAMERA_SIDE_OFFSET
	camera.global_position = desired_position
	camera.look_at(focus_point, Vector3.UP)
	is_controller_camera_active = false
	free_camera_target = target_player

func _on_spectator_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/mode_select.tscn")

func _get_camera_target_player() -> Variant:
	if human_player != null and human_player.is_alive:
		return human_player
	if spectated_player != null and spectated_player.is_alive:
		return spectated_player
	return _find_first_alive_player_except(null)

func _update_platform_size() -> void:
	var platform_mesh: BoxMesh = platform_mesh_instance.mesh as BoxMesh
	platform_mesh.size = Vector3(arena_radius * 2.0, 1.0, arena_radius * 2.0)

	var platform_shape: BoxShape3D = platform_collision.shape as BoxShape3D
	platform_shape.size = Vector3(arena_radius * 2.0, 1.0, arena_radius * 2.0)

func _update_camera(delta: float) -> void:
	# Caméra orbitale : souris par défaut, gyro si la souris sort de l'écran.
	_ensure_spectated_target()
	var camera_target: Variant = _get_camera_target_player()
	if camera_target == null:
		return
	var target_player: PlayerCharacter = camera_target as PlayerCharacter
	var focus_point: Vector3 = target_player.global_position + Vector3(0, target_player.get_camera_focus_height(), 0)
	var was_mouse_inside: bool = last_mouse_inside
	last_mouse_inside = _is_mouse_inside_viewport()
	if not last_mouse_inside and was_mouse_inside:
		gyro_active = true
	if last_mouse_inside and not was_mouse_inside:
		gyro_active = false
	if gyro_active and not last_mouse_inside:
		mouse_camera_yaw += gyro_yaw_speed * delta
		mouse_camera_pitch = clamp(mouse_camera_pitch + gyro_pitch_speed * delta, CAMERA_CONTROLLER_PITCH_MIN, CAMERA_CONTROLLER_PITCH_MAX)
		free_camera_yaw = mouse_camera_yaw
		free_camera_pitch = mouse_camera_pitch
	if not last_mouse_inside:
		controller_camera_yaw = mouse_camera_yaw
		controller_camera_pitch = mouse_camera_pitch
	if free_camera_active and target_player == free_camera_target:
		var use_yaw_fc: float = free_camera_yaw if not last_mouse_inside else mouse_camera_yaw
		var use_pitch_fc: float = free_camera_pitch if not last_mouse_inside else mouse_camera_pitch
		var look_basis_fc: Basis = Basis(Vector3.UP, use_yaw_fc) * Basis(Vector3.RIGHT, use_pitch_fc)
		var forward_fc: Vector3 = -look_basis_fc.z
		var right_fc: Vector3 = look_basis_fc.x
		var vertical_offset_fc: float = target_player.get_camera_height_offset() - target_player.get_camera_focus_height()
		var desired_position_fc: Vector3 = focus_point - forward_fc * CAMERA_DISTANCE + right_fc * CAMERA_SIDE_OFFSET + Vector3.UP * vertical_offset_fc
		camera.global_position = camera.global_position.lerp(desired_position_fc, clamp(delta * CAMERA_SMOOTHNESS, 0.0, 1.0))
		camera.look_at(focus_point, Vector3.UP)
		return
	if target_player == human_player:
		var use_yaw: float = controller_camera_yaw if (is_controller_camera_active or not last_mouse_inside) else mouse_camera_yaw
		var use_pitch: float = controller_camera_pitch if (is_controller_camera_active or not last_mouse_inside) else mouse_camera_pitch
		var look_basis: Basis = Basis(Vector3.UP, use_yaw) * Basis(Vector3.RIGHT, use_pitch)
		var forward: Vector3 = -look_basis.z
		var right: Vector3 = look_basis.x
		var vertical_offset: float = target_player.get_camera_height_offset() - target_player.get_camera_focus_height()
		var desired_position: Vector3 = focus_point - forward * CAMERA_DISTANCE + right * CAMERA_SIDE_OFFSET + Vector3.UP * vertical_offset
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
	var desired_position: Vector3 = focus_point + Vector3(0, target_player.get_camera_height_offset(), 0) + back_direction * CAMERA_DISTANCE + right_direction * CAMERA_SIDE_OFFSET
	camera.global_position = camera.global_position.lerp(desired_position, clamp(delta * CAMERA_SMOOTHNESS, 0.0, 1.0))
	camera.look_at(focus_point, Vector3.UP)

func _reposition_outside_players() -> void:
	var limit: float = max(1.0, arena_radius - 0.8)
	for player: PlayerCharacter in players:
		if not player.is_alive:
			continue
		var local_pos: Vector3 = player.global_position - arena_center
		local_pos.x = clamp(local_pos.x, -limit, limit)
		local_pos.z = clamp(local_pos.z, -limit, limit)
		player.global_position = arena_center + local_pos
		player.global_position.y = 1.05

func _refresh_shot_order_ui() -> void:
	# Met à jour le panneau d'ordre de tir et les nameplates (#).
	if phase != Phase.LIGHT or not light_phase_revealed:
		order_panel.visible = false
		return
	for child: Node in order_list.get_children():
		child.queue_free()
	var queued_players: Array[PlayerCharacter] = []
	for player: PlayerCharacter in shot_queue:
		if is_instance_valid(player) and player.is_alive:
			queued_players.append(player)
	if queued_players.is_empty():
		order_panel.visible = false
		return
	order_panel.visible = true
	var index: int = 1
	for player: PlayerCharacter in queued_players:
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
		name_label.text = player.player_name
		var player_color: Color = player.player_color
		if index == 1:
			player_color = player_color.lightened(0.35)
		name_label.add_theme_color_override("font_color", player_color)
		if player == spectated_player:
			name_label.text += " (cam)"
		row.add_child(name_label)
		order_list.add_child(row)
		index += 1
	_apply_shot_order_nameplates(queued_players)

func _build_alive_list_text() -> String:
	# Texte pour la transition listant les survivants.
	var names: Array[String] = []
	for player: PlayerCharacter in _get_alive_players():
		names.append(player.player_name)
	return "Joueurs en vie : %s" % ", ".join(names)

func _show_notification(text: String) -> void:
	if text == "":
		notification_label.visible = false
		return
	notification_label.text = text
	notification_label.visible = true
	notification_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.6)
	tween.tween_property(notification_label, "modulate:a", 0.0, 0.4)
	tween.finished.connect(func(): notification_label.visible = false)

func _apply_shot_order_nameplates(queued_players: Array[PlayerCharacter]) -> void:
	# Affiche pseudo + ordre de tir au-dessus de chaque bot (et des humains adverses éventuels).
	for i: int in range(queued_players.size()):
		var player: PlayerCharacter = queued_players[i]
		if player != null and player.is_alive:
			player.set_nameplate_text("%s (#%d)" % [player.player_name, i + 1])
			player.set_nameplate_visible(true)
	# Nettoie les autres vivants pour éviter un ordre obsolète.
	for player: PlayerCharacter in _get_alive_players():
		if not queued_players.has(player):
			player.set_nameplate_text(player.player_name)
			var should_show: bool = (phase == Phase.LIGHT and light_phase_revealed) or player == human_player
			player.set_nameplate_visible(should_show)

func _update_ui() -> void:
	# Rafraîchit HUD (phase, spectateur, compteur survivants).
	var alive_names: Array[String] = []
	for player: PlayerCharacter in players:
		if player.is_alive:
			alive_names.append(player.player_name)

	match phase:
		Phase.DARK:
			phase_label.text = "Déplacez-vous"
		Phase.LIGHT:
			phase_label.text = ""
		Phase.ROUND_END:
			phase_label.text = ""
		Phase.GAME_OVER:
			phase_label.text = "Partie terminee"

	var is_spectating: bool = human_player != null and not human_player.is_alive and phase != Phase.GAME_OVER
	spectator_label.visible = is_spectating
	if is_spectating and spectated_player != null and spectated_player.is_alive:
		spectator_label.text = "Spectateur - %s" % spectated_player.player_name
	else:
		spectator_label.text = "Spectateur"
	spectator_quit_button.visible = is_spectating
	if is_spectating and phase == Phase.DARK:
		for player: PlayerCharacter in players:
			if player.is_alive:
				player.set_revealed_in_darkness(true)
				player.set_phase_visibility(true)
		free_camera_target = spectated_player
		free_camera_active = true
		free_camera_yaw = mouse_camera_yaw
		free_camera_pitch = mouse_camera_pitch
	if human_player != null and human_player.is_alive:
		human_player.set_nameplate_text("%s" % human_player.player_name)
		human_player.set_nameplate_visible(true)
		free_camera_target = human_player
		free_camera_active = false

	if is_game_over_screen_open:
		info_label.text = ""
	else:
		info_label.text = "Joueurs en vie : %d" % alive_names.size()

func _show_round_transition(text: String, alive_text: String = "") -> void:
	if is_instance_valid(round_transition_tween):
		round_transition_tween.kill()
	round_transition_label.text = text
	round_transition_alive_label.text = alive_text
	round_transition_overlay.modulate.a = 0.0
	round_transition_overlay.visible = true
	round_transition_tween = create_tween()
	round_transition_tween.tween_property(round_transition_overlay, "modulate:a", 0.8, ROUND_TRANSITION_FADE_IN)
	round_transition_tween.tween_interval(ROUND_TRANSITION_HOLD)
	round_transition_tween.tween_property(round_transition_overlay, "modulate:a", 0.0, ROUND_TRANSITION_FADE_OUT)
	round_transition_tween.finished.connect(_hide_round_transition)

func _hide_round_transition() -> void:
	round_transition_overlay.visible = false
	round_transition_alive_label.text = ""
	round_transition_tween = null

func _end_match() -> void:
	if is_game_over_screen_open:
		return
	phase = Phase.GAME_OVER
	_save_match_result()
	_show_game_over_screen()

func _show_game_over_screen() -> void:
	# Affiche l'écran de fin (victoire/défaite) et fige la partie.
	is_game_over_screen_open = true
	if is_pause_menu_open:
		_close_pause_menu()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	game_over_overlay.visible = true
	order_panel.visible = false
	round_transition_overlay.visible = false
	var human_alive: bool = human_player != null and human_player.is_alive
	game_over_title_label.text = "Victoire" if human_alive else "Défaite"
	_show_notification(game_over_title_label.text)
	ranking_label.text = _build_ranking_text()
	spectator_label.visible = false
	MenuAudio.connect_buttons(game_over_overlay)
	game_over_restart_button.call_deferred("grab_focus")

func _compute_final_ranking() -> Array[PlayerCharacter]:
	var ranking: Array[PlayerCharacter] = []
	for survivor: PlayerCharacter in _get_alive_players():
		if not ranking.has(survivor):
			ranking.append(survivor)
	for index: int in range(elimination_order.size() - 1, -1, -1):
		var eliminated_player: PlayerCharacter = elimination_order[index]
		if not ranking.has(eliminated_player):
			ranking.append(eliminated_player)
	for player: PlayerCharacter in players:
		if not ranking.has(player):
			ranking.append(player)
	return ranking

func _get_player_rank(target_player: PlayerCharacter, ranking: Array[PlayerCharacter]) -> int:
	if target_player == null:
		return -1
	var index: int = ranking.find(target_player)
	return index + 1 if index != -1 else -1

func _build_ranking_text() -> String:
	var ranking: Array[PlayerCharacter] = _compute_final_ranking()
	var lines: Array[String] = []
	for i: int in range(ranking.size()):
		var player: PlayerCharacter = ranking[i]
		lines.append("%d. %s" % [i + 1, player.player_name])
	return "\n".join(lines)

func _save_match_result() -> void:
	if has_saved_match:
		return
	if human_player == null:
		return
	var ranking: Array[PlayerCharacter] = _compute_final_ranking()
	var player_rank: int = _get_player_rank(human_player, ranking)
	if player_rank <= 0:
		return
	var selected_character: Dictionary = GameState.get_selected_character()
	var skin_id: String = selected_character.get("id", "unknown")
	var difficulty_for_db: String = _map_difficulty_for_db(GameState.selected_bot_difficulty)
	register_score_in_database(
		human_player.player_name,
		player_rank,
		skin_id,
		difficulty_for_db,
		GameState.selected_bot_count,
		GameState.selected_game_mode
	)
	has_saved_match = true

func _map_difficulty_for_db(value: String) -> String:
	var normalized: String = value.to_lower()
	match normalized:
		GameState.BOT_DIFFICULTY_BEGINNER, "easy", "debutant":
			return "easy"
		GameState.BOT_DIFFICULTY_HARD, "hard", "difficile":
			return "hard"
		GameState.BOT_DIFFICULTY_NORMAL, "normal":
			return "normal"
		_:
			return "normal"

func _get_alive_players() -> Array[PlayerCharacter]:
	var alive: Array[PlayerCharacter] = []
	for player: PlayerCharacter in players:
		if player.is_alive:
			alive.append(player)
	return alive

func _get_movement_input_vector() -> Vector2:
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

func _get_controller_aim_input() -> Vector2:
	var aim_input: Vector2 = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		-Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)
	if aim_input.length() < GAMEPAD_DEADZONE:
		return Vector2.ZERO
	return aim_input.limit_length(1.0)

func _sync_controller_camera_to_player() -> void:
	# Aligne la caméra de contrôle (manette/souris) sur l'orientation du joueur.
	if human_player == null:
		return
	var facing: Vector3 = -human_player.global_basis.z
	facing.y = 0.0
	if facing.length() < 0.01:
		facing = Vector3.FORWARD
	facing = facing.normalized()
	controller_camera_yaw = atan2(-facing.x, -facing.z)
	controller_camera_pitch = 0.25
	mouse_camera_yaw = controller_camera_yaw
	mouse_camera_pitch = controller_camera_pitch

func _update_controller_aim_from_camera() -> void:
	# Convertit la caméra manette en vecteur d'aim pour le joueur.
	if human_player == null or not human_player.is_alive:
		return
	var look_basis: Basis = Basis(Vector3.UP, controller_camera_yaw) * Basis(Vector3.RIGHT, controller_camera_pitch)
	var forward: Vector3 = -look_basis.z
	forward.y = 0.0
	if forward.length() < 0.01:
		return
	human_player.aim_at_point(human_player.global_position + forward.normalized() * 20.0)

func _update_mouse_aim_from_camera() -> void:
	# Convertit la caméra souris en vecteur d'aim pour le joueur.
	if human_player == null or not human_player.is_alive:
		return
	var look_basis: Basis = Basis(Vector3.UP, mouse_camera_yaw) * Basis(Vector3.RIGHT, mouse_camera_pitch)
	var forward: Vector3 = -look_basis.z
	forward.y = 0.0
	if forward.length() < 0.01:
		return
	human_player.aim_at_point(human_player.global_position + forward.normalized() * 20.0)

func _ensure_gamepad_bindings() -> void:
	_ensure_action_has_joypad_button("toggle_prone", JOY_BUTTON_B)
	_ensure_action_has_joypad_button("toggle_pause", JOY_BUTTON_START)
	_ensure_action_has_joypad_button("ui_accept", JOY_BUTTON_A)
	_ensure_action_has_joypad_button("ui_cancel", JOY_BUTTON_B)
	_ensure_action_has_joypad_button("ui_up", JOY_BUTTON_DPAD_UP)
	_ensure_action_has_joypad_button("ui_down", JOY_BUTTON_DPAD_DOWN)
	_ensure_action_has_joypad_button("ui_left", JOY_BUTTON_DPAD_LEFT)
	_ensure_action_has_joypad_button("ui_right", JOY_BUTTON_DPAD_RIGHT)

func _ensure_action_has_joypad_button(action_id: String, button_index: JoyButton) -> void:
	if not InputMap.has_action(action_id):
		InputMap.add_action(action_id)
	for event: InputEvent in InputMap.action_get_events(action_id):
		if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == button_index:
			return
	var joy_event: InputEventJoypadButton = InputEventJoypadButton.new()
	joy_event.button_index = button_index
	InputMap.action_add_event(action_id, joy_event)

func _make_pixel_texture(palette: Array[Color], size: int) -> ImageTexture:
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(palette[0])
	for x: int in range(size):
		for y: int in range(size):
			var index: int = int((x * 7 + y * 11 + x * y) % palette.size())
			image.set_pixel(x, y, palette[index])
	return ImageTexture.create_from_image(image)

func _make_platform_reference_texture() -> ImageTexture:
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

func _make_nether_rock_texture() -> ImageTexture:
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

func _make_basalt_texture() -> ImageTexture:
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

func _make_glowstone_texture() -> ImageTexture:
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

func _make_lava_reference_texture() -> ImageTexture:
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

func _is_mouse_inside_viewport() -> bool:
	var pos: Vector2 = get_viewport().get_mouse_position()
	var size: Vector2 = get_viewport().get_visible_rect().size
	return pos.x >= 0.0 and pos.y >= 0.0 and pos.x <= size.x and pos.y <= size.y

func refresh_database_schema() -> void:
	var db: SQLite = SQLite.new()
	db.path = _get_database_path()
	if not db.open_db():
		printerr("Impossible d'ouvrir ou de créer la base SQLite à l'emplacement %s" % db.path)
		return
	_ensure_results_table(db)
	db.close_db()

func register_score_in_database(name, position, skin, difficulty_selected, number_of_bots, mode: String = "solo") -> void:
	var db: SQLite = SQLite.new()
	db.path = _get_database_path()
	if not db.open_db():
		printerr("Impossible d'ouvrir la base SQLite à l'emplacement %s" % db.path)
		return
	_ensure_results_table(db)
	var row := {
		"name": name,
		"position": position,
		"skin": skin,
		"difficulty_selected": _map_difficulty_for_db(str(difficulty_selected)),
		"mode_selected": mode,
		"number_of_bots": number_of_bots
	}
	db.insert_row("Resultats", row)
	db.close_db()

func _get_database_path() -> String:
	return ProjectSettings.globalize_path(DATABASE_PATH)

func _ensure_results_table(db: SQLite) -> void:
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
