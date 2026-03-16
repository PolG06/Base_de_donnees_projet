extends CharacterBody3D
class_name PlayerCharacter

# Script d'un joueur (humain ou bot) : déplacements, tir, affichage.

signal eliminated(player: PlayerCharacter)

@export var player_name: String = "Joueur"
@export var player_color: Color = Color(0.8, 0.2, 0.2)
@export var skin_color: Color = Color(0.88, 0.74, 0.58)
@export var accent_color: Color = Color(0.12, 0.12, 0.12)

const MOVE_SPEED := 4.6
const LASER_MIN_LENGTH := 0.35
const LASER_MAX_LENGTH := 32.0
const BOT_PRONE_CHANCE := 0.35
const CONTROLLER_AIM_DISTANCE := 20.0
const WALK_SWING_SPEED := 11.0
const WALK_ARM_SWING := 0.8
const WALK_LEG_SWING := 0.95
const WALK_BOB_HEIGHT := 0.08
const PRONE_SWING_SPEED := 8.0
const PRONE_ARM_SWING := 0.22
const PRONE_LEG_SWING := 0.18
const PRONE_BOB_HEIGHT := 0.03
const ANIMATION_LERP_SPEED := 10.0

var is_alive: bool = true
var is_human: bool = false
var is_prone: bool = false
var desired_position: Vector3 = Vector3.ZERO
var aim_target: Vector3 = Vector3.ZERO
var locked_shot_direction: Vector3 = Vector3.ZERO
var shot_is_locked: bool = false
var arena_radius: float = 8.0
var reveal_in_darkness: bool = true
var animation_time: float = 0.0

@onready var body_root: Node3D = $BodyRoot
@onready var muzzle: Marker3D = $BodyRoot/Muzzle
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
var collision_shapes: Dictionary = {}

func _ready() -> void:
	# Prépare collisions, visuels et vise vers l'avant par défaut.
	add_to_group("players")
	_ensure_collision_shapes()
	rebuild_visuals()
	_update_collision_shape()
	if aim_target == Vector3.ZERO:
		aim_target = global_position + (-global_basis.z * 12.0)
	locked_shot_direction = get_shot_direction()
	update_laser()

func _physics_process(delta: float) -> void:
	# Mouvement/animation/laser à chaque frame physique.
	if not is_alive:
		return
	move_and_slide()
	_update_animation(delta)
	update_laser()

func set_human_controlled(value: bool) -> void:
	is_human = value
	set_nameplate_visible(false)

func toggle_prone() -> void:
	set_prone(not is_prone)

func set_prone(value: bool) -> void:
	if not is_alive:
		return
	is_prone = value
	rebuild_visuals()
	_update_collision_shape()
	update_laser()
	_update_nameplate_height()

func _update_collision_shape() -> void:
	_ensure_collision_shapes()
	if is_prone:
		_set_box_collision("torso", Vector3(0.94, 0.36, 1.42), Vector3(0.0, 0.56, -0.02))
		_set_box_collision("head", Vector3(0.56, 0.36, 0.58), Vector3(0.0, 0.72, -0.92))
		_set_box_collision("arm_left", Vector3(0.22, 0.22, 1.08), Vector3(-0.28, 0.54, -1.22))
		_set_box_collision("arm_right", Vector3(0.22, 0.22, 1.08), Vector3(0.28, 0.54, -1.22))
		_set_box_collision("leg_left", Vector3(0.28, 0.24, 1.28), Vector3(-0.2, 0.42, 1.02))
		_set_box_collision("leg_right", Vector3(0.28, 0.24, 1.28), Vector3(0.2, 0.42, 1.02))
		_set_box_collision("foot_left", Vector3(0.3, 0.18, 0.38), Vector3(-0.2, 0.42, 1.58))
		_set_box_collision("foot_right", Vector3(0.3, 0.18, 0.38), Vector3(0.2, 0.42, 1.58))
	else:
		_set_box_collision("torso", Vector3(0.84, 0.96, 0.46), Vector3(0.0, 1.15, 0.0))
		_set_box_collision("head", Vector3(0.6, 0.6, 0.6), Vector3(0.0, 1.95, 0.0))
		_set_box_collision("arm_left", Vector3(0.3, 0.9, 0.3), Vector3(-0.65, 1.15, 0.0))
		_set_box_collision("arm_right", Vector3(0.3, 0.9, 0.3), Vector3(0.65, 1.15, 0.0))
		_set_box_collision("leg_left", Vector3(0.32, 0.9, 0.32), Vector3(-0.2, 0.5, 0.0))
		_set_box_collision("leg_right", Vector3(0.32, 0.9, 0.32), Vector3(0.2, 0.5, 0.0))
		_set_box_collision("foot_left", Vector3(0.36, 0.22, 0.36), Vector3(-0.2, 0.08, 0.0))
		_set_box_collision("foot_right", Vector3(0.36, 0.22, 0.36), Vector3(0.2, 0.08, 0.0))

