class_name ActorThrowableComponent extends ActorComponent

@export var itemAnchor: Node3D
@export var itemAnchorOffsetPosition: Vector3
var heldItem: Item
var justPickedUp := false
 
func interact(item: Item) -> void:
	var itemThrowableComponent: ItemThrowableComponent = item.get_component(ItemThrowableComponent)
	if itemThrowableComponent == null:
		return
	
	var itemRigidbodyComponent: ItemRigidbodyComponent = item.get_component(ItemRigidbodyComponent)
	if itemRigidbodyComponent != null:
		itemRigidbodyComponent.rigidbody.freeze = true
		itemRigidbodyComponent.rigidbody.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	
	item.collider.set_disabled(true)
	
	item.reparent(itemAnchor, false)
	item.position = itemAnchorOffsetPosition
	item.rotation = Vector3.ZERO
	
	heldItem = item
	justPickedUp = true

func dropItem() -> void:
	if(heldItem == null || justPickedUp):
		return
	
	heldItem.collider.set_disabled(false)
	
	var itemRigidbodyComponent: ItemRigidbodyComponent = heldItem.get_component(ItemRigidbodyComponent)
	if itemRigidbodyComponent != null:
		itemRigidbodyComponent.rigidbody.freeze = false
	
	heldItem.resetParentToOriginal()

func _process(delta: float) -> void:
	var drop := Input.is_action_just_pressed("interact_player1")
	if drop:
		dropItem();
		
	justPickedUp = false
