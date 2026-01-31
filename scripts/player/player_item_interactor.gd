extends Node3D

@export var playerController: PlayerController
@export var maximumDistance: float
@export var interactionRadius: float
@export var actor: Actor

var debugMesh: MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# var mesh_instance := MeshInstance3D.new()
	# var sphere_mesh := SphereMesh.new()
	# sphere_mesh.radius = interactionRadius  # Set the radius
	# mesh_instance.mesh = sphere_mesh
	# get_tree().root.add_child(mesh_instance)
	# debugMesh = mesh_instance
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var is_interacting := Input.is_action_just_pressed("interact_%s" % [playerController.playerId])
	if !is_interacting:
		return

	var space_state := self.get_world_3d().direct_space_state

	var camera := get_viewport().get_camera_3d()
	var lookDirection := get_viewport().get_camera_3d().get_global_transform().basis.z

	var from := camera.global_position
	var to := from + lookDirection * maximumDistance

	var distanceQuery := PhysicsRayQueryParameters3D.new()
	distanceQuery.from = from
	distanceQuery.to = to

	var targetPosition: Vector3
	var distanceQueryResult := space_state.intersect_ray(distanceQuery)
	if distanceQueryResult.is_empty():
		targetPosition = to
	else:
		targetPosition = distanceQueryResult.position
	targetPosition = self.global_position

	var shape: SphereShape3D = SphereShape3D.new()
	shape.radius = interactionRadius

	var shapeTransform := Transform3D.IDENTITY
	shapeTransform.origin = targetPosition

	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.transform = shapeTransform
	query.shape = shape

	# debugMesh.global_position = targetPosition
	# print(targetPosition)

	var shapeQueryResults := space_state.intersect_shape(query)
	if shapeQueryResults.is_empty():
		return

	var closestItem: Item
	var closestItemDistance: float = INF
	for result in shapeQueryResults:
		var colliderPosition: Vector3 = result.collider.position
		var distance := self.position.distance_squared_to(colliderPosition)
		if distance >= closestItemDistance:
			continue

		var collider: Node3D = result.collider
		# print(collider.name)
		if collider is Item:
			closestItem = collider
			closestItemDistance = distance
		else:
			var selected := false
			for child in get_children():
				if child is Item:
					closestItem = child
					closestItemDistance = distance
					selected = true
					break
			if selected:
				continue

		var currentParent := collider.get_parent()
		while currentParent != null:
			# print("\t" , currentParent.name)
			if currentParent is not Item:
				currentParent = currentParent.get_parent()
				continue

			closestItem = currentParent
			closestItemDistance = distance
			break

	if closestItem != null:
		actor.interact(closestItem)
