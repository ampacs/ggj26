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

@export_group("Throw Configuration")
@export var minimumThrowHoldTime: float
@export var maximumThrowHoldTime: float
@export var minimumThrowSpeed: float
@export var maximumThrowSpeed: float
@export var throwingAngleDegrees: float

var heldItem: Item
var isThrowingAllowed := false

var startThrowTime: float

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

	var now := Time.get_unix_time_from_system()
	var delta := now - startThrowTime
	if delta < minimumThrowHoldTime:
		dropItem()

		return

	var itemRigidbodyComponent: ItemRigidbodyComponent = heldItem.get_component(ItemRigidbodyComponent)
	if itemRigidbodyComponent == null:
		return

	var t: float = min(1., delta / (maximumThrowHoldTime - minimumThrowHoldTime))
	
	var throwAngle := deg_to_rad(throwingAngleDegrees)
	var lookDirection := -get_viewport().get_camera_3d().get_global_transform().basis.z

	var throwDirection := lookDirection.rotated(lookDirection.cross(Vector3.UP).normalized(), throwAngle)
	var throwForce := throwDirection * maximumThrowSpeed;

	var itemDamagerComponent: ItemDamagerComponent = heldItem.get_component(ItemDamagerComponent)
	if itemDamagerComponent != null:
		itemDamagerComponent.start_throw(playerController)

	dropItem()

	itemRigidbodyComponent.rigidbody.apply_central_impulse(throwForce)

func dropItem() -> void:
	var itemRigidbodyComponent: ItemRigidbodyComponent = heldItem.get_component(ItemRigidbodyComponent)
	if itemRigidbodyComponent != null:
		_ignore_player_collision_until_clear(itemRigidbodyComponent.rigidbody)

	heldItem.collider.set_disabled(false)

	if itemRigidbodyComponent != null:
		itemRigidbodyComponent.rigidbody.freeze = false
		itemRigidbodyComponent.rigidbody.linear_velocity = rigidbody.linear_velocity

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
