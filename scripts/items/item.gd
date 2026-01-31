class_name Item extends Node3D

@export var components: Array[ItemComponent]

@export var collider: CollisionShape3D

func get_component(type: Variant) -> ItemComponent:
	for component in components:
		if is_instance_of(component, type):
			return component

	return null

func get_components(type: Variant) -> Array[ItemComponent]:
	var selectedComponents: Array[ItemComponent] = [] 

	for component in components:
		if is_instance_of(component, type):
			selectedComponents.append(component)

	return selectedComponents
