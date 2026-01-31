extends Control
@export var scene: PackedScene;

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(scene.resource_path)

func _on_exit_pressed() -> void:
	get_tree().quit()
