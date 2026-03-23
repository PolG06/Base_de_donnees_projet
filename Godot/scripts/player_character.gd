extends CharacterBody3D
class_name PlayerCharacter

# Script d'un joueur (humain ou bot) :
# - reçoit les commandes (humain) ou se déplace aléatoirement (bot) pendant la phase sombre
# - verrouille une direction de tir et affiche un laser pendant la phase lumière
# - gère posture debout/allongé, collisions, couleurs du skin et nameplate
# - émet le signal `elimine` quand il meurt pour informer le contrôleur de partie.

signal elimine(player: PlayerCharacter)

@export var nom_joueur: String = "Joueur"
@export var couleur_joueur: Color = Color(0.8, 0.2, 0.2)
@export var couleur_peau: Color = Color(0.88, 0.74, 0.58)
@export var couleur_accent: Color = Color(0.12, 0.12, 0.12)

const VITESSE_DEPLACEMENT := 4.6
const LONGUEUR_LASER_MIN := 0.35
const LONGUEUR_LASER_MAX := 32.0
const PROBA_BOT_ALLONGE := 0.35
const DISTANCE_VISEE_MANETTE := 20.0
const VITESSE_BALANCEMENT_MARCHE := 11.0
const BALANCEMENT_BRAS_MARCHE := 0.8
const BALANCEMENT_JAMBES_MARCHE := 0.95
const HAUTEUR_BALANCEMENT_MARCHE := 0.08
const VITESSE_BALANCEMENT_ALLONGE := 8.0
const BALANCEMENT_BRAS_ALLONGE := 0.22
const BALANCEMENT_JAMBES_ALLONGE := 0.18
const HAUTEUR_BALANCEMENT_ALLONGE := 0.03
const VITESSE_LISSAGE_ANIM := 10.0

var est_vivant: bool = true
var est_humain: bool = false
var est_allonge: bool = false
var position_voulue: Vector3 = Vector3.ZERO
var cible_visee: Vector3 = Vector3.ZERO
var direction_tir_verrouillee: Vector3 = Vector3.ZERO
var tir_verrouille: bool = false
var rayon_arene: float = 8.0
var reveler_dans_obscurite: bool = true
var temps_animation: float = 0.0

@onready var racine_corps: Node3D = $BodyRoot
@onready var bouche_canon: Marker3D = $BodyRoot/Muzzle
@onready var forme_collision: CollisionShape3D = $CollisionShape3D
var formes_collision: Dictionary = {}

func _ready() -> void:
	# Prépare collisions/visuels, initialise le laser et oriente la visée par défaut vers l'avant.
	add_to_group("players")
	_assurer_formes_collision()
	reconstruire_visuels()
	_maj_forme_collision()
	if cible_visee == Vector3.ZERO:
		cible_visee = global_position + (-global_basis.z * 12.0)
	direction_tir_verrouillee = obtenir_direction_tir()
	mettre_a_jour_laser()

func _physics_process(delta: float) -> void:
	# Mouvement/animation/laser à chaque frame physique.
	if not est_vivant:
		return
	move_and_slide()
	_mettre_a_jour_animation(delta)
	mettre_a_jour_laser()

func definir_controle_humain(value: bool) -> void:
	# Bascule ce personnage en contrôle joueur (sinon IA).
	est_humain = value
	definir_nameplate_visible(false)

func basculer_allonge() -> void:
	# Inverse posture debout/allongé.
	definir_allonge(not est_allonge)

func definir_allonge(value: bool) -> void:
	if not est_vivant:
		return
	est_allonge = value
	reconstruire_visuels()
	_maj_forme_collision()
	mettre_a_jour_laser()
	_maj_hauteur_nameplate()

# Ajuste les hitboxes selon la posture.
func _maj_forme_collision() -> void:
	_assurer_formes_collision()
	if est_allonge:
		_definir_collision_boite("torso", Vector3(0.94, 0.36, 1.42), Vector3(0.0, 0.56, -0.02))
		_definir_collision_boite("head", Vector3(0.56, 0.36, 0.58), Vector3(0.0, 0.72, -0.92))
		_definir_collision_boite("arm_left", Vector3(0.22, 0.22, 1.08), Vector3(-0.28, 0.54, -1.22))
		_definir_collision_boite("arm_right", Vector3(0.22, 0.22, 1.08), Vector3(0.28, 0.54, -1.22))
		_definir_collision_boite("leg_left", Vector3(0.28, 0.24, 1.28), Vector3(-0.2, 0.42, 1.02))
		_definir_collision_boite("leg_right", Vector3(0.28, 0.24, 1.28), Vector3(0.2, 0.42, 1.02))
		_definir_collision_boite("foot_left", Vector3(0.3, 0.18, 0.38), Vector3(-0.2, 0.42, 1.58))
		_definir_collision_boite("foot_right", Vector3(0.3, 0.18, 0.38), Vector3(0.2, 0.42, 1.58))
	else:
		_definir_collision_boite("torso", Vector3(0.84, 0.96, 0.46), Vector3(0.0, 1.15, 0.0))
		_definir_collision_boite("head", Vector3(0.6, 0.6, 0.6), Vector3(0.0, 1.95, 0.0))
		_definir_collision_boite("arm_left", Vector3(0.3, 0.9, 0.3), Vector3(-0.65, 1.15, 0.0))
		_definir_collision_boite("arm_right", Vector3(0.3, 0.9, 0.3), Vector3(0.65, 1.15, 0.0))
		_definir_collision_boite("leg_left", Vector3(0.32, 0.9, 0.32), Vector3(-0.2, 0.5, 0.0))
		_definir_collision_boite("leg_right", Vector3(0.32, 0.9, 0.32), Vector3(0.2, 0.5, 0.0))
		_definir_collision_boite("foot_left", Vector3(0.36, 0.22, 0.36), Vector3(-0.2, 0.08, 0.0))
		_definir_collision_boite("foot_right", Vector3(0.36, 0.22, 0.36), Vector3(0.2, 0.08, 0.0))

