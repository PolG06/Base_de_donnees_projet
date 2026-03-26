extends Control

# Menu de configuration des contrôles et du volume :
# - liste les actions définies dans GameState.LIAISONS_ACTIONS
# - permet de réassigner une touche/manette et affiche l'état d'attente
# - règle le volume global via GameState et renvoie au menu principal.

@onready var etiquette_titre: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var etiquette_sous_titre: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/SubtitleLabel
@onready var etiquette_entete_action: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/ControlsPanel/ControlsMargin/ControlsColumn/HeaderRow/ActionHeader
@onready var etiquette_entete_touche: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/ControlsPanel/ControlsMargin/ControlsColumn/HeaderRow/KeyHeader
@onready var liste_controles: VBoxContainer = $CenterContainer/Panel/MarginContainer/VBoxContainer/ControlsPanel/ControlsMargin/ControlsColumn/ScrollContainer/ControlsList
@onready var panneau_statut: Control = $CenterContainer/Panel/MarginContainer/VBoxContainer/StatusPanel
@onready var etiquette_statut: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/StatusPanel/StatusLabel
@onready var bouton_retour: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/BackButton

var identifiant_action_attendue: String = ""
var boutons_actions: Dictionary = {}
var curseur_volume: HSlider
var etiquette_valeur_volume: Label
var curseur_sensibilite: HSlider
var etiquette_valeur_sensibilite: Label

func _ready() -> void:
	# Applique la langue, construit la liste d'actions + volume, joue la musique, connecte le retour.
	_appliquer_traductions()
	_construire_lignes_actions()
	_rafraichir_boutons_actions()
	# On masque le panneau de statut pour éviter le texte en pied de page.
	panneau_statut.visible = false
	MenuAudio.connecter_boutons(self)
	MenuMusic.jouer_musique_menu()
	bouton_retour.pressed.connect(_sur_retour_presse)
	if boutons_actions.has("ui_up"):
		(boutons_actions["ui_up"] as Button).call_deferred("grab_focus")

func _unhandled_input(event: InputEvent) -> void:
	# Si on attend une nouvelle touche, capture la première pression et applique le rebind.
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
		panneau_statut.visible = false
		get_viewport().set_input_as_handled()

func _appliquer_traductions() -> void:
	# Met à jour les libellés des entêtes et du bouton retour.
	etiquette_titre.text = GameState.cle_traduction("settings_title")
	etiquette_sous_titre.text = GameState.cle_traduction("settings_subtitle")
	etiquette_entete_action.text = GameState.cle_traduction("settings_action_header")
	etiquette_entete_touche.text = GameState.cle_traduction("settings_binding_header")
	etiquette_statut.text = ""
	bouton_retour.text = GameState.cle_traduction("common_back")

func _construire_lignes_actions() -> void:
	# Construit dynamiquement chaque ligne (libellé + bouton d'assignation) puis la ligne volume.
	for child: Node in liste_controles.get_children():
		child.queue_free()
	boutons_actions.clear()
	curseur_volume = null
	etiquette_valeur_volume = null
	curseur_sensibilite = null
	etiquette_valeur_sensibilite = null

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

	var sensi_row: HBoxContainer = HBoxContainer.new()
	sensi_row.add_theme_constant_override("separation", 12)
	liste_controles.add_child(sensi_row)

	var sensi_label: Label = Label.new()
	sensi_label.text = GameState.cle_traduction("settings_mouse_sens")
	sensi_label.custom_minimum_size = Vector2(280, 46)
	sensi_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sensi_row.add_child(sensi_label)

	var sensi_box: HBoxContainer = HBoxContainer.new()
	sensi_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sensi_box.add_theme_constant_override("separation", 10)
	sensi_row.add_child(sensi_box)

	curseur_sensibilite = HSlider.new()
	curseur_sensibilite.min_value = 0.5
	curseur_sensibilite.max_value = 2.0
	curseur_sensibilite.step = 0.05
	curseur_sensibilite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	curseur_sensibilite.custom_minimum_size = Vector2(180, 46)
	curseur_sensibilite.value = GameState.obtenir_sensibilite_souris()
	curseur_sensibilite.value_changed.connect(_sur_sensibilite_change)
	sensi_box.add_child(curseur_sensibilite)

	etiquette_valeur_sensibilite = Label.new()
	etiquette_valeur_sensibilite.custom_minimum_size = Vector2(70, 46)
	etiquette_valeur_sensibilite.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiquette_valeur_sensibilite.text = GameState.obtenir_texte_sensibilite_souris()
	sensi_box.add_child(etiquette_valeur_sensibilite)

	var aim_row: HBoxContainer = HBoxContainer.new()
	aim_row.add_theme_constant_override("separation", 12)
	liste_controles.add_child(aim_row)

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
	# Met à jour les textes des boutons selon l'état (attente ou assignation existante) et le volume affiché.
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
	if curseur_sensibilite != null:
		curseur_sensibilite.set_value_no_signal(GameState.obtenir_sensibilite_souris())
	if etiquette_valeur_sensibilite != null:
		etiquette_valeur_sensibilite.text = GameState.obtenir_texte_sensibilite_souris()

func _sur_reaffectation_presse(action_id: String) -> void:
	# Passe en mode "attente de touche" pour l'action choisie.
	identifiant_action_attendue = action_id
	etiquette_statut.text = GameState.cle_traduction("settings_waiting") % [GameState.obtenir_nom_action(action_id), GameState.obtenir_texte_manette_action(action_id)]
	panneau_statut.visible = true
	_rafraichir_boutons_actions()

func _sur_volume_change(value: float) -> void:
	# Sauvegarde le volume global et rafraîchit l'affichage; laisse l'état d'attente intact si rebind en cours.
	GameState.definir_volume_general(value)
	if etiquette_valeur_volume != null:
		etiquette_valeur_volume.text = GameState.obtenir_texte_volume_general()
	if identifiant_action_attendue.is_empty():
		etiquette_statut.text = GameState.cle_traduction("settings_volume_status")

func _sur_sensibilite_change(value: float) -> void:
	# Met a jour la sensibilite souris et rafraichit l'affichage.
	GameState.definir_sensibilite_souris(value)
	if etiquette_valeur_sensibilite != null:
		etiquette_valeur_sensibilite.text = GameState.obtenir_texte_sensibilite_souris()
	if identifiant_action_attendue.is_empty():
		etiquette_statut.text = GameState.cle_traduction("settings_mouse_sens_status")

func _sur_retour_presse() -> void:
	# Retour au menu principal.
	get_tree().change_scene_to_file("res://scenes/menu_main.tscn")
