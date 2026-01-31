class_name Actor extends Node

@export var components: Array[ActorComponent]

func interact(item: Item) -> void:
	for component in components:
		component.interact(item)