# Initialise le dictionnaire de CollisionShape3D si vide.
func _assurer_formes_collision() -> void:
	if formes_collision.is_empty():
		formes_collision["torso"] = forme_collision
		formes_collision["head"] = _obtenir_ou_creer_forme_collision("CollisionShapeHead")
		formes_collision["arm_left"] = _obtenir_ou_creer_forme_collision("CollisionShapeArmLeft")
		formes_collision["arm_right"] = _obtenir_ou_creer_forme_collision("CollisionShapeArmRight")
		formes_collision["leg_left"] = _obtenir_ou_creer_forme_collision("CollisionShapeLegLeft")
		formes_collision["leg_right"] = _obtenir_ou_creer_forme_collision("CollisionShapeLegRight")
		formes_collision["foot_left"] = _obtenir_ou_creer_forme_collision("CollisionShapeFootLeft")
		formes_collision["foot_right"] = _obtenir_ou_creer_forme_collision("CollisionShapeFootRight")

# R�cup�re ou cr�e une forme de collision nomm�e sous BodyRoot.
func _obtenir_ou_creer_forme_collision(node_name: String) -> CollisionShape3D:
	var existing: CollisionShape3D = get_node_or_null(node_name) as CollisionShape3D
	if existing != null:
		return existing
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	shape_node.name = node_name
	add_child(shape_node)
	return shape_node

# Param�tre taille/position d'une box collider nomm�e.
func _definir_collision_boite(shape_name: String, size: Vector3, position: Vector3) -> void:
	var shape_node: CollisionShape3D = formes_collision.get(shape_name, null)
	if shape_node == null:
		return
	var box: BoxShape3D = shape_node.shape as BoxShape3D
	if box == null:
		box = BoxShape3D.new()
		shape_node.shape = box
	box.size = size
	shape_node.position = position
	shape_node.disabled = not est_vivant

func obtenir_hauteur_focus_camera() -> float:
	# Point que la caméra suit (légèrement plus haut pour mieux voir l'arène).
	return 1.3 if est_allonge else 2.5

func obtenir_offset_hauteur_camera() -> float:
	# Décalage vertical de la caméra (encore un peu plus surélevée).
	return 3.2 if est_allonge else 4.35

# Force la visibilit� en phase sombre (utilis� en spectateur).
func definir_visible_dans_obscurite(value: bool) -> void:
	reveler_dans_obscurite = value
	if est_vivant:
		racine_corps.visible = value
		_definir_laser_visible(value)
		definir_nameplate_visible(false)

# Affiche/caches corps/laser/nameplate selon phase sombre/lumi�re.
func definir_visibilite_phase(is_dark_phase: bool) -> void:
	# Affiche ou cache corps/laser/nameplate selon la phase.
	if not est_vivant:
		return
	if is_dark_phase:
		tir_verrouille = false
	if is_dark_phase and not reveler_dans_obscurite:
		racine_corps.visible = false
		_definir_laser_visible(false)
		definir_nameplate_visible(false)
	else:
		racine_corps.visible = true
		_definir_laser_visible(true)
		definir_nameplate_visible(not is_dark_phase or est_humain)
	mettre_a_jour_laser()

# Affiche ou cache le label 3D (nameplate).
func definir_nameplate_visible(value: bool) -> void:
	var nameplate: Label3D = _obtenir_ou_creer_nameplate()
	if nameplate != null:
		nameplate.visible = value and est_vivant

# Met � jour le texte du nameplate.
func definir_texte_nameplate(value: String) -> void:
	var nameplate: Label3D = _obtenir_ou_creer_nameplate()
	if nameplate != null:
		nameplate.text = value
		nameplate.visible = est_vivant and not est_humain

# Ajuste la hauteur du nameplate selon posture.
func _maj_hauteur_nameplate() -> void:
	var nameplate: Label3D = _obtenir_ou_creer_nameplate()
	if nameplate != null:
		nameplate.position.y = 2.7 if not est_allonge else 1.25