func _ensure_collision_shapes() -> void:
	if collision_shapes.is_empty():
		collision_shapes["torso"] = collision_shape
		collision_shapes["head"] = _get_or_create_collision_shape("CollisionShapeHead")
		collision_shapes["arm_left"] = _get_or_create_collision_shape("CollisionShapeArmLeft")
		collision_shapes["arm_right"] = _get_or_create_collision_shape("CollisionShapeArmRight")
		collision_shapes["leg_left"] = _get_or_create_collision_shape("CollisionShapeLegLeft")
		collision_shapes["leg_right"] = _get_or_create_collision_shape("CollisionShapeLegRight")
		collision_shapes["foot_left"] = _get_or_create_collision_shape("CollisionShapeFootLeft")
		collision_shapes["foot_right"] = _get_or_create_collision_shape("CollisionShapeFootRight")

func _get_or_create_collision_shape(node_name: String) -> CollisionShape3D:
	var existing: CollisionShape3D = get_node_or_null(node_name) as CollisionShape3D
	if existing != null:
		return existing
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	shape_node.name = node_name
	add_child(shape_node)
	return shape_node

func _set_box_collision(shape_name: String, size: Vector3, position: Vector3) -> void:
	var shape_node: CollisionShape3D = collision_shapes.get(shape_name, null)
	if shape_node == null:
		return
	var box: BoxShape3D = shape_node.shape as BoxShape3D
	if box == null:
		box = BoxShape3D.new()
		shape_node.shape = box
	box.size = size
	shape_node.position = position
	shape_node.disabled = not is_alive

func get_camera_focus_height() -> float:
	return 0.72 if is_prone else 1.45

func get_camera_height_offset() -> float:
	return 2.0 if is_prone else 2.75

func set_revealed_in_darkness(value: bool) -> void:
	reveal_in_darkness = value
	if is_alive:
		body_root.visible = value
		_set_laser_visible(value)
		set_nameplate_visible(false)

func set_phase_visibility(is_dark_phase: bool) -> void:
	# Affiche ou cache corps/laser/nameplate selon la phase.
	if not is_alive:
		return
	if is_dark_phase:
		shot_is_locked = false
	if is_dark_phase and not reveal_in_darkness:
		body_root.visible = false
		_set_laser_visible(false)
		set_nameplate_visible(false)
	else:
		body_root.visible = true
		_set_laser_visible(true)
		set_nameplate_visible(not is_dark_phase or is_human)
	update_laser()

func set_nameplate_visible(value: bool) -> void:
	var nameplate: Label3D = _get_or_create_nameplate()
	if nameplate != null:
		nameplate.visible = value and is_alive

func set_nameplate_text(value: String) -> void:
	var nameplate: Label3D = _get_or_create_nameplate()
	if nameplate != null:
		nameplate.text = value
		nameplate.visible = is_alive and not is_human

