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

	item.global_position = maskAnchor.global_position
	item.rotation = Vector3.ZERO
	# item.reparent(maskAnchor, true)
	equippedMask = item

	PlayerStatus.add_debuff(debuff)

func _process(delta: float) -> void:
	if equippedMask != null:
		equippedMask.global_position = maskAnchor.global_position
		equippedMask.global_basis = maskAnchor.global_basis