# Reconstruit le mesh voxelis� du personnage et ajoute laser/nameplate.
func reconstruire_visuels() -> void:
	var actual_racine_corps: Node3D = racine_corps if racine_corps != null else get_node_or_null("BodyRoot") as Node3D
	var actual_bouche_canon: Marker3D = bouche_canon if bouche_canon != null else get_node_or_null("BodyRoot/bouche_canon") as Marker3D
	if actual_racine_corps == null:
		return

	for child: Node in actual_racine_corps.get_children():
		if child != actual_bouche_canon and child.name != "Nameplate" and child.name != "LaserRoot":
			child.queue_free()

	var skin_material: StandardMaterial3D = _creer_materiau_texture(_creer_texture_peau(couleur_peau))
	var face_material: StandardMaterial3D = _creer_materiau_texture(_creer_texture_visage(couleur_peau))
	var shirt_material: StandardMaterial3D = _creer_materiau_texture(_creer_texture_chemise(couleur_joueur))
	var pants_material: StandardMaterial3D = _creer_materiau_texture(_creer_texture_pantalon(couleur_joueur, couleur_accent))
	var boots_material: StandardMaterial3D = _creer_materiau_texture(_creer_texture_bottes(couleur_accent))
	var gun_material: StandardMaterial3D = _creer_materiau_texture(_creer_texture_arme(couleur_accent))
	var hair_material: StandardMaterial3D = _creer_materiau_texture(_creer_texture_cheveux())

	if est_allonge:
		if actual_bouche_canon != null:
			actual_bouche_canon.position = Vector3(0.0, 0.62, -1.9)
		_ajouter_boite(actual_racine_corps, "Torso", Vector3(0.0, 0.56, -0.1), Vector3(0.86, 0.32, 1.18), shirt_material)
		var head: MeshInstance3D = _ajouter_boite(actual_racine_corps, "Head", Vector3(0.0, 0.72, -0.92), Vector3(0.52, 0.38, 0.52), skin_material)
		_ajouter_boite(actual_racine_corps, "ArmLeft", Vector3(-0.28, 0.54, -1.26), Vector3(0.2, 0.2, 1.0), skin_material)
		_ajouter_boite(actual_racine_corps, "ArmRight", Vector3(0.28, 0.54, -1.26), Vector3(0.2, 0.2, 1.0), skin_material)
		_ajouter_boite(actual_racine_corps, "LegLeft", Vector3(-0.2, 0.42, 1.02), Vector3(0.24, 0.24, 1.16), pants_material)
		_ajouter_boite(actual_racine_corps, "LegRight", Vector3(0.2, 0.42, 1.02), Vector3(0.24, 0.24, 1.16), pants_material)
		_ajouter_boite(actual_racine_corps, "BootLeft", Vector3(-0.2, 0.42, 1.55), Vector3(0.26, 0.18, 0.34), boots_material)
		_ajouter_boite(actual_racine_corps, "BootRight", Vector3(0.2, 0.42, 1.55), Vector3(0.26, 0.18, 0.34), boots_material)
		_ajouter_boite(actual_racine_corps, "Gun", Vector3(0.0, 0.66, -1.55), Vector3(0.14, 0.14, 1.08), gun_material)
		_ajouter_details_tete(head, face_material, hair_material, true)
	else:
		if actual_bouche_canon != null:
			actual_bouche_canon.position = Vector3(0.55, 1.25, -0.95)
		_ajouter_boite(actual_racine_corps, "Torso", Vector3(0, 1.15, 0), Vector3(0.8, 0.9, 0.45), shirt_material)
		var head_standing: MeshInstance3D = _ajouter_boite(actual_racine_corps, "Head", Vector3(0, 1.95, 0), Vector3(0.62, 0.62, 0.62), skin_material)
		_ajouter_boite(actual_racine_corps, "ArmLeft", Vector3(-0.65, 1.15, 0), Vector3(0.28, 0.9, 0.28), skin_material)
		_ajouter_boite(actual_racine_corps, "ArmRight", Vector3(0.65, 1.15, 0), Vector3(0.28, 0.9, 0.28), skin_material)
		_ajouter_boite(actual_racine_corps, "LegLeft", Vector3(-0.2, 0.42, 0), Vector3(0.3, 0.84, 0.3), pants_material)
		_ajouter_boite(actual_racine_corps, "LegRight", Vector3(0.2, 0.42, 0), Vector3(0.3, 0.84, 0.3), pants_material)
		_ajouter_boite(actual_racine_corps, "BootLeft", Vector3(-0.2, 0.06, 0.0), Vector3(0.34, 0.18, 0.34), boots_material)
		_ajouter_boite(actual_racine_corps, "BootRight", Vector3(0.2, 0.06, 0.0), Vector3(0.34, 0.18, 0.34), boots_material)
		_ajouter_boite(actual_racine_corps, "Gun", Vector3(0.48, 1.25, -0.52), Vector3(0.18, 0.14, 0.72), gun_material)
		_ajouter_details_tete(head_standing, face_material, hair_material, false)
	_ajouter_laser(actual_racine_corps, actual_bouche_canon)
	_ajouter_nameplate(actual_racine_corps)
	_appliquer_pose_idle()
	_maj_hauteur_nameplate()

