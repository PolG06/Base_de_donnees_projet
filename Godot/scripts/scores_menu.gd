extends Control

# �?cran de consultation des scores persistés en SQLite :
# - ouvre la base (chemin relatif au projet), crée la table si besoin
# - charge les lignes et remplit un tableau scrollable
# - gère l'état vide/erreur et permet de revenir au menu principal.

const DATABASE_PATH := "res://../Database_sqlite/database.db"

@onready var etiquette_titre: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var etiquette_sous_titre: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/SubtitleLabel
@onready var entete_nom: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/ScoresPanel/ScoresMargin/ScrollContainer/Table/HeaderRow/NameHeader
@onready var entete_position: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/ScoresPanel/ScoresMargin/ScrollContainer/Table/HeaderRow/PositionHeader
@onready var entete_mode: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/ScoresPanel/ScoresMargin/ScrollContainer/Table/HeaderRow/ModeHeader
@onready var entete_difficulte: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/ScoresPanel/ScoresMargin/ScrollContainer/Table/HeaderRow/DifficultyHeader
@onready var entete_bots: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/ScoresPanel/ScoresMargin/ScrollContainer/Table/HeaderRow/BotsHeader
@onready var entete_skin: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/ScoresPanel/ScoresMargin/ScrollContainer/Table/HeaderRow/SkinHeader
@onready var liste_scores: VBoxContainer = $CenterContainer/Panel/MarginContainer/VBoxContainer/ScoresPanel/ScoresMargin/ScrollContainer/Table/ScoresList
@onready var etiquette_vide: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/EmptyLabel
@onready var bouton_quitter: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/QuitButton

func _ready() -> void:
	# Met à jour les textes, connecte le bouton retour, joue la musique et charge les scores.
	_appliquer_traductions()
	bouton_quitter.pressed.connect(_sur_quitter_presse)
	MenuAudio.connecter_boutons(self)
	MenuMusic.jouer_musique_menu()
	_charger_scores()
	bouton_quitter.call_deferred("grab_focus")

func _appliquer_traductions() -> void:
	# Applique les libellés localisés des en-têtes et du bouton retour.
	etiquette_titre.text = GameState.cle_traduction("scores_title")
	etiquette_sous_titre.text = GameState.cle_traduction("scores_subtitle")
	entete_nom.text = GameState.cle_traduction("scores_header_name")
	entete_position.text = GameState.cle_traduction("scores_header_position")
	entete_mode.text = GameState.cle_traduction("scores_header_mode")
	entete_difficulte.text = GameState.cle_traduction("scores_header_difficulty")
	entete_bots.text = GameState.cle_traduction("scores_header_bots")
	entete_skin.text = GameState.cle_traduction("scores_header_skin")
	etiquette_vide.text = GameState.cle_traduction("scores_empty")
	bouton_quitter.text = GameState.cle_traduction("scores_back")

func _sur_quitter_presse() -> void:
	# Retour menu principal.
	get_tree().change_scene_to_file("res://scenes/menu_main.tscn")

func _charger_scores() -> void:
	# Ouvre la base, vérifie la table, lit les lignes et construit la liste ou affiche un message vide.
	_vider_scores()
	var db: SQLite = SQLite.new()
	db.path = ProjectSettings.globalize_path(DATABASE_PATH)
	if not db.open_db():
		_afficher_vide(GameState.cle_traduction("scores_error_db"))
		return
	_verifier_table_resultats(db)
	db.query("""
		SELECT name, position, skin, difficulty_selected, mode_selected, number_of_bots
		FROM Resultats
		ORDER BY id DESC
	""")
	var results: Array = db.query_result
	db.close_db()
	if results == null or results.is_empty():
		_afficher_vide(GameState.cle_traduction("scores_empty"))
		return
	for row in results:
		liste_scores.add_child(_construire_ligne(row))

func _vider_scores() -> void:
	# Supprime le contenu actuel du tableau et cache le label vide.
	for child: Node in liste_scores.get_children():
		child.queue_free()
	etiquette_vide.visible = false

func _afficher_vide(message: String) -> void:
	# Affiche un message d'état (erreur ou aucun score).
	etiquette_vide.text = message
	etiquette_vide.visible = true

func _construire_ligne(row: Dictionary) -> HBoxContainer:
	# Construit une ligne de scores avec cellules formatées.
	var container := HBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_theme_constant_override("separation", 12)
	container.add_child(_creer_cellule(str(row.get("name", "-")), 160, HORIZONTAL_ALIGNMENT_LEFT))
	container.add_child(_creer_cellule(_formater_position(row.get("position", "")), 90))
	container.add_child(_creer_cellule(_formater_mode(row.get("mode_selected", "")), 120))
	container.add_child(_creer_cellule(_formater_difficulte(row.get("difficulty_selected", "")), 120))
	container.add_child(_creer_cellule(_formater_bots(row.get("number_of_bots", "")), 80))
	container.add_child(_creer_cellule(str(row.get("skin", "-")), 90))
	return container

func _creer_cellule(text: String, min_width: float, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	# Crée une cellule de tableau avec largeur et alignement configurables.
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(min_width, 32)
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _formater_position(value) -> String:
	# Formate la position en entier ou chaîne brute.
	if typeof(value) == TYPE_INT:
		return str(value)
	if typeof(value) == TYPE_FLOAT:
		return str(int(value))
	return str(value)

func _formater_mode(value) -> String:
	# Traduction conviviale du mode sauvegardé.
	var normalized: String = str(value).to_lower()
	match normalized:
		"solo":
			return GameState.cle_traduction("scores_mode_solo")
		"multiplayer":
			return GameState.cle_traduction("scores_mode_multiplayer")
		"difficile":
			return GameState.cle_traduction("scores_mode_hardcore")
		_:
			return str(value)

func _formater_difficulte(value) -> String:
	# Traduction conviviale de la difficulté.
	var normalized: String = str(value).to_lower()
	match normalized:
		"easy":
			return GameState.cle_traduction("difficulty_beginner")
		"hard":
			return GameState.cle_traduction("difficulty_hard")
		"normal":
			return GameState.cle_traduction("difficulty_normal")
		_:
			return str(value)

func _formater_bots(value) -> String:
	# Formate le nombre de bots (entier) ou renvoie la valeur brute.
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return str(int(value))
	return str(value)

func _verifier_table_resultats(db: SQLite) -> void:
	# Crée la table si besoin (mêmes colonnes que côté jeu).
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