func _update_nameplate_height() -> void:
	var nameplate: Label3D = _get_or_create_nameplate()
	if nameplate != null:
		nameplate.position.y = 2.7 if not is_prone else 1.25

func rebuild_visuals() -> void:
	var actual_body_root: Node3D = body_root if body_root != null else get_node_or_null("BodyRoot") as Node3D
	var actual_muzzle: Marker3D = muzzle if muzzle != null else get_node_or_null("BodyRoot/Muzzle") as Marker3D
	if actual_body_root == null:
		return

	for child: Node in actual_body_root.get_children():
		if child != actual_muzzle and child.name != "Nameplate" and child.name != "LaserRoot":
			child.queue_free()

	var skin_material: StandardMaterial3D = _create_textured_material(_make_skin_texture(skin_color))
	var face_material: StandardMaterial3D = _create_textured_material(_make_face_texture(skin_color))
	var shirt_material: StandardMaterial3D = _create_textured_material(_make_shirt_texture(player_color))
	var pants_material: StandardMaterial3D = _create_textured_material(_make_pants_texture(player_color, accent_color))
	var boots_material: StandardMaterial3D = _create_textured_material(_make_boot_texture(accent_color))
	var gun_material: StandardMaterial3D = _create_textured_material(_make_gun_texture(accent_color))
	var hair_material: StandardMaterial3D = _create_textured_material(_make_hair_texture())

	if is_prone:
		if actual_muzzle != null:
			actual_muzzle.position = Vector3(0.0, 0.62, -1.9)
		_add_box(actual_body_root, "Torso", Vector3(0.0, 0.56, -0.1), Vector3(0.86, 0.32, 1.18), shirt_material)
		var head: MeshInstance3D = _add_box(actual_body_root, "Head", Vector3(0.0, 0.72, -0.92), Vector3(0.52, 0.38, 0.52), skin_material)
		_add_box(actual_body_root, "ArmLeft", Vector3(-0.28, 0.54, -1.26), Vector3(0.2, 0.2, 1.0), skin_material)
		_add_box(actual_body_root, "ArmRight", Vector3(0.28, 0.54, -1.26), Vector3(0.2, 0.2, 1.0), skin_material)
		_add_box(actual_body_root, "LegLeft", Vector3(-0.2, 0.42, 1.02), Vector3(0.24, 0.24, 1.16), pants_material)
		_add_box(actual_body_root, "LegRight", Vector3(0.2, 0.42, 1.02), Vector3(0.24, 0.24, 1.16), pants_material)
		_add_box(actual_body_root, "BootLeft", Vector3(-0.2, 0.42, 1.55), Vector3(0.26, 0.18, 0.34), boots_material)
		_add_box(actual_body_root, "BootRight", Vector3(0.2, 0.42, 1.55), Vector3(0.26, 0.18, 0.34), boots_material)
		_add_box(actual_body_root, "Gun", Vector3(0.0, 0.66, -1.55), Vector3(0.14, 0.14, 1.08), gun_material)
		_add_head_details(head, face_material, hair_material, true)
	else:
		if actual_muzzle != null:
			actual_muzzle.position = Vector3(0.55, 1.25, -0.95)
		_add_box(actual_body_root, "Torso", Vector3(0, 1.15, 0), Vector3(0.8, 0.9, 0.45), shirt_material)
		var head_standing: MeshInstance3D = _add_box(actual_body_root, "Head", Vector3(0, 1.95, 0), Vector3(0.62, 0.62, 0.62), skin_material)
		_add_box(actual_body_root, "ArmLeft", Vector3(-0.65, 1.15, 0), Vector3(0.28, 0.9, 0.28), skin_material)
		_add_box(actual_body_root, "ArmRight", Vector3(0.65, 1.15, 0), Vector3(0.28, 0.9, 0.28), skin_material)
		_add_box(actual_body_root, "LegLeft", Vector3(-0.2, 0.42, 0), Vector3(0.3, 0.84, 0.3), pants_material)
		_add_box(actual_body_root, "LegRight", Vector3(0.2, 0.42, 0), Vector3(0.3, 0.84, 0.3), pants_material)
		_add_box(actual_body_root, "BootLeft", Vector3(-0.2, 0.06, 0.0), Vector3(0.34, 0.18, 0.34), boots_material)
		_add_box(actual_body_root, "BootRight", Vector3(0.2, 0.06, 0.0), Vector3(0.34, 0.18, 0.34), boots_material)
		_add_box(actual_body_root, "Gun", Vector3(0.48, 1.25, -0.52), Vector3(0.18, 0.14, 0.72), gun_material)
		_add_head_details(head_standing, face_material, hair_material, false)
	_add_laser(actual_body_root, actual_muzzle)
	_add_nameplate(actual_body_root)
	_apply_idle_pose()
	_update_nameplate_height()

