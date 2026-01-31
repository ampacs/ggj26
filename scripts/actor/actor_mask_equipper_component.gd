class_name ActorMaskEquipperComponent extends ActorComponent

signal equipped_mask
signal dropped_mask

@export var rigidbody: RigidBody3D
@export var maskAnchor: Node3D
@export var maskAnchorOffsetPosition: Vector3
@export var debuff: String = "mask"

var equippedMask: Item

func interact(item: Item) -> void:
	var itemMaskComponent: ItemMaskComponent = item.get_component(ItemMaskComponent)
	if itemMaskComponent == null:
		return

	var itemRigidbodyComponent: ItemRigidbodyComponent = item.get_component(ItemRigidbodyComponent)
	if itemRigidbodyComponent != null:
		itemRigidbodyComponent.rigidbody.freeze = true
		itemRigidbodyComponent.rigidbody.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC

	if item.collider != null:
		item.collider.disabled = true

	item.reparent(maskAnchor, true)
	item.position = Vector3.ZERO
	item.rotation = Vector3.ZERO
	equippedMask = item
	equipped_mask.emit()

func drop() -> void:
	if equippedMask == null:
		return

	var itemRigidbodyComponent: ItemRigidbodyComponent = equippedMask.get_component(ItemRigidbodyComponent)
	if itemRigidbodyComponent != null:
		itemRigidbodyComponent.rigidbody.freeze = false
		itemRigidbodyComponent.rigidbody.linear_velocity = rigidbody.linear_velocity
		itemRigidbodyComponent.rigidbody.apply_central_impulse(Vector3.UP * 5.)

	if equippedMask.collider != null:
		equippedMask.collider.disabled = false

	equippedMask.resetParentToOriginal()
	equippedMask = null

	dropped_mask.emit()
