extends Control

@onready var etiquette_titre: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var etiquette_sous_titre: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/SubtitleLabel
@onready var etiquette_entete_action: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/ControlsPanel/ControlsMargin/ControlsColumn/HeaderRow/ActionHeader
@onready var etiquette_entete_touche: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/ControlsPanel/ControlsMargin/ControlsColumn/HeaderRow/KeyHeader
@onready var liste_controles: VBoxContainer = $CenterContainer/Panel/MarginContainer/VBoxContainer/ControlsPanel/ControlsMargin/ControlsColumn/ScrollContainer/ControlsList
@onready var etiquette_statut: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/StatusPanel/StatusLabel
@onready var bouton_retour: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/BackButton

var identifiant_action_attendue: String = ""
var boutons_actions: Dictionary = {}
var curseur_volume: HSlider
var etiquette_valeur_volume: Label

func _ready() -> void:
	_appliquer_traductions()
	_construire_lignes_actions()
	_rafraichir_boutons_actions()
	MenuAudio.connecter_boutons(self)
	MenuMusic.jouer_musique_menu()
	bouton_retour.pressed.connect(_sur_retour_presse)
	if boutons_actions.has("ui_up"):
		(boutons_actions["ui_up"] as Button).call_deferred("grab_focus")

func _unhandled_input(event: InputEvent) -> void:
	if identifiant_action_attendue.is_empty():
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		var keycode: Key = key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
		GameState.reaffecter_action(identifiant_action_attendue, keycode)
		etiquette_statut.text = "%s : %s" % [GameState.obtenir_nom_action(identifiant_action_attendue), GameState.obtenir_resume_assignation_action(identifiant_action_attendue)]
		identifiant_action_attendue = ""
		_rafraichir_boutons_actions()
		get_viewport().set_input_as_handled()

func _appliquer_traductions() -> void:
	etiquette_titre.text = GameState.cle_traduction("settings_title")
	etiquette_sous_titre.text = GameState.cle_traduction("settings_subtitle")
	etiquette_entete_action.text = GameState.cle_traduction("settings_action_header")
	etiquette_entete_touche.text = GameState.cle_traduction("settings_binding_header")
	etiquette_statut.text = GameState.cle_traduction("settings_status_default")
	bouton_retour.text = GameState.cle_traduction("common_back")

func _construire_lignes_actions() -> void:
	for child: Node in liste_controles.get_children():
		child.queue_free()
	boutons_actions.clear()
	curseur_volume = null
	etiquette_valeur_volume = null

	for binding: Dictionary in GameState.LIAISONS_ACTIONS:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		liste_controles.add_child(row)

		var label: Label = Label.new()
		label.text = GameState.obtenir_nom_action(binding["id"])
		label.custom_minimum_size = Vector2(280, 46)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(label)

		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(260, 46)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_sur_reaffectation_presse.bind(binding["id"]))
		row.add_child(button)
		boutons_actions[binding["id"]] = button

	var volume_row: HBoxContainer = HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 12)
	liste_controles.add_child(volume_row)

	var volume_label: Label = Label.new()
	volume_label.text = GameState.cle_traduction("settings_volume")
	volume_label.custom_minimum_size = Vector2(280, 46)
	volume_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	volume_row.add_child(volume_label)

	var volume_box: HBoxContainer = HBoxContainer.new()
	volume_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_box.add_theme_constant_override("separation", 10)
	volume_row.add_child(volume_box)

	curseur_volume = HSlider.new()
	curseur_volume.min_value = 0.0
	curseur_volume.max_value = 1.0
	curseur_volume.step = 0.01
	curseur_volume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	curseur_volume.custom_minimum_size = Vector2(180, 46)
	curseur_volume.value = GameState.obtenir_volume_general()
	curseur_volume.value_changed.connect(_sur_volume_change)
	volume_box.add_child(curseur_volume)

	etiquette_valeur_volume = Label.new()
	etiquette_valeur_volume.custom_minimum_size = Vector2(70, 46)
	etiquette_valeur_volume.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiquette_valeur_volume.text = GameState.obtenir_texte_volume_general()
	volume_box.add_child(etiquette_valeur_volume)

	var aim_row: HBoxContainer = HBoxContainer.new()
	aim_row.add_theme_constant_override("separation", 12)
	controls_list.add_child(aim_row)

	var aim_label: Label = Label.new()
	aim_label.text = GameState.cle_traduction("controls_aim")
	aim_label.custom_minimum_size = Vector2(280, 46)
	aim_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	aim_row.add_child(aim_label)

	var aim_value: Label = Label.new()
	aim_value.text = "%s | %s" % [GameState.cle_traduction("controls_mouse"), GameState.cle_traduction("controls_right_stick")]
	aim_value.custom_minimum_size = Vector2(260, 46)
	aim_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	aim_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	aim_row.add_child(aim_value)

func _rafraichir_boutons_actions() -> void:
	for binding: Dictionary in GameState.LIAISONS_ACTIONS:
		var action_id: String = binding["id"]
		var button: Button = boutons_actions.get(action_id, null)
		if button == null:
			continue
		button.text = GameState.cle_traduction("settings_press_key") if action_id == identifiant_action_attendue else GameState.obtenir_resume_assignation_action(action_id)
	if curseur_volume != null:
		curseur_volume.set_value_no_signal(GameState.obtenir_volume_general())
	if etiquette_valeur_volume != null:
		etiquette_valeur_volume.text = GameState.obtenir_texte_volume_general()

func _sur_reaffectation_presse(action_id: String) -> void:
	identifiant_action_attendue = action_id
	etiquette_statut.text = GameState.cle_traduction("settings_waiting") % [GameState.obtenir_nom_action(action_id), GameState.obtenir_texte_manette_action(action_id)]
	_rafraichir_boutons_actions()

func _sur_volume_change(value: float) -> void:
	GameState.definir_volume_general(value)
	if etiquette_valeur_volume != null:
		etiquette_valeur_volume.text = GameState.obtenir_texte_volume_general()
	if identifiant_action_attendue.is_empty():
		etiquette_statut.text = GameState.cle_traduction("settings_volume_status")

func _sur_retour_presse() -> void:
	get_tree().change_scene_to_file("res://scenes/menu_main.tscn")