# Ajoute un cube textur� au squelette du personnage.
func _ajouter_boite(target_root: Node3D, node_name: String, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = pos
	target_root.add_child(mesh_instance)
	return mesh_instance

# Ajoute cheveux/face sur la t�te (d�bou/ allong�).
func _ajouter_details_tete(head: MeshInstance3D, face_material: Material, hair_material: Material, prone_pose: bool) -> void:
	if head == null:
		return
	var hair_cap: MeshInstance3D = MeshInstance3D.new()
	hair_cap.name = "HairCap"
	var hair_mesh: BoxMesh = BoxMesh.new()
	hair_mesh.size = Vector3(0.66 if not prone_pose else 0.56, 0.18 if not prone_pose else 0.12, 0.66 if not prone_pose else 0.56)
	hair_cap.mesh = hair_mesh
	hair_cap.material_override = hair_material
	hair_cap.position = Vector3(0.0, 0.2 if not prone_pose else 0.11, 0.0)
	head.add_child(hair_cap)

	var face: MeshInstance3D = MeshInstance3D.new()
	face.name = "Face"
	var face_mesh: QuadMesh = QuadMesh.new()
	face_mesh.size = Vector2(0.42 if not prone_pose else 0.34, 0.42 if not prone_pose else 0.28)
	face.mesh = face_mesh
	face.material_override = face_material
	face.rotation = Vector3(0.0, PI, 0.0)
	face.position = Vector3(0.0, 0.0, -(0.315 if not prone_pose else 0.265))
	head.add_child(face)

# Cr�e le noeud laser (root + mesh) et l'accroche � la bouche de canon.
func _ajouter_laser(target_root: Node3D, actual_bouche_canon: Marker3D) -> void:
	var laser_root: Node3D = Node3D.new()
	laser_root.name = "LaserRoot"
	target_root.add_child(laser_root)
	if actual_bouche_canon != null:
		laser_root.position = actual_bouche_canon.position

	var laser_mesh_instance: MeshInstance3D = MeshInstance3D.new()
	laser_mesh_instance.name = "LaserMesh"
	var laser_mesh: CylinderMesh = CylinderMesh.new()
	laser_mesh.top_radius = 0.025
	laser_mesh.bottom_radius = 0.025
	laser_mesh.height = 1.0
	laser_mesh.radial_segments = 8
	laser_mesh_instance.mesh = laser_mesh

	var laser_material: StandardMaterial3D = StandardMaterial3D.new()
	laser_material.albedo_color = Color(1.0, 0.1, 0.1)
	laser_material.emission_enabled = true
	laser_material.emission = Color(1.0, 0.15, 0.15)
	laser_material.emission_energy_multiplier = 2.4
	laser_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	laser_mesh_instance.material_override = laser_material
	laser_root.add_child(laser_mesh_instance)

# Cr�e le label 3D au-dessus du personnage.
func _ajouter_nameplate(target_root: Node3D) -> void:
	var nameplate: Label3D = Label3D.new()
	nameplate.name = "Nameplate"
	nameplate.text = nom_joueur
	nameplate.position = Vector3(0.0, 2.7 if not est_allonge else 1.25, 0.0)
	nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nameplate.font_size = 36
	nameplate.modulate = Color(1.0, 1.0, 1.0)
	nameplate.outline_modulate = Color(0.0, 0.0, 0.0)
	nameplate.outline_size = 6
	nameplate.no_depth_test = true
	nameplate.pixel_size = 0.008
	nameplate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nameplate.visible = false
	target_root.add_child(nameplate)

func _obtenir_ou_creer_nameplate() -> Label3D:
	var nameplate: Label3D = get_node_or_null("BodyRoot/Nameplate") as Label3D
	if nameplate == null and racine_corps != null:
		_ajouter_nameplate(racine_corps)
		nameplate = get_node_or_null("BodyRoot/Nameplate") as Label3D
	return nameplate

# Pour les bots : choisit posture et point cible al�atoire en phase sombre.
func planifier_phase_obscure(center: Vector3, radius: float, rng: RandomNumberGenerator) -> void:
	if not est_vivant or est_humain:
		return
	rayon_arene = radius
	definir_allonge(rng.randf() < PROBA_BOT_ALLONGE)
	var x: float = rng.randf_range(-(radius - 1.2), radius - 1.2)
	var z: float = rng.randf_range(-(radius - 1.2), radius - 1.2)
	position_voulue = center + Vector3(x, 0.0, z)

# D�placement bots en phase sombre vers leur position_voulue.
func deplacer_en_obscurite(_delta: float, center: Vector3, radius: float) -> void:
	# Déplacements bots en phase obscure (errance vers une cible).
	if not est_vivant or est_humain:
		return
	var speed_multiplier: float = 0.5 if est_allonge else 1.0
	var to_target: Vector3 = position_voulue - global_position
	to_target.y = 0.0
	if to_target.length() > 0.15:
		var dir: Vector3 = to_target.normalized()
		velocity.x = dir.x * VITESSE_DEPLACEMENT * speed_multiplier
		velocity.z = dir.z * VITESSE_DEPLACEMENT * speed_multiplier
	else:
		velocity.x = move_toward(velocity.x, 0.0, VITESSE_DEPLACEMENT)
		velocity.z = move_toward(velocity.z, 0.0, VITESSE_DEPLACEMENT)
	_appliquer_limites_arene(center, radius)

# D�placement humain en fonction de l'input et de l'orientation cam�ra.
func deplacer_humain(input_vector: Vector2, camera_basis: Basis, center: Vector3, radius: float) -> void:
	# Déplacement joueur humain en tenant compte de la caméra.
	if not est_vivant:
		return
	var speed_multiplier: float = 0.5 if est_allonge else 1.0
	var camera_forward: Vector3 = -camera_basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()
	var camera_right: Vector3 = camera_basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()
	var movement: Vector3 = (camera_right * input_vector.x) + (camera_forward * input_vector.y)
	if movement.length() > 1.0:
		movement = movement.normalized()
	velocity.x = movement.x * VITESSE_DEPLACEMENT * speed_multiplier
	velocity.z = movement.z * VITESSE_DEPLACEMENT * speed_multiplier
	_appliquer_limites_arene(center, radius)

# Met imm�diatement la v�locit� � z�ro (fin de phase sombre).
func arreter_mouvement() -> void:
	# Fige immédiatement le déplacement (utilisé en fin de phase).
	velocity = Vector3.ZERO

# Contraint la position dans le rayon de l'ar�ne et amortit la vitesse en bord.
func _appliquer_limites_arene(center: Vector3, radius: float) -> void:
	var limit: float = max(1.0, radius - 0.6)
	var local_pos: Vector3 = global_position - center
	var clamped_x: float = clamp(local_pos.x, -limit, limit)
	var clamped_z: float = clamp(local_pos.z, -limit, limit)
	if clamped_x != local_pos.x:
		velocity.x = sign(clamped_x - local_pos.x) * VITESSE_DEPLACEMENT
	if clamped_z != local_pos.z:
		velocity.z = sign(clamped_z - local_pos.z) * VITESSE_DEPLACEMENT

# Calcule un point de vis�e via raycast �cran->monde (souris).
func mettre_a_jour_visee_souris(camera: Camera3D, mouse_position: Vector2) -> void:
	if camera == null or not est_vivant or tir_verrouille:
		return
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_position)
	var ray_direction: Vector3 = camera.project_ray_normal(mouse_position)
	if abs(ray_direction.y) < 0.001:
		return
	var plane_y: float = 0.62 if est_allonge else global_position.y + 0.9
	var distance: float = (plane_y - ray_origin.y) / ray_direction.y
	if distance <= 0.0:
		return
	var hit_point: Vector3 = ray_origin + ray_direction * distance
	viser_point(hit_point)

