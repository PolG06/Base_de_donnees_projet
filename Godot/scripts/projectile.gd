extends Area3D
class_name Projectile

signal joueur_touche(cible: PlayerCharacter, tireur: PlayerCharacter)

var direction_tir := Vector3.ZERO
var vitesse := 14.0
var duree_vie := 2.2
var tireur: PlayerCharacter
var a_touche: bool = false

@onready var forme_collision: CollisionShape3D = $CollisionShape3D
@onready var maillage: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	var sphere := SphereShape3D.new()
	sphere.radius = 0.16
	forme_collision.shape = sphere

	var mesh := SphereMesh.new()
	mesh.radius = 0.16
	mesh.height = 0.32
	maillage.mesh = mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.82, 0.2)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.42, 0.1)
	material.emission_energy_multiplier = 1.5
	maillage.material_override = material

	body_entered.connect(_sur_corps_penetre)

func configurer(orig: Vector3, direction_coup: Vector3, proprietaire: PlayerCharacter) -> void:
	global_position = orig
	direction_tir = direction_coup.normalized()
	tireur = proprietaire

func _physics_process(delta: float) -> void:
	if a_touche:
		return
	var position_depart: Vector3 = global_position
	var position_arrivee: Vector3 = position_depart + direction_tir * vitesse * delta
	if _verifier_impact_sur_trajet(position_depart, position_arrivee):
		return
	global_position = position_arrivee
	duree_vie -= delta
	if duree_vie <= 0.0:
		queue_free()

func _sur_corps_penetre(body: Node) -> void:
	if a_touche:
		return
	if body == tireur:
		return
	if body is PlayerCharacter and body.est_vivant:
		a_touche = true
		joueur_touche.emit(body, tireur)
	queue_free()

func _verifier_impact_sur_trajet(position_depart: Vector3, position_arrivee: Vector3) -> bool:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(position_depart, position_arrivee)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	if tireur != null:
		query.exclude = [get_rid(), tireur.get_rid()]
	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return false
	var collider: Object = result.get("collider", null)
	if collider is PlayerCharacter:
		var target: PlayerCharacter = collider as PlayerCharacter
		if target.est_vivant:
			a_touche = true
			global_position = result.get("position", position_arrivee)
			joueur_touche.emit(target, tireur)
			queue_free()
			return true
	return false
