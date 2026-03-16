extends Control

@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/SubtitleLabel
@onready var action_header_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/ControlsPanel/ControlsMargin/ControlsColumn/HeaderRow/ActionHeader
@onready var key_header_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/ControlsPanel/ControlsMargin/ControlsColumn/HeaderRow/KeyHeader
@onready var controls_list: VBoxContainer = $CenterContainer/Panel/MarginContainer/VBoxContainer/ControlsPanel/ControlsMargin/ControlsColumn/ScrollContainer/ControlsList
@onready var status_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/StatusPanel/StatusLabel
@onready var back_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/BackButton

var waiting_action_id: String = ""
var action_buttons: Dictionary = {}
var volume_slider: HSlider
var volume_value_label: Label

func _ready() -> void:
	_apply_translations()
	_build_action_rows()
	_refresh_action_buttons()
	MenuAudio.connect_buttons(self)
	MenuMusic.play_menu_music()
	back_button.pressed.connect(_on_back_pressed)
	if action_buttons.has("ui_up"):
		(action_buttons["ui_up"] as Button).call_deferred("grab_focus")

func _unhandled_input(event: InputEvent) -> void:
	if waiting_action_id.is_empty():
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		var keycode: Key = key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
		GameState.rebind_action(waiting_action_id, keycode)
		status_label.text = "%s : %s" % [GameState.get_action_display_name(waiting_action_id), GameState.get_action_binding_summary(waiting_action_id)]
		waiting_action_id = ""
		_refresh_action_buttons()
		get_viewport().set_input_as_handled()

func _apply_translations() -> void:
	title_label.text = GameState.tr_key("settings_title")
	subtitle_label.text = GameState.tr_key("settings_subtitle")
	action_header_label.text = GameState.tr_key("settings_action_header")
	key_header_label.text = GameState.tr_key("settings_binding_header")
	status_label.text = GameState.tr_key("settings_status_default")
	back_button.text = GameState.tr_key("common_back")

func _build_action_rows() -> void:
	for child: Node in controls_list.get_children():
		child.queue_free()
	action_buttons.clear()
	volume_slider = null
	volume_value_label = null

	for binding: Dictionary in GameState.ACTION_BINDINGS:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		controls_list.add_child(row)

		var label: Label = Label.new()
		label.text = GameState.get_action_display_name(binding["id"])
		label.custom_minimum_size = Vector2(280, 46)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(label)

		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(260, 46)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_on_rebind_pressed.bind(binding["id"]))
		row.add_child(button)
		action_buttons[binding["id"]] = button

	var volume_row: HBoxContainer = HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 12)
	controls_list.add_child(volume_row)

	var volume_label: Label = Label.new()
	volume_label.text = GameState.tr_key("settings_volume")
	volume_label.custom_minimum_size = Vector2(280, 46)
	volume_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	volume_row.add_child(volume_label)

	var volume_box: HBoxContainer = HBoxContainer.new()
	volume_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_box.add_theme_constant_override("separation", 10)
	volume_row.add_child(volume_box)

	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.01
	volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_slider.custom_minimum_size = Vector2(180, 46)
	volume_slider.value = GameState.get_master_volume()
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_box.add_child(volume_slider)

	volume_value_label = Label.new()
	volume_value_label.custom_minimum_size = Vector2(70, 46)
	volume_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	volume_value_label.text = GameState.get_master_volume_text()
	volume_box.add_child(volume_value_label)

	var aim_row: HBoxContainer = HBoxContainer.new()
	aim_row.add_theme_constant_override("separation", 12)
	controls_list.add_child(aim_row)

	var aim_label: Label = Label.new()
	aim_label.text = GameState.tr_key("controls_aim")
	aim_label.custom_minimum_size = Vector2(280, 46)
	aim_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	aim_row.add_child(aim_label)

	var aim_value: Label = Label.new()
	aim_value.text = "%s | %s" % [GameState.tr_key("controls_mouse"), GameState.tr_key("controls_right_stick")]
	aim_value.custom_minimum_size = Vector2(260, 46)
	aim_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	aim_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	aim_row.add_child(aim_value)

func _refresh_action_buttons() -> void:
	for binding: Dictionary in GameState.ACTION_BINDINGS:
		var action_id: String = binding["id"]
		var button: Button = action_buttons.get(action_id, null)
		if button == null:
			continue
		button.text = GameState.tr_key("settings_press_key") if action_id == waiting_action_id else GameState.get_action_binding_summary(action_id)
	if volume_slider != null:
		volume_slider.set_value_no_signal(GameState.get_master_volume())
	if volume_value_label != null:
		volume_value_label.text = GameState.get_master_volume_text()

func _on_rebind_pressed(action_id: String) -> void:
	waiting_action_id = action_id
	status_label.text = GameState.tr_key("settings_waiting") % [GameState.get_action_display_name(action_id), GameState.get_action_gamepad_text(action_id)]
	_refresh_action_buttons()

func _on_volume_changed(value: float) -> void:
	GameState.set_master_volume(value)
	if volume_value_label != null:
		volume_value_label.text = GameState.get_master_volume_text()
	if waiting_action_id.is_empty():
		status_label.text = GameState.tr_key("settings_volume_status")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu_main.tscn")
