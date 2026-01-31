class_name Actor extends Node

@export var components: Array[ActorComponent]

func get_component(type: Variant) -> ActorComponent:
	for component in components:
		if is_instance_of(component, type):
			return component

	return null

func interact(item: Item) -> void:
	for component in components:
		component.interact(item)