func _add_box(target_root: Node3D, node_name: String, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = pos
	target_root.add_child(mesh_instance)
	return mesh_instance

func _add_head_details(head: MeshInstance3D, face_material: Material, hair_material: Material, prone_pose: bool) -> void:
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

func _add_laser(target_root: Node3D, actual_muzzle: Marker3D) -> void:
	var laser_root: Node3D = Node3D.new()
	laser_root.name = "LaserRoot"
	target_root.add_child(laser_root)
	if actual_muzzle != null:
		laser_root.position = actual_muzzle.position

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

func _add_nameplate(target_root: Node3D) -> void:
	var nameplate: Label3D = Label3D.new()
	nameplate.name = "Nameplate"
	nameplate.text = player_name
	nameplate.position = Vector3(0.0, 2.7 if not is_prone else 1.25, 0.0)
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

func _get_or_create_nameplate() -> Label3D:
	var nameplate: Label3D = get_node_or_null("BodyRoot/Nameplate") as Label3D
	if nameplate == null and body_root != null:
		_add_nameplate(body_root)
		nameplate = get_node_or_null("BodyRoot/Nameplate") as Label3D
	return nameplate

func plan_dark_phase(center: Vector3, radius: float, rng: RandomNumberGenerator) -> void:
	if not is_alive or is_human:
		return
	arena_radius = radius
	set_prone(rng.randf() < BOT_PRONE_CHANCE)
	var x: float = rng.randf_range(-(radius - 1.2), radius - 1.2)
	var z: float = rng.randf_range(-(radius - 1.2), radius - 1.2)
	desired_position = center + Vector3(x, 0.0, z)

func move_in_darkness(_delta: float, center: Vector3, radius: float) -> void:
	# Déplacements bots en phase obscure (errance vers une cible).
	if not is_alive or is_human:
		return
	var speed_multiplier: float = 0.5 if is_prone else 1.0
	var to_target: Vector3 = desired_position - global_position
	to_target.y = 0.0
	if to_target.length() > 0.15:
		var dir: Vector3 = to_target.normalized()
		velocity.x = dir.x * MOVE_SPEED * speed_multiplier
		velocity.z = dir.z * MOVE_SPEED * speed_multiplier
	else:
		velocity.x = move_toward(velocity.x, 0.0, MOVE_SPEED)
		velocity.z = move_toward(velocity.z, 0.0, MOVE_SPEED)
	_apply_arena_bounds(center, radius)

func move_human(input_vector: Vector2, camera_basis: Basis, center: Vector3, radius: float) -> void:
	# Déplacement joueur humain en tenant compte de la caméra.
	if not is_alive:
		return
	var speed_multiplier: float = 0.5 if is_prone else 1.0
	var camera_forward: Vector3 = -camera_basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()
	var camera_right: Vector3 = camera_basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()
	var movement: Vector3 = (camera_right * input_vector.x) + (camera_forward * input_vector.y)
	if movement.length() > 1.0:
		movement = movement.normalized()
	velocity.x = movement.x * MOVE_SPEED * speed_multiplier
	velocity.z = movement.z * MOVE_SPEED * speed_multiplier
	_apply_arena_bounds(center, radius)

func _apply_arena_bounds(center: Vector3, radius: float) -> void:
	var limit: float = max(1.0, radius - 0.6)
	var local_pos: Vector3 = global_position - center
	var clamped_x: float = clamp(local_pos.x, -limit, limit)
	var clamped_z: float = clamp(local_pos.z, -limit, limit)
	if clamped_x != local_pos.x:
		velocity.x = sign(clamped_x - local_pos.x) * MOVE_SPEED
	if clamped_z != local_pos.z:
		velocity.z = sign(clamped_z - local_pos.z) * MOVE_SPEED

func update_mouse_aim(camera: Camera3D, mouse_position: Vector2) -> void:
	if camera == null or not is_alive or shot_is_locked:
		return
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_position)
	var ray_direction: Vector3 = camera.project_ray_normal(mouse_position)
	if abs(ray_direction.y) < 0.001:
		return
	var plane_y: float = 0.62 if is_prone else global_position.y + 0.9
	var distance: float = (plane_y - ray_origin.y) / ray_direction.y
	if distance <= 0.0:
		return
	var hit_point: Vector3 = ray_origin + ray_direction * distance
	aim_at_point(hit_point)