# Calcule un point de vis�e depuis le stick droit et la cam�ra (manette).
func mettre_a_jour_visee_manette(aim_input: Vector2, camera_basis: Basis) -> void:
	if not est_vivant or tir_verrouille or aim_input.length() < 0.2:
		return
	var camera_forward: Vector3 = -camera_basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()
	var camera_right: Vector3 = camera_basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()
	var aim_direction: Vector3 = (camera_right * aim_input.x) + (camera_forward * aim_input.y)
	if aim_direction.length() < 0.1:
		return
	viser_point(global_position + aim_direction.normalized() * DISTANCE_VISEE_MANETTE)

# Choisit une cible vivante al�atoire (pour les bots).
func choisir_cible(players: Array[PlayerCharacter], rng: RandomNumberGenerator) -> Variant:
	var candidates: Array[PlayerCharacter] = []
	for player: PlayerCharacter in players:
		if player != self and player.est_vivant:
			candidates.append(player)
	if candidates.is_empty():
		return null
	return candidates[rng.randi_range(0, candidates.size() - 1)]

# Oriente le personnage vers un point et met � jour le laser.
func viser_point(target: Vector3) -> void:
	# Oriente le corps vers la cible mais aplati l'axe Y pour garder un tir horizontal.
	cible_visee = target
	cible_visee.y = global_position.y
	var flat_target: Vector3 = cible_visee
	look_at(flat_target, Vector3.UP)
	mettre_a_jour_laser()

# Verrouille direction/laser pour la phase lumi�re et stoppe le mouvement.
func verrouiller_pour_lumiere() -> void:
	# Verrouille la direction de tir pour la phase lumière.
	velocity = Vector3.ZERO
	direction_tir_verrouillee = obtenir_direction_tir()
	tir_verrouille = true
	mettre_a_jour_laser()

# Direction actuelle de tir (non verrouill�e).
func obtenir_direction_tir() -> Vector3:
	var origin: Vector3 = obtenir_position_bouche_canon()
	var direction: Vector3 = cible_visee - origin
	direction.y = 0.0
	if direction.length() < 0.1:
		return -global_basis.z
	return direction.normalized()

# Direction de tir verrouill�e (fallback sur direction actuelle).
func obtenir_direction_tir_verrouillee() -> Vector3:
	if direction_tir_verrouillee.length() < 0.1:
		return obtenir_direction_tir()
	return direction_tir_verrouillee.normalized()

# Met � jour position/orientation/longueur du laser visuel.
func mettre_a_jour_laser() -> void:
	# Met à jour position/orientation/longueur du laser visuel.
	var laser_root: Node3D = get_node_or_null("BodyRoot/LaserRoot") as Node3D
	var laser_mesh_instance: MeshInstance3D = get_node_or_null("BodyRoot/LaserRoot/LaserMesh") as MeshInstance3D
	if laser_root == null or laser_mesh_instance == null:
		return
	var bouche_canon_position: Vector3 = obtenir_position_bouche_canon()
	var direction: Vector3 = obtenir_direction_tir_verrouillee() if tir_verrouille else obtenir_direction_tir()
	var laser_length: float = clamp(max((cible_visee - bouche_canon_position).length(), 20.0), LONGUEUR_LASER_MIN, LONGUEUR_LASER_MAX)
	laser_root.global_position = bouche_canon_position + direction * (laser_length * 0.5)
	laser_root.look_at(bouche_canon_position + direction * laser_length, Vector3.UP)
	laser_root.rotate_object_local(Vector3.RIGHT, deg_to_rad(90.0))
	var laser_mesh: CylinderMesh = laser_mesh_instance.mesh as CylinderMesh
	laser_mesh.height = laser_length

# Affiche/cache le laser Root.
func _definir_laser_visible(value: bool) -> void:
	var laser_root: Node3D = get_node_or_null("BodyRoot/LaserRoot") as Node3D
	if laser_root != null:
		laser_root.visible = value

