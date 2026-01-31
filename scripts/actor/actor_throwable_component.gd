class_name ActorThrowableComponent extends ActorComponent

@export_group("References")
@export var playerController: PlayerController
@export var rigidbody: RigidBody3D

@export_group("Item Anchor")
@export var itemAnchor: Node3D
@export var itemAnchorOffsetPosition: Vector3

@export_group("Throw Configuration")
@export var minimumThrowHoldTime: float
@export var maximumThrowHoldTime: float
@export var minimumThrowSpeed: float
@export var maximumThrowSpeed: float
@export var startThrowAngle: float
@export var endThrowAngle: float

var heldItem: Item
var isThrowingAllowed := false

var startThrowTime: float

func interact(item: Item) -> void:
	var itemThrowableComponent: ItemThrowableComponent = item.get_component(ItemThrowableComponent)
	if itemThrowableComponent == null:
		return

	var itemRigidbodyComponent: ItemRigidbodyComponent = item.get_component(ItemRigidbodyComponent)
	if itemRigidbodyComponent != null:
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
	if heldItem == null || !isThrowingAllowed:
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
	var throwSpeed: float = lerp(minimumThrowSpeed, maximumThrowSpeed, t)
	var throwAngle: float = lerp_angle(startThrowAngle, endThrowAngle, t)

	var lookDirection := -get_viewport().get_camera_3d().get_global_transform().basis.z

	var throwDirection: Vector3 = project_on_plane(lookDirection, Vector3.UP)
	throwDirection = throwDirection.rotated(-playerController.global_basis.x, deg_to_rad(throwAngle))
	var throwForce := throwDirection * throwSpeed;

	dropItem()

	itemRigidbodyComponent.rigidbody.apply_central_impulse(throwForce)

func dropItem() -> void:
	heldItem.collider.set_disabled(false)

	var itemRigidbodyComponent: ItemRigidbodyComponent = heldItem.get_component(ItemRigidbodyComponent)
	if itemRigidbodyComponent != null:
		itemRigidbodyComponent.rigidbody.freeze = false
		itemRigidbodyComponent.rigidbody.linear_velocity = rigidbody.linear_velocity

	heldItem.resetParentToOriginal()
	heldItem = null
	isThrowingAllowed = false

func _process(delta: float) -> void:
	var pressed := Input.is_action_just_pressed("interact_%s" % playerController.playerId)
	if pressed:
		startThrow();

	var released := Input.is_action_just_released("interact_%s" % playerController.playerId)
	if released:
		if isThrowingAllowed:
			finalizeThrow()
		else:
			isThrowingAllowed = true

static func project_on_plane(vector: Vector3, surface_normal: Vector3) -> Vector3:
	var axis1 := vector.cross(surface_normal).normalized()
	var axis2 := axis1.cross(-surface_normal).normalized()

	return vector.project(axis1) + vector.project(axis2)