func update_controller_aim(aim_input: Vector2, camera_basis: Basis) -> void:
	if not is_alive or shot_is_locked or aim_input.length() < 0.2:
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
	aim_at_point(global_position + aim_direction.normalized() * CONTROLLER_AIM_DISTANCE)

func choose_target(players: Array[PlayerCharacter], rng: RandomNumberGenerator) -> Variant:
	var candidates: Array[PlayerCharacter] = []
	for player: PlayerCharacter in players:
		if player != self and player.is_alive:
			candidates.append(player)
	if candidates.is_empty():
		return null
	return candidates[rng.randi_range(0, candidates.size() - 1)]

func aim_at_point(target: Vector3) -> void:
	aim_target = target
	var flat_target: Vector3 = target
	flat_target.y = global_position.y
	look_at(flat_target, Vector3.UP)
	update_laser()

func lock_for_light() -> void:
	# Verrouille la direction de tir pour la phase lumière.
	velocity = Vector3.ZERO
	locked_shot_direction = get_shot_direction()
	shot_is_locked = true
	update_laser()

func get_shot_direction() -> Vector3:
	var origin: Vector3 = get_muzzle_position()
	var direction: Vector3 = aim_target - origin
	if direction.length() < 0.1:
		return -global_basis.z
	return direction.normalized()

func get_locked_shot_direction() -> Vector3:
	if locked_shot_direction.length() < 0.1:
		return get_shot_direction()
	return locked_shot_direction.normalized()

func update_laser() -> void:
	# Met à jour position/orientation/longueur du laser visuel.
	var laser_root: Node3D = get_node_or_null("BodyRoot/LaserRoot") as Node3D
	var laser_mesh_instance: MeshInstance3D = get_node_or_null("BodyRoot/LaserRoot/LaserMesh") as MeshInstance3D
	if laser_root == null or laser_mesh_instance == null:
		return
	var muzzle_position: Vector3 = get_muzzle_position()
	var direction: Vector3 = get_locked_shot_direction() if shot_is_locked else get_shot_direction()
	var laser_length: float = clamp(max((aim_target - muzzle_position).length(), 20.0), LASER_MIN_LENGTH, LASER_MAX_LENGTH)
	laser_root.global_position = muzzle_position + direction * (laser_length * 0.5)
	laser_root.look_at(muzzle_position + direction * laser_length, Vector3.UP)
	laser_root.rotate_object_local(Vector3.RIGHT, deg_to_rad(90.0))
	var laser_mesh: CylinderMesh = laser_mesh_instance.mesh as CylinderMesh
	laser_mesh.height = laser_length

func _set_laser_visible(value: bool) -> void:
	var laser_root: Node3D = get_node_or_null("BodyRoot/LaserRoot") as Node3D
	if laser_root != null:
		laser_root.visible = value

