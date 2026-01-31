class_name ActorThrowableComponent extends ActorComponent

@export var itemAnchor: Node3D
@export var itemAnchorOffsetPosition: Vector3
var heldItem: Item
 
func interact(item: Item) -> void:
	var itemThrowableComponent: ItemThrowableComponent = item.get_component(ItemThrowableComponent)
	if itemThrowableComponent == null:
		return

	var itemRigidbodyComponent: ItemRigidbodyComponent = item.get_component(ItemRigidbodyComponent)
	if itemRigidbodyComponent != null:
		itemRigidbodyComponent.rigidbody.freeze = true
		itemRigidbodyComponent.rigidbody.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC

	item.reparent(itemAnchor, false)
	item.position = itemAnchorOffsetPosition
	item.rotation = Vector3.ZERO
	heldItem = item

func dropItem() -> void:
	if(heldItem == null):
		return
	
	var itemRigidbodyComponent: ItemRigidbodyComponent = heldItem.get_component(ItemRigidbodyComponent)
	if itemRigidbodyComponent != null:
		itemRigidbodyComponent.rigidbody.freeze = false

func _process(delta: float) -> void:
	var jump := Input.is_action_just_pressed("jump_player1")
	if jump:
		dropItem();