# Marque le joueur comme mort, coupe collisions/visuels et �met le signal elimine.
func eliminer() -> void:
	if not est_vivant:
		return
	est_vivant = false
	velocity = Vector3.ZERO
	_assurer_formes_collision()
	for shape_key: Variant in formes_collision.keys():
		var shape_node: CollisionShape3D = formes_collision[shape_key] as CollisionShape3D
		if shape_node != null:
			shape_node.disabled = true
	if racine_corps != null:
		racine_corps.visible = false
	_definir_laser_visible(false)
	definir_nameplate_visible(false)
	elimine.emit(self)

# Retourne la position mondiale de la bouche du canon.
func obtenir_position_bouche_canon() -> Vector3:
	return bouche_canon.global_position if bouche_canon != null else global_position + Vector3(0.0, 0.62, -1.9)

# Pose neutre des membres selon posture.
func _appliquer_pose_idle() -> void:
	if est_allonge:
		_definir_transform_noeud("Torso", Vector3(0.0, 0.56, -0.1), Vector3.ZERO)
		_definir_transform_noeud("Head", Vector3(0.0, 0.72, -0.92), Vector3.ZERO)
		# Légère rotation vers le bas pour que le laser pointe droit en posture allongée.
		_definir_transform_noeud("ArmLeft", Vector3(-0.28, 0.54, -1.26), Vector3(0.3, 0.0, 0.0))
		_definir_transform_noeud("ArmRight", Vector3(0.28, 0.54, -1.26), Vector3(-0.3, 0.0, 0.0))
		_definir_transform_noeud("LegLeft", Vector3(-0.2, 0.42, 1.02), Vector3.ZERO)
		_definir_transform_noeud("LegRight", Vector3(0.2, 0.42, 1.02), Vector3.ZERO)
		_definir_transform_noeud("BootLeft", Vector3(-0.2, 0.42, 1.55), Vector3.ZERO)
		_definir_transform_noeud("BootRight", Vector3(0.2, 0.42, 1.55), Vector3.ZERO)
		_definir_transform_noeud("Gun", Vector3(0.0, 0.66, -1.55), Vector3(0.3, 0.0, 0.0))
		_definir_transform_noeud("Nameplate", Vector3(0.0, 1.25, 0.0), Vector3.ZERO)
	else:
		_definir_transform_noeud("Torso", Vector3(0.0, 1.15, 0.0), Vector3.ZERO)
		_definir_transform_noeud("Head", Vector3(0.0, 1.95, 0.0), Vector3.ZERO)
		_definir_transform_noeud("ArmLeft", Vector3(-0.65, 1.15, 0.0), Vector3.ZERO)
		_definir_transform_noeud("ArmRight", Vector3(0.65, 1.15, 0.0), Vector3.ZERO)
		_definir_transform_noeud("LegLeft", Vector3(-0.2, 0.42, 0.0), Vector3.ZERO)
		_definir_transform_noeud("LegRight", Vector3(0.2, 0.42, 0.0), Vector3.ZERO)
		_definir_transform_noeud("BootLeft", Vector3(-0.2, 0.06, 0.0), Vector3.ZERO)
		_definir_transform_noeud("BootRight", Vector3(0.2, 0.06, 0.0), Vector3.ZERO)
		_definir_transform_noeud("Gun", Vector3(0.48, 1.25, -0.52), Vector3.ZERO)
		_definir_transform_noeud("Nameplate", Vector3(0.0, 2.7, 0.0), Vector3.ZERO)

# Anime marche/crawl en interpolant les transforms des membres.
func _mettre_a_jour_animation(delta: float) -> void:
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	var movement_ratio: float = clamp(horizontal_speed / VITESSE_DEPLACEMENT, 0.0, 1.0)
	temps_animation += delta * lerp(1.5, VITESSE_BALANCEMENT_ALLONGE if est_allonge else VITESSE_BALANCEMENT_MARCHE, movement_ratio)
	var swing: float = sin(temps_animation)
	var sway: float = cos(temps_animation * 0.5)
	if est_allonge:
		_appliquer_animation_allonge(movement_ratio, swing, sway, delta)
	else:
		_appliquer_animation_debout(movement_ratio, swing, sway, delta)
	var nameplate: Node3D = get_node_or_null("BodyRoot/Nameplate") as Node3D
	if nameplate != null:
		nameplate.rotation = Vector3.ZERO
		nameplate.position = nameplate.position.lerp(Vector3(0.0, 1.25 if est_allonge else 2.7, 0.0), clamp(delta * VITESSE_LISSAGE_ANIM, 0.0, 1.0))