func eliminate() -> void:
	if not is_alive:
		return
	is_alive = false
	velocity = Vector3.ZERO
	_ensure_collision_shapes()
	for shape_key: Variant in collision_shapes.keys():
		var shape_node: CollisionShape3D = collision_shapes[shape_key] as CollisionShape3D
		if shape_node != null:
			shape_node.disabled = true
	if body_root != null:
		body_root.visible = false
	_set_laser_visible(false)
	set_nameplate_visible(false)
	eliminated.emit(self)

func get_muzzle_position() -> Vector3:
	return muzzle.global_position if muzzle != null else global_position + Vector3(0.0, 0.62, -1.9)

func _apply_idle_pose() -> void:
	if is_prone:
		_set_node_transform("Torso", Vector3(0.0, 0.56, -0.1), Vector3.ZERO)
		_set_node_transform("Head", Vector3(0.0, 0.72, -0.92), Vector3.ZERO)
		_set_node_transform("ArmLeft", Vector3(-0.28, 0.54, -1.26), Vector3.ZERO)
		_set_node_transform("ArmRight", Vector3(0.28, 0.54, -1.26), Vector3.ZERO)
		_set_node_transform("LegLeft", Vector3(-0.2, 0.42, 1.02), Vector3.ZERO)
		_set_node_transform("LegRight", Vector3(0.2, 0.42, 1.02), Vector3.ZERO)
		_set_node_transform("BootLeft", Vector3(-0.2, 0.42, 1.55), Vector3.ZERO)
		_set_node_transform("BootRight", Vector3(0.2, 0.42, 1.55), Vector3.ZERO)
		_set_node_transform("Gun", Vector3(0.0, 0.66, -1.55), Vector3.ZERO)
		_set_node_transform("Nameplate", Vector3(0.0, 1.25, 0.0), Vector3.ZERO)
	else:
		_set_node_transform("Torso", Vector3(0.0, 1.15, 0.0), Vector3.ZERO)
		_set_node_transform("Head", Vector3(0.0, 1.95, 0.0), Vector3.ZERO)
		_set_node_transform("ArmLeft", Vector3(-0.65, 1.15, 0.0), Vector3.ZERO)
		_set_node_transform("ArmRight", Vector3(0.65, 1.15, 0.0), Vector3.ZERO)
		_set_node_transform("LegLeft", Vector3(-0.2, 0.42, 0.0), Vector3.ZERO)
		_set_node_transform("LegRight", Vector3(0.2, 0.42, 0.0), Vector3.ZERO)
		_set_node_transform("BootLeft", Vector3(-0.2, 0.06, 0.0), Vector3.ZERO)
		_set_node_transform("BootRight", Vector3(0.2, 0.06, 0.0), Vector3.ZERO)
		_set_node_transform("Gun", Vector3(0.48, 1.25, -0.52), Vector3.ZERO)
		_set_node_transform("Nameplate", Vector3(0.0, 2.7, 0.0), Vector3.ZERO)

func _update_animation(delta: float) -> void:
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	var movement_ratio: float = clamp(horizontal_speed / MOVE_SPEED, 0.0, 1.0)
	animation_time += delta * lerp(1.5, PRONE_SWING_SPEED if is_prone else WALK_SWING_SPEED, movement_ratio)
	var swing: float = sin(animation_time)
	var sway: float = cos(animation_time * 0.5)
	if is_prone:
		_apply_prone_animation(movement_ratio, swing, sway, delta)
	else:
		_apply_standing_animation(movement_ratio, swing, sway, delta)
	var nameplate: Node3D = get_node_or_null("BodyRoot/Nameplate") as Node3D
	if nameplate != null:
		nameplate.rotation = Vector3.ZERO
		nameplate.position = nameplate.position.lerp(Vector3(0.0, 1.25 if is_prone else 2.7, 0.0), clamp(delta * ANIMATION_LERP_SPEED, 0.0, 1.0))

