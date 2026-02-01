class_name ActorThrowableComponent extends ActorComponent

@export_group("References")
@export var playerController: PlayerController
@export var rigidbody: RigidBody3D

@export_group("Item Anchor")
@export var itemAnchor: Node3D
@export var itemAnchorOffsetPosition: Vector3

@export_group("Collision")
@export_range(0.0, 5.0, 0.05) var ignore_player_release_radius: float = 0.9
@export_range(0.0, 2.0, 0.05) var ignore_player_release_max_time: float = 0.4
@export var vision_cone: Area3D

@export_group("Throw Configuration")
@export var minimumThrowHoldTime: float
@export var maximumThrowHoldTime: float
@export var minimumThrowSpeed: float
@export var maximumThrowSpeed: float
@export var throwingAngleDegrees: float
@export_range(0.0, 1.0, 0.05) var aim_assist_angle_multiplier: float = 0.25
@export_range(0.0, 25.0, 0.1) var aim_assist_min_distance: float = 2.0

@onready var throw_sfx: AudioStreamPlayer = $"../../throwSfx"

var heldItem: Item
var isThrowingAllowed := false

var startThrowTime: float

func _get_throw_origin_position() -> Vector3:
	if heldItem != null and is_instance_valid(heldItem):
		return heldItem.global_position
	if itemAnchor != null and is_instance_valid(itemAnchor):
		return itemAnchor.global_position
	if playerController != null and is_instance_valid(playerController):
		return playerController.global_position
	return Vector3.ZERO

func _get_player_aim_target_position(target: Node3D) -> Vector3:
	if target is PlayerController:
		var target_player: PlayerController = target
		var collision_shape_node := target_player.get_node_or_null("CollisionShape3D")
		if collision_shape_node != null and collision_shape_node is CollisionShape3D:
			var collision_shape: CollisionShape3D = collision_shape_node
			return collision_shape.global_position
	return target.global_position

func _get_look_direction() -> Vector3:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera != null:
		return -camera.global_transform.basis.z
	if playerController != null:
		return -playerController.global_transform.basis.z
	return Vector3.FORWARD

func _get_throw_pitch_axis(direction: Vector3) -> Vector3:
	var pitch_axis: Vector3 = direction.cross(Vector3.UP).normalized()
	if pitch_axis.length_squared() < 0.0001:
		return Vector3.RIGHT
	return pitch_axis

func _is_hit_target_or_child(collider: Variant, target: Node) -> bool:
	if collider == null:
		return false
	if collider == target:
		return true
	if collider is Node:
		var collider_node: Node = collider
		return collider_node.is_ancestor_of(target) or target.is_ancestor_of(collider_node)
	return false

func _has_line_of_sight_to(target: Node3D) -> bool:
	if target == null:
		return false
	if playerController == null:
		return false

	var space_state: PhysicsDirectSpaceState3D = playerController.get_world_3d().direct_space_state
	var ray_start: Vector3 = _get_throw_origin_position()
	var ray_end: Vector3 = _get_player_aim_target_position(target)

	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var exclude: Array[RID] = []
	if playerController != null:
		exclude.append(playerController.get_rid())
	if rigidbody != null and rigidbody != playerController:
		exclude.append(rigidbody.get_rid())
	if heldItem != null:
		var item_rigidbody: ItemRigidbodyComponent = heldItem.get_component(ItemRigidbodyComponent)
		if item_rigidbody != null and item_rigidbody.rigidbody != null:
			exclude.append(item_rigidbody.rigidbody.get_rid())
	query.exclude = exclude

	var hit: Dictionary = space_state.intersect_ray(query)
	if hit.is_empty():
		return true

	return _is_hit_target_or_child(hit.get("collider"), target)

func _acquire_visible_player_in_vision_cone(camera_forward: Vector3) -> PlayerController:
	if vision_cone == null:
		return null
	if playerController == null:
		return null

	var bodies: Array[Node3D] = vision_cone.get_overlapping_bodies()
	if bodies.is_empty():
		return null

	var throw_origin: Vector3 = _get_throw_origin_position()
	var camera_forward_normalized: Vector3 = camera_forward.normalized()

	var best_target: PlayerController = null
	var best_alignment: float = -INF
	var best_distance_sq: float = INF

	for body: Node3D in bodies:
		if !(body is PlayerController):
			continue
		var candidate: PlayerController = body as PlayerController
		if candidate == playerController:
			continue
		if !is_instance_valid(candidate):
			continue
		if !_has_line_of_sight_to(candidate):
			continue

		var candidate_target_position: Vector3 = _get_player_aim_target_position(candidate)
		var to_candidate: Vector3 = candidate_target_position - throw_origin
		var candidate_distance_sq: float = to_candidate.length_squared()
		if candidate_distance_sq <= 0.0001:
			continue
		var candidate_direction: Vector3 = to_candidate / sqrt(candidate_distance_sq)
		var candidate_alignment: float = camera_forward_normalized.dot(candidate_direction)

		if (
			candidate_alignment > best_alignment
			or (is_equal_approx(candidate_alignment, best_alignment) and candidate_distance_sq < best_distance_sq)
		):
			best_target = candidate
			best_alignment = candidate_alignment
			best_distance_sq = candidate_distance_sq

	return best_target

func interact(item: Item) -> void:
	if heldItem:
		return
	var itemThrowableComponent: ItemThrowableComponent = item.get_component(ItemThrowableComponent)
	if itemThrowableComponent == null:
		return

	var itemRigidbodyComponent: ItemRigidbodyComponent = item.get_component(ItemRigidbodyComponent)
	if itemRigidbodyComponent != null:
		_remove_player_collision_exceptions(itemRigidbodyComponent.rigidbody)
		itemRigidbodyComponent.rigidbody.freeze = true
		itemRigidbodyComponent.rigidbody.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC

	item.collider.set_disabled(true)

	item.reparent(itemAnchor, false)
	item.position = itemAnchorOffsetPosition
	item.rotation = Vector3.ZERO

	heldItem = item
	isThrowingAllowed = false