# Animation debout : balancement bras/jambes + l�g�re oscillation.
func _appliquer_animation_debout(movement_ratio: float, swing: float, sway: float, delta: float) -> void:
	var bob: float = abs(sin(temps_animation * 2.0)) * HAUTEUR_BALANCEMENT_MARCHE * movement_ratio
	_definir_transform_noeud_lisse("Torso", Vector3(0.0, 1.15 + bob, 0.0), Vector3(0.06 * sway * movement_ratio, 0.0, 0.0), delta)
	_definir_transform_noeud_lisse("Head", Vector3(0.0, 1.95 + bob * 0.5, 0.0), Vector3(-0.04 * sway * movement_ratio, 0.0, 0.0), delta)
	_definir_transform_noeud_lisse("ArmLeft", Vector3(-0.65, 1.15 + bob, 0.0), Vector3(BALANCEMENT_BRAS_MARCHE * swing * movement_ratio, 0.0, 0.0), delta)
	_definir_transform_noeud_lisse("ArmRight", Vector3(0.65, 1.15 + bob, 0.0), Vector3(-BALANCEMENT_BRAS_MARCHE * swing * movement_ratio, 0.0, 0.0), delta)
	_definir_transform_noeud_lisse("LegLeft", Vector3(-0.2, 0.42 + bob * 0.2, 0.0), Vector3(-BALANCEMENT_JAMBES_MARCHE * swing * movement_ratio, 0.0, 0.0), delta)
	_definir_transform_noeud_lisse("LegRight", Vector3(0.2, 0.42 + bob * 0.2, 0.0), Vector3(BALANCEMENT_JAMBES_MARCHE * swing * movement_ratio, 0.0, 0.0), delta)
	_definir_transform_noeud_lisse("BootLeft", Vector3(-0.2, 0.06 + bob * 0.08, 0.0), Vector3(-BALANCEMENT_JAMBES_MARCHE * swing * movement_ratio, 0.0, 0.0), delta)
	_definir_transform_noeud_lisse("BootRight", Vector3(0.2, 0.06 + bob * 0.08, 0.0), Vector3(BALANCEMENT_JAMBES_MARCHE * swing * movement_ratio, 0.0, 0.0), delta)
	_definir_transform_noeud_lisse("Gun", Vector3(0.48, 1.25 + bob, -0.52), Vector3(-0.2 * swing * movement_ratio, 0.0, 0.0), delta)

# Animation allong� : ramping avec petites oscillations.
func _appliquer_animation_allonge(movement_ratio: float, swing: float, sway: float, delta: float) -> void:
	var crawl_bob: float = abs(sin(temps_animation * 1.6)) * HAUTEUR_BALANCEMENT_ALLONGE * movement_ratio
	_definir_transform_noeud_lisse("Torso", Vector3(0.0, 0.56 + crawl_bob, -0.1), Vector3(0.0, 0.0, 0.025 * sway * movement_ratio), delta)
	_definir_transform_noeud_lisse("Head", Vector3(0.0, 0.72 + crawl_bob * 0.4, -0.92), Vector3(0.04 * sway * movement_ratio, 0.0, 0.0), delta)
	_definir_transform_noeud_lisse("ArmLeft", Vector3(-0.28, 0.54 + crawl_bob, -1.26), Vector3(-BALANCEMENT_BRAS_ALLONGE * swing * movement_ratio, 0.0, 0.0), delta)
	_definir_transform_noeud_lisse("ArmRight", Vector3(0.28, 0.54 + crawl_bob, -1.26), Vector3(BALANCEMENT_BRAS_ALLONGE * swing * movement_ratio, 0.0, 0.0), delta)
	_definir_transform_noeud_lisse("LegLeft", Vector3(-0.2, 0.42 + crawl_bob * 0.5, 1.02), Vector3(BALANCEMENT_JAMBES_ALLONGE * swing * movement_ratio, 0.0, 0.0), delta)
	_definir_transform_noeud_lisse("LegRight", Vector3(0.2, 0.42 + crawl_bob * 0.5, 1.02), Vector3(-BALANCEMENT_JAMBES_ALLONGE * swing * movement_ratio, 0.0, 0.0), delta)
	_definir_transform_noeud_lisse("BootLeft", Vector3(-0.2, 0.42 + crawl_bob * 0.5, 1.55), Vector3(BALANCEMENT_JAMBES_ALLONGE * swing * movement_ratio, 0.0, 0.0), delta)
	_definir_transform_noeud_lisse("BootRight", Vector3(0.2, 0.42 + crawl_bob * 0.5, 1.55), Vector3(-BALANCEMENT_JAMBES_ALLONGE * swing * movement_ratio, 0.0, 0.0), delta)
	_definir_transform_noeud_lisse("Gun", Vector3(0.0, 0.66 + crawl_bob, -1.55), Vector3.ZERO, delta)

# Affecte directement position/rotation d'un noeud du squelette.
func _definir_transform_noeud(node_name: String, target_position: Vector3, target_rotation: Vector3) -> void:
	var node: Node3D = get_node_or_null("BodyRoot/%s" % node_name) as Node3D
	if node == null:
		return
	node.position = target_position
	node.rotation = target_rotation

# Lisse position/rotation d'un noeud vers une cible (lerp).
func _definir_transform_noeud_lisse(node_name: String, target_position: Vector3, target_rotation: Vector3, delta: float) -> void:
	var node: Node3D = get_node_or_null("BodyRoot/%s" % node_name) as Node3D
	if node == null:
		return
	var weight: float = clamp(delta * VITESSE_LISSAGE_ANIM, 0.0, 1.0)
	node.position = node.position.lerp(target_position, weight)
	node.rotation = node.rotation.lerp(target_rotation, weight)

# Cr�e un mat�riau standard � partir d'une texture pixellis�e.
func _creer_materiau_texture(texture: Texture2D) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_texture = texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 1.0
	return material