func _apply_standing_animation(movement_ratio: float, swing: float, sway: float, delta: float) -> void:
	var bob: float = abs(sin(animation_time * 2.0)) * WALK_BOB_HEIGHT * movement_ratio
	_set_node_transform_lerped("Torso", Vector3(0.0, 1.15 + bob, 0.0), Vector3(0.06 * sway * movement_ratio, 0.0, 0.0), delta)
	_set_node_transform_lerped("Head", Vector3(0.0, 1.95 + bob * 0.5, 0.0), Vector3(-0.04 * sway * movement_ratio, 0.0, 0.0), delta)
	_set_node_transform_lerped("ArmLeft", Vector3(-0.65, 1.15 + bob, 0.0), Vector3(WALK_ARM_SWING * swing * movement_ratio, 0.0, 0.0), delta)
	_set_node_transform_lerped("ArmRight", Vector3(0.65, 1.15 + bob, 0.0), Vector3(-WALK_ARM_SWING * swing * movement_ratio, 0.0, 0.0), delta)
	_set_node_transform_lerped("LegLeft", Vector3(-0.2, 0.42 + bob * 0.2, 0.0), Vector3(-WALK_LEG_SWING * swing * movement_ratio, 0.0, 0.0), delta)
	_set_node_transform_lerped("LegRight", Vector3(0.2, 0.42 + bob * 0.2, 0.0), Vector3(WALK_LEG_SWING * swing * movement_ratio, 0.0, 0.0), delta)
	_set_node_transform_lerped("BootLeft", Vector3(-0.2, 0.06 + bob * 0.08, 0.0), Vector3(-WALK_LEG_SWING * swing * movement_ratio, 0.0, 0.0), delta)
	_set_node_transform_lerped("BootRight", Vector3(0.2, 0.06 + bob * 0.08, 0.0), Vector3(WALK_LEG_SWING * swing * movement_ratio, 0.0, 0.0), delta)
	_set_node_transform_lerped("Gun", Vector3(0.48, 1.25 + bob, -0.52), Vector3(-0.2 * swing * movement_ratio, 0.0, 0.0), delta)

func _apply_prone_animation(movement_ratio: float, swing: float, sway: float, delta: float) -> void:
	var crawl_bob: float = abs(sin(animation_time * 1.6)) * PRONE_BOB_HEIGHT * movement_ratio
	_set_node_transform_lerped("Torso", Vector3(0.0, 0.56 + crawl_bob, -0.1), Vector3(0.0, 0.0, 0.025 * sway * movement_ratio), delta)
	_set_node_transform_lerped("Head", Vector3(0.0, 0.72 + crawl_bob * 0.4, -0.92), Vector3(0.04 * sway * movement_ratio, 0.0, 0.0), delta)
	_set_node_transform_lerped("ArmLeft", Vector3(-0.28, 0.54 + crawl_bob, -1.26), Vector3(-PRONE_ARM_SWING * swing * movement_ratio, 0.0, 0.0), delta)
	_set_node_transform_lerped("ArmRight", Vector3(0.28, 0.54 + crawl_bob, -1.26), Vector3(PRONE_ARM_SWING * swing * movement_ratio, 0.0, 0.0), delta)
	_set_node_transform_lerped("LegLeft", Vector3(-0.2, 0.42 + crawl_bob * 0.5, 1.02), Vector3(PRONE_LEG_SWING * swing * movement_ratio, 0.0, 0.0), delta)
	_set_node_transform_lerped("LegRight", Vector3(0.2, 0.42 + crawl_bob * 0.5, 1.02), Vector3(-PRONE_LEG_SWING * swing * movement_ratio, 0.0, 0.0), delta)
	_set_node_transform_lerped("BootLeft", Vector3(-0.2, 0.42 + crawl_bob * 0.5, 1.55), Vector3(PRONE_LEG_SWING * swing * movement_ratio, 0.0, 0.0), delta)
	_set_node_transform_lerped("BootRight", Vector3(0.2, 0.42 + crawl_bob * 0.5, 1.55), Vector3(-PRONE_LEG_SWING * swing * movement_ratio, 0.0, 0.0), delta)
	_set_node_transform_lerped("Gun", Vector3(0.0, 0.66 + crawl_bob, -1.55), Vector3.ZERO, delta)

