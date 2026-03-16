extends Area3D
class_name Projectile

signal hit_player(target: PlayerCharacter, shooter: PlayerCharacter)

var direction := Vector3.ZERO
var speed := 14.0
var lifetime := 2.2
var shooter: PlayerCharacter
var has_hit: bool = false

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	var sphere := SphereShape3D.new()
	sphere.radius = 0.16
	collision_shape.shape = sphere

	var mesh := SphereMesh.new()
	mesh.radius = 0.16
	mesh.height = 0.32
	mesh_instance.mesh = mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.82, 0.2)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.42, 0.1)
	material.emission_energy_multiplier = 1.5
	mesh_instance.material_override = material

	body_entered.connect(_on_body_entered)

func configure(origin: Vector3, shot_direction: Vector3, owner: PlayerCharacter) -> void:
	global_position = origin
	direction = shot_direction.normalized()
	shooter = owner

func _physics_process(delta: float) -> void:
	if has_hit:
		return
	var start_position: Vector3 = global_position
	var end_position: Vector3 = start_position + direction * speed * delta
	if _check_hit_along_path(start_position, end_position):
		return
	global_position = end_position
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if has_hit:
		return
	if body == shooter:
		return
	if body is PlayerCharacter and body.is_alive:
		has_hit = true
		hit_player.emit(body, shooter)
	queue_free()

func _check_hit_along_path(start_position: Vector3, end_position: Vector3) -> bool:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start_position, end_position)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	if shooter != null:
		query.exclude = [get_rid(), shooter.get_rid()]
	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return false
	var collider: Object = result.get("collider", null)
	if collider is PlayerCharacter:
		var target: PlayerCharacter = collider as PlayerCharacter
		if target.is_alive:
			has_hit = true
			global_position = result.get("position", end_position)
			hit_player.emit(target, shooter)
			queue_free()
			return true
	return false