# G�n�re une mini-texture de peau � partir d'une couleur de base.
func _creer_texture_peau(base: Color) -> ImageTexture:
	var light: Color = _ombrer(base, 1.08)
	var mid: Color = _ombrer(base, 0.98)
	var dark: Color = _ombrer(base, 0.86)
	var image: Image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y: int in range(8):
		for x: int in range(8):
			var pixel: Color = mid
			if (x + y) % 4 == 0:
				pixel = light
			elif (x * 2 + y) % 5 == 0:
				pixel = dark
			if y >= 6:
				pixel = _ombrer(pixel, 0.92)
			image.set_pixel(x, y, pixel)
	return ImageTexture.create_from_image(image)

# G�n�re une texture de visage simple (yeux/barbe).
func _creer_texture_visage(base: Color) -> ImageTexture:
	var skin_mid: Color = _ombrer(base, 1.0)
	var skin_dark: Color = _ombrer(base, 0.82)
	var eye_white: Color = Color(0.9, 0.92, 0.98)
	var eye_blue: Color = Color(0.36, 0.49, 0.82)
	var beard: Color = Color(0.4, 0.24, 0.14)
	var image: Image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y: int in range(8):
		for x: int in range(8):
			image.set_pixel(x, y, skin_mid)
	for x: int in range(8):
		image.set_pixel(x, 0, beard)
	for x: int in range(1, 7):
		image.set_pixel(x, 1, _ombrer(beard, 1.08))
	for x: int in range(8):
		image.set_pixel(x, 6, skin_dark)
		image.set_pixel(x, 7, _ombrer(skin_dark, 0.95))
	for y: int in range(3, 8):
		image.set_pixel(0, y, beard)
		image.set_pixel(7, y, beard)
	for x: int in range(2, 6):
		image.set_pixel(x, 5, beard)
	image.set_pixel(2, 3, eye_white)
	image.set_pixel(3, 3, eye_blue)
	image.set_pixel(4, 3, eye_white)
	image.set_pixel(5, 3, eye_blue)
	return ImageTexture.create_from_image(image)

# G�n�re une texture de chemise pixelis�e.
func _creer_texture_chemise(base: Color) -> ImageTexture:
	var light: Color = _ombrer(base, 1.16)
	var mid: Color = _ombrer(base, 1.0)
	var dark: Color = _ombrer(base, 0.78)
	var seam: Color = _ombrer(base, 0.64)
	var image: Image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y: int in range(8):
		for x: int in range(8):
			var pixel: Color = mid
			if (x + y) % 3 == 0:
				pixel = light
			elif (x * y + y) % 5 == 0:
				pixel = dark
			if x == 0 or x == 7 or y == 0:
				pixel = seam
			image.set_pixel(x, y, pixel)
	return ImageTexture.create_from_image(image)

# G�n�re une texture de pantalon avec accents.
func _creer_texture_pantalon(base: Color, accent: Color) -> ImageTexture:
	var mixed: Color = base.lerp(Color(0.32, 0.36, 0.78), 0.45)
	var light: Color = _ombrer(mixed, 1.08)
	var mid: Color = _ombrer(mixed, 0.96)
	var dark: Color = _ombrer(accent.lerp(mixed, 0.55), 0.72)
	var image: Image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y: int in range(8):
		for x: int in range(8):
			var pixel: Color = mid
			if x in [1, 5] and y > 1:
				pixel = light
			elif (x + y * 2) % 4 == 0:
				pixel = dark
			image.set_pixel(x, y, pixel)
	return ImageTexture.create_from_image(image)

# G�n�re une texture de bottes.
func _creer_texture_bottes(base: Color) -> ImageTexture:
	var dark: Color = _ombrer(base, 0.48)
	var mid: Color = _ombrer(base, 0.65)
	var line: Color = _ombrer(base, 0.82)
	var image: Image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y: int in range(8):
		for x: int in range(8):
			var pixel: Color = dark if y > 2 else mid
			if y == 3 or y == 6:
				pixel = line
			image.set_pixel(x, y, pixel)
	return ImageTexture.create_from_image(image)

# G�n�re une texture d'arme.
func _creer_texture_arme(base: Color) -> ImageTexture:
	var dark: Color = _ombrer(base, 0.56)
	var mid: Color = _ombrer(base, 0.75)
	var metal: Color = Color(0.38, 0.38, 0.4)
	var image: Image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y: int in range(8):
		for x: int in range(8):
			var pixel: Color = dark
			if y <= 2:
				pixel = metal
			elif x in [1, 5]:
				pixel = mid
			image.set_pixel(x, y, pixel)
	return ImageTexture.create_from_image(image)

# G�n�re une texture de cheveux.
func _creer_texture_cheveux() -> ImageTexture:
	var base: Color = Color(0.28, 0.18, 0.1)
	var light: Color = _ombrer(base, 1.18)
	var dark: Color = _ombrer(base, 0.72)
	var image: Image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y: int in range(8):
		for x: int in range(8):
			var pixel: Color = base
			if (x + y) % 3 == 0:
				pixel = light
			elif (x * 3 + y) % 5 == 0:
				pixel = dark
			image.set_pixel(x, y, pixel)
	return ImageTexture.create_from_image(image)

# Applique un facteur d'ombrage (clamp 0..1).
func _ombrer(color: Color, factor: float) -> Color:
	return Color(
		clamp(color.r * factor, 0.0, 1.0),
		clamp(color.g * factor, 0.0, 1.0),
		clamp(color.b * factor, 0.0, 1.0),
		color.a
	)