func _set_node_transform(node_name: String, target_position: Vector3, target_rotation: Vector3) -> void:
	var node: Node3D = get_node_or_null("BodyRoot/%s" % node_name) as Node3D
	if node == null:
		return
	node.position = target_position
	node.rotation = target_rotation

func _set_node_transform_lerped(node_name: String, target_position: Vector3, target_rotation: Vector3, delta: float) -> void:
	var node: Node3D = get_node_or_null("BodyRoot/%s" % node_name) as Node3D
	if node == null:
		return
	var weight: float = clamp(delta * ANIMATION_LERP_SPEED, 0.0, 1.0)
	node.position = node.position.lerp(target_position, weight)
	node.rotation = node.rotation.lerp(target_rotation, weight)

func _create_textured_material(texture: Texture2D) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_texture = texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 1.0
	return material

func _make_skin_texture(base: Color) -> ImageTexture:
	var light: Color = _shade(base, 1.08)
	var mid: Color = _shade(base, 0.98)
	var dark: Color = _shade(base, 0.86)
	var image: Image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y: int in range(8):
		for x: int in range(8):
			var pixel: Color = mid
			if (x + y) % 4 == 0:
				pixel = light
			elif (x * 2 + y) % 5 == 0:
				pixel = dark
			if y >= 6:
				pixel = _shade(pixel, 0.92)
			image.set_pixel(x, y, pixel)
	return ImageTexture.create_from_image(image)

func _make_face_texture(base: Color) -> ImageTexture:
	var skin_mid: Color = _shade(base, 1.0)
	var skin_dark: Color = _shade(base, 0.82)
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
		image.set_pixel(x, 1, _shade(beard, 1.08))
	for x: int in range(8):
		image.set_pixel(x, 6, skin_dark)
		image.set_pixel(x, 7, _shade(skin_dark, 0.95))
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

func _make_shirt_texture(base: Color) -> ImageTexture:
	var light: Color = _shade(base, 1.16)
	var mid: Color = _shade(base, 1.0)
	var dark: Color = _shade(base, 0.78)
	var seam: Color = _shade(base, 0.64)
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

func _make_pants_texture(base: Color, accent: Color) -> ImageTexture:
	var mixed: Color = base.lerp(Color(0.32, 0.36, 0.78), 0.45)
	var light: Color = _shade(mixed, 1.08)
	var mid: Color = _shade(mixed, 0.96)
	var dark: Color = _shade(accent.lerp(mixed, 0.55), 0.72)
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

func _make_boot_texture(base: Color) -> ImageTexture:
	var dark: Color = _shade(base, 0.48)
	var mid: Color = _shade(base, 0.65)
	var line: Color = _shade(base, 0.82)
	var image: Image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y: int in range(8):
		for x: int in range(8):
			var pixel: Color = dark if y > 2 else mid
			if y == 3 or y == 6:
				pixel = line
			image.set_pixel(x, y, pixel)
	return ImageTexture.create_from_image(image)

func _make_gun_texture(base: Color) -> ImageTexture:
	var dark: Color = _shade(base, 0.56)
	var mid: Color = _shade(base, 0.75)
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

func _make_hair_texture() -> ImageTexture:
	var base: Color = Color(0.28, 0.18, 0.1)
	var light: Color = _shade(base, 1.18)
	var dark: Color = _shade(base, 0.72)
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

func _shade(color: Color, factor: float) -> Color:
	return Color(
		clamp(color.r * factor, 0.0, 1.0),
		clamp(color.g * factor, 0.0, 1.0),
		clamp(color.b * factor, 0.0, 1.0),
		color.a
	)
