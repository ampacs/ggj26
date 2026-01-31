class_name ActorMaskEquipperComponent extends ActorComponent

@export var maskAnchor: Node3D
@export var maskAnchorOffsetPosition: Vector3

func interact(item: Item) -> void:
	var itemMaskComponent: ItemMaskComponent = item.get_component(ItemMaskComponent)
	if itemMaskComponent == null:
		return

	var itemRigidbodyComponent: ItemRigidbodyComponent = item.get_component(ItemRigidbodyComponent)
	if itemRigidbodyComponent != null:
		itemRigidbodyComponent.rigidbody.freeze = true
		itemRigidbodyComponent.rigidbody.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC

	item.reparent(maskAnchor, false)
	item.position = maskAnchorOffsetPosition
	item.rotation = Vector3.ZERO
