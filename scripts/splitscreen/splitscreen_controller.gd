extends Node

@export var box: HBoxContainer
@export var viewports: Array[SubViewport]
@export var world: World3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if len(viewports) == 0:
		return

	world = viewports[0].world_3d
	for viewport in viewports:
		viewport.world_3d = world

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