func startThrow() -> void:
	if heldItem == null || !isThrowingAllowed:
		return

	startThrowTime = Time.get_unix_time_from_system()

func finalizeThrow() -> void:
	if heldItem == null:
		return

	var current_time: float = Time.get_unix_time_from_system()
	var hold_time: float = current_time - startThrowTime
	self.throw_sfx.play()
	if hold_time < minimumThrowHoldTime:
		dropItem()

		return

	var held_item_rigidbody: ItemRigidbodyComponent = heldItem.get_component(ItemRigidbodyComponent)
	if held_item_rigidbody == null:
		return

	var look_direction: Vector3 = _get_look_direction()
	var aim_target: PlayerController = _acquire_visible_player_in_vision_cone(look_direction)

	var base_throw_angle_rad: float = deg_to_rad(throwingAngleDegrees)
	var assisted_throw_angle_rad: float = base_throw_angle_rad
	var throw_aim_direction: Vector3 = look_direction

	if aim_target != null:
		var throw_origin: Vector3 = _get_throw_origin_position()
		var aim_target_position: Vector3 = _get_player_aim_target_position(aim_target)
		var to_aim_target: Vector3 = aim_target_position - throw_origin
		if to_aim_target.length_squared() > 0.0001:
			throw_aim_direction = to_aim_target.normalized()
			var target_distance: float = to_aim_target.length()
			var is_close_range_assist: bool = aim_assist_min_distance > 0.0 and target_distance < aim_assist_min_distance
			assisted_throw_angle_rad = 0.0 if is_close_range_assist else (base_throw_angle_rad * aim_assist_angle_multiplier)

	var throw_pitch_axis: Vector3 = _get_throw_pitch_axis(throw_aim_direction)
	var throw_direction: Vector3 = throw_aim_direction.rotated(throw_pitch_axis, assisted_throw_angle_rad)
	var throw_impulse: Vector3 = throw_direction * maximumThrowSpeed

	var itemDamagerComponent: ItemDamagerComponent = heldItem.get_component(ItemDamagerComponent)
	if itemDamagerComponent != null:
		itemDamagerComponent.start_throw(playerController)

	dropItem(false)

	held_item_rigidbody.rigidbody.apply_central_impulse(throw_impulse)

func dropItem(inherit_player_velocity: bool = true) -> void:
	var itemRigidbodyComponent: ItemRigidbodyComponent = heldItem.get_component(ItemRigidbodyComponent)
	if itemRigidbodyComponent != null:
		_ignore_player_collision_until_clear(itemRigidbodyComponent.rigidbody)

	heldItem.collider.set_disabled(false)

	if itemRigidbodyComponent != null:
		itemRigidbodyComponent.rigidbody.freeze = false
		if inherit_player_velocity and rigidbody != null:
			itemRigidbodyComponent.rigidbody.linear_velocity = rigidbody.linear_velocity
		else:
			itemRigidbodyComponent.rigidbody.linear_velocity = Vector3.ZERO

	heldItem.resetParentToOriginal()
	heldItem = null
	isThrowingAllowed = false

func _player_collision_objects() -> Array[PhysicsBody3D]:
	var objects: Array[PhysicsBody3D] = []
	if rigidbody != null:
		objects.append(rigidbody)
	if playerController != null and playerController != rigidbody:
		objects.append(playerController)
	return objects

func _remove_player_collision_exceptions(item_body: RigidBody3D) -> void:
	if item_body == null:
		return
	for obj in _player_collision_objects():
		if obj != null:
			item_body.remove_collision_exception_with(obj)
			obj.remove_collision_exception_with(item_body)

func _ignore_player_collision_until_clear(item_body: RigidBody3D) -> void:
	if item_body == null:
		return

	var objects := _player_collision_objects()
	for obj in objects:
		if obj != null:
			item_body.add_collision_exception_with(obj)
			obj.add_collision_exception_with(item_body)

	_unignore_player_collision_when_safe.call_deferred(item_body, objects)

func _unignore_player_collision_when_safe(item_body: RigidBody3D, objects: Array[PhysicsBody3D]) -> void:
	if itemAnchor == null:
		return

	var start_ms := Time.get_ticks_msec()
	while is_instance_valid(item_body) and is_instance_valid(itemAnchor):
		var dist := item_body.global_position.distance_to(itemAnchor.global_position)
		if dist > ignore_player_release_radius:
			break
		if ignore_player_release_max_time > 0.0 and (Time.get_ticks_msec() - start_ms) >= int(ignore_player_release_max_time * 1000.0):
			break
		await get_tree().physics_frame

	if !is_instance_valid(item_body):
		return

	for obj in objects:
		if is_instance_valid(obj):
			item_body.remove_collision_exception_with(obj)
			obj.remove_collision_exception_with(item_body)

func _process(delta: float) -> void:
	var pressed := Input.is_action_just_pressed("interact_%s" % playerController.playerId)

	if pressed:
		startThrow();

	var released := Input.is_action_just_released("interact_%s" % playerController.playerId)
	if released:
		finalizeThrow()

static func project_on_plane(vector: Vector3, surface_normal: Vector3) -> Vector3:
	var axis1 := vector.cross(surface_normal).normalized()
	var axis2 := axis1.cross(-surface_normal).normalized()

	return vector.project(axis1) + vector.project(axis2)
