extends Control

const PREVIEW_PLAYER_SCENE := preload("res://scenes/player_character.tscn")

@onready var title_label: Label = $MarginContainer/RootColumn/MainRow/PreviewPanel/PreviewMargin/PreviewColumn/TitleLabel
@onready var preview_name_label: Label = $MarginContainer/RootColumn/MainRow/PreviewPanel/PreviewMargin/PreviewColumn/SelectedNameLabel
@onready var preview_viewport: SubViewport = $MarginContainer/RootColumn/MainRow/PreviewPanel/PreviewMargin/PreviewColumn/ViewportFrame/SubViewportContainer/SubViewport
@onready var hint_label: Label = $MarginContainer/RootColumn/MainRow/OptionsPanel/OptionsMargin/OptionsColumn/HintLabel
@onready var options_grid: GridContainer = $MarginContainer/RootColumn/MainRow/OptionsPanel/OptionsMargin/OptionsColumn/ScrollContainer/OptionsGrid
@onready var pseudo_line_edit: LineEdit = $MarginContainer/RootColumn/PseudoRow/PseudoLineEdit
@onready var start_button: Button = $MarginContainer/RootColumn/BottomRow/StartButton
@onready var back_button: Button = $MarginContainer/RootColumn/BottomRow/BackButton

var preview_player: PlayerCharacter
var option_buttons: Array[Button] = []

func _ready() -> void:
	_apply_translations()
	_build_preview()
	_build_option_buttons()
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	pseudo_line_edit.text = GameState.get_human_player_name()
	pseudo_line_edit.text_changed.connect(_on_pseudo_changed)
	_refresh_selection()
	MenuAudio.connect_buttons(self)
	MenuMusic.play_menu_music()
	_grab_selected_option_focus()

func _process(delta: float) -> void:
	if preview_player != null:
		preview_player.rotate_y(delta * 0.9)

func _apply_translations() -> void:
	title_label.text = GameState.tr_key("character_title")
	hint_label.text = GameState.tr_key("character_hint")
	start_button.text = GameState.tr_key("character_start")
	back_button.text = GameState.tr_key("common_back")

func _build_preview() -> void:
	var root: Node3D = Node3D.new()
	preview_viewport.add_child(root)

	var camera: Camera3D = Camera3D.new()
	camera.position = Vector3(0, 1.8, 4.8)
	camera.look_at(Vector3(0, 1.2, 0), Vector3.UP)
	camera.current = true
	root.add_child(camera)

	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 30, 0)
	light.light_energy = 2.0
	root.add_child(light)

	var fill: OmniLight3D = OmniLight3D.new()
	fill.position = Vector3(0, 2.0, 2.2)
	fill.light_energy = 1.5
	root.add_child(fill)

	var floor: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(4, 0.2, 4)
	floor.mesh = mesh
	floor.position = Vector3(0, -0.1, 0)
	var floor_material: StandardMaterial3D = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.35, 0.35, 0.38)
	floor.material_override = floor_material
	root.add_child(floor)

	preview_player = PREVIEW_PLAYER_SCENE.instantiate() as PlayerCharacter
	preview_player.player_name = "Preview"
	preview_player.global_position = Vector3(0, 0, 0)
	root.add_child(preview_player)

func _build_option_buttons() -> void:
	for child: Node in options_grid.get_children():
		child.queue_free()
	option_buttons.clear()

	for i: int in range(GameState.CHARACTER_OPTIONS.size()):
		var option: Dictionary = GameState.CHARACTER_OPTIONS[i]
		var button: Button = Button.new()
		button.text = GameState.get_character_display_name(option)
		button.custom_minimum_size = Vector2(0, 64)
		button.modulate = option["body_color"]
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_on_option_pressed.bind(i))
		options_grid.add_child(button)
		option_buttons.append(button)

func _on_option_pressed(index: int) -> void:
	GameState.select_character(index)
	_refresh_selection()
	MenuAudio.connect_buttons(self)
	MenuMusic.play_menu_music()
	_grab_selected_option_focus()

func _refresh_selection() -> void:
	var selected: Dictionary = GameState.get_selected_character()
	var selected_name: String = GameState.get_character_display_name(selected)
	preview_name_label.text = GameState.tr_key("character_selected_color") % selected_name
	preview_player.player_name = selected_name
	preview_player.player_color = selected["body_color"]
	preview_player.skin_color = selected["skin_color"]
	preview_player.accent_color = selected["accent_color"]
	preview_player.rebuild_visuals()
	for i: int in range(option_buttons.size()):
		option_buttons[i].disabled = i == GameState.selected_character_index
		option_buttons[i].text = GameState.get_character_display_name(GameState.CHARACTER_OPTIONS[i])

func _on_pseudo_changed(text: String) -> void:
	GameState.set_human_player_name(text)

func _grab_selected_option_focus() -> void:
	if GameState.selected_character_index >= 0 and GameState.selected_character_index < option_buttons.size():
		option_buttons[GameState.selected_character_index].call_deferred("grab_focus")

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_back_pressed() -> void:
	if GameState.selected_game_mode == GameState.GAME_MODE_SOLO:
		get_tree().change_scene_to_file("res://scenes/solo_setup.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/mode_select.tscn")

