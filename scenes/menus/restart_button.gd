extends TextureButton

func resume() -> void:
	get_tree().paused = false
	visible = false

func _on_restart_pressed() -> void:
	resume()
	get_tree().reload_current_scene()
