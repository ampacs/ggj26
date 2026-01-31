class_name ActorMaskEquipperComponent extends ActorComponent

@export var maskAnchor: Node3D
@export var maskAnchorOffsetPosition: Vector3
@export var debuff: String = "mask"

var equippedMask: Item

func interact(item: Item) -> void:
	var itemMaskComponent: ItemMaskComponent = item.get_component(ItemMaskComponent)
	if itemMaskComponent == null:
		PlayerStatus.remove_debuff(debuff)
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

	PlayerStatus.add_debuff(debuff)
